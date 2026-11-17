import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart' show InstallStatus;
import 'package:url_launcher/url_launcher.dart';

import '../api/api_result.dart';
import '../app_providers.dart';
import 'store_updates.dart';
import 'update_policy.dart';
import 'update_store.dart';

/// A flexible (background) download, Android only.
enum UpdateDownload { none, downloading, downloaded, failed }

@immutable
class UpdatesState {
  const UpdatesState({
    this.checked = false,
    this.level = UpdateLevel.none,
    this.installed,
    this.policy,
    this.store,
    this.download = UpdateDownload.none,
    this.gentleClosed = false,
    this.whatsNew = false,
  });

  /// A check has finished at least once.
  final bool checked;
  final UpdateLevel level;
  final InstalledApp? installed;
  final UpdatePolicy? policy;
  final StoreInfo? store;
  final UpdateDownload download;

  /// The seller closed the gentle banner for this build, recently.
  final bool gentleClosed;

  /// The app was just updated and the notes are for this build: show
  /// What's new once.
  final bool whatsNew;

  /// The update comes before anything else.
  bool get blocking =>
      level == UpdateLevel.required || level == UpdateLevel.blocked;

  /// The gentle banner shows on Home.
  bool get showGentle =>
      download == UpdateDownload.none &&
      (level == UpdateLevel.comingSoon ||
          (level == UpdateLevel.gentle && !gentleClosed));

  UpdatesState copyWith({
    bool? checked,
    UpdateLevel? level,
    InstalledApp? installed,
    UpdatePolicy? policy,
    StoreInfo? store,
    UpdateDownload? download,
    bool? gentleClosed,
    bool? whatsNew,
  }) => UpdatesState(
    checked: checked ?? this.checked,
    level: level ?? this.level,
    installed: installed ?? this.installed,
    policy: policy ?? this.policy,
    store: store ?? this.store,
    download: download ?? this.download,
    gentleClosed: gentleClosed ?? this.gentleClosed,
    whatsNew: whatsNew ?? this.whatsNew,
  );
}

/// Where the installed app's details come from. Tests give their own.
final installedAppProvider = Provider<Future<InstalledApp?> Function()>(
  (ref) => InstalledApp.load,
);
final updateStoreProvider = Provider<UpdateStore>(
  (ref) => const FileUpdateStore(),
);
final storeUpdatesProvider = Provider<StoreUpdates>(
  (ref) => storeUpdatesForPlatform(),
);

/// The time, so tests can move it.
final updateClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// App updates (docs/trd/2026-11-09-seller-app-updates.md).
///
/// One check on open and on resume (through `AccessController.checkVersion`),
/// and when Atomshop pushes `app_update`. Each check:
///
/// 1. The server's policy, kept for its `check_hours`: no request at all
///    on most resumes, and none in the background.
/// 2. What the store has. Google Play's answer is a local call to the
///    Play Store app; the App Store lookup is asked only when the server
///    says something newer exists, and kept for a day.
/// 3. [decideUpdate].
///
/// Nothing here ever waits on the network before the app can be used.
class UpdatesController extends Notifier<UpdatesState> {
  /// The gentle banner stays closed this long.
  static const gentleQuiet = Duration(days: 3);

  /// Google Play's download prompt, at most this often per build.
  static const flexibleQuiet = Duration(days: 3);

  /// Google Play's full-screen prompt for a high-priority release, at most
  /// this often per build.
  static const immediateQuiet = Duration(days: 1);

  /// The App Store lookup is kept this long.
  static const lookupKeep = Duration(hours: 24);

  /// Google Play is asked at most this often, unless pushed.
  static const playEvery = Duration(minutes: 30);

  /// From this Play priority, Play downloads in the background (after one
  /// tap). Lower priorities are cosmetic and never ask.
  static const flexibleFromPriority = 2;

  /// From this Play priority, Play's full-screen update is offered once a
  /// day (the seller can still back out).
  static const immediateFromPriority = 4;

  /// A downloaded update installs this long after the seller leaves the
  /// app from a main tab.
  static const installAfter = Duration(minutes: 2);

  UpdateMemory? _memory;
  DateTime? _playAt;
  Future<UpdatesState>? _checking;
  StreamSubscription<InstallStatus>? _status;
  Timer? _install;

  @override
  UpdatesState build() {
    ref.onDispose(() {
      _status?.cancel();
      _install?.cancel();
    });
    return const UpdatesState();
  }

  DateTime get _now => ref.read(updateClockProvider)();

  Future<UpdateMemory> _remembered() async =>
      _memory ??= await ref.read(updateStoreProvider).read();

  Future<void> _keep(UpdateMemory m) async {
    _memory = m;
    await ref.read(updateStoreProvider).write(m);
  }

  /// One check. Calls made while one is running share it. [force]: ask
  /// the server and the store even if what is kept is still fresh (the
  /// Update screen's Check again, an `app_update` push).
  Future<UpdatesState> check({bool force = false}) =>
      _checking ??= _check(force).whenComplete(() => _checking = null);

