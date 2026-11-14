import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

import '../../../core/access/access.dart';
import '../../../core/access/addon_store.dart';
import '../../../core/api/api_client.dart';
import '../../../core/db/atom_db.dart';
import '../../../core/db/copy_key.dart';
import '../../../core/db/copy_photos.dart';
import '../../../core/db/outbox_db.dart';
import '../../../core/db/outbox_files.dart';
import '../../../core/db/sync_store.dart';
import '../../../core/session/session.dart';
import '../../../core/quiet_logs.dart';
import '../../../core/session/session_store.dart';
import '../../../core/update/update_policy.dart';
import 'sync_engine.dart';
import 'sync_repository.dart';

/// Sync with the app closed.
///
/// A seller does not know when their signal went, or when it came back.
/// A payment taken in a basement has to reach Atomshop when the phone next
/// has a network — not when the seller next happens to open the app. And a
/// copy that is a day old is worse than one that is an hour old.
///
/// Three triggers, all through Android's WorkManager, all waiting for a
/// network:
///
/// - **Every [every]**, while the account has the Offline add-on.
/// - **Something was saved with no signal** ([soon]): a one-off that runs
///   the moment a network is back, even if the app was closed by then.
/// - **Atomshop says something changed** (`sync_now` push with the app in
///   the background): the same one-off.
///
/// **One database, one writer.** The app and this task never write the
/// files at the same time:
///
/// - While the app is open in this process it has registered [appPort].
///   The task finds it, asks the app to sync instead, and stops.
/// - While the task runs it holds [taskPort]. The app, opening part-way
///   through, sees it and leaves its first sync to the next trigger.
///
/// The server's once-only rule (every action carries the uuid it was made
/// with) is the backstop behind both: an action sent twice is applied
/// once.
///
/// **What it can open.** The outbox always — it has its own key, never
/// wrapped by the PIN, so a queued payment goes up whether or not anyone
/// has unlocked the phone. The copy only when its key is not wrapped: a
/// phone with a PIN keeps its copy shut until the PIN is entered, and the
/// task leaves it alone (`SyncEngine` sends and stops).
abstract final class BackgroundSync {
  /// How often, at most, while the app is closed. WorkManager may batch it
  /// with other apps' work and run it later; never more often.
  static const every = Duration(hours: 2);

  /// The app's port while it is open in this process.
  static const appPort = 'atom_seller.app';

  /// The task's port while it runs.
  static const taskPort = 'atom_seller.background_sync';

  static const _task = 'atom.sync';
  static const _periodic = 'atom.sync.periodic';
  static const _soon = 'atom.sync.soon';

  static final _connected = Constraints(networkType: NetworkType.connected);

  /// The every-two-hours run also waits for a battery that isn't low: it
  /// is only keeping the copy fresh. A save's own run (one-off, [soon])
  /// keeps [_connected] alone, so a payment goes up on any battery.
  static final _connectedNotLow = Constraints(
    networkType: NetworkType.connected,
    requiresBatteryNotLow: true,
  );

  /// Android (WorkManager) and iOS (BGTaskScheduler, set up in
  /// `AppDelegate.swift` and `Info.plist`). On iOS the system decides when
  /// a periodic run happens, and a one-off runs in the short window after
  /// the app goes to the background rather than waiting for a network.
  static bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static bool _initialised = false;

  /// Once, before any of the others. In `main`.
  static Future<void> initialise() async {
    if (!_supported || _initialised) return;
    try {
      await Workmanager().initialize(backgroundSyncDispatcher);
      _initialised = true;
    } catch (e) {
      debugPrint('[background sync] could not start: $e');
    }
  }

