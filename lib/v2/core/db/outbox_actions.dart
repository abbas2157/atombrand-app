import 'dart:io';

import 'package:flutter/foundation.dart';

/// The outbox actions the brand server replays (`POST sync`,
/// `docs/brand-app-sync.md` §6.2), and the reasons it gives back.
///
/// Feature screens never write an action key or a `data` map by hand: they
/// build an [OfflineAction] and hand it to
/// `OfflineSaves.saveAction(...)` (`features/sync/data/offline_saves.dart`).
/// The builders hold the server's field names, so a payment queued on a
/// phone in a basement reaches `POST orders/{uuid}/payment` with exactly
/// the fields the online call would have sent.
abstract final class SyncActionKeys {
  static const orderStatus = 'order.status';
  static const orderCancel = 'order.cancel';
  static const orderPayment = 'order.payment';
  static const atompayHandover = 'atompay.handover';
  static const dealDeliver = 'deal.deliver';
  static const dealPayment = 'deal.payment';
  static const bulkStatus = 'bulk.status';
  static const stockIn = 'stock.in';
  static const stockAdjust = 'stock.adjust';
  static const stockTransfer = 'stock.transfer';

  /// Every action the server takes from the outbox.
  static const all = {
    orderStatus,
    orderCancel,
    orderPayment,
    atompayHandover,
    dealDeliver,
    dealPayment,
    bulkStatus,
    stockIn,
    stockAdjust,
    stockTransfer,
  };

  /// Never saved offline (§6.4): call their endpoints while online.
  static const onlineOnly = {
    'bulk.quote',
    'bulk.won',
    'bulk.lost',
    'order.move',
    'product.save',
    'stock.warehouse',
    'stock.tracking',
    'team.change',
    'outlet.change',
    'settings.change',
    'billing.pay',
    'billing.addon',
    'ask_atom',
  };
}

/// Why the server did not apply an action (§6.1, `reason`).
abstract final class SyncReasons {
  /// The record changed since the person saw it. `server` says what it is
  /// now. Opens the conflict screen.
  static const seenChanged = 'seen_changed';

  /// A serial / IMEI in the action was taken meanwhile. `details.serials`
  /// names them. Opens the serial clash screen (10.4).
  static const serialClash = 'serial_clash';
  static const notFound = 'not_found';
  static const notAllowed = 'not_allowed';
  static const readOnly = 'read_only';
  static const addon = 'addon';
  static const refused = 'refused';
  static const needsInternet = 'needs_internet';
  static const unknownAction = 'unknown_action';
  static const badRequest = 'bad_request';
  static const serverError = 'server_error';
  static const busy = 'busy';

  /// The server will run it again when it is resent: the phone keeps it
  /// waiting rather than asking the person.
  static const retry = {serverError, busy};

  /// The server's record moved on: a conflict screen, not a plain refusal.
  static const conflicts = {seenChanged, serialClash};

  /// Sending the same action again can never work: Try again is hidden.
  static const noRetry = {badRequest, unknownAction, needsInternet};
}

/// The order steps `order.status` takes (`Varification` is the server's
/// own spelling, kept as it is).
abstract final class OrderSteps {
  static const verification = 'Varification';
  static const processing = 'Processing';
  static const delivered = 'Delivered';
  static const completed = 'Completed';
  static const cancelled = 'Cancelled';

  static const all = {
    verification,
    processing,
    delivered,
    completed,
    cancelled,
  };
}

/// The bulk request statuses a phone may set offline (`bulk.status`).
/// Quoted and Won come from quotes and deals, online only.
abstract final class BulkSteps {
  static const newLead = 'New Lead';
  static const contacted = 'Contacted';
  static const lost = 'Lost';

  static const all = {newLead, contacted, lost};
}

/// One line of a bulk deal delivery: how many of a deal item, and their
/// serials when the item is tracked.
typedef DealDeliverLine = ({int qty, List<String> serials});