  Future<UpdatesState> _check(bool force) async {
    final installed = await ref.read(installedAppProvider)();
    if (installed == null) return state = state.copyWith(checked: true);
    var memory = await _remembered();
    final now = _now;

    // 1. The policy.
    var policy = memory.policy == null
        ? null
        : UpdatePolicy.fromJson(memory.policy!);
    final fresh =
        policy != null &&
        !memory.stale &&
        memory.policyAt != null &&
        now.difference(memory.policyAt!) < Duration(hours: policy.checkHours);
    if (force || !fresh) {
      final fetched = await _fetchPolicy(installed.platform);
      if (fetched != null) {
        policy = fetched;
        memory = memory.copyWith(
          policy: fetched.toJson(),
          policyAt: now,
          stale: false,
        );
        await _keep(memory);
      }
    }

    // 2. The store.
    final store = await _storeInfo(installed, policy, memory, force, now);

    // 3. The decision.
    final level = decideUpdate(
      installed: installed,
      policy: policy,
      store: store,
    );

    // Just updated: What's new once, if the notes are for this build. The
    // first run after installing never counts as an update.
    final seen = memory.lastSeenBuild;
    final justUpdated =
        seen != null && installed.build > 0 && seen < installed.build;
    final whatsNew =
        state.whatsNew ||
        (justUpdated &&
            policy?.latestBuild == installed.build &&
            (policy?.notePoints.isNotEmpty ?? false));
    if (installed.build > 0 && seen != installed.build) {
      await _keep(memory.copyWith(lastSeenBuild: installed.build));
    }

    final target = policy?.recommendedBuild ?? policy?.latestBuild;
    final closedAt = memory.gentleClosedAt;
    final gentleClosed =
        closedAt != null &&
        memory.gentleClosedFor == target &&
        now.difference(closedAt) < gentleQuiet;

    var download = state.download;
    // A failed download is not kept past the next check: kept, it hid the
    // offer for good ([offerOnHome] asks only from none), and the banner
    // could only send the seller to the store. [offerOnHome]'s own quiet
    // spell stops Play being asked again too soon.
    if (download == UpdateDownload.failed) download = UpdateDownload.none;
    if (store?.downloaded ?? false) download = UpdateDownload.downloaded;

    return state = UpdatesState(
      checked: true,
      level: level,
      installed: installed,
      policy: policy,
      store: store,
      download: download,
      gentleClosed: gentleClosed,
      whatsNew: whatsNew,
    );
  }

  Future<UpdatePolicy?> _fetchPolicy(String platform) async {
    final result = await ref
        .read(apiClientProvider)
        .get('config', parse: (d) => d);
    return switch (result) {
      ApiOk(:final value) => UpdatePolicy.fromConfig(value, platform),
      ApiErr() => null,
    };
  }

  Future<StoreInfo?> _storeInfo(
    InstalledApp installed,
    UpdatePolicy? policy,
    UpdateMemory memory,
    bool force,
    DateTime now,
  ) async {
    if (policy == null) return null;
    final stores = ref.read(storeUpdatesProvider);
    if (installed.platform == 'ios') {
      // Only when the server says something newer exists or is required.
      final b = installed.build;
      final newer =
          (policy.latestBuild != null && b > 0 && b < policy.latestBuild!) ||
          decideUpdate(installed: installed, policy: policy, store: null) !=
              UpdateLevel.none;
      if (!newer) return null;
      final kept = memory.lookupVersion;
      final at = memory.lookupAt;
      if (!force &&
          kept != null &&
          at != null &&
          now.difference(at) < lookupKeep) {
        return AppStoreUpdates.lookupInfo(installed, kept);
      }
      final info = await stores.info(installed, policy);
      if (info?.storeVersion case final v?) {
        await _keep(memory.copyWith(lookupVersion: v, lookupAt: now));
      }
      return info;
    }
    // Android: Google Play, a local call, at most every [playEvery].
    if (!force &&
        _playAt != null &&
        now.difference(_playAt!) < playEvery &&
        state.store != null) {
      return state.store;
    }
    _playAt = now;
    return stores.info(installed, policy);
  }

  // ─────────────────────────────────────────────── what the seller does

  /// "Update" on the banner or the Update screen.
  ///
  /// Android: Play's full-screen update when it is required, its
  /// background download when it is not; the store page when Play can't
  /// do either (installed outside Play). iOS: the App Store page.
  Future<void> updateNow() async {
    final s = state;
    final store = s.store;
    final stores = ref.read(storeUpdatesProvider);
    if (s.installed?.platform == 'android' && store != null) {
      if (s.blocking && store.immediateAllowed) {
        if (await stores.immediate()) return;
      } else if (!s.blocking && store.flexibleAllowed) {
        if (await _startFlexible(stores)) return;
      }
    }
    await openStore();
  }

  /// Try again on the failed-download banner: the same as Update now,
  /// from a clean start.
  Future<void> retryDownload() async {
    state = state.copyWith(download: UpdateDownload.none);
    await updateNow();
  }

