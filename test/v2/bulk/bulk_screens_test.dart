import 'package:atombrand_app/l10n/app_localizations.dart';
import 'package:atombrand_app/v2/core/access/access.dart';
import 'package:atombrand_app/v2/core/access/access_controller.dart';
import 'package:atombrand_app/v2/core/api/api_result.dart';
import 'package:atombrand_app/v2/core/api/api_retry.dart';
import 'package:atombrand_app/v2/core/session/session.dart';
import 'package:atombrand_app/v2/core/session/session_controller.dart';
import 'package:atombrand_app/v2/core/session/session_store.dart';
import 'package:atombrand_app/v2/features/bulk/data/bulk_models.dart';
import 'package:atombrand_app/v2/features/bulk/data/bulk_repository.dart';
import 'package:atombrand_app/v2/features/bulk/ui/bulk_list_screen.dart';
import 'package:atombrand_app/v2/features/bulk/ui/deal_screens.dart';
import 'package:atombrand_app/v2/features/bulk/ui/quote_screen.dart';
import 'package:atombrand_app/v2/features/bulk/ui/request_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Access extends AccessController {
  @override
  AccessState build() => const AccessState(addonStates: {});
}

final _seller = BulkDossier.fromJson({
  'request': {
    'id': 88,
    'status': 'Quoted',
    'full_name': 'Hall Road Electronics',
    'phone': '03001234567',
    'quantity': 12,
    'product_title': 'OXY 55in LED',
    'product': {'id': 5, 'title': 'OXY 55in LED'},
    'from': 'seller',
    'target_price': 41000,
    'needed_by': '2026-11-20',
    'created_at': '2026-11-13 10:20:00',
  },
  'sourcing': {
    'seller': {
      'id': 31,
      'name': 'Hall Road Electronics',
      'verified': true,
      'city': 'Lahore',
      'on_atomshop_since': '2025-08-14',
      'deals_with_you': 3,
      'deals_amount': 1250000,
      'paid_on_time': 2,
      'other_open_requests': 0,
    },
    'item': {
      'typed': false,
      'product_id': 5,
      'title': 'OXY 55in LED',
      'quantity': 12,
    },
    'target_price': 41000,
    'needed_by': '2026-11-20',
    'note': 'Black only.',
    'deliver_to': {'address': 'Shop 4', 'city': 'Lahore'},
    'live_quote': {
      'id': 55,
      'number': 'QT-0007',
      'revision': 1,
      'status': 'sent',
      'total': 498000,
      'valid_until': '2026-11-21',
      'sent_at': '2026-11-13T10:00:00+05:00',
    },
    'answer': {
      'action': 'change_asked',
      'message': 'Can you do Rs. 39,500 a unit?',
      'pending': true,
      'at': '2026-11-14T09:12:00+05:00',
    },
    'history': [
      {
        'kind': 'event',
        'action': 'change_asked',
        'label': 'Change asked',
        'actor': 'seller',
        'details': 'Can you do 39,500?',
        'at': '2026-11-14T09:12:00+05:00',
      },
    ],
    'commission': {'amount': 0, 'label': 'No Atomshop fee'},
  },
});

final _website = BulkDossier.fromJson({
  'request': {
    'id': 90,
    'status': 'Quoted',
    'full_name': 'Crescent Hotels',
    'phone': '03215530190',
    'quantity': 40,
    'product_title': 'Zenvo 55" TV',
    'product': {'id': 5},
    'from': 'buyer',
    'city': 'Islamabad',
    'comments': [
      {
        'comments': 'Called, wants delivery soon',
        'status': 'Contacted',
        'by': {'name': 'Usman'},
        'created_at': '2026-11-12 11:02:00',
      },
    ],
  },
  'requester': {'name': 'Faraz', 'phone': '03215530190', 'verified': true},
  'orders': [],
  'other_requests': [],
  'lifetime_value': 0,
});

final _quotes = RequestQuotes.fromJson({
  'quotes': [
    {
      'id': 55,
      'number': 'QT-0007',
      'revision': 1,
      'status': 'sent',
      'total': 498000,
      'advance_pct': 30,
      'balance_terms': 'before_each',
      'valid_until': '2099-11-21',
      'delivery_charge': 0,
      'items': [
        {
          'product_id': 5,
          'title': 'OXY 55in LED',
          'qty': 12,
          'unit_price': 41500,
          'discount_pct': 0,
          'line_total': 498000,
        },
      ],
    },
  ],
  'deal': null,
});

