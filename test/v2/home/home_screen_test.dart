// Home draws for the owner, a team member and a new brand from one
// dashboard answer, leaving out what the role or add-ons don't allow.

import 'package:atombrand_app/l10n/app_localizations.dart';
import 'package:atombrand_app/v2/core/access/access.dart';
import 'package:atombrand_app/v2/core/access/access_controller.dart';
import 'package:atombrand_app/v2/core/api/api_result.dart';
import 'package:atombrand_app/v2/core/net/network_status.dart';
import 'package:atombrand_app/v2/core/session/session.dart';
import 'package:atombrand_app/v2/core/session/session_controller.dart';
import 'package:atombrand_app/v2/design/design.dart';
import 'package:atombrand_app/v2/features/home/data/home_logic.dart';
import 'package:atombrand_app/v2/features/home/data/home_models.dart';
import 'package:atombrand_app/v2/features/home/data/home_repository.dart';
import 'package:atombrand_app/v2/features/home/ui/home_screen.dart';
import 'package:atombrand_app/v2/features/home/ui/quick_actions_sheet.dart';
import 'package:atombrand_app/v2/features/sync/data/sync_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final l = lookupAppLocalizations(const Locale('en'));

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
  @override
  Future<void> refreshIfStale() async {}
}

class _Sync extends SyncController {
  @override
  SyncStatus build() => const SyncStatus(loaded: true);
}

class _Repo implements HomeRepository {
  _Repo(this.json);
  final Map<String, dynamic> json;
  @override
  Future<ApiResult<HomeDashboard>> dashboard() async =>
      ApiOk(HomeDashboard.fromJson(json, readAt: DateTime(2026, 11, 3, 9, 42)));
  @override
  Future<ApiResult<int>> unreadCount() async => const ApiOk(5);
  @override
  Future<ApiResult<BillingGlance>> billing() async =>
      const ApiOk(BillingGlance());
  @override
  Future<ApiResult<OutletList>> outlets() async =>
      const ApiOk(OutletList(outlets: []));
  @override
  Future<ApiResult<bool>> paymentsChosen() async => const ApiOk(false);
  @override
  Future<ApiResult<int>> teamCount() async => const ApiOk(0);
  @override
  Future<ApiResult<SearchResults>> search(String q, {required Who who}) async =>
      ApiOk(SearchResults(query: q));
  @override
  Future<OfflineHome?> offlineHome() async => null;
}

final _ownerJson = {
  'catalogue': {'total': 64, 'published': 52},
  'orders': {'total': 702},
  'home': {
    'hero': {
      'orders_to_confirm': 4,
      'atompay_to_hand_over': 2,
      'bulk_requests_waiting': 1,
      'seller_requests_waiting': 2,
    },
    'tasks': [
      {
        'key': 'confirm',
        'title': 'Confirm 4 new orders',
        'detail': '1 waiting longer than 4 hours',
        'button': 'Confirm',
        'tone': 't-rose',
        'deadline': 'Oldest 6 hours',
        'urgent': true,
      },
    ],
    'periods': {
      for (final p in ['today', 'month', 'year', 'all'])
        p: {
          'period': p,
          'cash_sales': 4644500,
          'orders': 55,
          'payments_received': 4129000,
          'still_due': 515500,
          'units_sold': 71,
          'live': 52,
          'catalogue_total': 64,
        },
    },
    'chart': {
      'months': [
        for (final m in ['Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov'])
          {'label': m, 'sales': 3000000, 'paid': 2800000},
      ],
    },
    'pipeline': [
      {'status': 'Pending', 'label': 'Pending', 'count': 4},
      {'status': 'Completed', 'label': 'Completed', 'count': 38},
    ],
    'bulk': {'new': 3, 'contacted': 4, 'quoted': 5, 'won': 7, 'lost': 2},
    'outlets': [
      {
        'id': 1,
        'name': 'Head office',
        'main': true,
        'status': 'open',
        'sales': 2846000,
        'orders': 32,
        'to_confirm': 2,
      },
    ],
    'top_products': [
      {'id': 5, 'title': 'Zenvo Inverter AC 1.5 ton', 'units': 21},
    ],
    'latest_orders': [
      {
        'uuid': 'u1',
        'id': 48219,
        'type': 'cash',
        'status': 'Pending',
        'status_label': 'Pending',
        'total': 149999,
        'product': {'id': 5, 'title': 'Zenvo Inverter AC'},
        'city': 'Lahore',
        'created_at': '2026-11-03 09:12:00',
      },
    ],
    'activity': [
      {
        'id': 3,
        'type': 'brand_new_order',
        'title': 'New order received',
        'body': 'New order #48219',
        'screen': 'order',
        'data': {},
        'is_read': true,
        'created_at': '2026-11-03 09:12:00',
      },
    ],
    'plan': {
      'package': {'name': 'Basic package'},
      'paid_until': '2026-11-30',
      'addons': [],
    },
  },
};

