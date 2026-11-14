import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/atom_db.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/db/copy_key.dart';
import '../../../core/db/copy_photos.dart';
import '../../../core/db/outbox_files.dart';
import '../../../core/db/sync_store.dart';
import '../../../core/net/network_status.dart';
import '../../../core/session/session_controller.dart';
import 'background_sync.dart';
import 'offline_saves.dart';
import 'sync_engine.dart';
import 'sync_models.dart';
import '../../../core/db/outbox_db.dart';
import 'sync_repository.dart';

/// Whether the copy's key is open, so the copy can be read.
///
/// With no PIN in the way it opens at launch. Once its key is wrapped by
/// the PIN (`RULES.md` §5) it opens when the PIN is entered, or when the
/// fingerprint gives back its copy of the key.
final copyOpenProvider = NotifierProvider<CopyOpen, bool>(CopyOpen.new);

class CopyOpen extends Notifier<bool> {
  @override
  bool build() {
    void follow() => state = CopyKey.opened.value;
    CopyKey.opened.addListener(follow);
    ref.onDispose(() => CopyKey.opened.removeListener(follow));
    if (!CopyKey.isOpen) Future.microtask(CopyKey.openIfNotWrapped);
    return CopyKey.isOpen;
  }
}

/// The phone's encrypted copy. One per app run; it closes with the
/// provider.
///
/// Made again whenever the copy opens or closes. Not for tidiness: a
/// database asked for while its key was shut has failed to open, and the
/// database layer keeps that failure for good, so the one made after the
/// PIN has to be a new one.
final atomDbProvider = Provider<AtomDb>((ref) {
  ref.watch(copyOpenProvider);
  final db = AtomDb.open();
  ref.onDispose(db.close);
  return db;
});

/// What this phone has made and not sent. Its own file and its own key,
/// so it is readable even when the copy is not.
final outboxDbProvider = Provider<OutboxDb>((ref) {
  final db = OutboxDb.open();
  ref.onDispose(db.close);
  return db;
});

/// The store, for the person signed in: what they save is marked as
/// theirs, and only theirs is sent or counted.
final syncStoreProvider = Provider<SyncStore>(
  (ref) => SyncStore(
    ref.watch(atomDbProvider),
    ref.watch(outboxDbProvider),
    userId: ref.watch(
      sessionProvider.select((s) => s is SignedIn ? s.session.userId : null),
    ),
  ),
);

/// The outlet scope this copy is of: the outlet chosen, else 0 (the whole
/// brand). `X-Outlet` carries the same choice to the server.
final syncShopIdProvider = Provider<int?>((ref) {
  ref.watch(sessionProvider);
  final s = ref.read(sessionProvider.notifier).current;
  // The copy's scope: the outlet chosen, or 0 for the whole brand (the
  // same rule as BackgroundSync).
  return s == null ? null : (s.outletId ?? 0);
});

/// Where the photos that come down with the copy are kept.
///
/// Null when app storage cannot be reached. It answers null rather than
/// failing, because a provider that throws is retried for ever: a phone
/// that can sync its rows but not keep photos should sync its rows.
final copyPhotosProvider = FutureProvider<CopyPhotos?>(
  (ref) => _orNull(CopyPhotos.start, "the copy's photos"),
);

/// Where the photos of a queued save are kept. It opens the folder in
/// the background; a save made in that first second waits for it.
final outboxFilesProvider = FutureProvider<OutboxFiles?>(
  (ref) => _orNull(OutboxFiles.open, "the outbox's photos"),
);

Future<T?> _orNull<T>(Future<T> Function() open, String what) async {
  try {
    return await open();
  } on Object catch (e) {
    debugPrint('[sync] no folder for $what: $e');
    return null;
  }
}

final syncEngineProvider = Provider<SyncEngine>(
  (ref) => SyncEngine(
    repository: ref.watch(syncRepositoryProvider),
    store: ref.watch(syncStoreProvider),
    photos: ref.watch(outboxFilesProvider).value,
    copyPhotos: ref.watch(copyPhotosProvider).value,
    onProgress: (p) => ref.read(syncStatusProvider.notifier).onProgress(p),
    copyOpen: () => ref.read(copyOpenProvider),
    copyId: CopyKey.currentId,
    seal: CopyKey.seal,
    openSealed: CopyKey.openSealed,
    storedCopyId: CopyKey.storedId,
  ),
);

