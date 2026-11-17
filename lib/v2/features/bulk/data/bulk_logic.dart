import 'package:flutter/foundation.dart';

import '../../../../l10n/app_localizations.dart';
import 'bulk_models.dart';

/// The rules behind the bulk screens, kept apart from the widgets so they
/// can be tested: where a request stands, quote maths and its checks, and
/// what a delivery or payment is allowed to do. The server
/// (`BrandBulkDealService`) is the judge; these only say it first.

// ───────────────────────────────────────────── seller (sourcing) requests

/// Where a seller's request stands, as 7.2 shows it.
enum SourcingState {
  fresh,
  changeAsked,
  quoted,
  declined,

  /// The brand turned the request down (Lost).
  closed,
  accepted;

  String label(AppLocalizations l) => switch (this) {
    fresh => l.bulkStatusNew,
    changeAsked => l.bulkStatusChangeAsked,
    quoted => l.bulkStatusQuoted,
    declined || closed => l.bulkStatusDeclined,
    accepted => l.bulkStatusAccepted,
  };

  /// The brand can still quote it.
  bool get canQuote =>
      this == fresh ||
      this == changeAsked ||
      this == quoted ||
      this == declined;
}

/// A seller request's state from its status, the seller's latest answer,
/// the live quote and the deal.
SourcingState sourcingStateOf({
  required RequestStatus status,
  SellerAnswer? answer,
  Quote? liveQuote,
  DealRef? deal,
}) {
  if (deal != null || status == RequestStatus.won) {
    return SourcingState.accepted;
  }
  if (answer?.action == SellerAction.accepted) return SourcingState.accepted;
  if (status == RequestStatus.lost) {
    return answer != null && answer.action.saidNo
        ? SourcingState.declined
        : SourcingState.closed;
  }
  if (answer != null &&
      answer.pending &&
      answer.action == SellerAction.changeAsked) {
    return SourcingState.changeAsked;
  }
  if (answer != null && answer.action.saidNo) {
    final sent = liveQuote?.sentAt;
    final at = answer.at;
    // a revision sent after the "no" puts it back with the seller
    if (sent == null || at == null || !sent.isAfter(at)) {
      return SourcingState.declined;
    }
  }
  if (liveQuote != null && !liveQuote.isDraft) return SourcingState.quoted;
  if (status == RequestStatus.quoted) return SourcingState.quoted;
  return SourcingState.fresh;
}

/// A list row's state (the list has no answer unless the server sends one).
SourcingState sourcingStateOfRow(BulkRequest r) =>
    sourcingStateOf(status: r.status, answer: r.answer, liveQuote: r.quote);

/// How many of 7.2's five steps (Asked, Quoted, Seller answers, Deal,
/// Delivered) are reached.
int sourcingStepsReached(SourcingState s, {DealStatus? dealStatus}) {
  if (s == SourcingState.accepted) {
    return (dealStatus?.deliveredOrLater ?? false) ? 5 : 4;
  }
  return switch (s) {
    SourcingState.fresh => 1,
    SourcingState.quoted => 2,
    SourcingState.changeAsked ||
    SourcingState.declined ||
    SourcingState.closed => 3,
    SourcingState.accepted => 4,
  };
}

/// How urgent a "needed by" date is: 0 calm, 1 within a week, 2 within
/// three days or passed.
@immutable
class NeedBy {
  const NeedBy({required this.days, required this.urgency});

  /// Days from today; negative once passed.
  final int days;
  final int urgency;
}

NeedBy needByOf(DateTime neededBy, {required DateTime today}) {
  final a = DateTime(neededBy.year, neededBy.month, neededBy.day);
  final b = DateTime(today.year, today.month, today.day);
  final days = a.difference(b).inDays;
  final urgency = days <= 3
      ? 2
      : days <= 7
      ? 1
      : 0;
  return NeedBy(days: days, urgency: urgency);
}

