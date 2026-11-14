import 'package:flutter/foundation.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/api/api_client.dart' show Json;
import '../../../core/format/dates.dart';
import '../../orders/data/orders_models.dart';

/// The brand's step on an AtomPay order (`AtompaySellerService::BRAND_STEPS`).
enum AtompayStep {
  approving('approving'),
  seller('seller'),
  handover('handover'),
  handed('handed'),
  paid('paid'),
  cancelled('cancelled');

  const AtompayStep(this.key);
  final String key;

  String label(AppLocalizations l) => switch (this) {
    approving => l.atompayStepApproving,
    seller => l.atompayStepSeller,
    handover => l.atompayHandOver,
    handed => l.atompayHandedOver,
    paid => l.atompayStepPaid,
    cancelled => l.atompayStepCancelled,
  };

  static AtompayStep fromKey(String? key) =>
      values.where((s) => s.key == key).firstOrNull ?? approving;

  /// The steps of the stepper (6.9), in order. Not approved is not one.
  static const flow = [approving, seller, handover, handed, paid];
}

/// What can be done on an AtomPay order (the detail's `actions`).
enum AtompayAction { handover, payment, complete }

/// The actions the server listed, else the step's own: hand over when it
/// is the brand's turn, then the seller's payment, then complete.
List<AtompayAction> atompayActionsFor(
  AtompayStep step, {
  required int balance,
  List<AtompayAction>? fromServer,
}) =>
    fromServer ??
    switch (step) {
      AtompayStep.handover => const [AtompayAction.handover],
      AtompayStep.handed =>
        balance > 0
            ? const [AtompayAction.payment]
            : const [AtompayAction.complete],
      _ => const <AtompayAction>[],
    };

/// The seller Atomshop gave the order to.
@immutable
class AtompaySeller {
  const AtompaySeller({
    required this.name,
    this.id,
    this.code,
    this.area,
    this.city,
    this.contact,
    this.phone,
    this.address,
  });

  final int? id;
  final String name;
  final String? code;
  final String? area;
  final String? city;
  final String? contact;
  final String? phone;
  final String? address;

  /// "Model Town, Lahore".
  String get place => [?area, ?city].join(', ');

  /// "MA" for Madina Electronics.
  String get initials => name
      .split(' ')
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();

  static AtompaySeller? fromJson(Object? data) {
    if (data is! Map) return null;
    final j = Json.map(data);
    final name = Json.str(j['name']);
    if (name == null) return null;
    return AtompaySeller(
      id: Json.integer(j['id']),
      name: name,
      code: Json.str(j['code']),
      area: Json.str(j['area']),
      city: Json.str(j['city']),
      contact: Json.str(j['contact']),
      phone: Json.str(j['phone']),
      address: Json.str(j['address']),
    );
  }
}

/// An AtomPay order on the list (6.8) and at the top of its page.
@immutable
class AtompayOrder {
  const AtompayOrder({
    required this.uuid,
    required this.id,
    required this.step,
    required this.cashPrice,
    required this.paid,
    required this.balance,
    required this.productTitle,
    this.stepLabel,
    this.picture,
    this.variant,
    this.outlet,
    this.seller,
    this.createdAt,
  });

  final String uuid;
  final int id;
  final AtompayStep step;
  final String? stepLabel;
  final int cashPrice;
  final int paid;
  final int balance;
  final String productTitle;
  final String? picture;
  final String? variant;
  final OrderOutlet? outlet;
  final AtompaySeller? seller;
  final DateTime? createdAt;

  /// "#A-20931", as the board numbers AtomPay orders.
  String get number => '#A-$id';

  String stepName(AppLocalizations l) => stepLabel ?? step.label(l);

  String get productLine => [
    productTitle,
    if (variant case final v? when v.isNotEmpty) v,
  ].join(' · ');

  factory AtompayOrder.fromJson(Object? data) {
    final j = Json.map(data);
    final price =
        Json.integer(j['cash_price']) ??
        Json.integer(j['total_deal_price']) ??
        0;
    final paid = Json.integer(j['paid']) ?? 0;
    final product = Json.map(j['product']);
    return AtompayOrder(
      uuid: Json.str(j['uuid']) ?? '',
      id: Json.integer(j['id']) ?? 0,
      step: AtompayStep.fromKey(Json.str(j['step'])),
      stepLabel: Json.str(j['step_label']),
      cashPrice: price,
      paid: paid,
      balance: Json.integer(j['balance']) ?? (price - paid).clamp(0, price),
      productTitle:
          Json.str(product['title']) ?? Json.str(j['product_title']) ?? '',
      picture: Json.str(product['picture']),
      variant: Json.str(j['variant']),
      outlet: OrderOutlet.fromJson(j['outlet']),
      seller:
          AtompaySeller.fromJson(j['seller']) ??
          (Json.str(j['seller_name']) == null
              ? null
              : AtompaySeller(
                  name: Json.str(j['seller_name'])!,
                  code: Json.str(j['seller_code']),
                )),
      createdAt: AtomDates.parse(j['created_at']),
    );
  }
}

/// The AtomPay order page (6.9): `GET atompay/{uuid}`.
@immutable
class AtompayDetail {
  const AtompayDetail({
    required this.order,
    this.customerName,
    this.customerCity,
    this.customerArea,
    this.seller,
    this.months = 3,
    this.monthly = 0,
    this.handedAt,
    this.serial,
    this.payments = const [],
    this.paymentMethods = const ['cash'],
    this.history = const [],
    this.actions,
    this.fromCopy = false,
  });

  final AtompayOrder order;
  final String? customerName;
  final String? customerCity;
  final String? customerArea;
  final AtompaySeller? seller;
  final int months;
  final int monthly;
  final DateTime? handedAt;
  final String? serial;
  final List<OrderPaymentRow> payments;
  final List<String> paymentMethods;

  /// Newest first.
  final List<OrderEvent> history;

  /// The server's `actions`; null when not known.
  final List<AtompayAction>? actions;
  final bool fromCopy;

  String get uuid => order.uuid;
  AtompayStep get step => order.step;

  List<AtompayAction> get allowed =>
      atompayActionsFor(step, balance: order.balance, fromServer: actions);

  factory AtompayDetail.fromJson(Object? data) {
    final j = Json.map(data);
    final customer = Json.map(j['customer']);
    final plan = Json.map(j['customer_plan']);
    final hand = Json.map(j['handover']);
    final acts = j['actions'];
    final seller = AtompaySeller.fromJson(j['seller']);
    final order = AtompayOrder.fromJson(j['order']);
    return AtompayDetail(
      order: order,
      customerName: Json.str(customer['name']),
      customerCity: Json.str(customer['city']),
      customerArea: Json.str(customer['area']),
      seller: seller ?? order.seller,
      months: Json.integer(plan['months']) ?? 3,
      monthly: Json.integer(plan['monthly']) ?? 0,
      handedAt: AtomDates.parse(hand['at']),
      serial: Json.str(hand['serial']),
      payments: [
        for (final p in Json.list(j['payments'])) OrderPaymentRow.fromJson(p),
      ],
      paymentMethods: [
        for (final m in Json.list(j['payment_methods'])) ?Json.str(m),
      ],
      history: [
        for (final h in Json.list(j['history'])) OrderEvent.fromJson(h),
      ],
      actions: acts is List
          ? [
              for (final a in acts)
                ?AtompayAction.values
                    .where((x) => x.name == Json.str(a))
                    .firstOrNull,
            ]
          : null,
    );
  }
}