final _options = QuoteOptions.fromJson({
  'products': [
    {
      'id': 5,
      'title': 'OXY 55in LED',
      'price': 45000,
      'memories': [],
      'colors': [
        {'id': 1, 'title': 'Black'},
      ],
    },
  ],
  'payment_methods': [
    {'key': 'bank', 'label': 'Bank transfer'},
    {'key': 'cash', 'label': 'Cash'},
  ],
});

final _deal = Deal.fromJson({
  'id': 7,
  'number': 'BD-0007',
  'status': 'delivering',
  'buyer_name': 'Green Hostels',
  'buyer_phone': '03452290117',
  'outlet': {'id': 2, 'name': 'Head office'},
  'total': 1650000,
  'paid': 990000,
  'advance_pct': 30,
  'balance_terms': 'before_each',
  'bulk_order_id': 90,
  'created_at': '2026-11-06T10:00:00+05:00',
  'items': [
    {
      'id': 11,
      'title': 'Washer · White',
      'qty': 20,
      'unit_price': 55000,
      'line_total': 1100000,
      'delivered_qty': 18,
    },
    {
      'id': 12,
      'title': 'Washer · Grey',
      'qty': 10,
      'unit_price': 55000,
      'line_total': 550000,
      'delivered_qty': 0,
    },
  ],
  'deliveries': [
    {
      'id': 1,
      'number': 'DN-0001',
      'delivered_on': '2026-11-07',
      'received_by': 'Kamran',
      'items': [
        {
          'deal_item_id': 11,
          'qty': 18,
          'serials': ['A1', 'A2'],
        },
      ],
    },
  ],
  'payments': [
    {
      'id': 1,
      'amount': 495000,
      'method_label': 'Bank transfer',
      'paid_on': '2026-11-06',
    },
    {
      'id': 2,
      'amount': 495000,
      'method_label': 'Bank transfer',
      'paid_on': '2026-11-10',
    },
  ],
});

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(390, 1600),
  ApiFailure? requestsFail,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final session = BrandSession(
    token: 't',
    userId: 1,
    name: 'Owner',
    who: const Who.owner(),
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: apiRetry,
      overrides: [
        sessionStoreProvider.overrideWithValue(MemorySessionStore(session)),
        accessProvider.overrideWith(_Access.new),
        bulkCountsProvider.overrideWith(
          (ref) async => BulkCounts.fromJson({
            'count': 4,
            'website': 3,
            'deals': 6,
            'seller_requests': 2,
            'seller_counts': {
              'waiting': 1,
              'change_asked': 1,
              'open': 3,
              'total': 9,
            },
          }),
        ),
        bulkRequestsProvider.overrideWith(
          (ref, q) async => requestsFail != null
              ? throw requestsFail
              : BulkRequestsPage.fromJson({
                  'items': [
                    {
                      'id': 88,
                      'status': 'New Lead',
                      'full_name': 'Hall Road Electronics',
                      'quantity': 12,
                      'product_title': 'OXY 55in LED',
                      'from': q.from == 'sellers' ? 'seller' : 'buyer',
                      'target_price': 41000,
                      'needed_by': '2026-11-16',
                      'phone': '03001234567',
                      if (q.from == 'sellers')
                        'seller': {
                          'id': 31,
                          'name': 'Hall Road Electronics',
                          'verified': true,
                        },
                    },
                  ],
                  'pagination': {'current_page': 1, 'last_page': 1, 'total': 1},
                }),
        ),
        bulkDossierProvider.overrideWith(
          (ref, id) async => id == 88 ? _seller : _website,
        ),
        requestQuotesProvider.overrideWith((ref, id) async => _quotes),
        quoteOptionsProvider.overrideWith((ref) async => _options),
        dealsProvider.overrideWith(
          (ref, q) async => DealsPage.fromJson({
            'items': [
              {
                'id': 7,
                'number': 'BD-0007',
                'status': 'delivering',
                'buyer_name': 'Green Hostels',
                'units': 30,
                'delivered_units': 18,
                'total': 1650000,
                'paid': 990000,
                'balance': 660000,
              },
            ],
            'pagination': {'current_page': 1, 'last_page': 1, 'total': 1},
          }),
        ),
        dealProvider.overrideWith((ref, id) async => _deal),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('7.1 counts every chip and tab, and filters by received day', (
    tester,
  ) async {
    await _pump(tester, const BulkListScreen());
    expect(find.text('Website 3'), findsNothing); // counts sit apart
    expect(find.bySemanticsLabel('Website 3'), findsOneWidget);
    expect(find.bySemanticsLabel('Deals 6'), findsOneWidget);
    await tester.tap(find.text('Website'));
    await tester.pumpAndSettle();
    expect(find.text('Received: Any time'), findsOneWidget);
    await tester.tap(find.text('Received: Any time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 7 days'));
    await tester.pumpAndSettle();
    expect(find.text('Received: Last 7 days'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a list the role may not see shows the not-in-role state', (
    tester,
  ) async {
    await _pump(
      tester,
      const BulkListScreen(),
      requestsFail: const ApiFailure(ApiFailureKind.notInRole, statusCode: 403),
    );
    expect(find.text("Your role doesn't include this"), findsOneWidget);
    expect(find.text('Something went wrong'), findsNothing);
  });

  testWidgets('a server error never shows its own words', (tester) async {
    await _pump(
      tester,
      const BulkListScreen(),
      requestsFail: const ApiFailure(
        ApiFailureKind.server,
        message: 'SQLSTATE[42S22]: Column not found',
        statusCode: 500,
        body: {'ref': '7F2K-91'},
      ),
    );
    expect(find.text("That didn't load"), findsOneWidget);
    expect(find.textContaining('SQLSTATE'), findsNothing);
    expect(find.textContaining('Ref 7F2K-91'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('bulk screens fit 320dp at 200% text', (tester) async {
    const narrow = Size(320, 1400);
    for (final screen in const <Widget>[
      BulkListScreen(),
      BulkListScreen(tab: 'deals'),
      BulkRequestScreen(id: 88, seller: true),
      BulkRequestScreen(id: 90),
      DealScreen(id: 7),
      DealDeliverScreen(id: 7),
      DealPaymentScreen(id: 7),
      QuoteScreen(id: 90),
    ]) {
      final old = FlutterError.onError;
      final errors = <String>[];
      FlutterError.onError = (d) => errors.add(d.toString());
      for (final scale in const [1.0, 2.0]) {
        await _pump(tester, screen, size: narrow, textScale: scale);
      }
      FlutterError.onError = old;
      expect(errors, isEmpty, reason: '$screen');
    }
  });

  testWidgets('7.1 lists seller requests, website requests and deals', (
    tester,
  ) async {
    await _pump(tester, const BulkListScreen());
    expect(find.text('Bulk deals'), findsOneWidget);
    expect(find.text('Hall Road Electronics'), findsOneWidget);
    expect(find.text('Send quote'), findsOneWidget);
    await tester.tap(find.text('Website'));
    await tester.pumpAndSettle();
    expect(find.text('Reply'), findsOneWidget);
    await tester.tap(find.text('Deals'));
    await tester.pumpAndSettle();
    expect(find.text('BD-0007'), findsOneWidget);
    expect(find.text('Deliver'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a wide tablet shows the list and the picked row side by side', (
    tester,
  ) async {
    await _pump(tester, const BulkListScreen(), size: const Size(1280, 900));
    // The first request opens beside the list, with no back arrow.
    expect(find.text('Hall Road Electronics'), findsWidgets);
    expect(find.text('The seller asked for a change'), findsOneWidget);
    expect(find.text('What they need'), findsOneWidget);
    await tester.tap(find.text('Deals'));
    await tester.pumpAndSettle();
    expect(find.text('BD-0007'), findsWidgets);
    expect(find.text('Green Hostels'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('7.2 shows a change asked with the seller record', (
    tester,
  ) async {
    await _pump(tester, const BulkRequestScreen(id: 88, seller: true));
    expect(find.text('The seller asked for a change'), findsOneWidget);
    expect(find.text('What they need'), findsOneWidget);
    expect(find.text('Atomshop commission'), findsOneWidget);
    expect(find.text('Change asked'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('7.3 shows a quoted website request', (tester) async {
    await _pump(tester, const BulkRequestScreen(id: 90));
    expect(find.text('The request'), findsOneWidget);
    expect(find.text('They said yes?'), findsOneWidget);
    expect(find.text('New quote revision'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('7.4 builds a revision from the sent quote', (tester) async {
    await _pump(tester, const QuoteScreen(id: 90));
    expect(find.text('Quote total'), findsOneWidget);
    expect(find.textContaining('Sending makes rev 2'), findsOneWidget);
    expect(find.text('Save and send on WhatsApp'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('7.7, 7.8 and 7.9 render a deal', (tester) async {
    await _pump(tester, const DealScreen(id: 7));
    expect(find.text('Green Hostels'), findsOneWidget);
    expect(find.text('Deliver units'), findsOneWidget);
    await _pump(tester, const DealDeliverScreen(id: 7));
    expect(find.text('WHAT GOES OUT NOW'), findsOneWidget);
    expect(find.textContaining('Save delivery'), findsOneWidget);
    await _pump(tester, const DealPaymentScreen(id: 7));
    expect(find.text('Save payment'), findsOneWidget);
    expect(find.text('Full balance'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
