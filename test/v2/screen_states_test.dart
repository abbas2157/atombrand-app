import 'dart:async';

import 'package:atombrand_app/l10n/app_localizations.dart';
import 'package:atombrand_app/v2/core/access/access.dart';
import 'package:atombrand_app/v2/core/access/access_controller.dart';
import 'package:atombrand_app/v2/core/api/api_result.dart';
import 'package:atombrand_app/v2/core/session/session.dart';
import 'package:atombrand_app/v2/core/session/session_controller.dart';
import 'package:atombrand_app/v2/features/auth/data/auth_repository.dart';
import 'package:atombrand_app/v2/features/auth/ui/forgot_screens.dart';
import 'package:atombrand_app/v2/features/catalogue/data/catalogue_models.dart';
import 'package:atombrand_app/v2/features/catalogue/data/catalogue_repository.dart';
import 'package:atombrand_app/v2/features/catalogue/ui/products_screen.dart';
import 'package:atombrand_app/v2/features/help/data/help_repository.dart';
import 'package:atombrand_app/v2/features/help/ui/help_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Screen states that phase 4 put into one value: products' later pages,
/// and Verify / Send again on the reset code.

final l = lookupAppLocalizations(const Locale('en'));

void _phone(WidgetTester t) {
  t.view.physicalSize = const Size(1080, 2376);
  t.view.devicePixelRatio = 2.625;
  addTearDown(t.view.reset);
}

