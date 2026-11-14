import 'package:flutter/foundation.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/api/api_client.dart' show Json;
import '../../../core/format/dates.dart';
import 'order_rules.dart';

/// What the Orders list asks for: one status (null is all), the search
/// words, one outlet (null is all), the payment state (`unpaid`, `part`,
/// `paid`; null is any) and the days the order was placed (`from` / `to`,
/// either end open). A record, so it compares by value and can key a
/// provider.
typedef OrdersQuery = ({
  String? status,
  String q,
  int? outletId,
  String? payment,
  DateTime? from,
  DateTime? to,
});

/// [q] with every status: what the status chips count.
OrdersQuery anyStatus(OrdersQuery q) => (
  status: null,
  q: q.q,
  outletId: q.outletId,
  payment: q.payment,
  from: q.from,
  to: q.to,
);

/// The `GET orders` filters of [q] other than the status and the page.
Map<String, dynamic> ordersFilters(OrdersQuery q) => {
  'type': 'retail',
  'cash': 1,
  if (q.q.trim().isNotEmpty) 'q': q.q.trim(),
  'outlet_id': ?q.outletId,
  'payment': ?q.payment,
  if (q.from case final d?) 'from': AtomDates.api(d),
  if (q.to case final d?) 'to': AtomDates.api(d),
};

/// The sibling `counts` of `GET orders` (`[{status, label, count}]`, under
/// every filter but the status) as status key → count; null when the
/// server sent none. Counts add up per stage, so a status the app folds
/// into another (an old `Instalments` reads as Pending) never overwrites
/// that stage's own count.
Map<String, int>? orderCountsOf(Object? raw) {
  if (raw is! List) return null;
  final out = <String, int>{};
  for (final c in raw) {
    final row = Json.map(c);
    final s = Json.str(row['status']);
    if (s == null) continue;
    final key = OrderStage.fromKey(s).key;
    out[key] = (out[key] ?? 0) + (Json.integer(row['count']) ?? 0);
  }
  return out;
}

/// An order's outlet: `{id, name, is_main, label}`.
@immutable
class OrderOutlet {
  const OrderOutlet({
    required this.id,
    required this.name,
    this.isMain = false,
  });

  final int id;
  final String name;
  final bool isMain;

  static OrderOutlet? fromJson(Object? data) {
    final j = Json.map(data);
    final id = Json.integer(j['id']);
    if (id == null) return null;
    return OrderOutlet(
      id: id,
      name: Json.str(j['label']) ?? Json.str(j['name']) ?? '',
      isMain: Json.flag(j['is_main']),
    );
  }
}

/// A cash order as the list (and the top of the detail) shows it: the
/// server's `retailSummary` plus the v2 money fields.
@immutable
class CashOrder {
  const CashOrder({
    required this.uuid,
    required this.id,
    required this.stage,
    required this.total,
    required this.paid,
    required this.balance,
    required this.payState,
    required this.productTitle,
    this.statusLabel,
    this.picture,
    this.variant,
    this.quantity = 1,
    this.city,
    this.portal,
    this.createdAt,
    this.outlet,
    this.isAtompay = false,
    this.customerName,
    this.customerPhone,
  });

  final String uuid;
  final int id;
  final OrderStage stage;
  final String? statusLabel;
  final int total;
  final int paid;
  final int balance;
  final PaymentState payState;
  final String productTitle;
  final String? picture;
  final String? variant;
  final int quantity;
  final String? city;
  final String? portal;
  final DateTime? createdAt;
  final OrderOutlet? outlet;

  /// An AtomPay order (its page is 6.9, not this one).
  final bool isAtompay;

  /// On the list only when the server sends it (`customer_name`, or the
  /// phone's copy); the detail always has the customer.
  final String? customerName;
  final String? customerPhone;

  /// "#48224", as the board numbers orders.
  String get number => '#$id';

  /// "Zenvo Refrigerator 14 cft · Silver · Qty 1".
  String productLine(AppLocalizations l) => [
    productTitle,
    if (variant case final v? when v.isNotEmpty) v,
    l.ordersQty(quantity),
  ].join(' · ');

  /// The status's name: the server's label, else the app's.
  String stageName(AppLocalizations l) => statusLabel ?? stage.label(l);

