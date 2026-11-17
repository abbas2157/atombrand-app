import 'package:atombrand_app/v2/core/lock/app_lock.dart';
import 'package:atombrand_app/v2/core/lock/quick_sign_in.dart';
import 'package:atombrand_app/v2/core/session/session.dart';
import 'package:atombrand_app/v2/core/session/session_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The lock's phases: loading → unlocked ⇄ quickUnlock ⇄ password /
/// forgotPin → unlocked, driven by the session and the person.

BrandSession _asad({String token = 't1', int userId = 1}) => BrandSession(
  token: token,
  userId: userId,
  name: 'Asad',
  who: const Who.owner(),
  brandName: 'Zenvo',
);

/// A session the test moves by hand.
class _Session extends SessionController {
  _Session(this._first);
  final SessionState _first;

  @override
  SessionState build() => _first;

  void go(SessionState next) => state = next;
}

/// No sign-in saved behind the fingerprint.
class _NoQuick extends QuickSignInController {
  @override
  QuickSignInState build() => const QuickSignInState(loaded: true);
}

const _pin = LockPrefs(pinHash: 'h', salt: 's', userId: 1);

void main() {
  late MemoryLockStore store;

  Future<ProviderContainer> start(
    SessionState session, {
    LockPrefs prefs = const LockPrefs(),
  }) async {
    store = MemoryLockStore(prefs);
    final c = ProviderContainer(
      overrides: [
        lockStoreProvider.overrideWithValue(store),
        sessionProvider.overrideWith(() => _Session(session)),
        quickSignInProvider.overrideWith(_NoQuick.new),
      ],
    );
    addTearDown(c.dispose);
    c.listen(appLockProvider, (_, _) {});
    await pumpEventQueue();
    return c;
  }

  LockPhase phase(ProviderContainer c) => c.read(appLockProvider).phase;
  AppLockController lock(ProviderContainer c) =>
      c.read(appLockProvider.notifier);
  _Session session(ProviderContainer c) =>
      c.read(sessionProvider.notifier) as _Session;

  test('loading until the settings are read', () {
    final c = ProviderContainer(
      overrides: [
        lockStoreProvider.overrideWithValue(MemoryLockStore()),
        sessionProvider.overrideWith(() => _Session(const SignedOut())),
        quickSignInProvider.overrideWith(_NoQuick.new),
      ],
    );
    addTearDown(c.dispose);
    expect(phase(c), LockPhase.loading);
    expect(c.read(appLockProvider).loaded, isFalse);
    expect(c.read(appLockProvider).locked, isFalse);
  });

  test('signed out, or no PIN: unlocked', () async {
    expect(phase(await start(const SignedOut())), LockPhase.unlocked);
    expect(phase(await start(SignedIn(_asad()))), LockPhase.unlocked);
  });

  test('a stored session with this person\'s PIN starts locked', () async {
    final c = await start(SignedIn(_asad()), prefs: _pin);
    expect(phase(c), LockPhase.quickUnlock);
    expect(c.read(appLockProvider).locked, isTrue);
    expect(c.read(appLockProvider).passwordMode, isFalse);
  });

  test('the session restoring after the settings: locked too', () async {
    final c = await start(const SessionLoading(), prefs: _pin);
    expect(phase(c), LockPhase.unlocked);
    session(c).go(SignedIn(_asad()));
    expect(phase(c), LockPhase.quickUnlock);
  });

  test('someone else\'s PIN: not locked, a new PIN is due', () async {
    final c = await start(SignedIn(_asad(userId: 2)), prefs: _pin);
    await pumpEventQueue();
    expect(phase(c), LockPhase.unlocked);
    expect(store.prefs.pinDue, isTrue);
    expect(store.prefs.hasPin, isFalse);
  });

  group('locked', () {
    late ProviderContainer c;
    setUp(() async => c = await start(SignedIn(_asad()), prefs: _pin));

    test('Sign in with password, and back', () {
      lock(c).usePassword();
      expect(phase(c), LockPhase.password);
      expect(c.read(appLockProvider).locked, isTrue);
      expect(c.read(appLockProvider).passwordMode, isTrue);
      lock(c).backToQuickUnlock();
      expect(phase(c), LockPhase.quickUnlock);
    });

    test('Forgot PIN, and back', () {
      lock(c).usePassword(forgotPin: true);
      expect(phase(c), LockPhase.forgotPin);
      expect(c.read(appLockProvider).passwordMode, isTrue);
      lock(c).backToQuickUnlock();
      expect(phase(c), LockPhase.quickUnlock);
    });

    test('the same person signing in again keeps the PIN', () async {
      lock(c).usePassword();
      session(c).go(SignedIn(_asad(token: 't2')));
      await pumpEventQueue();
      expect(phase(c), LockPhase.unlocked);
      expect(store.prefs.hasPin, isTrue);
      expect(store.prefs.pinDue, isFalse);
    });

    test(
      'after Forgot PIN, signing in drops the PIN: a new one is due',
      () async {
        lock(c).usePassword(forgotPin: true);
        session(c).go(SignedIn(_asad(token: 't2')));
        await pumpEventQueue();
        expect(phase(c), LockPhase.unlocked);
        expect(store.prefs.hasPin, isFalse);
        expect(store.prefs.pinDue, isTrue);
      },
    );

    test('Back after Forgot PIN forgets it: the PIN stays', () async {
      lock(c).usePassword(forgotPin: true);
      lock(c).backToQuickUnlock();
      lock(c).usePassword();
      session(c).go(SignedIn(_asad(token: 't2')));
      await pumpEventQueue();
      expect(store.prefs.hasPin, isTrue);
    });

    test('a fingerprint unlocks', () async {
      await lock(c).unlockedByBiometrics();
      expect(phase(c), LockPhase.unlocked);
    });

    test('signing out forgets the PIN and unlocks', () async {
      session(c).go(const SignedOut(reason: SignOutReason.chosen));
      await pumpEventQueue();
      expect(phase(c), LockPhase.unlocked);
      expect(store.prefs.hasPin, isFalse);
    });

    test('back from the background while locked: it stays as it was', () {
      lock(c).usePassword();
      lock(c).paused();
      lock(c).resumed();
      expect(phase(c), LockPhase.password);
    });
  });

  group('unlocked', () {
    late ProviderContainer c;
    setUp(() async {
      c = await start(SignedIn(_asad()), prefs: _pin);
      await lock(c).unlockedByBiometrics();
    });

    test('Sign in with password and Back do nothing', () {
      lock(c).usePassword();
      expect(phase(c), LockPhase.unlocked);
      lock(c).usePassword(forgotPin: true);
      expect(phase(c), LockPhase.unlocked);
      lock(c).backToQuickUnlock();
      expect(phase(c), LockPhase.unlocked);
    });

    test('back from the background after the wait: locked', () async {
      await lock(c).setLockAfter(0);
      lock(c).paused();
      lock(c).resumed();
      expect(phase(c), LockPhase.quickUnlock);
    });

    test('back from the background before the wait: still open', () async {
      await lock(c).setLockAfter(3600);
      lock(c).paused();
      lock(c).resumed();
      expect(phase(c), LockPhase.unlocked);
    });

    test('resumed without a pause: nothing', () async {
      await lock(c).setLockAfter(0);
      lock(c).resumed();
      expect(phase(c), LockPhase.unlocked);
    });
  });

  test('no PIN: the background never locks', () async {
    final c = await start(SignedIn(_asad()));
    await lock(c).setLockAfter(0);
    lock(c).paused();
    lock(c).resumed();
    expect(phase(c), LockPhase.unlocked);
  });
}
