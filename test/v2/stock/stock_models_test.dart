import 'package:atombrand_app/v2/features/stock/data/stock_copy.dart';
import 'package:atombrand_app/v2/features/stock/data/stock_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GET stock reads items, totals, warehouses, holds and access', () {
    final o = StockOverview.fromJson({
      'items': [
        {
          'id': 3,
          'title': 'Zenvo TV',
          'tracking': 'imei',
          'pr_number': 'PR-10388',
          'variants': [
            {
              'id': 11,
              'name': '55" Black',
              'price': '189999',
              'on_hand': 5,
              'held': 2,
              'available': 3,
              'state': 'low',
              'by_warehouse': [
                {'warehouse_id': 1, 'on_hand': 5, 'reserved': 2},
              ],
              'on_website': true,
            },
          ],
        },
      ],
      'pagination': {'current_page': 1, 'last_page': 2, 'total': 21},
      'access': {
        'state': 'trial',
        'read_only': false,
        'days_left': 9,
        'can_change': true,
      },
      'totals': {
        'units': 186,
        'held': 9,
        'live': 18,
        'listed': 20,
        'low': 4,
        'out': 2,
        'variants': 30,
        'by_outlet': [
          {'name': 'Lahore', 'units': 150},
        ],
      },
      'warehouses': [
        {
          'id': 1,
          'name': 'Factory store',
          'outlet_id': 4,
          'outlet': 'Head office',
          'sells_online': 1,
          'is_default': true,
        },
      ],
      'held': [
        {
          'id': 1,
          'for': 'bulk_deal',
          'order_id': 117,
          'product': 'Zenvo AC',
          'qty': 15,
          'since': '2026-11-01 10:00:00',
        },
      ],
    });
    expect(o.hasMore, isTrue);
    expect(o.total, 21);
    expect(o.access.trial, isTrue);
    expect(o.access.changes, isTrue);
    expect(o.totals.available, 177);
    expect(o.totals.byOutlet.single.units, 150);
    final v = o.items.single.variants.single;
    expect(o.items.single.tracking, Tracking.imei);
    expect(v.price, 189999);
    expect(v.byWarehouse.single.reserved, 2);
    expect(o.warehouses.single.sellsOnline, isTrue);
    expect(o.held.single.forDeal, isTrue);
    expect(o.held.single.since, DateTime(2026, 11, 1, 10));
  });

  test('a lapsed add-on is read only, whatever the role', () {
    final a = StockAccess.fromJson({
      'state': 'lapsed',
      'read_only': true,
      'can_change': true,
      'can_manage': true,
    });
    expect(a.changes, isFalse);
    expect(a.manages, isFalse);
  });

  test('form options fall back to the server reasons when missing', () {
    final f = StockFormOptions.fromJson({
      'variants': [
        {
          'id': 1,
          'product_id': 2,
          'product': 'AC',
          'variant': 'Standard',
          'tracking': 'auto',
          'next_auto_number': 'ZN-0001',
        },
      ],
      'in_stock_units': [
        {'id': 4, 'serial': 'S1', 'variant_id': 1, 'warehouse_id': 3},
      ],
    });
    expect(f.variants.single.title, 'AC');
    expect(f.variants.single.tracking, Tracking.auto);
    expect(f.outReasons, contains('Lost or stolen'));
    expect(f.inReasons, ['Recount', 'Found', 'Other']);
    expect(f.maxStockIn, 200);
  });

  group('the phone copy', () {
    final tables = <String, List<Map<String, dynamic>>>{
      'warehouses': [
        {
          'id': 1,
          'name': 'Factory store',
          'brand_outlet_id': 4,
          'status': 'active',
          'in_scope': true,
          'sells_online': true,
        },
        {
          'id': 2,
          'name': 'Karachi godown',
          'brand_outlet_id': 5,
          'status': 'active',
          'in_scope': false,
        },
      ],
      'stock_products': [
        {
          'id': 10,
          'title': 'Zenvo TV',
          'tracking': 'serial',
          'status': 'active',
          'product_id': 77,
        },
        {
          'id': 11,
          'title': 'Zenvo AC',
          'tracking': 'auto',
          'auto_prefix': 'ZAC',
          'status': 'active',
        },
      ],
      'stock_variants': [
        {
          'id': 100,
          'seller_product_id': 10,
          'name': 'Black',
          'sku': 'TV-BK',
          'low_stock_at': 3,
          'status': 'active',
        },
        {
          'id': 101,
          'seller_product_id': 11,
          'name': 'White',
          'sku': 'AC-WH',
          'low_stock_at': 3,
          'status': 'active',
        },
      ],
      'stock_balances': [
        {
          'id': 1,
          'variant_id': 100,
          'warehouse_id': 1,
          'on_hand': 6,
          'reserved': 1,
        },
        {
          'id': 2,
          'variant_id': 101,
          'warehouse_id': 1,
          'on_hand': 2,
          'reserved': 0,
        },
        // another outlet's warehouse: not this person's stock
        {
          'id': 3,
          'variant_id': 101,
          'warehouse_id': 2,
          'on_hand': 50,
          'reserved': 0,
        },
      ],
      'stock_units': [
        {
          'id': 1,
          'variant_id': 100,
          'warehouse_id': 1,
          'serial': 'TV-1',
          'status': 'in_stock',
        },
        {
          'id': 2,
          'variant_id': 100,
          'warehouse_id': 1,
          'serial': 'TV-2',
          'status': 'sold',
        },
        {
          'id': 3,
          'variant_id': 101,
          'warehouse_id': 2,
          'serial': 'AC-9',
          'status': 'in_stock',
        },
      ],
      'stock_holds': [
        {
          'id': 1,
          'variant_id': 100,
          'warehouse_id': 1,
          'for': 'order',
          'order_id': 9,
          'qty': 1,
          'status': 'active',
        },
      ],
    };
    final copy = StockCopy(
      (t) async => tables[t] ?? const [],
      outletNames: {4: 'Head office'},
    );

    test('counts stock in this person\'s warehouses only', () async {
      final o = await copy.overview();
      expect(o.fromCopy, isTrue);
      expect(o.totals.units, 8);
      expect(o.totals.held, 1);
      expect(o.totals.low, 1); // the AC: 2 left, warn at 3
      expect(o.items.map((p) => p.title), ['Zenvo AC', 'Zenvo TV']);
      expect(o.warehouses.single.outlet, 'Head office');
      expect(o.held.single.product, 'Zenvo TV');
    });

    test('filters by level and search', () async {
      expect((await copy.overview(show: 'low')).items.single.title, 'Zenvo AC');
      expect(
        (await copy.overview(query: 'tv-bk')).items.single.title,
        'Zenvo TV',
      );
    });

    test('form options: moves may go to any warehouse', () async {
      final f = await copy.formOptions();
      expect(f.warehouses.map((w) => w.id), [1]);
      expect(f.allWarehouses.map((w) => w.id), [1, 2]);
      expect(f.inStockUnits.map((u) => u.serial), ['TV-1']);
      expect(f.variants.firstWhere((v) => v.id == 101).tracking, Tracking.auto);
    });

    test('a product with its units', () async {
      final p = await copy.product(10);
      expect(p!.variants.single.available, 5);
      expect(p.units.map((u) => (u.serial, u.status)), [
        ('TV-1', 'in_stock'),
        ('TV-2', 'delivered'),
      ]);
      expect(await copy.product(999), isNull);
    });
  });
}
