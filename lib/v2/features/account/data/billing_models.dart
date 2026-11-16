import 'package:flutter/foundation.dart';

import '../../../core/access/access.dart';
import '../../../core/api/api_client.dart';
import '../../../core/format/dates.dart';
import '../../../../l10n/app_localizations.dart';

/// Plan & billing, as `GET billing` sends it (docs/brand-app-billing.md).
/// Every amount is Atomshop's; the app never works a price out itself.

/// The periods Atomshop sells a plan for, in months.
const billingPeriods = [1, 3, 6, 12];

/// "1 month", "3 months", "1 year".
String periodLabel(AppLocalizations l, int months) =>
    months == 12 ? l.acctOneYear : l.acctMonths(months);

/// "Monthly", "Every 3 months", "Yearly".
String periodAdverb(AppLocalizations l, int months) => switch (months) {
  1 => l.acctMonthly,
  12 => l.acctYearly,
  _ => l.acctEveryMonths(months),
};

/// One row of Atomshop's price list (`items[]`): the package, the price per
/// extra outlet, or an add-on.
@immutable
class PriceItem {
  const PriceItem({
    required this.key,
    required this.kind,
    required this.name,
    this.description,
    this.trialDays,
    this.prices = const {},
  });

  final String key;

  /// package, branch or addon.
  final String kind;
  final String name;
  final String? description;
  final int? trialDays;

  /// months → price; a period Atomshop doesn't sell is left out.
  final Map<int, int> prices;

  int? priceFor(int months) => prices[months];

  factory PriceItem.fromJson(Object? raw) {
    final j = Json.map(raw);
    return PriceItem(
      key: Json.str(j['key']) ?? '',
      kind: Json.str(j['kind']) ?? '',
      name: Json.str(j['name']) ?? '',
      description: Json.str(j['description']),
      trialDays: Json.integer(j['trial_days']),
      prices: _prices(j['prices']),
    );
  }
}

/// `{"1": 5000, "3": 14000, "6": null}` → `{1: 5000, 3: 14000}`.
Map<int, int> _prices(Object? raw) {
  final out = <int, int>{};
  for (final e in Json.map(raw).entries) {
    final months = int.tryParse(e.key);
    final price = Json.integer(e.value);
    if (months != null && price != null) out[months] = price;
  }
  return out;
}

/// An add-on on Plan & billing (`addons[]`).
@immutable
class BillingAddon {
  const BillingAddon({
    required this.key,
    required this.name,
    required this.state,
    this.description,
    this.status = 'off',
    this.endsOn,
    this.renew = true,
    this.trialDays,
    this.trialAvailable = false,
    this.legacyUntil,
  });

  final String key;
  final String name;
  final String? description;

  /// What the app does with it: off, trial, active, lapsed or legacy.
  final AddonState state;

  /// The billing row's own status: off, trial or active.
  final String status;
  final DateTime? endsOn;

  /// False once switched off: it runs to [endsOn], then stops.
  final bool renew;
  final int? trialDays;

  /// A free trial is still there to take.
  final bool trialAvailable;

  /// Free until this day (brands that had a login before billing).
  final DateTime? legacyUntil;

  Addon? get addon => Addon.fromKey(key);

  /// Working now: trial, paid or free until the legacy date.
  bool get on => state.usable;

  /// On, but switched off: it stops at [endsOn].
  bool get stopping => on && !renew && endsOn != null;

  factory BillingAddon.fromJson(Object? raw) {
    final j = Json.map(raw);
    return BillingAddon(
      key: Json.str(j['key']) ?? '',
      name: Json.str(j['name']) ?? Json.str(j['key']) ?? '',
      description: Json.str(j['description']),
      state: AddonState.fromKey(j['state'] ?? j['status']),
      status: Json.str(j['status']) ?? 'off',
      endsOn: AtomDates.parse(j['ends_on']),
      renew: j['renew'] == null || Json.flag(j['renew']),
      trialDays: Json.integer(j['trial_days']),
      trialAvailable: Json.flag(j['trial_available']),
      legacyUntil: AtomDates.parse(j['legacy_until']),
    );
  }
}

/// A bill's status (`invoices[].status`).
enum InvoiceStatus {
  open,
  partPaid,
  paid,

  /// Cancelled.
  voided;

  /// A missing or unknown status is an open bill.
  static InvoiceStatus fromKey(Object? key) => switch (key) {
    'part_paid' => partPaid,
    'paid' => paid,
    'void' => voided,
    _ => open,
  };

  /// Still owed.
  bool get owed => this == open || this == partPaid;
}

/// A payment's status (`payments[].status`).
enum PaymentStatus {
  /// Being checked; also a missing or unknown status.
  pending,
  received,

  /// Not found.
  rejected,
  reversed;

  static PaymentStatus fromKey(Object? key) => switch (key) {
    'received' => received,
    'rejected' => rejected,
    'reversed' => reversed,
    _ => pending,
  };
}

