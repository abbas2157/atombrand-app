import 'dart:async';

import 'package:atombrand_app/l10n/app_localizations.dart';
import 'package:atombrand_app/v2/core/api/api_result.dart';
import 'package:atombrand_app/v2/core/lock/app_lock.dart';
import 'package:atombrand_app/v2/core/lock/quick_sign_in.dart';
import 'package:atombrand_app/v2/core/net/network_status.dart';
import 'package:atombrand_app/v2/core/session/session.dart';
import 'package:atombrand_app/v2/core/session/session_controller.dart';
import 'package:atombrand_app/v2/features/auth/data/auth_repository.dart';
import 'package:atombrand_app/v2/features/auth/ui/set_pin_screen.dart';
import 'package:atombrand_app/v2/features/auth/ui/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

final l = lookupAppLocalizations(const Locale('en'));

/// The lock, without the phone's key store.
class _Lock extends AppLockController {
  _Lock({this.wrong = 0, this.current});
  final int wrong;

  /// What checking the PIN in use answers, one call at a time.
  final Future<PinCheck> Function()? current;
  final set = <String>[];
  int checks = 0;

  @override
  AppLockState build() => AppLockState(
    prefs: LockPrefs(pinHash: 'h', salt: 's', userId: 1, wrong: wrong),
    phase: LockPhase.unlocked,
  );

  @override
  Future<void> setPin(String pin) async => set.add(pin);

  @override
  Future<PinCheck> checkCurrent(String pin) {
    checks++;
    return current!();
  }

  @override
  Duration waitLeft() => Duration.zero;
}

class _NoQuick extends QuickSignInController {
  @override
  QuickSignInState build() => const QuickSignInState(loaded: true);
}

class _SignedOut extends SessionController {
  @override
  SessionState build() => const SignedOut();
}

class _NoBiometrics implements Biometrics {
  @override
  Future<bool> available() async => false;
  @override
  Future<bool> check(String reason) async => false;
}

class _Online implements NetworkStatus {
  @override
  Future<bool> check() async => true;
  @override
  Stream<bool> watch() => Stream.value(true);
}

/// Answers sign-ins from a list, in order.
class _Auth extends Fake implements AuthRepository {
  _Auth(this.answers);
  final List<Future<ApiResult<BrandSession>> Function()> answers;
  int calls = 0;

  @override
  Future<ApiResult<BrandSession>> signIn({
    required String login,
    required String password,
  }) => answers[calls++]();
}

Widget _app(Widget screen, {_Lock? lock, _Auth? auth}) => ProviderScope(
  overrides: [
    appLockProvider.overrideWith(() => lock ?? _Lock()),
    quickSignInProvider.overrideWith(_NoQuick.new),
    sessionProvider.overrideWith(_SignedOut.new),
    biometricsProvider.overrideWithValue(_NoBiometrics()),
    networkStatusProvider.overrideWithValue(_Online()),
    onlineProvider.overrideWith((ref) => Stream.value(true)),
    if (auth != null) authRepositoryProvider.overrideWithValue(auth),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: screen,
  ),
);

/// A phone's screen (the OnePlus the app is checked on).
void _phone(WidgetTester t) {
  t.view.physicalSize = const Size(1080, 2376);
  t.view.devicePixelRatio = 2.625;
  addTearDown(t.view.reset);
}

/// Text anywhere, also inside a note's rich text.
Finder _says(String text) => find.textContaining(text, findRichText: true);

Future<void> _type(WidgetTester t, String digits) async {
  for (final d in digits.split('')) {
    await t.tap(find.text(d).last);
    await t.pump();
  }
  await t.pumpAndSettle();
}