/// The phone's copy, for reading when there is no signal.
///
/// Null unless the account works offline and the phone knows its shop, so
/// a repository without one behaves exactly as it always did.
@immutable
class OfflineCopy {
  const OfflineCopy({
    required this.db,
    required this.shopId,
    required this.isOnline,
  });

  final AtomDb db;
  final int shopId;

  /// What the phone last knew about its network. False means read the
  /// copy first rather than wait for a call to fail.
  final bool Function() isOnline;
}

final offlineCopyProvider = Provider<OfflineCopy?>((ref) {
  final shopId = ref.watch(syncShopIdProvider);
  final on = ref.watch(accessProvider).has(Addon.offline);
  if (!on || shopId == null) return null;
  // Shut until the PIN or fingerprint opens it: the screens ask the
  // server instead, which is what they did before there was a copy.
  if (!ref.watch(copyOpenProvider)) return null;
  // A shop this phone has never downloaded (a branch switched to with no
  // signal): an empty copy would answer "0 orders", which reads as "this
  // shop has none". Asking the server instead says "No internet", which
  // is the truth. Assumed downloaded until the answer is in, so a phone
  // opening with no signal never starts on the wrong foot.
  if (!(ref.watch(shopDownloadedProvider).value ?? true)) return null;
  return OfflineCopy(
    db: ref.watch(atomDbProvider),
    shopId: shopId,
    isOnline: () => ref.read(onlineProvider).value ?? true,
  );
});

/// Whether this phone's copy holds the shop on screen: it has finished a
/// download of it at least once.
final shopDownloadedProvider = FutureProvider<bool>((ref) async {
  final shopId = ref.watch(syncShopIdProvider);
  if (shopId == null) return false;
  // Asked again after each sync, which is when the answer can change.
  ref.watch(syncStatusProvider.select((s) => s.lastSyncAt));
  try {
    return await ref
            .watch(syncStoreProvider)
            .meta(SyncEngine.lastSyncKey, shopId: shopId) !=
        null;
  } catch (_) {
    // Can't tell (the outbox didn't open): behave as before, rather than
    // throw and be retried in a loop.
    return true;
  }
});

/// Saves that can wait for a signal, for the repositories.
///
/// Null until the account works offline and the phone knows which shop it
/// is in: a repository with no [OfflineSaves] calls the server and fails
/// as it always did, which is what every account without the add-on
/// wants.
final offlineSavesProvider = Provider<OfflineSaves?>((ref) {
  final shopId = ref.watch(syncShopIdProvider);
  final on = ref.watch(accessProvider).has(Addon.offline);
  if (!on || shopId == null) return null;
  return OfflineSaves(
    store: ref.watch(syncStoreProvider),
    // Awaited at the moment a save needs it, not read now: the folder
    // opens in the background and a save in that first second must
    // wait for it rather than lose its photo.
    photos: () => ref.read(outboxFilesProvider.future),
    shopId: shopId,
    enabled: true,
    // `onlineProvider` is the phone's own radio. It cannot promise the
    // server answers, so a call is still tried; this only decides
    // whether to try at all.
    isOnline: () => ref.read(onlineProvider).value ?? true,
    onQueued: () {
      ref.read(syncStatusProvider.notifier).refresh();
      // Saved with no signal: it goes the moment a network is back, even
      // if the seller has closed the app by then.
      unawaited(BackgroundSync.soon());
    },
  );
});

/// What the Sync centre (10.1) and the offline bar show.
@immutable
class SyncStatus {
  const SyncStatus({
    this.progress = const SyncProgress(),
    this.waiting = 0,
    this.attention = 0,
    this.lastSyncAt,
    this.offlineUntil,
    this.stop,
    this.message,
    this.loaded = false,
    this.photos = 0,
    this.check,
  });

  final SyncProgress progress;

  /// Waiting changes that carry a photo (10.1's Photos).
  final int photos;