/// "3 days", "Today", "Tomorrow", "2 days late".
String daysLeftText(AppLocalizations l, int days) => switch (days) {
  0 => l.bulkDaysToday,
  1 => l.bulkDaysTomorrow,
  < 0 => l.bulkDaysLate(-days),
  _ => l.bulkDaysCount(days),
};

/// How far a price is above (+) or below (-) another, in whole percent.
int percentAbove(int price, int base) =>
    base <= 0 ? 0 : (((price - base) * 100) / base).round();

// ───────────────────────────────────────────────────── website requests

/// The steps of 7.3 (New, Contacted, Quoted, Won, Delivered and paid):
/// the index reached, 0-based.
int requestStepIndex(RequestStatus s) => switch (s) {
  RequestStatus.fresh => 0,
  RequestStatus.contacted => 1,
  RequestStatus.quoted => 2,
  RequestStatus.won => 3,
  RequestStatus.lost => 2,
};

/// What a website request row offers (7.1).
enum RequestAction {
  reply,
  sendQuote,
  followUp,
  openDeal,
  view;

  String label(AppLocalizations l) => switch (this) {
    reply => l.bulkActReply,
    sendQuote => l.bulkActSendQuote,
    followUp => l.bulkActFollowUp,
    openDeal => l.bulkActOpenDeal,
    view => l.bulkActView,
  };

  bool get primary => this == reply || this == sendQuote;
}

RequestAction requestActionOf(RequestStatus s, {required bool canQuote}) =>
    switch (s) {
      RequestStatus.fresh => RequestAction.reply,
      RequestStatus.contacted =>
        canQuote ? RequestAction.sendQuote : RequestAction.view,
      RequestStatus.quoted => RequestAction.followUp,
      RequestStatus.won => RequestAction.openDeal,
      RequestStatus.lost => RequestAction.view,
    };

/// The manual statuses of 7.5.
enum StatusChoice {
  contacted(RequestStatus.contacted),
  lost(RequestStatus.lost),
  backToNew(RequestStatus.fresh);

  const StatusChoice(this.status);
  final RequestStatus status;

  String label(AppLocalizations l) => switch (this) {
    contacted => l.bulkStatusContacted,
    lost => l.bulkStatusLost,
    backToNew => l.bulkStatusBackToNew,
  };
}

/// The reasons a request is lost (the server's `LOST_REASONS`). These are
/// the values sent back to the server, so they stay as the server spells
/// them.
const lostReasons = [
  'Price too high',
  'Bought from someone else',
  'Not enough stock',
  'Not reachable',
  'Other',
];

/// What stops a status save: a lost request needs its reason.
String? statusProblem(
  AppLocalizations l,
  StatusChoice choice,
  String? reason,
) => choice == StatusChoice.lost && (reason == null || reason.trim().isEmpty)
    ? l.bulkLostReasonNeeded
    : null;

/// The statuses 7.5 offers for a request in [s].
List<StatusChoice> statusChoicesFor(RequestStatus s) => switch (s) {
  RequestStatus.fresh => const [StatusChoice.contacted, StatusChoice.lost],
  RequestStatus.contacted || RequestStatus.quoted => const [
    StatusChoice.contacted,
    StatusChoice.lost,
    StatusChoice.backToNew,
  ],
  RequestStatus.lost => const [StatusChoice.backToNew, StatusChoice.contacted],
  RequestStatus.won => const [],
};

// ───────────────────────────────────────────────────────────── quotes

const maxQuoteLines = 30;
const maxQuoteTotal = 4000000000;
const maxUnitPrice = 50000000;
const maxDeliveryCharge = 5000000;
const maxQty = 100000;
const maxNotes = 500;
const advanceChoices = [0, 10, 20, 25, 30, 50, 100];

/// One line as the builder edits it.
@immutable
class QuoteDraftLine {
  const QuoteDraftLine({
    this.productId,
    this.memoryId,
    this.colorId,
    this.qty = 1,
    this.unitPrice = 0,
    this.discountPct = 0,
  });