/// The plan's status (`account.status`).
enum PlanStatus {
  none,
  trial,
  active,
  ended;

  /// Missing is no plan; an unknown status counts as a running plan.
  static PlanStatus fromKey(Object? key) => switch (key) {
    null || 'none' => none,
    'trial' => trial,
    'ended' => ended,
    _ => active,
  };
}

/// A bill from Atomshop (`invoices[]`, `open_invoices[]`, or the `invoice`
/// that checkout and an add-on switch answer with).
@immutable
class Invoice {
  const Invoice({
    required this.id,
    required this.number,
    required this.total,
    required this.due,
    required this.status,
    this.kind,
    this.kindLabel,
    this.periodMonths,
    this.coversFrom,
    this.coversTo,
    this.paid = 0,
    this.dueOn,
    this.overdue = false,
    this.lines = const [],
  });

  final int id;
  final String number;
  final int total;
  final int due;
  final int paid;

  final InvoiceStatus status;
  final String? kind;
  final String? kindLabel;
  final int? periodMonths;
  final DateTime? coversFrom;
  final DateTime? coversTo;
  final DateTime? dueOn;
  final bool overdue;
  final List<({String description, int amount})> lines;

  bool get open => status.owed;

  factory Invoice.fromJson(Object? raw) {
    final j = Json.map(raw);
    final status = InvoiceStatus.fromKey(Json.str(j['status']));
    return Invoice(
      id: Json.integer(j['id']) ?? 0,
      number: Json.str(j['number']) ?? '',
      total: Json.integer(j['total']) ?? 0,
      due: Json.integer(j['due']) ?? 0,
      paid: Json.integer(j['paid']) ?? 0,
      status: status,
      kind: Json.str(j['kind']),
      kindLabel: Json.str(j['kind_label']),
      periodMonths: Json.integer(j['period_months']),
      coversFrom: AtomDates.parse(j['covers_from']),
      coversTo: AtomDates.parse(j['covers_to']),
      dueOn: AtomDates.parse(j['due_on']),
      overdue: Json.flag(j['overdue']) && status.owed,
      lines: [
        for (final l in Json.list(j['lines']))
          (
            description: Json.str(Json.map(l)['description']) ?? '',
            amount: Json.integer(Json.map(l)['amount']) ?? 0,
          ),
      ],
    );
  }
}

/// A payment the brand sent Atomshop (`payments[]`).
@immutable
class BillPayment {
  const BillPayment({
    required this.id,
    required this.amountClaimed,
    required this.status,
    this.number,
    this.amountReceived,
    this.method,
    this.methodLabel,
    this.paidOn,
    this.reference,
    this.reason,
  });

  final int id;

  /// The receipt number (`RCT-…`), once there is one.
  final String? number;
  final int amountClaimed;
  final int? amountReceived;
  final String? method;
  final String? methodLabel;
  final DateTime? paidOn;
  final String? reference;

  /// pending ("being checked"), received, rejected or reversed.
  final PaymentStatus status;

  /// Why Atomshop didn't find it.
  final String? reason;

  /// A receipt PDF is there only once Atomshop received it.
  bool get hasReceipt => status == PaymentStatus.received && (number ?? '').isNotEmpty;

  factory BillPayment.fromJson(Object? raw) {
    final j = Json.map(raw);
    return BillPayment(
      id: Json.integer(j['id']) ?? 0,
      number: Json.str(j['number']),
      amountClaimed: Json.integer(j['amount_claimed']) ?? 0,
      amountReceived: Json.integer(j['amount_received']),
      method: Json.str(j['method']),
      methodLabel: Json.str(j['method_label']),
      paidOn: AtomDates.parse(j['paid_on']),
      reference: Json.str(j['reference']),
      status: PaymentStatus.fromKey(Json.str(j['status'])),
      reason: Json.str(j['reason']),
    );
  }
}

/// The whole Plan & billing page (`GET billing`).
@immutable
class BillingOverview {
  const BillingOverview({
    required this.accessState,
    this.shopType = 'single',
    this.outlets = 0,
    this.status = PlanStatus.none,
    this.periodMonths,
    this.periodStartsOn,
    this.periodEndsOn,
    this.trialEndsOn,
    this.legacyUntil,
    this.paidUntil,
    this.credit = 0,
    this.discountPct = 0,
    this.daysLate = 0,
    this.due = 0,
    this.paused = false,
    this.message,
    this.periods = const [],
    this.items = const [],
    this.addons = const [],
    this.openInvoices = const [],
    this.invoices = const [],
    this.payments = const [],
    this.payee = const {},
    this.methods = const {},
  });

  /// single or multi.
  final String shopType;
  final int outlets;