  /// The account works offline: sync every [every] while the app is closed.
  static Future<void> schedule() async {
    if (!_supported) return;
    await initialise();
    try {
      await Workmanager().registerPeriodicTask(
        _periodic,
        _task,
        frequency: every,
        constraints: _connectedNotLow,
        // `update`, not `keep`: a different [every] in a newer app takes
        // effect instead of the old one living on.
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
    } catch (e) {
      debugPrint('[background sync] could not schedule: $e');
    }
  }

  /// A closed app runs at most one nudged sync in this long. A busy shop
  /// sends a `sync_now` for every payment anyone takes; without this, each
  /// one would wake every other phone for a whole sync.
  static const nudgeGap = Duration(minutes: 10);

  /// As soon as there is a network, even if the app is closed by then.
  /// Asked for when something is saved with no signal, and when Atomshop
  /// says something changed. Several asks before it runs are one run.
  ///
  /// [nudge]: Atomshop said something changed. Within [nudgeGap] of the
  /// last background run it waits out the gap instead, and every nudge in
  /// between joins that one run. A save made with no signal never waits:
  /// that is the seller's own work.
  static Future<void> soon({bool nudge = false}) async {
    if (!_supported) return;
    await initialise();
    var wait = Duration.zero;
    if (nudge) {
      final last = await _lastRun();
      if (last != null) {
        final since = DateTime.now().difference(last);
        if (since >= Duration.zero && since < nudgeGap) wait = nudgeGap - since;
      }
    }
    try {
      await Workmanager().registerOneOffTask(
        _soon,
        _task,
        constraints: _connected,
        initialDelay: wait,
        // A nudge joins whatever is queued. The seller's own save replaces
        // it, so it never waits behind a nudge's delay.
        existingWorkPolicy: nudge
            ? ExistingWorkPolicy.keep
            : ExistingWorkPolicy.replace,
      );
    } catch (e) {
      debugPrint('[background sync] could not ask for a run: $e');
    }
  }

  /// When the last background run finished: a file of its own, readable
  /// from the push handler's isolate with nothing else started.
  static Future<File> _lastRunFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'background_sync_at'));
  }

  static Future<DateTime?> _lastRun() async {
    try {
      final f = await _lastRunFile();
      if (!await f.exists()) return null;
      return DateTime.tryParse((await f.readAsString()).trim());
    } catch (_) {
      return null;
    }
  }

  static Future<void> _ranNow() async {
    try {
      await (await _lastRunFile()).writeAsString(
        DateTime.now().toIso8601String(),
        flush: true,
      );
    } catch (_) {}
  }

  /// No add-on, or nobody signed in: nothing to sync in the background.
  static Future<void> stop() async {
    if (!_supported || !_initialised) return;
    try {
      await Workmanager().cancelByUniqueName(_periodic);
      await Workmanager().cancelByUniqueName(_soon);
    } catch (e) {
      debugPrint('[background sync] could not stop: $e');
    }
  }

  /// True while a background run holds the files.
  static bool get running =>
      IsolateNameServer.lookupPortByName(taskPort) != null;
}

/// WorkManager's entry point. Runs on its own isolate, with no `main()`
/// behind it.
@pragma('vm:entry-point')
void backgroundSyncDispatcher() {
  quietLogsInRelease();
  Workmanager().executeTask((task, input) async {
    try {
      await runBackgroundSync();
    } catch (e) {
      debugPrint('[background sync] failed: $e');
    }
    // Always "done": a failed run is tried again by the next trigger, not
    // retried in a loop by WorkManager on a phone with a bad connection.
    return true;
  });
}

/// One background run. Public for the app's own use and for a test.
@visibleForTesting
Future<void> runBackgroundSync() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  // The platform and build go with each request: a pulled build is told
  // to stop syncing here too.
  await InstalledApp.load();

  // The app is open in this process: it syncs, and owns the files.
  final app = IsolateNameServer.lookupPortByName(BackgroundSync.appPort);
  if (app != null) {
    app.send('sync');
    return;
  }

  // Hold the files. Another background run already does: let it finish.
  final mine = ReceivePort();
  if (!IsolateNameServer.registerPortWithName(
    mine.sendPort,
    BackgroundSync.taskPort,
  )) {
    mine.close();
    return;
  }

  try {
    final session = await const SecureSessionStore().read();
    if (session == null) return;
    final addons = await AddonStore.read(session.userId);
    if (addons == null || !(addons[Addon.offline]?.usable ?? false)) return;
    // The copy's scope: the outlet chosen, or 0 for the whole brand.
    final shopId = session.outletId ?? 0;

    final outbox = OutboxDb.open();
    final copy = AtomDb.open();
    try {
      // Not wrapped by a PIN: the whole sync. Wrapped: only what is waiting
      // goes, and the copy stays shut until someone unlocks the phone.
      final copyOpen = await CopyKey.openIfNotWrapped();
      final engine = SyncEngine(
        repository: ApiSyncRepository(ApiClient(auth: _Stored(session))),
        // Only what this person saved goes up under their token.
        store: SyncStore(copy, outbox, userId: session.userId),
        photos: await _orNull(OutboxFiles.open),
        copyPhotos: copyOpen ? await _orNull(CopyPhotos.start) : null,
        copyOpen: () => copyOpen,
        copyId: CopyKey.currentId,
        // Shut behind a PIN: what changed is fetched and kept sealed, to
        // be applied the moment the PIN opens the copy.
        seal: CopyKey.seal,
        openSealed: CopyKey.openSealed,
        storedCopyId: CopyKey.storedId,
      );
      final out = await engine.run(shopId: shopId);
      await BackgroundSync._ranNow();
      debugPrint(
        '[background sync] sent ${out.sent}, '
        '${out.rows} rows, stop: ${out.stop}',
      );
    } finally {
      await copy.close();
      await outbox.close();
    }
  } finally {
    IsolateNameServer.removePortNameMapping(BackgroundSync.taskPort);
    mine.close();
  }
}

Future<T?> _orNull<T>(Future<T> Function() open) async {
  try {
    return await open();
  } catch (_) {
    return null;
  }
}

/// The signed-in person, from what the app stored, for a run with no app.
class _Stored implements ApiAuthSource {
  const _Stored(this.session);
  final BrandSession session;

  @override
  String? get token => session.token;

  @override
  int? get outletId => session.who.isOwner ? session.outletId : null;
}
