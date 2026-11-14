import 'package:atombrand_app/l10n/app_localizations.dart';
import 'package:atombrand_app/v2/core/access/access.dart';
import 'package:atombrand_app/v2/core/access/access_controller.dart';
import 'package:atombrand_app/v2/core/api/api_page.dart';
import 'package:atombrand_app/v2/core/session/session.dart';
import 'package:atombrand_app/v2/core/session/session_controller.dart';
import 'package:atombrand_app/v2/features/stock/data/stock_models.dart';
import 'package:atombrand_app/v2/features/stock/data/stock_repository.dart';
import 'package:atombrand_app/v2/features/stock/ui/inventory_home_screen.dart';
import 'package:atombrand_app/v2/features/stock/ui/product_stock_screen.dart';
import 'package:atombrand_app/v2/features/stock/ui/stock_adjust_screen.dart';
import 'package:atombrand_app/v2/features/stock/ui/stock_history_screen.dart';
import 'package:atombrand_app/v2/features/stock/ui/stock_in_screen.dart';
import 'package:atombrand_app/v2/features/stock/ui/stock_list_screen.dart';
import 'package:atombrand_app/v2/features/stock/ui/stock_transfer_screen.dart';
import 'package:atombrand_app/v2/features/stock/ui/warehouses_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Session extends SessionController {
  _Session(this.who);
  final Who who;

  @override
  SessionState build() => SignedIn(
    BrandSession(token: 't', userId: 1, name: 'Usman', who: who, brandName: 'Zenvo'),
  );
}

class _Access extends AccessController {
  @override
  AccessState build() => const AccessState(
    addonStates: {Addon.inventory: AddonState.active},
  );
}

Map<String, dynamic> _overview({bool readOnly = false, bool trial = false}) => {
  'items': [
    {
      'id': 3,
      'title': 'Zenvo 55" 4K Smart TV',
      'pr_number': 'PR-10388',
      'variants': [
        {
          'id': 11, 'name': 'Black', 'on_hand': 7, 'held': 2, 'available': 5, 'state': 'in',
          'by_warehouse': [{'warehouse_id': 1, 'on_hand': 7, 'reserved': 2}],
          'on_website': true,
        },
      ],
    },
    {
      'id': 4,
      'title': 'Zenvo Refrigerator 14 cft',
      'variants': [
        {'id': 12, 'name': 'Graphite', 'on_hand': 0, 'available': 0, 'state': 'out'},
      ],
    },
  ],
  'pagination': {'current_page': 1, 'last_page': 1, 'total': 2},
  'access': {
    'state': trial ? 'trial' : (readOnly ? 'lapsed' : 'active'),
    'read_only': readOnly,
    'days_left': 9,
    'can_change': true,
    'can_manage': true,
  },
  'totals': {'units': 186, 'held': 9, 'live': 18, 'listed': 20, 'low': 4, 'out': 2, 'variants': 30},
  'warehouses': [
    {'id': 1, 'name': 'Factory store', 'outlet': 'Head office', 'sells_online': true, 'is_default': true},
  ],
  'held': [
    {'id': 1, 'for': 'bulk_deal', 'order_id': 117, 'product': 'Zenvo AC', 'qty': 15, 'warehouse': 'Factory store'},
  ],
};

final _options = StockFormOptions.fromJson({
  'access': {'state': 'active', 'can_change': true},
  'variants': [
    {'id': 11, 'product_id': 3, 'product': 'Zenvo 55" 4K Smart TV', 'variant': 'Black', 'tracking': 'serial'},
  ],
  'warehouses': [
    {'id': 1, 'name': 'Factory store', 'outlet': 'Head office', 'is_default': true},
    {'id': 2, 'name': 'Karachi godown', 'outlet': 'Karachi'},
  ],
  'all_warehouses': [
    {'id': 1, 'name': 'Factory store'},
    {'id': 2, 'name': 'Karachi godown'},
  ],
  'in_stock_units': [
    {'id': 5, 'serial': 'ZNV55K-240918', 'variant_id': 11, 'product': 'Zenvo 55" 4K Smart TV', 'variant': 'Black', 'warehouse_id': 1, 'warehouse': 'Factory store'},
  ],
});

