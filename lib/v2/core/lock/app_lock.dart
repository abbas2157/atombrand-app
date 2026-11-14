import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../db/copy_key.dart';
import '../session/session.dart';
import '../session/session_controller.dart';
import 'quick_sign_in.dart';
import 'bio_prompt.dart';

/// Quick unlock on this phone (2.4, 3.0–3.2, 19.2): a 4-digit PIN, kept
/// only as a salted hash in secure storage, and optionally fingerprint or
/// face. It never leaves the phone and is cleared on sign-out.
@immutable
class LockPrefs {
  const LockPrefs({
    this.pinHash,
    this.salt,
    this.userId,
    this.biometric = false,
    this.lockAfterSeconds = 60,
    this.wrong = 0,
    this.waitUntil,
    this.pinDue = false,
  });

  final String? pinHash;
  final String? salt;

  /// Whose PIN it is. Null for a PIN set before this was kept: it is taken
  /// as the signed-in person's.
  final int? userId;
  final bool biometric;

  /// How long in the background before the app asks again; 0 is at once.
  final int lockAfterSeconds;

  /// Wrong PINs in a row, kept across restarts so closing the app doesn't
  /// reset them.
  final int wrong;

  /// After [maxPinTries] wrong PINs, no PIN is taken before this (3.2).
  final DateTime? waitUntil;

  /// A password sign-in on this phone still has to set a PIN (2.4): a
  /// way-in step until the person presses Continue.
  final bool pinDue;

  bool get hasPin => pinHash != null;

  LockPrefs copyWith({
    String? Function()? pinHash,
    String? Function()? salt,
    int? Function()? userId,
    bool? biometric,
    int? lockAfterSeconds,
    int? wrong,
    DateTime? Function()? waitUntil,
    bool? pinDue,
  }) => LockPrefs(
    pinHash: pinHash == null ? this.pinHash : pinHash(),
    salt: salt == null ? this.salt : salt(),
    userId: userId == null ? this.userId : userId(),
    biometric: biometric ?? this.biometric,
    lockAfterSeconds: lockAfterSeconds ?? this.lockAfterSeconds,
    wrong: wrong ?? this.wrong,
    waitUntil: waitUntil == null ? this.waitUntil : waitUntil(),
    pinDue: pinDue ?? this.pinDue,
  );

  Map<String, Object?> toJson() => {
    'pin': pinHash,
    'salt': salt,
    'user': userId,
    'bio': biometric,
    'after': lockAfterSeconds,
    'wrong': wrong,
    'wait': waitUntil?.millisecondsSinceEpoch,
    'due': pinDue,
  };

  factory LockPrefs.fromJson(Map<String, dynamic> j) => LockPrefs(
    pinHash: j['pin'] as String?,
    salt: j['salt'] as String?,
    userId: (j['user'] as num?)?.toInt(),
    biometric: j['bio'] == true,
    lockAfterSeconds: (j['after'] as num?)?.toInt() ?? 60,
    wrong: (j['wrong'] as num?)?.toInt() ?? 0,
    waitUntil: j['wait'] is num
        ? DateTime.fromMillisecondsSinceEpoch((j['wait'] as num).toInt())
        : null,
    pinDue: j['due'] == true,
  );
}

abstract interface class LockStore {
  Future<LockPrefs> read();
  Future<void> write(LockPrefs prefs);
  Future<void> clear();
}

class SecureLockStore implements LockStore {
  const SecureLockStore();

