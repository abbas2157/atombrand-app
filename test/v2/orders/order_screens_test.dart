// The order page and a list row draw for each step without layout errors,
// and show only what the role and the step allow.

import 'package:atombrand_app/l10n/app_localizations.dart';
import 'package:atombrand_app/v2/core/access/access.dart';
import 'package:atombrand_app/v2/core/access/access_controller.dart';
import 'package:atombrand_app/v2/core/net/network_status.dart';
import 'package:atombrand_app/v2/core/session/session.dart';
import 'package:atombrand_app/v2/core/session/session_controller.dart';
import 'package:atombrand_app/v2/features/orders/data/orders_models.dart';
import 'package:atombrand_app/v2/features/orders/data/orders_providers.dart';
import 'package:atombrand_app/v2/core/api/api_result.dart';
import 'package:atombrand_app/v2/features/orders/ui/order_detail_screen.dart';
import 'package:atombrand_app/v2/features/orders/ui/order_parts.dart';
import 'package:atombrand_app/v2/features/orders/ui/order_payment_screen.dart';
import 'package:atombrand_app/v2/features/orders/ui/orders_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Session extends SessionController {
  _Session(this.session);
  final BrandSession session;
  @override
  SessionState build() => SignedIn(session);
}

class _Access extends AccessController {
  _Access(this.value);
  final AccessState value;
  @override
  AccessState build() => value;
}

const _owner = BrandSession(
  token: 't',
  userId: 1,
  name: 'Asad Raza',
  who: Who.owner(),
);

final _viewer = BrandSession(
  token: 't',
  userId: 2,
  name: 'Usman Ali',
  who: const Who(isOwner: false, permissions: {'orders.view'}),
);

const _noAddons = AccessState(addonStates: {});

Map<String, dynamic> _detail(String status, {int paid = 0}) => {
  'order': {
    'uuid': 'u-1',
    'id': 48224,
    'status': status,
    'total_deal_price': 112500,
    'product': {'title': 'Zenvo Refrigerator 14 cft'},
    'variant': 'Silver',
    'created_at': '2026-11-02 16:18:00',
    'type': 'cash',
    'paid': paid,
    'balance': 112500 - paid,
    'quantity': 1,
  },
  'customer': {
    'name': 'Faisal Qureshi',
    'phone': '03214410779',
    'verified': true,
    'city': 'Lahore',
  },
  'history': [],
  'payments': [
    if (paid > 0) {'amount': paid, 'method': 'cod', 'paid_on': '2026-11-04'},
  ],
  'payment_methods': ['cod', 'cash'],
  'next_statuses': switch (status) {
    'Pending' => ['Varification', 'Processing', 'Cancelled'],
    'Processing' => ['Delivered', 'Cancelled'],
    'Delivered' => ['Completed'],
    _ => <String>[],
  },
  'also_bought': [],
};

Widget _app(
  Widget child, {
  BrandSession session = _owner,
  Map<String, dynamic>? detail,
}) => ProviderScope(
  overrides: [
    sessionProvider.overrideWith(() => _Session(session)),
    accessProvider.overrideWith(() => _Access(_noAddons)),
    onlineProvider.overrideWith((ref) => Stream.value(true)),
    if (detail != null)
      orderDetailProvider.overrideWith(
        (ref, uuid) async => CashOrderDetail.fromJson(detail),
      ),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('Pending: the next step is to call, Cancel is offered', (
    t,
  ) async {
    await t.pumpWidget(
      _app(const OrderView(uuid: 'u-1'), detail: _detail('Pending')),
    );
    await t.pumpAndSettle();
    expect(find.text('Call the customer'), findsWidgets);
    expect(find.text('Start confirming'), findsOneWidget);
    await t.scrollUntilVisible(find.text('Cancel'), 300);
    expect(find.text('Cancel'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('Delivered and part paid: record payment, Complete waits', (
    t,
  ) async {
    await t.pumpWidget(
      _app(
        const OrderView(uuid: 'u-1'),
        detail: _detail('Delivered', paid: 50000),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Complete · Rs 62,500 still to pay'), findsOneWidget);
    expect(find.text('Record payment'), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets('a viewer sees the order but no buttons', (t) async {
    await t.pumpWidget(
      _app(
        const OrderView(uuid: 'u-1'),
        session: _viewer,
        detail: _detail('Processing'),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Mark delivered'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('What was ordered'), findsOneWidget);
  });

  testWidgets('a list row shows its one action', (t) async {
    final o = CashOrder.fromJson(_detail('Processing')['order']);
    await t.pumpWidget(_app(CashOrderCard(order: o, multiOutlet: false)));
    await t.pumpAndSettle();
    expect(find.text('Mark delivered'), findsOneWidget);
    expect(find.text('Unpaid'), findsOneWidget);
    expect(find.text('Rs 112,500'), findsOneWidget);
  });

  for (final scale in [1.0, 2.0]) {
    Future<void> narrow(WidgetTester t, Widget child, Map<String, dynamic>? d) {
      t.view.physicalSize = const Size(320, 700);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      return t.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: const Size(320, 700),
            textScaler: TextScaler.linear(scale),
          ),
          child: _app(child, detail: d),
        ),
      );
    }

    testWidgets('order page at 320dp, text x$scale: no overflow', (t) async {
      await narrow(
        t,
        const OrderView(uuid: 'u-1'),
        _detail('Delivered', paid: 50000),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.scrollUntilVisible(find.text('Free'), 300);
      expect(find.text('Free'), findsOneWidget);
      await t.scrollUntilVisible(find.text('Not given').first, 300);
      expect(t.takeException(), isNull);
    });

    testWidgets('list card at 320dp, text x$scale', (t) async {
      final o = CashOrder.fromJson({
        ..._detail('Delivered', paid: 50000)['order'] as Map<String, dynamic>,
        'customer': {'name': 'Faisal Qureshi'},
        'city': 'Lahore',
      });
      await narrow(
        t,
        ListView(children: [CashOrderCard(order: o, multiOutlet: true)]),
        null,
      );
      await t.pumpAndSettle();
      expect(find.text('Take payment'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('record a payment at 320dp, text x$scale', (t) async {
      await narrow(
        t,
        const OrderPaymentScreen(uuid: 'u-1'),
        _detail('Delivered', paid: 50000),
      );
      await t.pumpAndSettle();
      expect(find.text('Rs'), findsWidgets);
      expect(find.text('Half'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('a crash shows the board copy, a 403 the role, never raw text', (
    t,
  ) async {
    await t.pumpWidget(
      _app(
        OrdersLoadError(
          error: classifyFailure(
            statusCode: 500,
            body: {'message': 'SQLSTATE[42S22]: Column not found'},
          ),
          onRetry: () {},
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text("That didn't load"), findsOneWidget);
    expect(find.textContaining('SQLSTATE'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
  });
}
