import 'dart:io';

import 'package:atombrand_app/v2/core/db/outbox_actions.dart';
import 'package:flutter_test/flutter_test.dart';

/// The builders hold the brand server's own field names
/// (docs/brand-app-sync.md §6.2), so these pin them down.
void main() {
  group('action keys', () {
    test('are the server\'s, and none is online only', () {
      expect(SyncActionKeys.all, {
        'order.status',
        'order.cancel',
        'order.payment',
        'atompay.handover',
        'deal.deliver',
        'deal.payment',
        'bulk.status',
        'stock.in',
        'stock.adjust',
        'stock.transfer',
      });
      expect(
        SyncActionKeys.all.intersection(SyncActionKeys.onlineOnly),
        isEmpty,
      );
    });
  });

  group('order.status', () {
    test('Delivered carries who received it, the serial, cash and photo', () {
      final photo = File('proof.jpg');
      final a = OfflineAction.orderStatus(
        orderUuid: 'u-1',
        status: OrderSteps.delivered,
        seenStatus: 'Processing',
        receivedBy: ' Hamid ',
        serial: 'SN-1',
        codAmount: 149999,
        codMethod: 'cash',
        deliveredPhoto: photo,
      );
      expect(a.action, 'order.status');
      expect(a.data, {
        'order_uuid': 'u-1',
        'status': 'Delivered',
        'received_by': 'Hamid',
        'serial': 'SN-1',
        'cod_amount': 149999,
        'cod_method': 'cash',
      });
      expect(a.seen, {'status': 'Processing'});
      expect(a.files, {'delivered_photo': photo});
      expect(a.serials, ['SN-1']);
    });

    test('a step leaves out the delivery fields', () {
      final a = OfflineAction.orderStatus(
        orderUuid: 'u-1',
        status: OrderSteps.processing,
        seenStatus: 'Varification',
        receivedBy: 'ignored',
      );
      expect(a.data, {'order_uuid': 'u-1', 'status': 'Processing'});
      expect(a.files, isEmpty);
    });

    test('refuses what the server would refuse', () {
      expect(
        () => OfflineAction.orderStatus(
          orderUuid: 'u-1',
          status: 'Shipped',
          seenStatus: 'Pending',
        ),
        throwsArgumentError,
      );
      expect(
        () => OfflineAction.orderStatus(
          orderUuid: 'u-1',
          status: OrderSteps.delivered,
          seenStatus: 'Processing',
        ),
        throwsArgumentError,
        reason: 'Delivered needs received_by',
      );
      expect(
        () => OfflineAction.orderStatus(
          orderUuid: 'u-1',
          status: OrderSteps.processing,
          seenStatus: '',
        ),
        throwsArgumentError,
        reason: 'seen.status is required',
      );
    });
  });

  test('order.cancel needs reasons or a reason', () {
    final a = OfflineAction.orderCancel(
      orderUuid: 'u-1',
      seenStatus: 'Pending',
      reasons: ['out_of_stock'],
    );
    expect(a.action, 'order.cancel');
    expect(a.data, {
      'order_uuid': 'u-1',
      'reasons': ['out_of_stock'],
    });
    expect(
      () => OfflineAction.orderCancel(orderUuid: 'u-1', seenStatus: 'Pending'),
      throwsArgumentError,
    );
  });

  test('order.payment sends the day, and seen.paid only when known', () {
    final a = OfflineAction.orderPayment(
      orderUuid: 'u-1',
      amount: 5000,
      method: 'cash',
      paidOn: DateTime(2026, 11, 4, 23, 30),
      seenPaid: 10000,
    );
    expect(a.data, {
      'order_uuid': 'u-1',
      'amount': 5000,
      'method': 'cash',
      'paid_on': '2026-11-04',
    });
    expect(a.seen, {'paid': 10000});
    expect(
      OfflineAction.orderPayment(
        orderUuid: 'u',
        amount: 1,
        method: 'cash',
      ).seen,
      isEmpty,
    );
    expect(
      () =>
          OfflineAction.orderPayment(orderUuid: 'u', amount: 0, method: 'cash'),
      throwsArgumentError,
    );
  });

  test('atompay.handover defaults seen.step to handover', () {
    final a = OfflineAction.atompayHandover(
      orderUuid: 'u-2',
      receivedBy: 'Bilal',
      serial: 'IMEI-9',
    );
    expect(a.action, 'atompay.handover');
    expect(a.seen, {'step': 'handover'});
    expect(a.data['serial'], 'IMEI-9');
  });

  test('deal.deliver keys items by deal item id and drops empty lines', () {
    final a = OfflineAction.dealDeliver(
      dealId: 27,
      items: {
        101: (qty: 2, serials: ['A', ' B ']),
        102: (qty: 0, serials: const []),
        103: (qty: 5, serials: const []),
      },
      receivedBy: 'Store keeper',
      deliveredOn: DateTime(2026, 11, 14),
    );
    expect(a.data, {
      'deal_id': 27,
      'items': {
        '101': {
          'qty': 2,
          'serials': ['A', 'B'],
        },
        '103': {'qty': 5},
      },
      'received_by': 'Store keeper',
      'delivered_on': '2026-11-14',
    });
    expect(a.serials, ['A', 'B']);
    expect(
      () => OfflineAction.dealDeliver(
        dealId: 1,
        items: {1: (qty: 0, serials: const [])},
        receivedBy: 'x',
      ),
      throwsArgumentError,
    );
  });

  test('deal.payment and bulk.status', () {
    expect(
      OfflineAction.dealPayment(
        dealId: 3,
        amount: 100,
        method: 'bank',
        seenPaid: 0,
      ).data,
      {'deal_id': 3, 'amount': 100, 'method': 'bank'},
    );
    final lost = OfflineAction.bulkStatus(
      requestId: 9,
      status: BulkSteps.lost,
      reason: 'Price',
      seenStatus: 'Contacted',
    );
    expect(lost.data, {'request_id': 9, 'status': 'Lost', 'reason': 'Price'});
    expect(lost.seen, {'status': 'Contacted'});
    expect(
      () => OfflineAction.bulkStatus(requestId: 9, status: BulkSteps.lost),
      throwsArgumentError,
    );
    expect(
      () => OfflineAction.bulkStatus(requestId: 9, status: 'Won'),
      throwsArgumentError,
      reason: 'Won comes from deals, online only',
    );
  });

  group('stock', () {
    test('stock.in: one serial per unit, none for auto numbers', () {
      final a = OfflineAction.stockIn(
        variantId: 5,
        warehouseId: 2,
        qty: 2,
        serials: ['S1', 'S2'],
        movedOn: DateTime(2026, 11, 1),
      );
      expect(a.action, 'stock.in');
      expect(a.data, {
        'variant_id': 5,
        'warehouse_id': 2,
        'qty': 2,
        'serials': ['S1', 'S2'],
        'moved_on': '2026-11-01',
      });
      expect(OfflineAction.stockIn(variantId: 5, warehouseId: 2, qty: 3).data, {
        'variant_id': 5,
        'warehouse_id': 2,
        'qty': 3,
      });
      expect(
        () => OfflineAction.stockIn(
          variantId: 5,
          warehouseId: 2,
          qty: 3,
          serials: ['S1'],
        ),
        throwsArgumentError,
      );
    });

    test('stock.adjust out names the unit by id or by serial', () {
      expect(
        OfflineAction.stockAdjustOut(
          unitId: 77,
          reason: 'damaged',
          note: 'Dropped',
        ).data,
        {
          'direction': 'out',
          'unit_id': 77,
          'reason': 'damaged',
          'note': 'Dropped',
        },
      );
      expect(
        OfflineAction.stockAdjustOut(
          serial: 'S9',
          reason: 'lost',
          note: '',
        ).data['serial'],
        'S9',
      );
      expect(
        () => OfflineAction.stockAdjustOut(reason: 'lost', note: ''),
        throwsArgumentError,
      );
    });

    test('stock.adjust in and stock.transfer', () {
      final adjust = OfflineAction.stockAdjustIn(
        variantId: 5,
        warehouseId: 2,
        reason: 'found',
        note: 'Back from repair',
      );
      expect(adjust.action, 'stock.adjust');
      expect(adjust.data['direction'], 'in');
      final move = OfflineAction.stockTransfer(
        unitIds: [1, 2],
        serials: ['S3'],
        toWarehouseId: 4,
      );
      expect(move.action, 'stock.transfer');
      expect(move.data, {
        'unit_ids': [1, 2],
        'serials': ['S3'],
        'to_warehouse_id': 4,
      });
      expect(
        () => OfflineAction.stockTransfer(toWarehouseId: 4),
        throwsArgumentError,
      );
    });
  });

  test('serialsOf reads a list or one per line', () {
    expect(OfflineAction.serialsOf('stock.in', {'serials': 'A\n B \n\nC'}), [
      'A',
      'B',
      'C',
    ]);
    expect(OfflineAction.serialsOf('order.payment', {'amount': 1}), isEmpty);
  });

  test('reasons: retry, conflicts', () {
    expect(SyncReasons.retry, {'server_error', 'busy'});
    expect(SyncReasons.conflicts, {'seen_changed', 'serial_clash'});
  });
}