  final int? productId;
  final int? memoryId;
  final int? colorId;
  final int qty;
  final int unitPrice;
  final double discountPct;

  QuoteDraftLine copyWith({
    int? Function()? productId,
    int? Function()? memoryId,
    int? Function()? colorId,
    int? qty,
    int? unitPrice,
    double? discountPct,
  }) => QuoteDraftLine(
    productId: productId != null ? productId() : this.productId,
    memoryId: memoryId != null ? memoryId() : this.memoryId,
    colorId: colorId != null ? colorId() : this.colorId,
    qty: qty ?? this.qty,
    unitPrice: unitPrice ?? this.unitPrice,
    discountPct: discountPct ?? this.discountPct,
  );

  int get gross => qty * unitPrice;

  int get total => quoteLineTotal(qty, unitPrice, discountPct);

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'memory_id': ?memoryId,
    'color_id': ?colorId,
    'qty': qty,
    'unit_price': unitPrice,
    'discount_pct': discountPct,
  };
}

/// qty × unit price × (1 − discount/100), rounded to the rupee, as the
/// server works it out (`BrandBulkDealService::lineTotal`).
int quoteLineTotal(int qty, int unitPrice, double discountPct) {
  final d = discountPct.clamp(0, 100);
  return (qty * unitPrice * (100 - d) / 100).round();
}

/// The figures under the quote builder.
@immutable
class QuoteTotals {
  const QuoteTotals({
    required this.units,
    required this.gross,
    required this.discount,
    required this.delivery,
    required this.total,
    required this.advancePct,
    required this.advance,
  });

  final int units;

  /// Before discounts.
  final int gross;
  final int discount;
  final int delivery;
  final int total;
  final int advancePct;
  final int advance;

  /// The lines after their discounts (the server's `subtotal`).
  int get subtotal => gross - discount;
  int get balance => total - advance;
}

QuoteTotals quoteTotals(
  List<QuoteDraftLine> lines, {
  int delivery = 0,
  int advancePct = 0,
}) {
  var units = 0, gross = 0, net = 0;
  for (final l in lines) {
    units += l.qty;
    gross += l.gross;
    net += l.total;
  }
  final total = net + delivery;
  return QuoteTotals(
    units: units,
    gross: gross,
    discount: gross - net,
    delivery: delivery,
    total: total,
    advancePct: advancePct,
    advance: (total * advancePct / 100).round(),
  );
}

/// What stops a quote being saved: field → message. Lines are `line.N`
/// (from 0).
Map<String, String> quoteProblems(
  AppLocalizations l, {
  required List<QuoteDraftLine> lines,
  required int delivery,
  required DateTime? validUntil,
  required DateTime today,
  required int advancePct,
  required String notes,
}) {
  final out = <String, String>{};
  if (lines.isEmpty) out['lines'] = l.bulkQpNoLines;
  if (lines.length > maxQuoteLines) {
    out['lines'] = l.bulkQpMaxLines('$maxQuoteLines');
  }
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final n = i + 1;
    if (line.productId == null) {
      out['line.$i'] = l.bulkQpLineProduct(n);
    } else if (line.qty < 1 || line.qty > maxQty) {
      out['line.$i'] = l.bulkQpLineQty(n, '$maxQty');
    } else if (line.unitPrice < 1) {
      out['line.$i'] = l.bulkQpLinePrice(n);
    } else if (line.unitPrice > maxUnitPrice) {
      out['line.$i'] = l.bulkQpLinePriceHigh(n);
    } else if (line.discountPct < 0 || line.discountPct > 100) {
      out['line.$i'] = l.bulkQpLineDiscount(n);
    }
  }
  if (delivery < 0 || delivery > maxDeliveryCharge) {
    out['delivery'] = l.bulkQpDelivery;
  }
  if (validUntil == null) {
    out['valid_until'] = l.bulkQpValidNeeded;
  } else {
    final v = DateTime(validUntil.year, validUntil.month, validUntil.day);
    final t = DateTime(today.year, today.month, today.day);
    if (v.isBefore(t)) out['valid_until'] = l.bulkQpValidPast;
  }
  if (advancePct < 0 || advancePct > 100) {
    out['advance'] = l.bulkQpAdvance;
  }
  if (notes.length > maxNotes) out['notes'] = l.bulkQpNotes;
  if (out.isEmpty) {
    final t = quoteTotals(lines, delivery: delivery, advancePct: advancePct);
    if (t.total > maxQuoteTotal || t.gross > maxQuoteTotal) {
      out['lines'] = l.bulkQpTooLarge;
    }
  }
  return out;
}