Future<void> _pump(
  WidgetTester tester, {
  required BrandSession session,
  required Map<String, dynamic> json,
  AccessState access = const AccessState(addonStates: {}),
  Size size = const Size(390, 3000),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(() => _Session(session)),
        accessProvider.overrideWith(() => _Access(access)),
        syncStatusProvider.overrideWith(_Sync.new),
        onlineProvider.overrideWith((ref) => Stream.value(true)),
        offlineCopyProvider.overrideWithValue(null),
        homeRepositoryProvider.overrideWithValue(_Repo(json)),
        homeClockProvider.overrideWithValue(() => DateTime(2026, 11, 3, 9)),
      ],
      child: MaterialApp(
        theme: AtomTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

const _owner = BrandSession(
  token: 't',
  userId: 1,
  name: 'Asad Raza',
  who: Who.owner(),
  brandName: 'Zenvo Appliances',
  outlets: [
    Outlet(id: 1, name: 'Head office'),
    Outlet(id: 2, name: 'Karachi'),
  ],
);

void main() {
  testWidgets('the owner sees the full Home', (tester) async {
    await _pump(tester, session: _owner, json: _ownerJson);
    expect(find.text('Good morning, Asad'), findsOneWidget);
    expect(find.text('9 things need you today'), findsOneWidget);
    expect(find.text('All outlets'), findsOneWidget);
    expect(find.text('Confirm 4 new orders'), findsOneWidget);
    expect(find.text('Your sales on Atomshop'), findsOneWidget);
    expect(find.text('Order pipeline'), findsOneWidget);
    expect(find.text('Your outlets this month'), findsOneWidget);
    expect(find.text('Basic package'), findsOneWidget);
    // Ask Atom is off: no bar.
    expect(find.text(l.homeAskBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a wide tablet shows Home in two columns', (tester) async {
    await _pump(
      tester,
      session: _owner,
      json: _ownerJson,
      size: const Size(1280, 2000),
    );
    expect(find.text('Good morning, Asad'), findsOneWidget);
    expect(find.text('9 things need you today'), findsOneWidget);
    expect(find.text('Confirm 4 new orders'), findsOneWidget);
    expect(find.text('Your sales on Atomshop'), findsOneWidget);
    // Needs your attention sits beside the hero, not under it.
    final hero = tester.getTopLeft(find.text('9 things need you today'));
    final tasks = tester.getTopLeft(find.text('Confirm 4 new orders'));
    expect(tasks.dx, greaterThan(hero.dx + 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('with Ask Atom on, the bar shows', (tester) async {
    await _pump(
      tester,
      session: _owner,
      json: _ownerJson,
      access: const AccessState(
        addonStates: {Addon.askAtom: AddonState.active},
      ),
    );
    expect(find.text(l.homeAskBar), findsOneWidget);
  });

  testWidgets('a team member without totals sees their part only', (
    tester,
  ) async {
    await _pump(
      tester,
      session: const BrandSession(
        token: 't',
        userId: 2,
        name: 'Usman Ali',
        brandName: 'Zenvo Appliances',
        outletName: 'Karachi outlet',
        who: Who(
          isOwner: false,
          roleName: 'Order handler',
          permissions: {'orders.view', 'orders.status'},
        ),
      ),
      json: {
        'home': {
          'hero': {'orders_to_confirm': 2},
          'tasks': [],
          'latest_orders': [],
        },
      },
    );
    expect(find.text('Salam, Usman'), findsOneWidget);
    expect(find.text('new orders to confirm'), findsOneWidget);
    expect(find.text('Your sales on Atomshop'), findsNothing);
    expect(
      find.textContaining('Business totals and reports are for your brand'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a member in every outlet sees All outlets and Confirm orders', (
    tester,
  ) async {
    await _pump(
      tester,
      session: const BrandSession(
        token: 't',
        userId: 2,
        name: 'Hamza Saeed',
        brandName: 'Zenvo Appliances',
        outlets: [
          Outlet(id: 1, name: 'Lahore · Gulberg'),
          Outlet(id: 2, name: 'Karachi · Tariq Road'),
        ],
        who: Who(
          isOwner: false,
          roleName: 'Order handler',
          permissions: {'orders.view', 'orders.status', 'atompay.view'},
        ),
      ),
      json: {
        'home': {
          'hero': {'orders_to_confirm': 3, 'atompay_to_hand_over': 0},
          'tasks': [],
          'latest_orders': [],
        },
      },
    );
    // 5.2: the outlet over "Brand · Role", and in the hero's corner.
    expect(find.text('All outlets'), findsNWidgets(2));
    expect(find.text('Zenvo Appliances · Order handler'), findsOneWidget);
    expect(find.text(l.homeConfirmOrders), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home fits 320dp at 200% text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(
      tester,
      session: _owner,
      json: _ownerJson,
      size: const Size(320, 6000),
    );
    expect(find.text('Confirm 4 new orders'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a new brand sees its first steps', (tester) async {
    await _pump(
      tester,
      session: _owner,
      json: {
        'catalogue': {'total': 0, 'published': 0},
        'orders': {'total': 0},
        'home': {'hero': {}},
      },
    );
    expect(find.text("Let's get your brand selling"), findsOneWidget);
    expect(find.text('Add your products'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick actions draw for the owner', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => _Session(_owner)),
          accessProvider.overrideWith(
            () => _Access(const AccessState(addonStates: {})),
          ),
        ],
        child: MaterialApp(
          theme: AtomTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: QuickActionsSheet()),
        ),
      ),
    );
    expect(find.text('Add product'), findsOneWidget);
    expect(find.text('Stock in'), findsNothing);
    expect(find.text('Ask Atom'), findsNothing);
  });
}