  /// The store's page for this app.
  Future<void> openStore() async {
    final p = state.policy;
    final ios = state.installed?.platform == 'ios';
    final uris = [
      // The App Store app itself, not Safari.
      if (ios && p?.appStoreId != null)
        Uri.parse('itms-apps://apps.apple.com/app/id${p!.appStoreId}'),
      // The Play Store app itself, for the package in the store link.
      if (!ios && p?.storeUrl != null)
        if (Uri.tryParse(p!.storeUrl!)?.queryParameters['id'] case final id?)
          Uri.parse('market://details?id=$id'),
      if (p?.storeUrl != null) Uri.parse(p!.storeUrl!),
      // Fallbacks when the server names no store page. The App Store id is
      // not known yet: iPhones then rely on `app_store_id` from GET config.
      if (!ios)
        Uri.parse(
          'https://play.google.com/store/apps/details?id=pk.atomshop.atombrand_app',
        ),
    ];
    for (final uri in uris) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (e) {
        debugPrint('[update] could not open $uri: $e');
      }
    }
  }

  /// Closes the gentle banner for [gentleQuiet].
  Future<void> closeGentle() async {
    final p = state.policy;
    state = state.copyWith(gentleClosed: true);
    await _keep(
      (await _remembered()).copyWith(
        gentleClosedAt: _now,
        gentleClosedFor: p?.recommendedBuild ?? p?.latestBuild,
      ),
    );
  }

  void closeWhatsNew() => state = state.copyWith(whatsNew: false);

  /// Installs a downloaded update now ("Restart" on the banner).
  Future<void> installNow() =>
      ref.read(storeUpdatesProvider).completeFlexible();

  /// Home is on screen: the moment Google Play may ask, never before
  /// (not over the PIN, sign-in, or a payment). Android only.
  ///
  /// - Priority [flexibleFromPriority]+: Play's one-tap background
  ///   download, at most every [flexibleQuiet] per build.
  /// - Priority [immediateFromPriority]+: Play's full-screen update, at
  ///   most once a day per build; the seller can still back out.
  /// - An immediate update left part-way: picked up again.
  Future<void> offerOnHome() async {
    final s = state;
    final store = s.store;
    if (s.installed?.platform != 'android' || store == null) return;
    if (!store.updateAvailable || s.download != UpdateDownload.none) return;
    final stores = ref.read(storeUpdatesProvider);
    final m = await _remembered();
    final now = _now;
    final code = store.availableBuild;

    if (store.immediateInProgress && store.immediateAllowed) {
      await stores.immediate();
      return;
    }
    bool quiet(DateTime? at, int? forCode, Duration gap) =>
        at != null && forCode == code && now.difference(at) < gap;

    if (store.priority >= immediateFromPriority &&
        store.immediateAllowed &&
        !quiet(m.immediateAskedAt, m.immediateAskedFor, immediateQuiet)) {
      await _keep(m.copyWith(immediateAskedAt: now, immediateAskedFor: code));
      if (await stores.immediate()) return;
    }
    if (store.priority >= flexibleFromPriority &&
        store.flexibleAllowed &&
        !quiet(m.flexibleAskedAt, m.flexibleAskedFor, flexibleQuiet)) {
      await _keep(
        (await _remembered()).copyWith(
          flexibleAskedAt: now,
          flexibleAskedFor: code,
        ),
      );
      await _startFlexible(stores);
    }
  }

  Future<bool> _startFlexible(StoreUpdates stores) async {
    _status ??= stores.installStatus.listen((s) {
      final next = switch (s) {
        InstallStatus.pending ||
        InstallStatus.downloading => UpdateDownload.downloading,
        InstallStatus.downloaded => UpdateDownload.downloaded,
        InstallStatus.failed => UpdateDownload.failed,
        InstallStatus.canceled => UpdateDownload.none,
        _ => null,
      };
      if (next != null) state = state.copyWith(download: next);
    });
    final started = await stores.startFlexible();
    if (started && state.download == UpdateDownload.none) {
      state = state.copyWith(download: UpdateDownload.downloading);
    }
    return started;
  }

  /// The app went to the background. A downloaded update installs after
  /// [installAfter] if the seller left from a main tab ([onTab]) — never
  /// from a form, where an install would lose what they were typing.
  /// [busy] (a sync running) puts it off to the next time.
  void paused({required bool onTab, required bool Function() busy}) {
    _install?.cancel();
    if (state.download != UpdateDownload.downloaded || !onTab) return;
    _install = Timer(installAfter, () {
      if (busy()) return;
      debugPrint('[update] installing the downloaded update');
      unawaited(ref.read(storeUpdatesProvider).completeFlexible());
    });
  }

  void resumed() => _install?.cancel();

  /// `app_update` push with the app open: ask again now.
  Future<void> pushed() => check(force: true);
}

final updatesProvider = NotifierProvider<UpdatesController, UpdatesState>(
  UpdatesController.new,
);