/// Which revision saving makes, and which sent one it replaces. A draft
/// is changed in place; otherwise the next revision.
({int revision, Quote? replaces, Quote? draft}) nextRevision(
  List<Quote> quotes,
) {
  if (quotes.isEmpty) return (revision: 1, replaces: null, draft: null);
  final latest = quotes.reduce((a, b) => a.revision >= b.revision ? a : b);
  Quote? sent;
  for (final q in quotes) {
    if (q.status == QuoteStatus.sent &&
        (sent == null || q.revision > sent.revision)) {
      sent = q;
    }
  }
  return latest.isDraft
      ? (revision: latest.revision, replaces: sent, draft: latest)
      : (revision: latest.revision + 1, replaces: sent, draft: null);
}

// ───────────────────────────────────────────────────────────── deals

/// How many of 7.7's steps (Open, Delivering, Delivered, Paid, Closed)
/// are reached.
int dealStepsReached(Deal d) => switch (d.status) {
  DealStatus.open => 1,
  DealStatus.delivering => 2,
  DealStatus.delivered => 3,
  DealStatus.paid => 4,
  DealStatus.closed => 5,
  DealStatus.lost => 1,
};

/// What a deal row offers (7.1): Deliver while units are left, else
/// Record payment while money is due.
enum DealAction { deliver, payment }

DealAction? dealActionOf(Deal d, {required bool canDeal}) {
  if (!canDeal || d.status.finished) return null;
  if (d.leftUnits > 0) return DealAction.deliver;
  if (d.balance > 0) return DealAction.payment;
  return null;
}

/// Why a delivery can't go out yet, as the server will refuse it.
sealed class DeliveryBlock {
  const DeliveryBlock();
}

/// Nothing picked.
class NothingPicked extends DeliveryBlock {
  const NothingPicked();
}

/// The advance must be in before the first delivery.
class AdvanceFirst extends DeliveryBlock {
  const AdvanceFirst({required this.advance, required this.paid});
  final int advance;
  final int paid;
}

/// The delivery completes the deal: the whole balance first.
class BalanceFirst extends DeliveryBlock {
  const BalanceFirst({required this.due});
  final int due;
}

/// Before each delivery: the units out so far, these included, must be
/// paid for.
class PayForUnits extends DeliveryBlock {
  const PayForUnits({required this.value, required this.paid});
  final int value;
  final int paid;
  int get short => value - paid;
}

/// More than is left on an item.
class TooMany extends DeliveryBlock {
  const TooMany({required this.title, required this.left});
  final String title;
  final int left;
}

/// [picked] is deal item id → units going out now.
DeliveryBlock? deliveryBlock(Deal d, Map<int, int> picked) {
  final units = picked.values.fold(0, (s, q) => s + q);
  if (units <= 0) return const NothingPicked();
  for (final i in d.items) {
    final q = picked[i.id] ?? 0;
    if (q > i.remaining) return TooMany(title: i.title, left: i.remaining);
  }
  if (d.deliveredUnits == 0 && d.paid < d.advance) {
    return AdvanceFirst(advance: d.advance, paid: d.paid);
  }
  final completes = d.items.every(
    (i) => i.deliveredQty + (picked[i.id] ?? 0) >= i.qty,
  );
  if (completes && d.paid < d.total) return BalanceFirst(due: d.total - d.paid);
  if (d.balanceTerms == 'before_each') {
    final value = valueDelivered(d, picked);
    if (d.paid < value) return PayForUnits(value: value, paid: d.paid);
  }
  return null;
}