Widget _app(Widget home, List overrides) => ProviderScope(
  overrides: [...overrides],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

// ───────────────────────────────────────────── products, later pages

class _Owner extends SessionController {
  @override
  SessionState build() => const SignedIn(
    BrandSession(
      token: 't',
      userId: 1,
      name: 'Owner',
      who: Who.owner(),
      brandName: 'Zenvo',
    ),
  );
}

class _Access extends AccessController {
  @override
  AccessState build() =>
      const AccessState(addonStates: {Addon.inventory: AddonState.off});
}

ProductRow _row(int id, String title) => ProductRow.fromJson({
  'id': id,
  'pr_number': 'PR-$id',
  'title': title,
  'price': 1000,
  'status': 'Published',
});

/// Page 2 answers when the test says so.
class _Repo extends Fake implements CatalogueRepository {
  final asked = <Completer<ApiResult<ProductsPage>>>[];

  @override
  Future<ApiResult<ProductsPage>> products({
    String search = '',
    String? status,
    String? sort,
    int page = 1,
  }) {
    final c = Completer<ApiResult<ProductsPage>>();
    asked.add(c);
    return c.future;
  }
}

List _products(_Repo repo) => [
  sessionProvider.overrideWith(_Owner.new),
  accessProvider.overrideWith(_Access.new),
  catalogueRepositoryProvider.overrideWithValue(repo),
  productsProvider.overrideWith(
    (ref, q) async => q.search.isEmpty
        ? ProductsPage(
            rows: [_row(1, 'First page AC')],
            hasMore: true,
            total: 2,
          )
        : ProductsPage(rows: [_row(3, 'Searched fridge')], total: 1),
  ),
];

final _page2 = ApiOk(ProductsPage(rows: [_row(2, 'Second page TV')], page: 2));

// ───────────────────────────────────────────── reset code

/// Verify and Send again answer when the test says so.
class _Forgot extends ForgotFlow {
  final verifies = <Completer<ApiFailure?>>[];
  final sends = <Completer<ApiFailure?>>[];

  @override
  ForgotState build() => const ForgotState(login: 'asad@zenvo.test');

  @override
  Future<ApiFailure?> verify(String code) {
    final c = Completer<ApiFailure?>();
    verifies.add(c);
    return c.future;
  }

  @override
  Future<ApiFailure?> send({String? login, ResetChannel? channel}) {
    final c = Completer<ApiFailure?>();
    sends.add(c);
    return c.future;
  }
}

// ───────────────────────────────────────────── a support thread

final _answered = SupportRequest.fromJson({
  'uuid': 'u1',
  'code': 'HLP-1',
  'subject': 'Stock',
  'question': 'How do I add stock?',
  'status': 'open',
  'reply': 'From Stock in.',
  'can_reply': true,
  'can_close': true,
});

/// Reply and close answer when the test says so.
class _Help extends Fake implements HelpRepository {
  final replies = <Completer<ApiResult<SupportRequest>>>[];
  final closes = <Completer<ApiResult<SupportRequest>>>[];

  @override
  Future<ApiResult<SupportRequest>> reply(String uuid, String message) {
    final c = Completer<ApiResult<SupportRequest>>();
    replies.add(c);
    return c.future;
  }

  @override
  Future<ApiResult<SupportRequest>> close(String uuid) {
    final c = Completer<ApiResult<SupportRequest>>();
    closes.add(c);
    return c.future;
  }
}

void main() {
  group('Products: the pages after the first', () {
    testWidgets('Show more adds the next page', (t) async {
      _phone(t);
      final repo = _Repo();
      await t.pumpWidget(_app(const ProductsScreen(), _products(repo)));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text(l.catShowMore));
      await t.pumpAndSettle();
      await t.tap(find.text(l.catShowMore));
      await t.pump();
      expect(repo.asked, hasLength(1));

      repo.asked.single.complete(_page2);
      await t.pumpAndSettle();
      expect(find.text('Second page TV'), findsOneWidget);
      // Page 2 was the last: no Show more.
      expect(find.text(l.catShowMore), findsNothing);
    });

    testWidgets('a page that lands after the search changed is dropped', (
      t,
    ) async {
      _phone(t);
      final repo = _Repo();
      await t.pumpWidget(_app(const ProductsScreen(), _products(repo)));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text(l.catShowMore));
      await t.pumpAndSettle();
      await t.tap(find.text(l.catShowMore));
      await t.pump();

      // While it loads the button is a spinner: nothing to tap twice.
      expect(find.text(l.catShowMore), findsNothing);
      expect(repo.asked, hasLength(1));

      // The search changes while page 2 is out.
      // (The spinner never settles, so pump by time while it shows.)
      await t.ensureVisible(find.byType(TextField));
      await t.pump(const Duration(milliseconds: 500));
      await t.enterText(find.byType(TextField), 'fridge');
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('Searched fridge'), findsOneWidget);
      // The new search starts its own pages: no spinner left over.
      expect(find.text('First page AC'), findsNothing);

      repo.asked.single.complete(_page2);
      await t.pumpAndSettle();
      expect(find.text('Second page TV'), findsNothing);
      expect(find.text('Searched fridge'), findsOneWidget);
    });
  });

  group('Reset code: Verify and Send again, one at a time', () {
    Future<_Forgot> open(WidgetTester t) async {
      _phone(t);
      final forgot = _Forgot();
      await t.pumpWidget(
        _app(const ForgotCodeScreen(), [
          forgotProvider.overrideWith(() => forgot),
        ]),
      );
      await t.pumpAndSettle();
      // Send again opens after its wait.
      await t.pump(ForgotCodeScreen.resendAfter + const Duration(seconds: 1));
      await t.pumpAndSettle();
      return forgot;
    }

    /// Six digits verify by themselves.
    Future<void> typeCode(WidgetTester t) async {
      await t.enterText(find.byType(TextField).first, '123456');
      await t.pump();
    }

    testWidgets('while Verify is out, Send again asks nothing', (t) async {
      final forgot = await open(t);
      await typeCode(t);
      expect(forgot.verifies, hasLength(1));

      await t.tap(find.text(l.codeResend), warnIfMissed: false);
      await t.pump();
      expect(forgot.sends, isEmpty);

      forgot.verifies.single.complete(
        const ApiFailure(ApiFailureKind.validation, message: 'Wrong code'),
      );
      await t.pumpAndSettle();

      // Back to idle: Send again works.
      await t.tap(find.text(l.codeResend));
      await t.pump();
      expect(forgot.sends, hasLength(1));
      forgot.sends.single.complete(null);
      await t.pumpAndSettle();
    });

    testWidgets('while Send again is out, Verify asks nothing', (t) async {
      final forgot = await open(t);
      await t.tap(find.text(l.codeResend));
      await t.pump();
      expect(forgot.sends, hasLength(1));

      await typeCode(t);
      await t.tap(find.text(l.codeVerify), warnIfMissed: false);
      await t.pump();
      expect(forgot.verifies, isEmpty);

      forgot.sends.single.complete(null);
      await t.pumpAndSettle();
    });
  });

  group('Support thread: a reply or a close, one at a time', () {
    Future<_Help> open(WidgetTester t) async {
      _phone(t);
      final help = _Help();
      await t.pumpWidget(
        _app(SupportThreadScreen(request: _answered), [
          helpRepositoryProvider.overrideWithValue(help),
        ]),
      );
      await t.pumpAndSettle();
      return help;
    }

    Future<void> send(WidgetTester t, String text) async {
      await t.enterText(find.byType(TextField).last, text);
      await t.pump();
      await t.tap(find.bySemanticsLabel(l.dpDcSend), warnIfMissed: false);
      await t.pump();
    }

    testWidgets('while a reply is out, Yes close asks nothing', (t) async {
      final help = await open(t);
      await send(t, 'Thanks, one more thing');
      expect(help.replies, hasLength(1));

      await t.tap(find.text(l.dpDcYesClose), warnIfMissed: false);
      await t.pump();
      expect(help.closes, isEmpty);

      help.replies.single.complete(ApiOk(_answered));
      await t.pump(const Duration(milliseconds: 500));

      // Back to idle: close works.
      await t.tap(find.text(l.dpDcYesClose));
      await t.pump();
      expect(help.closes, hasLength(1));
    });

    testWidgets('while a close is out, a reply asks nothing; a second '
        'close too', (t) async {
      final help = await open(t);
      await t.tap(find.text(l.dpDcYesClose));
      await t.pump();
      expect(help.closes, hasLength(1));

      await t.tap(find.text(l.dpDcYesClose), warnIfMissed: false);
      await t.pump();
      expect(help.closes, hasLength(1));

      await send(t, 'Wait');
      expect(help.replies, isEmpty);
    });
  });
}