  final PlanStatus status;
  final int? periodMonths;
  final DateTime? periodStartsOn;
  final DateTime? periodEndsOn;
  final DateTime? trialEndsOn;
  final DateTime? legacyUntil;
  final DateTime? paidUntil;
  final int credit;
  final double discountPct;

  final AccountStatus accessState;
  final int daysLate;
  final int due;

  /// A payment is being checked: nothing is blocked meanwhile.
  final bool paused;
  final String? message;

  /// The periods on offer for this account.
  final List<int> periods;
  final List<PriceItem> items;
  final List<BillingAddon> addons;
  final List<Invoice> openInvoices;
  final List<Invoice> invoices;
  final List<BillPayment> payments;

  /// Atomshop's own account: bank_name, account_title, iban, jazzcash,
  /// easypaisa, note (only those set).
  final Map<String, String> payee;

  /// bank → "Bank transfer", jazzcash, easypaisa, cash, cheque.
  final Map<String, String> methods;

  bool get multiOutlet => shopType == 'multi';

  PriceItem? get package => items.where((i) => i.kind == 'package').firstOrNull;

  PriceItem? get branch => items.where((i) => i.kind == 'branch').firstOrNull;

  PriceItem? item(String key) => items.where((i) => i.key == key).firstOrNull;

  /// The periods a plan can be bought for: the server's list, else every
  /// period the package has a price for.
  List<int> get periodsOnOffer {
    final fromServer = periods.where(billingPeriods.contains).toList();
    if (fromServer.isNotEmpty) return fromServer..sort();
    final priced = package?.prices.keys.toList() ?? <int>[];
    return priced..sort();
  }

  Invoice? invoiceByNumber(String number) => [
    ...openInvoices,
    ...invoices,
  ].where((i) => i.number == number).firstOrNull;

  factory BillingOverview.fromJson(Object? data) {
    final d = Json.map(data);
    final a = Json.map(d['account']);
    final s = Json.map(d['access']);
    Map<String, String> strings(Object? raw) => {
      for (final e in Json.map(raw).entries)
        if (Json.str(e.value) case final v? when v.trim().isNotEmpty) e.key: v,
    };
    return BillingOverview(
      shopType: Json.str(a['shop_type']) ?? 'single',
      outlets: Json.integer(a['outlets']) ?? 0,
      status: PlanStatus.fromKey(Json.str(a['status'])),
      periodMonths: Json.integer(a['period_months']),
      periodStartsOn: AtomDates.parse(a['period_starts_on']),
      periodEndsOn: AtomDates.parse(a['period_ends_on']),
      trialEndsOn: AtomDates.parse(a['trial_ends_on']),
      legacyUntil: AtomDates.parse(a['legacy_until']),
      paidUntil: AtomDates.parse(a['paid_until']),
      credit: Json.integer(a['credit']) ?? 0,
      discountPct: switch (a['discount_pct']) {
        final num n => n.toDouble(),
        final String t => double.tryParse(t) ?? 0,
        _ => 0,
      },
      accessState: AccountStatus.fromAccessState(Json.str(s['state'])),
      daysLate: Json.integer(s['days_late']) ?? 0,
      due: Json.integer(s['due']) ?? 0,
      paused: Json.flag(s['paused']),
      message: Json.str(s['message']),
      periods: [for (final p in Json.list(d['periods'])) ?Json.integer(p)],
      items: [for (final i in Json.list(d['items'])) PriceItem.fromJson(i)],
      addons: [
        for (final i in Json.list(d['addons'])) BillingAddon.fromJson(i),
      ],
      openInvoices: [
        for (final i in Json.list(d['open_invoices'])) Invoice.fromJson(i),
      ],
      invoices: [for (final i in Json.list(d['invoices'])) Invoice.fromJson(i)],
      payments: [
        for (final i in Json.list(d['payments'])) BillPayment.fromJson(i),
      ],
      payee: strings(d['payee']),
      methods: strings(d['methods']),
    );
  }
}

/// `POST billing/quote`: what a period and add-ons come to.
@immutable
class PlanQuote {
  const PlanQuote({
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.credit,
    required this.total,
    this.branches = 0,
  });

  final List<({String description, int amount})> lines;
  final int subtotal;
  final int discount;
  final int credit;
  final int total;
  final int branches;

  factory PlanQuote.fromJson(Object? data) {
    final d = Json.map(data);
    return PlanQuote(
      lines: [
        for (final l in Json.list(d['lines']))
          (
            description: Json.str(Json.map(l)['description']) ?? '',
            amount: Json.integer(Json.map(l)['amount']) ?? 0,
          ),
      ],
      subtotal: Json.integer(d['subtotal']) ?? 0,
      discount: Json.integer(d['discount']) ?? 0,
      credit: Json.integer(d['credit']) ?? 0,
      total: Json.integer(d['total']) ?? 0,
      branches: Json.integer(d['branches']) ?? 0,
    );
  }
}