final _product = ProductStock.fromJson({
  'access': {'state': 'active', 'can_change': true},
  'product': {
    'id': 3, 'title': 'Zenvo 55" 4K Smart TV', 'tracking': 'serial', 'pr_number': 'PR-10388',
    'website_status': 'Published', 'can_change_tracking': true,
  },
  'variants': [
    {'id': 11, 'name': 'Black', 'price': 189999, 'on_hand': 7, 'held': 2, 'available': 5, 'state': 'in',
     'by_warehouse': [{'warehouse_id': 1, 'on_hand': 7, 'reserved': 2}]},
  ],
  'warehouses': [
    {'id': 1, 'name': 'Factory store', 'outlet': 'Head office', 'sells_online': true, 'on_hand': 7, 'held': 2, 'available': 5},
  ],
  'units': [
    {'id': 5, 'serial': 'ZNV55K-240918', 'variant': 'Black', 'status': 'in_stock', 'warehouse': 'Factory store', 'came_in': '2026-10-02'},
    {'id': 6, 'serial': 'ZNV55K-240877', 'variant': 'Black', 'status': 'delivered', 'delivered_on': '2026-11-01', 'delivered_for': {'type': 'order', 'id': 20388}},
  ],
  'recent': [
    {'id': 1, 'type': 'stock_in', 'qty': 6, 'date': '2026-11-02', 'variant': 'Black', 'warehouse': 'Factory store', 'by': 'Usman Ali'},
  ],
  'delivered_90_days': 23,
});

final _book = WarehouseBook.fromJson({
  'access': {'state': 'active', 'can_change': true, 'can_manage': true},
  'outlets': [
    {'id': 4, 'name': 'Head office', 'is_main': true},
  ],
  'in_charge_choices': [
    {'id': 1, 'name': 'Usman Ali'},
  ],
  'warehouses': [
    {'id': 1, 'name': 'Factory store', 'type': 'factory', 'outlet_id': 4, 'sells_online': true, 'is_default': true,
     'units': 142, 'in_charge': {'id': 1, 'name': 'Usman Ali'}},
  ],
});

final _history = ApiPage.fromJson({
  'items': [
    {'id': 1, 'type': 'stock_in', 'qty': 3, 'date': DateTime.now().toIso8601String().substring(0, 10),
     'product': 'Zenvo 55" 4K Smart TV', 'variant': 'Black', 'warehouse': 'Factory store', 'why': 'Stock in SI-0412', 'by': 'Usman Ali'},
  ],
  'pagination': {'current_page': 1, 'last_page': 1},
}, StockMove.fromJson);

Widget _app(Widget home, {Who who = const Who.owner(), bool readOnly = false, bool trial = false}) =>
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(() => _Session(who)),
        accessProvider.overrideWith(_Access.new),
        stockOverviewProvider.overrideWith(
          (ref, q) async => StockOverview.fromJson(_overview(readOnly: readOnly, trial: trial)),
        ),
        stockFormOptionsProvider.overrideWith((ref) async => _options),
        productStockProvider.overrideWith((ref, id) async => _product),
        warehouseBookProvider.overrideWith((ref) async => _book),
        stockHistoryProvider.overrideWith((ref, q) async => _history),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

