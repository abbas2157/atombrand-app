// The fields the brand server added on 14 Nov: the orders `counts` and
// filters, the products `sort`, bulk `status=all` counts, a unit by serial
// (`stock/units`), held orders' `order_uuid`, archived warehouses kept out
// of pickers, and the outlet form's own options.

import 'package:atombrand_app/v2/features/bulk/data/bulk_models.dart';
import 'package:atombrand_app/v2/features/catalogue/data/catalogue_logic.dart';
import 'package:atombrand_app/v2/features/catalogue/data/catalogue_models.dart';
import 'package:atombrand_app/v2/features/orders/data/orders_models.dart';
import 'package:atombrand_app/v2/features/outlets/data/outlet_models.dart';
import 'package:atombrand_app/v2/features/stock/data/stock_models.dart';
import 'package:atombrand_app/v2/features/stock/data/stock_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('orders', () {
    test('the filters go to the server, the status apart', () {
      final q = (
        status: 'Delivered',
        q: ' zenvo ',
        outletId: 4,
        payment: 'unpaid',
        from: DateTime(2026, 11, 1),
        to: DateTime(2026, 11, 14),
      );
      expect(ordersFilters(q), {
        'type': 'retail',
        'cash': 1,
        'q': 'zenvo',
        'outlet_id': 4,
        'payment': 'unpaid',
        'from': '2026-11-01',
        'to': '2026-11-14',
      });
      expect(anyStatus(q).status, isNull);
      expect(anyStatus(q).payment, 'unpaid');
    });

    test('counts read the server list, with Varification kept as the key', () {
      expect(
        orderCountsOf([
          {'status': 'Pending', 'label': 'Pending', 'count': 3},
          {'status': 'Varification', 'label': 'Confirming', 'count': '2'},
        ]),
        {'Pending': 3, 'Varification': 2},
      );
      expect(orderCountsOf(null), isNull);
    });
  });

  test(
    'product sorts the server knows go as sort; oldest stays on the phone',
    () {
      expect(ProductSort.newest.serverKey, 'newest');
      expect(ProductSort.priceLow.serverKey, 'price_asc');
      expect(ProductSort.priceHigh.serverKey, 'price_desc');
      expect(ProductSort.name.serverKey, 'name');
      expect(ProductSort.oldest.serverKey, isNull);
    },
  );

  test('available.stock_product_id links a product to its stock', () {
    final a = Availability.fromJson({
      'units': 4,
      'warehouses': 2,
      'level': 'low',
      'stock_product_id': '31',
    });
    expect(a?.stockProductId, 31);
  });

  test('bulk: all_count, else the sum of the counts', () {
    final page = BulkRequestsPage.fromJson({
      'items': [],
      'pagination': {'current_page': 1, 'last_page': 1, 'total': 0},
      'counts': {'New Lead': 3, 'Contacted': 1},
      'all_count': 9,
    });
    expect(page.all, 9);
    final old = BulkRequestsPage.fromJson({
      'items': [],
      'counts': {'New Lead': 3, 'Contacted': 1},
    });
    expect(old.all, 4);
  });

  group('a unit by serial', () {
    SerialUnits answer(Map<String, dynamic> unit, {bool exact = true}) =>
        SerialUnits.fromJson({
          'exact': exact,
          'units': [unit],
        });

    test('in stock, held for an order that can be opened', () {
      final found = lookUnitFromServer(
        'imei-2',
        answer({
          'id': 7,
          'serial': 'IMEI-1',
          'serial_2': 'IMEI-2',
          'status': 'in_stock',
          'product_id': 12,
          'product': 'Zenvo X1',
          'variant_id': 3,
          'variant': '128GB',
          'warehouse_id': 2,
          'warehouse': 'Factory store',
          'came_in': '2026-11-02',
          'held_for': {'for': 'order', 'order_id': 501, 'order_uuid': 'u-501'},
        }),
      )!;
      expect(found.found, UnitFound.inStock);
      expect(found.unit?.id, 7);
      expect(found.unit?.warehouse, 'Factory store');
      expect(found.productId, 12);
      expect(found.cameIn?.date, DateTime(2026, 11, 2));
      expect(found.heldFor?.orderUuid, 'u-501');
    });

    test('delivered, with the deal it went to', () {
      final found = lookUnitFromServer(
        'S1',
        answer({
          'id': 8,
          'serial': 'S1',
          'status': 'delivered',
          'delivered_on': '2026-11-10',
          'delivered_for': {'type': 'bulk_deal', 'id': 44},
        }),
      )!;
      expect(found.found, UnitFound.delivered);
      expect(found.last?.refType, 'bulk_deal');
      expect(found.last?.refId, 44);
    });

    test('partial matches and unknown states fall back to the old way', () {
      expect(
        lookUnitFromServer(
          'S1',
          answer({
            'id': 8,
            'serial': 'S12',
            'status': 'in_stock',
          }, exact: false),
        ),
        isNull,
      );
      expect(
        lookUnitFromServer(
          'S1',
          answer({'id': 8, 'serial': 'S1', 'status': 'x'}),
        ),
        isNull,
      );
    });
  });

  test('held rows carry the order uuid', () {
    final h = StockHold.fromJson({
      'id': 1,
      'for': 'order',
      'order_id': 501,
      'order_uuid': 'u-501',
    });
    expect(h.orderUuid, 'u-501');
    expect(h.forDeal, isFalse);
  });

  test('archived warehouses are never offered in the stock forms', () {
    final o = StockFormOptions.fromJson({
      'warehouses': [
        {'id': 1, 'name': 'Store', 'status': 'active'},
        {'id': 2, 'name': 'Old godown', 'status': 'archived'},
      ],
      'all_warehouses': [
        {'id': 2, 'name': 'Old godown', 'status': 'archived'},
        {'id': 3, 'name': 'Karachi', 'status': 'active'},
      ],
    });
    expect([for (final w in o.warehouses) w.id], [1]);
    expect([for (final w in o.allWarehouses) w.id], [3]);
  });

  test('outlet form options: cities, the ones taken, who can run it', () {
    final o = OutletFormOptions.fromJson({
      'cities': [
        {'id': 1, 'title': 'Lahore', 'taken_by': null},
        {
          'id': 2,
          'title': 'Karachi',
          'taken_by': {'id': 5, 'name': 'Karachi outlet'},
        },
      ],
      'managers': [
        {'id': 9, 'user_id': 40, 'name': 'Bilal', 'role': 'Outlet manager'},
      ],
      'current_manager_id': 9,
    });
    expect(o.cities.map((c) => c.title), ['Lahore', 'Karachi']);
    expect(o.taken, {2: 'Karachi outlet'});
    expect(o.managers.single.name, 'Bilal');
    expect(o.currentManagerId, 9);
  });
}
