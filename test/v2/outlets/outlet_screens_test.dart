// The outlet screens draw from the server's answers: the list with shares
// and room to add, an outlet's page and its status choice, and the form's
// taken cities.

import 'package:atombrand_app/l10n/app_localizations.dart';
import 'package:atombrand_app/v2/core/access/access.dart';
import 'package:atombrand_app/v2/core/access/access_controller.dart';
import 'package:atombrand_app/v2/core/api/api_result.dart';
import 'package:atombrand_app/v2/core/net/network_status.dart';
import 'package:atombrand_app/v2/core/session/session.dart';
import 'package:atombrand_app/v2/core/session/session_controller.dart';
import 'package:atombrand_app/v2/design/design.dart';
import 'package:atombrand_app/v2/features/outlets/data/outlet_models.dart';
import 'package:atombrand_app/v2/features/outlets/data/outlets_repository.dart';
import 'package:atombrand_app/v2/features/outlets/ui/outlet_form_screen.dart';
import 'package:atombrand_app/v2/features/outlets/ui/outlet_screen.dart';
import 'package:atombrand_app/v2/features/outlets/ui/outlets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Session extends SessionController {
  @override
  SessionState build() => const SignedIn(
    BrandSession(
      token: 't',
      userId: 1,
      name: 'Asad Raza',
      brandName: 'Zenvo',
      who: Who.owner(),
    ),
  );
}

class _Access extends AccessController {
  @override
  AccessState build() => const AccessState(addonStates: {});
  @override
  Future<void> refreshIfStale() async {}
}

Map<String, dynamic> _outlet(
  int id,
  String name, {
  bool main = false,
  String status = 'open',
  List<(int, String)> cities = const [],
  int sales = 0,
  int? units,
}) => {
  'id': id,
  'name': name,
  'is_main': main,
  'status': status,
  'phone': '0321 8890 112',
  'address': 'Shahrah-e-Faisal',
  'city': cities.isEmpty
      ? null
      : {'id': cities.first.$1, 'title': cities.first.$2},
  'cities': [
    for (final c in cities) {'id': c.$1, 'title': c.$2},
  ],
  'manager': id == 9 ? {'id': 77, 'name': 'Usman Ali'} : null,
  'opened_on': '2026-08-02',
  'open_orders': 2,
  'figures': {
    'sales': sales,
    'orders': 5,
    'delivered': 3,
    'payments': sales ~/ 2,
    'avg_order': 123100,
    'to_confirm': 1,
    'units': units,
    'staff': 2,
  },
};

final _list = OutletList.fromJson({
  'account_type': 'multi',
  'outlet_limit': 4,
  'used': 3,
  'outlets': [
    _outlet(
      4,
      'Head office',
      main: true,
      cities: const [(1, 'Lahore')],
      sales: 1349000,
    ),
    _outlet(
      9,
      'Karachi outlet',
      cities: const [(2, 'Karachi'), (3, 'Hyderabad')],
      sales: 615500,
      units: 96,
    ),
    _outlet(
      12,
      'Islamabad outlet',
      status: 'paused',
      cities: const [(5, 'Islamabad')],
      sales: 220000,
    ),
  ],
});

class _Repo implements OutletsRepository {
  @override
  Future<ApiResult<OutletList>> outlets(OutletPeriod period) async =>
      ApiOk(_list);
  @override
  Future<ApiResult<BrandOutlet>> outlet(int id) async =>
      ApiOk(_list.outlets.firstWhere((o) => o.id == id));
  @override
  Future<ApiResult<List<City>>> cities() async => const ApiOk([
    (id: 1, title: 'Lahore'),
    (id: 2, title: 'Karachi'),
    (id: 6, title: 'Faisalabad'),
  ]);
  // An older server: no form options, so the form falls back to cities().
  @override
  Future<ApiResult<OutletFormOptions>> formOptions({int? outletId}) async =>
      const ApiErr(ApiFailure(ApiFailureKind.notFound));
  @override
  Future<ApiResult<List<OutletOrder>>> latestOrders(int outletId) async =>
      const ApiOk([
        OutletOrder(
          uuid: 'u1',
          id: 48213,
          status: 'Pending',
          product: 'Zenvo Inverter AC',
          city: 'Karachi',
        ),
      ]);
  @override
  Future<ApiResult<BrandOutlet>> add(OutletDraft draft) =>
      throw UnimplementedError();
  @override
  Future<ApiResult<BrandOutlet>> update(int id, OutletDraft draft) =>
      throw UnimplementedError();
  @override
  Future<ApiResult<BrandOutlet>> setStatus(int id, OutletStatus status) =>
      throw UnimplementedError();
}

Future<void> _pump(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(390 * 3, 2400 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(_Session.new),
        accessProvider.overrideWith(_Access.new),
        onlineProvider.overrideWith((ref) => Stream.value(true)),
        outletsRepositoryProvider.overrideWithValue(_Repo()),
      ],
      child: MaterialApp(
        theme: AtomTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Outlets: all outlets together, each card with its share, room to add',
    (tester) async {
      await _pump(tester, const OutletsScreen());
      expect(find.text('Rs 2,184,500'), findsOneWidget);
      expect(find.text('3 of 4 outlets'), findsOneWidget);
      expect(find.text('Karachi outlet'), findsOneWidget);
      expect(find.text('28% of sales'), findsOneWidget);
      expect(find.text('Paused · no new orders'), findsOneWidget);
      expect(find.bySemanticsLabel('Add outlet'), findsOneWidget);
      expect(
        find.text('Need more than 4 outlets? Ask Atomshop on WhatsApp'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'An outlet: figures, latest orders, and closing waits for open orders',
    (tester) async {
      await _pump(tester, const OutletScreen(id: 9));
      expect(find.textContaining('run by Usman Ali'), findsOneWidget);
      expect(find.text('#48213'), findsOneWidget);
      expect(find.text('Karachi, Hyderabad'), findsOneWidget);
      expect(
        find.text('Open: takes new orders for Karachi and Hyderabad.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Closed').last);
      await tester.pumpAndSettle();
      expect(find.text('Can’t close yet'), findsOneWidget);
    },
  );

  testWidgets(
    'Add outlet: used of the limit and cities other outlets serve shown taken',
    (tester) async {
      await _pump(tester, const OutletFormScreen());
      expect(find.text('Outlets used: 3 of 4'), findsOneWidget);
      expect(find.text('Karachi · Karachi'), findsOneWidget);
      expect(find.text('Lahore · Head office'), findsOneWidget);
      expect(find.text('Give the outlet a name'), findsOneWidget);
    },
  );
}