void main() {
  testWidgets('Stock home: figures, actions, out alert, rows and held', (t) async {
    await t.pumpWidget(_app(const InventoryHomeScreen()));
    await t.pumpAndSettle();
    expect(find.text('Available to sell'), findsOneWidget);
    expect(find.text('177'), findsOneWidget);
    expect(find.text('18 of 20'), findsOneWidget);
    expect(find.text('Stock in'), findsWidgets);
    expect(find.text('2 variants are out of stock'), findsOneWidget);
    expect(find.text('Zenvo 55" 4K Smart TV'), findsOneWidget);
    expect(find.text('2 held'), findsOneWidget);

    await t.tap(find.text('Held · 1'));
    await t.pumpAndSettle();
    expect(find.text('15 × Zenvo AC'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('a member without stock.change sees History only', (t) async {
    await t.pumpWidget(_app(
      const InventoryHomeScreen(),
      who: const Who(isOwner: false, roleKey: 'viewer', permissions: {'stock.view'}),
    ));
    await t.pumpAndSettle();
    expect(find.text('Move'), findsNothing);
    expect(find.text('History'), findsOneWidget);
  });

  testWidgets('read only: the notice shows, actions are off', (t) async {
    await t.pumpWidget(_app(const InventoryHomeScreen(), readOnly: true));
    await t.pumpAndSettle();
    expect(find.textContaining('Inventory has ended', findRichText: true), findsOneWidget);
    final move = t.widget<Opacity>(
      find.ancestor(of: find.text('Move'), matching: find.byType(Opacity)).first,
    );
    expect(move.opacity, lessThan(1));
  });

  testWidgets('trial notice', (t) async {
    await t.pumpWidget(_app(const InventoryHomeScreen(), trial: true));
    await t.pumpAndSettle();
    expect(find.textContaining('Inventory free trial: 9 days left.', findRichText: true), findsOneWidget);
  });

  testWidgets('list, product, history and warehouses render', (t) async {
    await t.pumpWidget(_app(const StockListScreen()));
    await t.pumpAndSettle();
    expect(find.text('Zenvo 55" 4K Smart TV · Black'), findsOneWidget);
    expect(find.text('On atomshop.pk'), findsOneWidget);

    await t.pumpWidget(_app(const ProductStockScreen(productId: 3)));
    await t.pumpAndSettle();
    expect(find.text('Delivered in 90 days'), findsOneWidget);
    await t.scrollUntilVisible(find.text('ZNV55K-240918'), 300);
    expect(find.text('ZNV55K-240918'), findsOneWidget);
    await t.scrollUntilVisible(find.text('How units are numbered'), 300);
    expect(find.text('Save numbering'), findsOneWidget);

    await t.pumpWidget(_app(const StockHistoryScreen()));
    await t.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('+3'), findsOneWidget);

    await t.pumpWidget(_app(const WarehousesScreen()));
    await t.pumpAndSettle();
    expect(find.text('Factory store'), findsWidgets);
    expect(find.text('142 units · in charge: Usman Ali'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('stock in counts good serials and flags ones in stock', (t) async {
    await t.pumpWidget(_app(const StockInScreen(productId: 3)));
    await t.pumpAndSettle();
    expect(find.text('Zenvo 55" 4K Smart TV · Black'), findsWidgets);
    final box = find.widgetWithText(TextField, 'One per line');
    await t.enterText(box, 'SN-1\nZNV55K-240918\nSN-2');
    await t.pumpAndSettle();
    expect(find.text('Already in stock'), findsOneWidget);
    expect(find.text('Serials · 3'), findsOneWidget);
  });

  testWidgets('move and adjust open on a scanned unit', (t) async {
    await t.pumpWidget(_app(const StockTransferScreen(serial: 'ZNV55K-240918')));
    await t.pumpAndSettle();
    expect(find.text('1 ticked'), findsOneWidget);
    expect(find.text('Move 1 unit to Karachi godown'), findsOneWidget);

    await t.pumpWidget(_app(const StockAdjustScreen(serial: 'ZNV55K-240918')));
    await t.pumpAndSettle();
    expect(find.text('ZNV55K-240918'), findsOneWidget);
    expect(find.text('Write a note: what happened?'), findsOneWidget);
  });
}