  /// The last `sync/check` answer this run of the app got: read-only,
  /// the versions for 10.6, this phone as the server has it.
  final SyncCheck? check;

  /// Saves on this phone that have not reached the server.
  final int waiting;

  /// Saves the server would not apply.
  final int attention;
  final DateTime? lastSyncAt;

  /// The day this phone stops working without the server.
  final DateTime? offlineUntil;

  /// Why the last run stopped, when it did.
  final SyncStop? stop;
  final String? message;
  final bool loaded;

  /// A run is going. Every phase is named, so a new one has to be put on
  /// one side or the other: the photos were once left off, and a second
  /// run could start while the first was still fetching them.
  bool get running => switch (progress.phase) {
    SyncPhase.checking ||
    SyncPhase.sending ||
    SyncPhase.downloading ||
    SyncPhase.photos => true,
    SyncPhase.idle || SyncPhase.done || SyncPhase.failed => false,
  };

  /// Nothing of this phone's own is unsent.
  bool get settled => waiting == 0 && attention == 0;

  SyncStatus copyWith({
    SyncProgress? progress,
    int? waiting,
    int? attention,
    DateTime? Function()? lastSyncAt,
    DateTime? Function()? offlineUntil,
    SyncStop? Function()? stop,
    String? Function()? message,
    bool? loaded,
    int? photos,
    SyncCheck? check,
  }) => SyncStatus(
    progress: progress ?? this.progress,
    waiting: waiting ?? this.waiting,
    attention: attention ?? this.attention,
    lastSyncAt: lastSyncAt == null ? this.lastSyncAt : lastSyncAt(),
    offlineUntil: offlineUntil == null ? this.offlineUntil : offlineUntil(),
    stop: stop == null ? this.stop : stop(),
    message: message == null ? this.message : message(),
    loaded: loaded ?? this.loaded,
    photos: photos ?? this.photos,
    check: check ?? this.check,
  );
}

final syncStatusProvider = NotifierProvider<SyncController, SyncStatus>(
  SyncController.new,
);

/// Runs a sync and keeps what the screens show in step with the outbox.
class SyncController extends Notifier<SyncStatus> {
  @override
  SyncStatus build() {
    Future.microtask(refresh);
    return const SyncStatus();
  }

  SyncStore get _store => ref.read(syncStoreProvider);

  /// The counts and dates, read from the phone. Cheap enough to call after
  /// anything that writes to the outbox.
  Future<void> refresh() async {
    final shopId = ref.read(syncShopIdProvider);
    try {
      final waiting = await _store.waitingCount();
      final attention = (await _store.needingAttention()).length;
      final photos = await _store.waitingPhotos();
      DateTime? last;
      DateTime? until;
      if (shopId != null) {
        final raw = await _store.meta(SyncEngine.lastSyncKey, shopId: shopId);
        last = raw == null ? null : DateTime.tryParse(raw)?.toLocal();
        // Read from the phone, not only from the last run: an app
        // started with no signal still knows when its window closes.
        final end = await _store.meta(SyncEngine.untilKey, shopId: shopId);
        until = end == null ? null : DateTime.tryParse(end)?.toLocal();
      }
      state = state.copyWith(
        waiting: waiting,
        attention: attention,
        lastSyncAt: () => last,
        // The phone's record is the answer, gone included: every check
        // writes or removes it, so an older value held here is stale.
        offlineUntil: () => until,
        photos: photos,
        loaded: true,
      );
    } catch (e) {
      debugPrint('[sync] could not read the phone: $e');
      state = state.copyWith(loaded: true);
    }
  }

  void onProgress(SyncProgress p) => state = state.copyWith(progress: p);