/// One change saved on this phone, ready for the outbox.
///
/// [action] and [data] are exactly what `POST sync` takes; [seen] is what
/// the person had in front of them (§6.3), which the server checks before
/// it applies anything; [files] are the photos, by the server's field
/// name. Build one with the named constructors; they refuse a change the
/// server would refuse for a missing field, so the mistake shows on the
/// screen rather than days later in Needs attention.
@immutable
class OfflineAction {
  const OfflineAction._(
    this.action,
    this.data, {
    this.seen = const {},
    this.files = const {},
  });

  final String action;
  final Map<String, dynamic> data;
  final Map<String, dynamic> seen;
  final Map<String, File> files;

  /// An order moves one step (`POST orders/{uuid}/status`).
  ///
  /// [seenStatus] is the order's status as the copy shows it; the server
  /// refuses the step (`seen_changed`) when someone else moved it first.
  /// Delivered takes [receivedBy] and may take the [serial] of the unit
  /// that left stock, the cash collected and its method, and the proof
  /// photo. Cancelled takes [reasons] (keys of `cancel_reasons`) and/or a
  /// [reason]: prefer [OfflineAction.orderCancel].
  factory OfflineAction.orderStatus({
    required String orderUuid,
    required String status,
    required String seenStatus,
    String? receivedBy,
    String? serial,
    num? codAmount,
    String? codMethod,
    List<String> reasons = const [],
    String? reason,
    File? deliveredPhoto,
  }) {
    _need(orderUuid, 'orderUuid');
    _need(seenStatus, 'seenStatus');
    if (!OrderSteps.all.contains(status)) {
      throw ArgumentError.value(status, 'status', 'not an order step');
    }
    if (status == OrderSteps.delivered) _need(receivedBy, 'receivedBy');
    if (status == OrderSteps.cancelled && reasons.isEmpty) {
      _need(reason, 'reason');
    }
    return OfflineAction._(
      SyncActionKeys.orderStatus,
      {
        'order_uuid': orderUuid,
        'status': status,
        if (status == OrderSteps.delivered) ...{
          'received_by': receivedBy!.trim(),
          if (_has(serial)) 'serial': serial!.trim(),
          'cod_amount': ?codAmount,
          if (_has(codMethod)) 'cod_method': codMethod,
        },
        if (status == OrderSteps.cancelled) ...{
          if (reasons.isNotEmpty) 'reasons': reasons,
          if (_has(reason)) 'reason': reason!.trim(),
        },
      },
      seen: {'status': seenStatus},
      files: {
        if (deliveredPhoto != null && status == OrderSteps.delivered)
          'delivered_photo': deliveredPhoto,
      },
    );
  }

  /// An order cancelled. Held units are released.
  factory OfflineAction.orderCancel({
    required String orderUuid,
    required String seenStatus,
    List<String> reasons = const [],
    String? reason,
  }) {
    _need(orderUuid, 'orderUuid');
    _need(seenStatus, 'seenStatus');
    if (reasons.isEmpty) _need(reason, 'reason');
    return OfflineAction._(
      SyncActionKeys.orderCancel,
      {
        'order_uuid': orderUuid,
        'reasons': reasons,
        if (_has(reason)) 'reason': reason!.trim(),
      },
      seen: {'status': seenStatus},
    );
  }

  /// A customer's payment on a cash order, or the seller's payment on a
  /// handed-over AtomPay order (`POST orders/{uuid}/payment`).
  ///
  /// [seenPaid] is the order's paid total the person saw (the sum of its
  /// `order_payments`); a different total on the server is `seen_changed`.
  /// [paidOn] defaults, on the server, to the day it was saved.
  factory OfflineAction.orderPayment({
    required String orderUuid,
    required num amount,
    required String method,
    String? reference,
    DateTime? paidOn,
    num? seenPaid,
    File? receipt,
  }) {
    _need(orderUuid, 'orderUuid');
    _need(method, 'method');
    _positive(amount, 'amount');
    return OfflineAction._(
      SyncActionKeys.orderPayment,
      {
        'order_uuid': orderUuid,
        'amount': amount,
        'method': method,
        if (_has(reference)) 'reference': reference!.trim(),
        if (paidOn != null) 'paid_on': day(paidOn),
      },
      seen: {'paid': ?seenPaid},
      files: {'receipt': ?receipt},
    );
  }