/// The value of the units out so far plus [picked] (delivery charge not
/// included), as the server counts it for "before each delivery".
int valueDelivered(Deal d, [Map<int, int> picked = const {}]) {
  var v = 0.0;
  for (final i in d.items) {
    final after = i.deliveredQty + (picked[i.id] ?? 0);
    v += after * i.lineTotal / (i.qty <= 0 ? 1 : i.qty);
  }
  return v.round();
}

/// How much more can go out on what has been paid (before each delivery).
int paidCoverLeft(Deal d) => (d.paid - valueDelivered(d)).clamp(0, d.paid);

/// Serials typed or scanned, one per line (commas too); blanks dropped.
List<String> splitSerials(String text) => [
  for (final s in text.split(RegExp(r'[\n,]+')))
    if (s.trim().isNotEmpty) s.trim(),
];

/// What is wrong with an item's serials: none is fine, else one per unit
/// and no repeats.
String? serialProblem(
  AppLocalizations l,
  String title,
  int qty,
  List<String> serials,
) {
  if (serials.isEmpty) return null;
  if (serials.length != qty) {
    return l.bulkSerialCount(title, '${serials.length}', qty);
  }
  if (serials.toSet().length != serials.length) {
    return l.bulkSerialTwice(title);
  }
  return null;
}

/// What stops the delivery form (other than the payment rules).
String? deliverFormProblem(
  AppLocalizations l, {
  required String receivedBy,
  required String note,
}) {
  if (receivedBy.trim().isEmpty) return l.bulkDeliverWhoNeeded;
  if (receivedBy.trim().length > 100) return l.bulkDeliverWhoLong;
  if (note.length > maxNotes) return l.bulkDeliverNoteLong;
  return null;
}

/// What stops a payment: nothing entered, or more than is due.
String? paymentProblem(AppLocalizations l, int amount, int balance) {
  if (amount <= 0) return l.bulkPayAmountNeeded;
  if (amount > balance) return l.bulkPayOverBalance(_rs(balance));
  return null;
}

/// Ready-made amounts for 7.9: what the advance still needs, half and the
/// whole balance. Never more than the balance, no repeats, none at zero.
List<({String label, int amount})> paymentQuickAmounts(
  AppLocalizations l,
  Deal d,
) {
  final out = <({String label, int amount})>[];
  void add(String label, int amount) {
    if (amount <= 0 || amount > d.balance) return;
    if (out.any((o) => o.amount == amount)) return;
    out.add((label: label, amount: amount));
  }

  if (d.deliveredUnits == 0 && d.paid < d.advance) {
    add(l.bulkPayAdvance, d.advance - d.paid);
  }
  add(l.bulkPayHalf, (d.balance / 2).round());
  add(l.bulkPayFull, d.balance);
  return out;
}

String _rs(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return 'Rs $b';
}

/// The deal payment methods (`BrandBulkDealService::PAY_METHODS`). JazzCash
/// and Easypaisa are brand names and stay as they are.
List<KeyLabel> dealPaymentMethods(AppLocalizations l) => [
  (key: 'bank', label: l.bulkMethodBank),
  (key: 'cash', label: l.bulkMethodCash),
  (key: 'cheque', label: l.bulkMethodCheque),
  (key: 'jazzcash', label: 'JazzCash'),
  (key: 'easypaisa', label: 'Easypaisa'),
];

/// "Before each delivery" / "Before the last delivery".
String balanceTermsLabel(AppLocalizations l, String key) => switch (key) {
  'before_each' => l.bulkTermsEach,
  _ => l.bulkTermsLast,
};