  /// One run for the shop on screen. Answers what it did, so a screen can
  /// say so; the state is updated either way.
  Future<SyncOutcome?> syncNow() async {
    if (state.running) return null;
    final shopId = ref.read(syncShopIdProvider);
    if (shopId == null) return null;

    state = state.copyWith(stop: () => null, message: () => null);
    SyncOutcome out;
    try {
      out = await ref.read(syncEngineProvider).run(shopId: shopId);
    } catch (e, st) {
      // A run that throws must still end: left in a running phase, every
      // later syncNow would return at the guard above until a restart.
      debugPrint('[sync] the run broke: $e\n$st');
      out = const SyncOutcome(ok: false, stop: SyncStop.failed);
    }
    if (out.stop == SyncStop.wiped) {
      await wipedByServer(out.message);
      return out;
    }
    state = state.copyWith(
      check: out.check,
      stop: () => out.stop,
      message: () => out.message,
      // A run that reached the server has its answer, no date included;
      // one that didn't keeps what was known.
      offlineUntil: () =>
          out.check != null ? out.check!.offline.until : state.offlineUntil,
      progress: SyncProgress(phase: out.ok ? SyncPhase.done : SyncPhase.failed),
    );
    await refresh();
    return out;
  }

  /// The phone was told to wipe (`sync/check` → `wipe`), or signed out by
  /// the server (401): the copy, its photos and this person's unsent
  /// changes go, the reason is kept for Account on hold (3.5), and the
  /// session ends.
  Future<void> wipedByServer(String? reason) async {
    ref.read(accountHoldProvider.notifier).hold(reason);
    await wipe();
    await ref
        .read(sessionProvider.notifier)
        .signOut(reason: SignOutReason.expired);
  }

  /// Deletes what this phone holds for the person: the copy and its
  /// photos, and their outbox with its photos. Wrong PINs never get here.
  ///
  /// [userId] names whose outbox goes when the session has already ended
  /// (a 401 from any call): the store follows the session, and with no one
  /// signed in it would see every person's rows.
  Future<void> wipe({int? userId}) async {
    final store = userId == null
        ? _store
        : SyncStore(
            ref.read(atomDbProvider),
            ref.read(outboxDbProvider),
            userId: userId,
          );
    try {
      await store.clearCopy();
    } catch (e) {
      debugPrint('[sync] could not clear the copy: $e');
    }
    try {
      await (await ref.read(copyPhotosProvider.future))?.forgetAll();
    } catch (_) {}
    try {
      final gone = await store.forgetOutbox();
      final files = await ref.read(outboxFilesProvider.future);
      for (final id in gone) {
        await files?.forget(id);
      }
    } catch (e) {
      debugPrint('[sync] could not clear the outbox: $e');
    }
    state = const SyncStatus(loaded: true);
  }

  /// Takes a change out of the queue before it is sent. False once the
  /// server has it, where undoing is no longer this phone's to do.
  Future<bool> undo(String id) async {
    final done = await _store.undo(id);
    if (done) await refresh();
    return done;
  }

  /// Continue on Offline working has ended (10.10), once nothing is left
  /// to send: the screen is left behind. [refresh] alone kept the stop,
  /// so the button did nothing until something else changed it.
  Future<void> carryOn() async {
    state = state.copyWith(stop: () => null, message: () => null);
    await refresh();
  }

  /// Sends a change the server would not apply once more, straight away
  /// when no run is going (otherwise it goes with the next one).
  Future<bool> retry(String id) async {
    final moved = await _store.retry(id);
    await refresh();
    // Not over a background run: two writers on one database is what the
    // scheduler keeps apart. That run, or the next, takes it.
    if (moved && !BackgroundSync.running) unawaited(syncNow());
    return moved;
  }

  /// Gives up on a change the server would not apply.
  Future<void> discard(String id) async {
    await _store.discard(id);
    await refresh();
  }
}

/// Why this phone was signed out by the server, for Account on hold (3.5):
/// `sync/check` said `wipe` with this reason. Kept apart from the session,
/// which ends at the same moment, so the screen outlives it; cleared when
/// the person carries on to sign in.
final accountHoldProvider = NotifierProvider<AccountHold, String?>(
  AccountHold.new,
);

class AccountHold extends Notifier<String?> {
  /// Set only by a wipe: no reason is "" so the screen still shows.
  bool _held = false;

  bool get held => _held;

  @override
  String? build() => null;

  void hold(String? reason) {
    _held = true;
    state = reason ?? '';
  }

  void clear() {
    _held = false;
    state = null;
  }
}