  static const _key = 'v2_app_lock';
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());

  @override
  Future<LockPrefs> read() async {
    try {
      final raw = await _storage.read(key: _key);
      // Nothing set up on this phone yet (a session from before the PIN
      // was asked for on the way in): the PIN is due.
      if (raw == null) return const LockPrefs(pinDue: true);
      return LockPrefs.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (e) {
      debugPrint('[lock] could not read the lock settings: $e');
      return const LockPrefs(pinDue: true);
    }
  }

  @override
  Future<void> write(LockPrefs prefs) =>
      _storage.write(key: _key, value: jsonEncode(prefs.toJson()));

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

class MemoryLockStore implements LockStore {
  MemoryLockStore([this._prefs = const LockPrefs()]);
  LockPrefs _prefs;

  LockPrefs get prefs => _prefs;

  @override
  Future<LockPrefs> read() async => _prefs;

  @override
  Future<void> write(LockPrefs prefs) async => _prefs = prefs;

  @override
  Future<void> clear() async => _prefs = const LockPrefs();
}

/// The phone's fingerprint or face check.
abstract interface class Biometrics {
  Future<bool> available();
  Future<bool> check(String reason);
}

class DeviceBiometrics implements Biometrics {
  DeviceBiometrics();
  final _auth = LocalAuthentication();

  @override
  Future<bool> available() async {
    try {
      // A sensor is not enough: with no finger (or face) added in the
      // phone's settings there is nothing to check, and the switch would
      // only fail. Such a phone keeps the PIN alone.
      if (!await _auth.isDeviceSupported()) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> check(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }
}

final lockStoreProvider = Provider<LockStore>((ref) => const SecureLockStore());
final biometricsProvider = Provider<Biometrics>((ref) => DeviceBiometrics());

/// The time, for the 5-minute wait. Tests move it on.
final lockClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Whether this phone can check a fingerprint or face.
final biometricsCanCheckProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.read(biometricsProvider).available(),
);

@immutable
class AppLockState {
  const AppLockState({
    this.prefs = const LockPrefs(),
    this.loaded = false,
    this.locked = false,
    this.passwordMode = false,
  });

  final LockPrefs prefs;

  /// The settings have been read from the phone.
  final bool loaded;

  /// The lock screens cover the app.
  final bool locked;

  /// Locked, but the person chose to sign in with the password (Forgot
  /// PIN, Switch account, Sign in with password). The lock steps aside for
  /// Sign in; the locked session stays until a sign-in succeeds.
  final bool passwordMode;

  int get wrongTries => prefs.wrong;

  /// Biometric unlock is offered: a PIN, and the switch on.
  bool get fingerprint => prefs.hasPin && prefs.biometric;

  AppLockState copyWith({
    LockPrefs? prefs,
    bool? loaded,
    bool? locked,
    bool? passwordMode,
  }) => AppLockState(
    prefs: prefs ?? this.prefs,
    loaded: loaded ?? this.loaded,
    locked: locked ?? this.locked,
    passwordMode: passwordMode ?? this.passwordMode,
  );
}

final appLockProvider = NotifierProvider<AppLockController, AppLockState>(
  AppLockController.new,
);

/// After this many wrong PINs in a row the PIN pad waits [pinWait] (3.2).
const maxPinTries = 5;

/// After this many wrong PINs in a row the phone signs out: the password
/// (and internet) is needed.
const pinTriesBeforeSignOut = 10;

/// The wait after [maxPinTries] wrong PINs.
const pinWait = Duration(minutes: 5);

/// What a typed PIN did.
enum PinCheck {
  ok,
  wrong,

  /// The wait (3.2) is on: nothing was checked.
  waiting,

  /// The tenth wrong PIN: the caller signs the phone out.
  tooMany,
}

class AppLockController extends Notifier<AppLockState> {
  LockStore get _store => ref.read(lockStoreProvider);
  DateTime get _now => ref.read(lockClockProvider)();
  DateTime? _pausedAt;

  /// A session change seen before the settings were read, handled once
  /// they are.
  ({SessionState? before, SessionState now})? _pending;

  @override
  AppLockState build() {
    ref.listen(sessionProvider, _onSession);
    _load();
    return const AppLockState();
  }

  Future<void> _load() async {
    final prefs = await _store.read();
    state = state.copyWith(prefs: prefs, loaded: true);
    final pending = _pending;
    _pending = null;
    if (pending != null) {
      _onSession(pending.before, pending.now);
    } else if (ref.read(sessionProvider) case SignedIn(:final session)) {
      // The session was restored before this was first read.
      _coldStart(session);
    }
  }

  void _onSession(SessionState? before, SessionState now) {
    if (!state.loaded) {
      _pending = (before: _pending?.before ?? before, now: now);
      return;
    }
    if (now is! SignedIn) {
      if (before is! SignedIn) return;
      // A sign-in saved behind the fingerprint for this person keeps the
      // PIN: signing in again with the fingerprint goes straight in.
      final quick = ref.read(quickSignInProvider).profile;
      if (quick != null && quick.userId == before.session.userId) {
        state = AppLockState(prefs: state.prefs, loaded: true);
        return;
      }
      // Otherwise signing out forgets the PIN: the next person signs in
      // with a password and sets their own.
      _forget();
      return;
    }
    switch (before) {
      case null || SessionLoading():
        _coldStart(now.session);
      case SignedOut():
        _passwordSignIn(now.session);
      // A new token, or any sign-in while the lock waits behind Sign in.
      case SignedIn(:final session)
          when session.token != now.session.token || state.passwordMode:
        _passwordSignIn(now.session);
      case SignedIn():
        break;
    }
  }

  /// A stored session at launch: locked when it has a PIN.
  void _coldStart(BrandSession session) {
    final p = state.prefs;
    if (!p.hasPin) return;
    if (p.userId != null && p.userId != session.userId) {
      // Someone else's PIN: it can't open this session. A new one is due.
      _save(
        LockPrefs(
          pinDue: true,
          userId: session.userId,
          lockAfterSeconds: p.lockAfterSeconds,
        ),
      );
      return;
    }
    final prefs = p.copyWith(userId: () => session.userId, pinDue: false);
    state = state.copyWith(prefs: prefs, locked: true);
    _store.write(prefs);
  }

  /// A sign-in with the password: the same person keeps their PIN (signed
  /// in again from the lock); anyone else sets their own.
  void _passwordSignIn(BrandSession session) {
    final p = state.prefs;
    final LockPrefs prefs;
    // After Forgot PIN the old one can't stay: a new one is due.
    final forgot = _forgotPin;
    _forgotPin = false;
    if (p.hasPin && p.userId == session.userId && !forgot) {
      prefs = p.copyWith(wrong: 0, waitUntil: () => null);
      // No PIN step follows, so the typed password isn't needed any more.
      ref.read(pendingSignInProvider.notifier).forget();
    } else {
      prefs = LockPrefs(
        pinDue: true,
        userId: session.userId,
        lockAfterSeconds: p.lockAfterSeconds,
      );
    }
    state = AppLockState(prefs: prefs, loaded: true);
    _store.write(prefs);
  }

  bool get _signedIn => ref.read(sessionProvider) is SignedIn;
  int? get _userId => ref.read(sessionProvider.notifier).current?.userId;

  static String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  Future<void> _save(LockPrefs prefs) async {
    state = state.copyWith(prefs: prefs);
    await _store.write(prefs);
  }

  Future<void> setPin(String pin) async {
    final rnd = Random.secure();
    final salt = base64Url.encode([
      for (var i = 0; i < 16; i++) rnd.nextInt(256),
    ]);
    await _save(
      state.prefs.copyWith(
        pinHash: () => _hash(pin, salt),
        salt: () => salt,
        userId: () => _userId,
        wrong: 0,
        waitUntil: () => null,
      ),
    );
    // The copy's key goes under the new PIN (§5). The same key when the
    // copy is open; a fresh copy when it isn't (Forgot PIN, a new person).
    await CopyKey.rewrap(pin);
  }

  /// The way-in PIN step is done (Continue on 2.4).
  Future<void> finishPinSetup() async {
    await _save(state.prefs.copyWith(pinDue: false));
    // Skipped: no PIN, so nothing may stand between the copy and the
    // person now signed in. A key still wrapped by someone else's PIN
    // can't be opened by them, and the copy starts over.
    if (!state.prefs.hasPin) await CopyKey.noPin();
  }

  /// Remove PIN (19.2): this phone goes back to no quick unlock. The
  /// sign-in saved behind the fingerprint goes with it, since it is only
  /// ever offered alongside a PIN. How long before the app locks is kept,
  /// for whenever a PIN is set again.
  Future<void> removePin() async {
    await _save(LockPrefs(lockAfterSeconds: state.prefs.lockAfterSeconds));
    await ref.read(quickSignInProvider.notifier).erase();
    // No PIN to wrap the copy's key with: it is held as it is again.
    await CopyKey.noPin();
  }

  /// The fingerprint switch. Off also erases the sign-in saved behind the
  /// fingerprint.
  Future<void> setBiometric(bool on) async {
    await _save(state.prefs.copyWith(biometric: on));
    if (!on) {
      await ref.read(quickSignInProvider.notifier).erase();
      await CopyKey.forgetBiometric();
    }
  }

  /// Gives the fingerprint its own copy of the copy's key, so a
  /// fingerprint unlock opens the copy too. Asks for the fingerprint,
  /// because writing behind it needs one. Only when it is wanted: the
  /// fingerprint is on, the key is wrapped by the PIN, and the
  /// fingerprint does not already hold this key.
  ///
  /// Null when there was nothing to keep; otherwise whether it was kept.
  Future<bool?> keepFingerprintKey(CopyPrompt prompt) async {
    if (!state.prefs.biometric || !CopyKey.isOpen) return null;
    if (!await CopyKey.isWrapped()) return null;
    if (await CopyKey.biometricIsCurrent()) return null;
    return CopyKey.keepForBiometrics(prompt);
  }

  /// The switch after a new PIN: on, and the copy's key kept behind the
  /// finger in the same prompt. A cancel there turns it off again, so the
  /// switch never says on for a finger that was not given. With no copy
  /// to keep, the finger is asked for when the sign-in is saved.
  Future<bool> turnOnFingerprint(CopyPrompt prompt) async {
    await setBiometric(true);
    if (await keepFingerprintKey(prompt) == false) {
      await setBiometric(false);
      return false;
    }
    return true;
  }

  /// The fingerprint unlock. With the copy shut behind the PIN, it is the
  /// fingerprint's copy of the key that is read — one prompt that opens
  /// the app and the copy. Otherwise the plain check it always was.
  ///
  /// [CopyBioResult.usePin] means the fingerprint can't open the copy any
  /// more; the PIN pad should open, and the PIN will hand the fingerprint
  /// the key again ([keepFingerprintKey]).
  Future<CopyBioResult> checkBiometrics(
    String reason,
    CopyPrompt prompt,
  ) async {
    if (await CopyKey.needsFingerprint()) {
      // Opened earlier in this run (a sign-in saved behind it): the read
      // would not ask, so the fingerprint is checked here first.
      if (FingerprintVault.unlocked &&
          !await ref.read(biometricsProvider).check(reason)) {
        return CopyBioResult.cancelled;
      }
      return CopyKey.openWithBiometrics(prompt);
    }
    // A PIN, but the key was never wrapped by it: the fingerprint can't do
    // the wrapping, so the PIN is asked for once.
    if (state.prefs.hasPin && await CopyKey.isHeldPlain()) {
      return CopyBioResult.pinToProtect;
    }
    final ok = await ref.read(biometricsProvider).check(reason);
    return ok ? CopyBioResult.opened : CopyBioResult.cancelled;
  }

  Future<void> setLockAfter(int seconds) =>
      _save(state.prefs.copyWith(lockAfterSeconds: seconds));

  bool matches(String pin) {
    final p = state.prefs;
    return p.hasPin && p.salt != null && _hash(pin, p.salt!) == p.pinHash;
  }

  /// How long until a PIN is taken again; zero when there is no wait.
  Duration waitLeft() {
    final until = state.prefs.waitUntil;
    if (until == null) return Duration.zero;
    final left = until.difference(_now);
    return left.isNegative ? Duration.zero : left;
  }

  /// The wait has run out: the PIN pad opens again (the wrong count stays).
  Future<void> waitOver() async {
    if (state.prefs.waitUntil == null || waitLeft() > Duration.zero) return;
    await _save(state.prefs.copyWith(waitUntil: () => null));
  }

  /// Checks [pin]. The fifth wrong PIN in a row starts a 5-minute wait;
  /// the tenth answers [PinCheck.tooMany] and the caller signs out.
  Future<PinCheck> check(String pin) => _count(
    pin,
    onRight: () async {
      // The one moment the PIN is in hand: it opens the copy (§5), and
      // wraps the key if this phone's was not wrapped yet.
      await CopyKey.openWithPin(pin);
      await _unlocked();
    },
  );

  /// Checks [pin] as the PIN in use, on Change PIN, against the same count
  /// and wait as the lock: a counter of its own there started again each
  /// time the screen opened, which gave an open phone as many guesses at
  /// the PIN as it liked. Right: the count clears and nothing else changes
  /// (the app is open already).
  Future<PinCheck> checkCurrent(String pin) => _count(
    pin,
    onRight: () async {
      if (state.prefs.wrong != 0 || state.prefs.waitUntil != null) {
        await _save(state.prefs.copyWith(wrong: 0, waitUntil: () => null));
      }
    },
  );

  Future<PinCheck> _count(
    String pin, {
    required Future<void> Function() onRight,
  }) async {
    if (waitLeft() > Duration.zero) return PinCheck.waiting;
    if (matches(pin)) {
      await onRight();
      return PinCheck.ok;
    }
    final wrong = state.prefs.wrong + 1;
    if (wrong >= pinTriesBeforeSignOut) {
      await _save(state.prefs.copyWith(wrong: wrong));
      return PinCheck.tooMany;
    }
    await _save(
      state.prefs.copyWith(
        wrong: wrong,
        waitUntil: wrong == maxPinTries ? () => _now.add(pinWait) : null,
      ),
    );
    return wrong == maxPinTries ? PinCheck.waiting : PinCheck.wrong;
  }

  /// Unlocks with [pin]; answers false when it is wrong. Ten wrong PINs in
  /// a row sign the phone out.
  Future<bool> unlock(String pin) async {
    final result = await check(pin);
    if (result == PinCheck.tooMany) {
      await ref.read(quickSignInProvider.notifier).erase();
      await ref.read(sessionProvider.notifier).signOut();
    }
    return result == PinCheck.ok;
  }

  Future<void> _unlocked() async {
    state = state.copyWith(locked: false, passwordMode: false);
    if (state.prefs.wrong != 0 || state.prefs.waitUntil != null) {
      await _save(state.prefs.copyWith(wrong: 0, waitUntil: () => null));
    }
  }

  Future<void> unlockedByBiometrics() => _unlocked();

  /// Forgot PIN, Switch account or Sign in with password: Sign in opens,
  /// and the locked session waits behind it.
  /// [forgotPin]: the sign-in that follows drops this PIN and asks for a
  /// new one, so the forgotten PIN can't lock them out again.
  void usePassword({bool forgotPin = false}) {
    if (!state.locked) return;
    _forgotPin = forgotPin;
    state = state.copyWith(passwordMode: true);
  }

  /// Back from Sign in to the fingerprint or PIN.
  void backToQuickUnlock() {
    _forgotPin = false;
    state = state.copyWith(passwordMode: false);
  }

  bool _forgotPin = false;

  void paused() => _pausedAt = DateTime.now();

  void resumed() {
    final at = _pausedAt;
    _pausedAt = null;
    if (at == null || !state.prefs.hasPin || !_signedIn) return;
    final away = DateTime.now().difference(at).inSeconds;
    if (away >= state.prefs.lockAfterSeconds) {
      state = state.copyWith(locked: true);
    }
  }

  Future<void> _forget() async {
    state = const AppLockState(loaded: true);
    await _store.clear();
    // The key leaves memory; nothing is deleted. Ten wrong PINs end here
    // too, and wrong PINs never wipe (§5).
    CopyKey.close();
  }
}
