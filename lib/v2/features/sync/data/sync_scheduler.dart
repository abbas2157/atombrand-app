import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/access/access.dart';
import '../../../core/api/api_result.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/net/network_status.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/session/session_controller.dart';
import 'background_sync.dart';
import 'sync_engine.dart';
import 'sync_providers.dart';
import 'sync_repository.dart';

/// How often a sync runs while the app is open (§1.5 of the contract).
const syncEvery = Duration(minutes: 5);

/// Nothing is tried again faster than this, so a flapping connection
/// cannot start a run every second.
const syncCoolOff = Duration(seconds: 20);

/// Starts a sync when it should run: the app opens, the connection comes
/// back, every few minutes while it is open, and when Atomshop says
/// something changed.
///
/// With the app closed, [BackgroundSync] carries on: every couple of
/// hours, and as soon as there is a network after something was saved
/// with no signal. This keeps that schedule in step with the add-on, and
/// answers a background run that finds the app open.
///
/// It only ever runs for an account that has the add-on and is signed in.
/// Nothing here forces a sync: each call goes through the controller,
/// which refuses while one is already going.
class SyncScheduler {
  SyncScheduler(this._ref) {
    _watch();
  }

  final Ref _ref;
  Timer? _timer;
  DateTime? _lastTry;

  /// Starts false: at launch the network's state is often still loading,
  /// so the first "online" counts as the connection coming back — the
  /// launch run that was skipped while it loaded happens then. The
  /// cool-off keeps it from being a second run when the first did go.
  bool _wasOnline = false;

  /// Atomshop's data-only nudge: `{type: sync_now, reason}`
  /// (`SyncNow.php`). It carries nothing but the nudge — the phone then
  /// downloads only what it may see.
  static const syncNowType = 'sync_now';

  ReceivePort? _port;

  /// A background run that finds the app open in this process asks it to
  /// sync, instead of opening the files a second time.
  void _listenForBackground() {
    final port = ReceivePort();
    // Left over from a hot restart, or an app that died without saying.
    IsolateNameServer.removePortNameMapping(BackgroundSync.appPort);
    if (IsolateNameServer.registerPortWithName(
      port.sendPort,
      BackgroundSync.appPort,
    )) {
      _port = port;
      port.listen((_) => _run('a background run found the app open'));
    } else {
      port.close();
    }
  }

  void _watch() {
    _listenForBackground();
    // A teammate recorded a payment, a lead came in, another phone
    // synced: the server says so rather than this phone waiting out its
    // five minutes.
    FcmService.onData = (data) {
      if (data['type'] != syncNowType) return;
      _run('Atomshop said to (${data['reason'] ?? 'no reason given'})');
    };
    // The connection coming back is the trigger that matters most: a
    // seller who walks back into signal expects their work to go.
    _ref.listen(onlineProvider, (_, next) {
      final online = next.value ?? false;
      final came = online && !_wasOnline;
      _wasOnline = online;
      if (came) _run('the connection came back');
    });

    // The PIN (or fingerprint) opened the copy: whatever was fetched and
    // sealed while it was shut goes in now — no network needed — and a
    // sync follows when there is one.
    _ref.listen(copyOpenProvider, (_, open) async {
      if (!open) return;
      final shopId = _ref.read(syncShopIdProvider);
      if (shopId == null) return;
      try {
        await _ref.read(syncEngineProvider).applyStaged(shopId: shopId);
      } catch (e) {
        debugPrint('[sync] could not apply what was fetched while shut: $e');
      }
      // Forced only when a run that started with the copy shut is still
      // going: it stops part-way to let the copy be applied, and this run
      // finishes the walk. A run that started with it open needs no
      // second.
      final going = _ref.read(syncStatusProvider).running;
      _run('the copy opened', force: !going || _startedShut);
    });

    // Signing in, or the add-on being switched on, starts the clock.
    _ref.listen(sessionProvider, (before, now) {
      if (now is SignedIn && before is! SignedIn) {
        // Registers the phone (`device_id`) right after sign-in and on
        // every open. With the add-on the run below checks in anyway, so
        // only a fresh sign-in asks twice.
        if (before is SignedOut) {
          unawaited(_checkIn(force: true));
        } else if (!_allowed) {
          unawaited(_checkIn());
        }
      }
      // A 401 from any call: the server signed this phone out (revoked,
      // signed out everywhere, password changed, member switched off).
      // The copy and this person's unsent changes go (§1.6).
      if (before is SignedIn &&
          now is SignedOut &&
          now.reason == SignOutReason.expired) {
        unawaited(
          _ref
              .read(syncStatusProvider.notifier)
              .wipe(userId: before.session.userId),
        );
      }
      _restart();
    });
    _ref.listen(accessProvider, (_, _) => _restart());

    _restart();
  }

  void _restart() {
    _timer?.cancel();
    if (!_allowed) {
      unawaited(BackgroundSync.stop());
      return;
    }
    // With the app closed too, while the account works offline.
    unawaited(BackgroundSync.schedule());
    _timer = Timer.periodic(syncEvery, (_) => _run('the timer'));
    _run('the app opened');
  }

  String get _notAllowedBecause {
    if (_ref.read(sessionProvider) is! SignedIn) return 'signed out';
    if (!_ref.read(accessProvider).has(Addon.offline)) return 'no add-on';
    return 'no shop';
  }