  factory CashOrder.fromJson(Object? data) {
    final j = Json.map(data);
    final stage = OrderStage.fromKey(Json.str(j['status']));
    final total = Json.integer(j['total_deal_price']) ?? 0;
    final paid = Json.integer(j['paid']) ?? 0;
    final product = Json.map(j['product']);
    final customer = Json.map(j['customer']);
    return CashOrder(
      uuid: Json.str(j['uuid']) ?? '',
      id: Json.integer(j['id']) ?? 0,
      stage: stage,
      statusLabel: Json.str(j['status_label']),
      total: total,
      paid: paid,
      balance: Json.integer(j['balance']) ?? (total - paid).clamp(0, total),
      payState: j['payment_state'] == null
          ? PaymentState.of(total: total, paid: paid, stage: stage)
          : PaymentState.fromKey(Json.str(j['payment_state']), stage: stage),
      productTitle:
          Json.str(product['title']) ?? Json.str(j['product_title']) ?? '',
      picture: Json.str(product['picture']),
      variant: Json.str(j['variant']),
      quantity: Json.integer(j['quantity']) ?? 1,
      city: Json.str(j['city']),
      portal: Json.str(j['portal']),
      createdAt: AtomDates.parse(j['created_at']),
      outlet: OrderOutlet.fromJson(j['outlet']),
      isAtompay: j['type'] == 'atompay',
      customerName: Json.str(customer['name']) ?? Json.str(j['customer_name']),
      customerPhone:
          Json.str(customer['phone']) ?? Json.str(j['customer_phone']),
    );
  }

  /// The same order after a status move saved on this phone.
  CashOrder moved(OrderStage to) => CashOrder(
    uuid: uuid,
    id: id,
    stage: to,
    total: total,
    paid: paid,
    balance: balance,
    payState: PaymentState.of(total: total, paid: paid, stage: to),
    productTitle: productTitle,
    picture: picture,
    variant: variant,
    quantity: quantity,
    city: city,
    portal: portal,
    createdAt: createdAt,
    outlet: outlet,
    isAtompay: isAtompay,
    customerName: customerName,
    customerPhone: customerPhone,
  );
}

/// The customer on the order page. Personal data: never logged or kept.
@immutable
class OrderCustomer {
  const OrderCustomer({
    required this.name,
    this.phone,
    this.email,
    this.since,
    this.verified = false,
    this.address,
    this.area,
    this.city,
  });

  final String name;
  final String? phone;
  final String? email;
  final DateTime? since;
  final bool verified;
  final String? address;
  final String? area;
  final String? city;

  String get firstName => name.trim().split(' ').first;

  static OrderCustomer? fromJson(Object? data) {
    if (data is! Map) return null;
    final j = Json.map(data);
    return OrderCustomer(
      name: Json.str(j['name']) ?? '',
      phone: Json.str(j['phone']),
      email: Json.str(j['email']),
      since: AtomDates.parse(j['customer_since']),
      verified: Json.flag(j['verified']),
      address: Json.str(j['address']),
      area: Json.str(j['area']),
      city: Json.str(j['city']),
    );
  }
}

/// A payment recorded against an order (`brand_payments`).
@immutable
class OrderPaymentRow {
  const OrderPaymentRow({
    required this.amount,
    required this.method,
    this.id,
    this.methodLabel,
    this.reference,
    this.receipt,
    this.paidOn,
    this.recordedBy,
  });

  final int? id;
  final int amount;
  final String method;
  final String? methodLabel;
  final String? reference;
  final String? receipt;
  final DateTime? paidOn;
  final String? recordedBy;

  String methodName(AppLocalizations l) =>
      methodLabel ?? labelOfMethod(method, l);

  factory OrderPaymentRow.fromJson(Object? data) {
    final j = Json.map(data);
    return OrderPaymentRow(
      id: Json.integer(j['id']),
      amount: Json.integer(j['amount']) ?? 0,
      method: Json.str(j['method']) ?? '',
      methodLabel: Json.str(j['method_label']),
      reference: Json.str(j['reference']),
      receipt: Json.str(j['receipt']),
      paidOn: AtomDates.parse(j['paid_on']),
      recordedBy:
          Json.str(j['recorded_by_name']) ??
          (j['recorded_by'] is String ? Json.str(j['recorded_by']) : null),
    );
  }
}

/// One row of an order's history (`order_change_histories`).
@immutable
class OrderEvent {
  const OrderEvent({
    required this.status,
    this.at,
    this.byName,
    this.role,
    this.payload = const {},
  });

  /// The status it moved to, as the server sent it.
  final String status;
  final DateTime? at;
  final String? byName;
  final String? role;
  final Map<String, dynamic> payload;

  OrderStage get stage => OrderStage.fromKey(status);

  factory OrderEvent.fromJson(Object? data) {
    final j = Json.map(data);
    final by = Json.map(j['changed_by']);
    return OrderEvent(
      status: Json.str(j['status']) ?? '',
      at: AtomDates.parse(j['created_at']),
      byName: Json.str(by['name']) ?? Json.str(j['changed_by_name']),
      role: Json.str(j['role']),
      payload: Json.map(j['payload']),
    );
  }
}