  /// An AtomPay order handed over to the customer
  /// (`POST atompay/{uuid}/handover`). The unit with [serial] leaves stock.
  factory OfflineAction.atompayHandover({
    required String orderUuid,
    required String receivedBy,
    String? serial,
    String? note,
    String seenStep = 'handover',
    File? photo,
  }) {
    _need(orderUuid, 'orderUuid');
    _need(receivedBy, 'receivedBy');
    return OfflineAction._(
      SyncActionKeys.atompayHandover,
      {
        'order_uuid': orderUuid,
        'received_by': receivedBy.trim(),
        if (_has(serial)) 'serial': serial!.trim(),
        if (_has(note)) 'note': note!.trim(),
      },
      seen: {'step': seenStep},
      files: {'photo': ?photo},
    );
  }

  /// A delivery against a bulk deal (`POST deals/{id}/deliver`). [items]
  /// is keyed by deal item id.
  factory OfflineAction.dealDeliver({
    required int dealId,
    required Map<int, DealDeliverLine> items,
    required String receivedBy,
    String? note,
    DateTime? deliveredOn,
    File? photo,
  }) {
    _need(receivedBy, 'receivedBy');
    final lines = {
      for (final e in items.entries)
        if (e.value.qty > 0) e.key: e.value,
    };
    if (lines.isEmpty) {
      throw ArgumentError.value(items, 'items', 'nothing to deliver');
    }
    return OfflineAction._(
      SyncActionKeys.dealDeliver,
      {
        'deal_id': dealId,
        'items': {
          for (final e in lines.entries)
            '${e.key}': {
              'qty': e.value.qty,
              if (e.value.serials.isNotEmpty)
                'serials': _clean(e.value.serials),
            },
        },
        'received_by': receivedBy.trim(),
        if (_has(note)) 'note': note!.trim(),
        if (deliveredOn != null) 'delivered_on': day(deliveredOn),
      },
      files: {'photo': ?photo},
    );
  }

  /// A payment on a bulk deal (`POST deals/{id}/payment`). [seenPaid] is
  /// the deal's `paid` as the person saw it.
  factory OfflineAction.dealPayment({
    required int dealId,
    required num amount,
    required String method,
    String? reference,
    DateTime? paidOn,
    num? seenPaid,
    File? receipt,
  }) {
    _need(method, 'method');
    _positive(amount, 'amount');
    return OfflineAction._(
      SyncActionKeys.dealPayment,
      {
        'deal_id': dealId,
        'amount': amount,
        'method': method,
        if (_has(reference)) 'reference': reference!.trim(),
        if (paidOn != null) 'paid_on': day(paidOn),
      },
      seen: {'paid': ?seenPaid},
      files: {'receipt': ?receipt},
    );
  }

  /// A bulk request's status (`POST bulk-orders/{id}/status`): New Lead,
  /// Contacted or Lost (Lost needs a [reason]).
  factory OfflineAction.bulkStatus({
    required int requestId,
    required String status,
    String? reason,
    String? comments,
    String? seenStatus,
  }) {
    if (!BulkSteps.all.contains(status)) {
      throw ArgumentError.value(status, 'status', 'not an offline bulk step');
    }
    if (status == BulkSteps.lost) _need(reason, 'reason');
    return OfflineAction._(
      SyncActionKeys.bulkStatus,
      {
        'request_id': requestId,
        'status': status,
        if (_has(reason)) 'reason': reason!.trim(),
        if (_has(comments)) 'comments': comments!.trim(),
      },
      seen: {'status': ?seenStatus},
    );
  }

  /// Stock in (`POST stock/in`). [serials] for tracked products, none for
  /// auto-numbered ones (the server's numbers come back in
  /// `changes.serials`).
  factory OfflineAction.stockIn({
    required int variantId,
    required int warehouseId,
    required int qty,
    List<String> serials = const [],
    String? reference,
    String? note,
    DateTime? movedOn,
  }) {
    if (qty <= 0) throw ArgumentError.value(qty, 'qty', 'must be above 0');
    final clean = _clean(serials);
    if (clean.isNotEmpty && clean.length != qty) {
      throw ArgumentError.value(serials, 'serials', 'one serial per unit');
    }
    return OfflineAction._(SyncActionKeys.stockIn, {
      'variant_id': variantId,
      'warehouse_id': warehouseId,
      'qty': qty,
      if (clean.isNotEmpty) 'serials': clean,
      if (_has(reference)) 'reference': reference!.trim(),
      if (_has(note)) 'note': note!.trim(),
      if (movedOn != null) 'moved_on': day(movedOn),
    });
  }