  /// The app went to the background: the timer stops. On older Android a
  /// backgrounded app keeps running until the system kills it, and a
  /// whole sync every five minutes from a phone in a pocket is battery for
  /// nothing — WorkManager ([BackgroundSync]) syncs a closed app instead.
  void paused() {
    _timer?.cancel();
    _timer = null;
    _retry?.cancel();
  }

  /// Back in front: one sync for the time away (the cool-off still
  /// applies), and the timer again.
  void resumed() {
    if (!_allowed) {
      // No add-on: no sync, but a phone signed out or switched off on the
      // server should still hear it (3.5), at most every few minutes.
      if (_ref.read(sessionProvider) is SignedIn) unawaited(_checkIn());
      return;
    }
    _timer?.cancel();
    _timer = Timer.periodic(syncEvery, (_) => _run('the timer'));
    _run('the app came back');
  }

  DateTime? _lastCheckIn;

  /// `sync/check` for a phone that doesn't sync (or has just signed in).
  Future<void> _checkIn({bool force = false}) async {
    final now = DateTime.now();
    final last = _lastCheckIn;
    if (!force && last != null && now.difference(last) < checkInEvery) {
      return;
    }
    _lastCheckIn = now;
    // Straight to the server: a brand without the add-on never opens the
    // phone's databases for this, unless it has to wipe them.
    final r = await _ref.read(syncRepositoryProvider).check();
    if (r case ApiOk(:final value) when value.wipe || !value.allowed) {
      await _ref.read(syncStatusProvider.notifier).wipedByServer(value.reason);
    }
  }

  /// How often a phone without the add-on checks in when it comes back.
  static const checkInEvery = Duration(minutes: 10);

  bool get _allowed {
    if (_ref.read(sessionProvider) is! SignedIn) return false;
    if (!_ref.read(accessProvider).has(Addon.offline)) return false;
    return _ref.read(syncShopIdProvider) != null;
  }

  /// A run asked for while one was going. Not dropped: the copy opening
  /// mid-run is exactly when the next run matters, so it follows as soon
  /// as the current one ends.
  ({String why, bool force})? _queued;

  /// Whether the run going now started with the copy shut.
  bool _startedShut = false;

  /// [force] skips the cool-off: the copy opening needs its run even
  /// straight after another, because that one may only have staged what
  /// it fetched. Everything else is covered by a run that just ended.
  Future<void> _run(String why, {bool force = false}) async {
    if (!_allowed) {
      if (force) debugPrint('[sync] not now ($why): $_notAllowedBecause');
      return;
    }
    if (_ref.read(syncStatusProvider).running) {
      // A forced ask is never replaced by an ordinary one.
      if (_queued?.force != true) _queued = (why: why, force: force);
      return;
    }
    final now = DateTime.now();
    final last = _lastTry;
    if (!force && last != null && now.difference(last) < syncCoolOff) return;
    if (!(_ref.read(onlineProvider).value ?? false)) {
      // What was last heard may be stale (an event the phone never sent):
      // the phone is asked before the run is given up.
      if (!await _ref.read(networkStatusProvider).check()) {
        debugPrint('[sync] waiting for a network ($why)');
        return;
      }
      _ref.invalidate(onlineProvider);
      // Another run may have started while the phone was asked.
      if (_ref.read(syncStatusProvider).running || BackgroundSync.running) {
        if (_queued?.force != true) _queued = (why: why, force: force);
        return;
      }
    }
    // A background run has the files: it is doing this already, and two
    // writers on one database is what the split into ports prevents.
    if (BackgroundSync.running) {
      debugPrint('[sync] skipped ($why): a background run is going');
      return;
    }
    // A run is going: any retry waiting is this run.
    _retry?.cancel();
    _lastTry = now;
    _startedShut = !_ref.read(copyOpenProvider);
    debugPrint('[sync] running: $why${_startedShut ? ' (copy shut)' : ''}');
    final out = await _ref.read(syncStatusProvider.notifier).syncNow();
    // How it ended, so a run that stops early says why.
    if (out != null) {
      debugPrint(
        '[sync] done: ok ${out.ok}, stop ${out.stop}, '
        'sent ${out.sent}, rows ${out.rows}',
      );
    }
    // From the end of the run, so a long run is not followed by another.
    _lastTry = DateTime.now();
    // The phone says it is online but the request found no network: the
    // network is still coming up (a cold start, a hand-over from Wi-Fi to
    // mobile data). Try once more shortly instead of waiting for the timer.
    // Set before the queue is looked at: a queued ask can be turned away
    // by the cool-off, and must not take the retry with it.
    if (out != null && out.stop == SyncStop.offline && !force) {
      _retry = Timer(retryAfterOffline, () => _run('$why, again', force: true));
    }
    if (_queued case final next?) {
      _queued = null;
      await _run(next.why, force: next.force);
    }
  }

  /// How long to wait before one more try when a run found no network
  /// that the phone said it had.
  static const retryAfterOffline = Duration(seconds: 15);
  Timer? _retry;

  void dispose() {
    _timer?.cancel();
    _retry?.cancel();
    FcmService.onData = null;
    if (_port != null) {
      IsolateNameServer.removePortNameMapping(BackgroundSync.appPort);
      _port!.close();
    }
  }
}

/// Kept alive for as long as the app is: reading it once starts the
/// triggers.
final syncSchedulerProvider = Provider<SyncScheduler>((ref) {
  final s = SyncScheduler(ref);
  ref.onDispose(s.dispose);
  return s;
});