void main() {
  group('Set PIN: create → confirm → saving → done', () {
    testWidgets('a PIN typed twice is stored, then done', (t) async {
      _phone(t);
      final lock = _Lock();
      await t.pumpWidget(_app(PinSetupScreen(onFinished: () {}), lock: lock));
      await t.pumpAndSettle();
      expect(find.text(l.pinCreateTitle), findsOneWidget);

      await _type(t, '2580');
      expect(find.text(l.pinConfirmTitle), findsOneWidget);

      await _type(t, '2580');
      expect(lock.set, ['2580']);
      expect(find.text(l.pinDoneTitle), findsOneWidget);

      // Done: the pad is gone, so no more digits.
      expect(find.text('7'), findsNothing);
    });

    testWidgets('an easy PIN is refused and stays on create', (t) async {
      _phone(t);
      await t.pumpWidget(_app(PinSetupScreen(onFinished: () {})));
      await t.pumpAndSettle();
      await _type(t, '1234');
      expect(_says(l.qa3PinTooEasy), findsOneWidget);
      expect(find.text(l.pinCreateTitle), findsOneWidget);
    });

    testWidgets('a different second PIN goes back to create', (t) async {
      _phone(t);
      final lock = _Lock();
      await t.pumpWidget(_app(PinSetupScreen(onFinished: () {}), lock: lock));
      await t.pumpAndSettle();
      await _type(t, '2580');
      await _type(t, '2581');
      expect(_says(l.pinMismatch), findsOneWidget);
      expect(find.text(l.pinCreateTitle), findsOneWidget);
      expect(lock.set, isEmpty);

      // And the next pair is a fresh start.
      await _type(t, '3691');
      expect(find.text(l.pinConfirmTitle), findsOneWidget);
      await _type(t, '3691');
      expect(lock.set, ['3691']);
    });

    testWidgets('Back on confirm starts the entry again', (t) async {
      _phone(t);
      await t.pumpWidget(_app(PinSetupScreen(onFinished: () {})));
      await t.pumpAndSettle();
      await _type(t, '2580');
      expect(find.text(l.pinConfirmTitle), findsOneWidget);
      await t.tap(find.byIcon(LucideIcons.chevronLeft));
      await t.pumpAndSettle();
      expect(find.text(l.pinCreateTitle), findsOneWidget);
    });
  });

  group('Change PIN: current → checking → create', () {
    testWidgets('a wrong current PIN stays on current, then a right one '
        'moves on', (t) async {
      _phone(t);
      final answers = [PinCheck.wrong, PinCheck.ok];
      final lock = _Lock(wrong: 1, current: () async => answers.removeAt(0));
      await t.pumpWidget(
        _app(PinSetupScreen(onFinished: () {}, askCurrent: true), lock: lock),
      );
      await t.pumpAndSettle();
      expect(find.text(l.qa3PinCurrentTitle), findsOneWidget);

      await _type(t, '9999');
      expect(_says(l.qa3PinCurrentWrong(maxPinTries - 1)), findsOneWidget);
      expect(find.text(l.qa3PinCurrentTitle), findsOneWidget);

      await _type(t, '2580');
      expect(find.text(l.pinCreateTitle), findsOneWidget);
      expect(lock.checks, 2);
    });

    testWidgets('no digits while the current PIN is being checked', (t) async {
      _phone(t);
      final answer = Completer<PinCheck>();
      final lock = _Lock(current: () => answer.future);
      await t.pumpWidget(
        _app(PinSetupScreen(onFinished: () {}, askCurrent: true), lock: lock),
      );
      await t.pumpAndSettle();
      await _type(t, '2580');
      expect(lock.checks, 1);

      // Still checking: taps are ignored, nothing is asked again.
      await _type(t, '1111');
      expect(lock.checks, 1);
      expect(find.text(l.qa3PinCurrentTitle), findsOneWidget);

      answer.complete(PinCheck.ok);
      await t.pumpAndSettle();
      expect(find.text(l.pinCreateTitle), findsOneWidget);
    });
  });

  group('Sign in: editing → signing in → offline / unverified / editing', () {
    Future<void> fill(WidgetTester t) async {
      await t.enterText(find.byType(TextField).at(0), 'asad@zenvo.test');
      await t.enterText(find.byType(TextField).at(1), 'secret123');
      await t.pump();
    }

    Future<void> submit(WidgetTester t) async {
      await t.tap(find.text(l.signInButton));
      await t.pump();
    }

    testWidgets('signing in shows the spinner; a wrong password comes back '
        'to editing', (t) async {
      _phone(t);
      final reply = Completer<ApiResult<BrandSession>>();
      final auth = _Auth([() => reply.future]);
      await t.pumpWidget(_app(const SignInScreen(), auth: auth));
      await t.pumpAndSettle();
      await fill(t);
      await submit(t);
      expect(find.text(l.signInSigningIn), findsOneWidget);

      reply.complete(const ApiErr(ApiFailure(ApiFailureKind.signedOut)));
      await t.pumpAndSettle();
      expect(find.text(l.signInSigningIn), findsNothing);
      expect(_says(l.auth2WrongOwner), findsOneWidget);
      expect(find.text(l.signInButton), findsOneWidget);
    });

    testWidgets('no connection: the offline note, and Try again sends again', (
      t,
    ) async {
      _phone(t);
      final auth = _Auth([
        () async => const ApiErr(ApiFailure(ApiFailureKind.offline)),
        () async => const ApiErr(ApiFailure(ApiFailureKind.signedOut)),
      ]);
      await t.pumpWidget(_app(const SignInScreen(), auth: auth));
      await t.pumpAndSettle();
      await fill(t);
      await submit(t);
      await t.pumpAndSettle();
      expect(_says(l.auth2OfflineTitle), findsOneWidget);
      expect(find.text(l.signInButton), findsNothing);

      await t.tap(find.text(l.commonTryAgain));
      await t.pumpAndSettle();
      expect(auth.calls, 2);
      expect(_says(l.auth2OfflineTitle), findsNothing);
      expect(_says(l.auth2WrongOwner), findsOneWidget);
    });

    testWidgets('not verified yet: the note and WhatsApp; typing starts '
        'again', (t) async {
      _phone(t);
      final auth = _Auth([
        () async => const ApiErr(
          ApiFailure(
            ApiFailureKind.signedOut,
            body: {'reason': unverifiedBrandReason},
          ),
        ),
      ]);
      await t.pumpWidget(_app(const SignInScreen(), auth: auth));
      await t.pumpAndSettle();
      await fill(t);
      await submit(t);
      await t.pumpAndSettle();
      expect(_says(l.auth2PendingTitle), findsOneWidget);
      expect(find.text(l.auth2AskOnWhatsApp), findsOneWidget);
      expect(find.text(l.signInButton), findsNothing);

      await t.enterText(find.byType(TextField).at(1), 'secret1234');
      await t.pumpAndSettle();
      expect(_says(l.auth2PendingTitle), findsNothing);
      expect(find.text(l.signInButton), findsOneWidget);
    });

    testWidgets('empty fields: errors, and nothing is sent', (t) async {
      _phone(t);
      final auth = _Auth([]);
      await t.pumpWidget(_app(const SignInScreen(), auth: auth));
      await t.pumpAndSettle();
      await submit(t);
      await t.pumpAndSettle();
      expect(_says(l.signInPasswordEmpty), findsOneWidget);
      expect(auth.calls, 0);
    });
  });
}