/// The order page (6.2): `GET orders/retail/{uuid}`.
@immutable
class CashOrderDetail {
  const CashOrderDetail({
    required this.order,
    this.customer,
    this.history = const [],
    this.payments = const [],
    this.paymentMethods = const ['cash'],
    this.nextStatuses,
    this.alsoBought = const [],
    this.locked = false,
    this.lockedReason,
    this.prNumber,
    this.fromCopy = false,
  });

  final CashOrder order;
  final OrderCustomer? customer;

  /// Newest first, as the server sends it.
  final List<OrderEvent> history;
  final List<OrderPaymentRow> payments;
  final List<String> paymentMethods;

  /// `next_statuses`; null when not known (falls back to the table).
  final List<OrderStage>? nextStatuses;
  final List<CashOrder> alsoBought;
  final bool locked;
  final String? lockedReason;
  final String? prNumber;

  /// Read from the phone's copy (no signal): the parts only the server
  /// has (customer since, also bought) are missing.
  final bool fromCopy;

  String get uuid => order.uuid;
  OrderStage get stage => order.stage;

  List<OrderStage> get moves => allowedMoves(stage, nextStatuses);

  /// The serial noted when it was delivered.
  String? get serial {
    for (final e in history) {
      if (e.stage == OrderStage.delivered) {
        final s = Json.str(e.payload['serial']);
        if (s != null && s.isNotEmpty) return s;
      }
    }
    return null;
  }

  /// The latest event that moved the order to [stage].
  OrderEvent? eventFor(OrderStage stage) {
    for (final e in history) {
      if (e.stage == stage) return e;
    }
    return null;
  }

  factory CashOrderDetail.fromJson(Object? data) {
    final j = Json.map(data);
    final summary = Json.map(j['order']);
    final product = Json.map(j['product']);
    // The product block carries the variant and picture of the detail.
    final order = CashOrder.fromJson({
      ...summary,
      if (summary['product'] == null && product.isNotEmpty) 'product': product,
      if (summary['variant'] == null && product['variant'] != null)
        'variant': product['variant'],
    });
    final next = j['next_statuses'];
    return CashOrderDetail(
      order: order,
      customer: OrderCustomer.fromJson(j['customer']),
      history: [
        for (final h in Json.list(j['history'])) OrderEvent.fromJson(h),
      ],
      payments: [
        for (final p in Json.list(j['payments'])) OrderPaymentRow.fromJson(p),
      ],
      paymentMethods: [
        for (final m in Json.list(j['payment_methods'])) ?Json.str(m),
      ],
      nextStatuses: next is List
          ? [for (final s in next) OrderStage.fromKey(Json.str(s))]
          : null,
      alsoBought: [
        for (final o in Json.list(j['also_bought'])) CashOrder.fromJson(o),
      ],
      locked: Json.flag(j['locked']),
      lockedReason: Json.str(j['locked_reason']),
      prNumber: Json.str(product['pr_number']),
    );
  }
}

/// The receipt as data (6.7): `GET orders/{uuid}/receipt`.
@immutable
class OrderReceipt {
  const OrderReceipt({
    required this.number,
    required this.order,
    required this.brand,
    this.outlet,
    this.address,
    this.phone,
    this.email,
    this.customer,
    this.serial,
    this.deliveredAt,
    this.payments = const [],
    this.note,
    this.webUrl,
  });

  final String number;
  final CashOrder order;
  final String brand;
  final String? outlet;
  final String? address;
  final String? phone;
  final String? email;
  final OrderCustomer? customer;
  final String? serial;
  final DateTime? deliveredAt;

  /// Newest first, as the server sends them.
  final List<OrderPaymentRow> payments;
  final String? note;
  final String? webUrl;

  int get paidTotal => payments.fold(0, (n, p) => n + p.amount);
  int get left => (order.total - paidTotal).clamp(0, order.total);

  /// The receipt's date: the last payment, else delivery, else the order.
  DateTime? get date =>
      payments
          .map((p) => p.paidOn)
          .whereType<DateTime>()
          .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a) ??
      deliveredAt ??
      order.createdAt;

  factory OrderReceipt.fromJson(Object? data) {
    final j = Json.map(data);
    final sold = Json.map(j['sold_by']);
    return OrderReceipt(
      number: Json.str(j['number']) ?? '',
      order: CashOrder.fromJson(j['order']),
      brand: Json.str(sold['brand']) ?? '',
      outlet: Json.str(sold['outlet']),
      address: Json.str(sold['address']),
      phone: Json.str(sold['phone']),
      email: Json.str(sold['email']),
      customer: OrderCustomer.fromJson(j['customer']),
      serial: Json.str(j['serial']),
      deliveredAt: AtomDates.parse(j['delivered_at']),
      payments: [
        for (final p in Json.list(j['payments'])) OrderPaymentRow.fromJson(p),
      ],
      note: Json.str(j['note']),
      webUrl: Json.str(j['web_url']),
    );
  }
}