  /// One unit out of stock (`POST stock/adjust`, direction out): by
  /// [unitId], or by [serial] for a unit stocked in offline that has no id
  /// yet. [reason] is one of the account's `adjust_out_reasons`.
  factory OfflineAction.stockAdjustOut({
    int? unitId,
    String? serial,
    required String reason,
    required String note,
    DateTime? movedOn,
  }) {
    if (unitId == null && !_has(serial)) {
      throw ArgumentError('Name the unit: unitId or serial.');
    }
    _need(reason, 'reason');
    return OfflineAction._(SyncActionKeys.stockAdjust, {
      'direction': 'out',
      if (unitId != null) 'unit_id': unitId else 'serial': serial!.trim(),
      'reason': reason,
      'note': note.trim(),
      if (movedOn != null) 'moved_on': day(movedOn),
    });
  }

  /// One unit back into stock (`POST stock/adjust`, direction in). A
  /// server-given number comes back in `changes.serial`.
  factory OfflineAction.stockAdjustIn({
    required int variantId,
    required int warehouseId,
    String? serial,
    required String reason,
    required String note,
    DateTime? movedOn,
  }) {
    _need(reason, 'reason');
    return OfflineAction._(SyncActionKeys.stockAdjust, {
      'direction': 'in',
      'variant_id': variantId,
      'warehouse_id': warehouseId,
      if (_has(serial)) 'serial': serial!.trim(),
      'reason': reason,
      'note': note.trim(),
      if (movedOn != null) 'moved_on': day(movedOn),
    });
  }

  /// Units moved to another warehouse of the brand (`POST stock/transfer`).
  factory OfflineAction.stockTransfer({
    List<int> unitIds = const [],
    List<String> serials = const [],
    required int toWarehouseId,
    String? note,
    DateTime? movedOn,
  }) {
    final clean = _clean(serials);
    if (unitIds.isEmpty && clean.isEmpty) {
      throw ArgumentError('Name the units: unitIds and/or serials.');
    }
    return OfflineAction._(SyncActionKeys.stockTransfer, {
      if (unitIds.isNotEmpty) 'unit_ids': unitIds,
      if (clean.isNotEmpty) 'serials': clean,
      'to_warehouse_id': toWarehouseId,
      if (_has(note)) 'note': note!.trim(),
      if (movedOn != null) 'moved_on': day(movedOn),
    });
  }

  /// The serials this action names, for the serial clash screen.
  List<String> get serials => serialsOf(action, data);

  /// The serials an outbox row names, read back from its `data`.
  static List<String> serialsOf(String action, Map<String, dynamic> data) {
    List<String> list(Object? v) => switch (v) {
      List l => [
        for (final s in l)
          if ('$s'.trim().isNotEmpty) '$s'.trim(),
      ],
      String s => _clean(s.split('\n')),
      _ => const [],
    };
    return switch (action) {
      SyncActionKeys.dealDeliver => [
        if (data['items'] case Map items)
          for (final line in items.values)
            if (line is Map) ...list(line['serials']),
      ],
      SyncActionKeys.stockIn ||
      SyncActionKeys.stockTransfer => list(data['serials']),
      _ => [
        if (data['serial'] case final s? when '$s'.trim().isNotEmpty)
          '$s'.trim(),
      ],
    };
  }

  /// A day as the server writes one, with no time and no zone.
  static String day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static bool _has(String? v) => v != null && v.trim().isNotEmpty;

  static void _need(String? v, String name) {
    if (!_has(v)) throw ArgumentError.value(v, name, 'is required');
  }

  static void _positive(num v, String name) {
    if (v <= 0) throw ArgumentError.value(v, name, 'must be above 0');
  }

  static List<String> _clean(Iterable<String> serials) => [
    for (final s in serials)
      if (s.trim().isNotEmpty) s.trim(),
  ];
}
