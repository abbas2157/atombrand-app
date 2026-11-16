import 'package:intl/intl.dart';

import '../../../core/access/access.dart';
import '../../../core/format/dates.dart';
import '../../../design/design.dart' show AtomTone;
import '../../../../l10n/app_localizations.dart';
import 'billing_models.dart';

/// What Plan & billing says, worked out from `GET billing` with no widgets,
/// so it can be tested. Copy is the canvas's (12.6–12.8).

/// The badge in the header (12.6): Paid, Bill waiting, Late, Read-only,
/// No plan yet, Free trial or Being checked.
({String label, AtomTone tone}) planBadge(
  AppLocalizations l,
  BillingOverview p,
) {
  if (p.paused) return (label: l.acctBeingChecked, tone: AtomTone.blue);
  return switch (p.accessState) {
    AccountStatus.readOnly => (label: l.acctReadOnly, tone: AtomTone.rose),
    AccountStatus.late ||
    AccountStatus.overdue => (label: l.acctLate, tone: AtomTone.rose),
    AccountStatus.due => (label: l.acctBillWaiting, tone: AtomTone.amber),
    AccountStatus.noPlan => (label: l.acctNoPlanYet, tone: AtomTone.grey),
    _ when p.status == PlanStatus.trial => (
      label: l.acctFreeTrial,
      tone: AtomTone.amber,
    ),
    _ when p.openInvoices.isNotEmpty => (
      label: l.acctBillWaiting,
      tone: AtomTone.amber,
    ),
    _ => (label: l.acctPaid, tone: AtomTone.green),
  };
}

/// The big line in the header: "Paid until 30 Nov", "Free trial until
/// 20 Nov", "Free until 31 Dec 2026" or "No plan yet".
String planHeadline(AppLocalizations l, BillingOverview p) {
  if (p.accessState == AccountStatus.noPlan || p.status == PlanStatus.none) {
    if (p.legacyUntil case final d?) return l.acctFreeUntil(AtomDates.day(d));
    return l.acctNoPlanYet;
  }
  if (p.status == PlanStatus.trial && p.trialEndsOn != null) {
    return l.acctFreeTrialUntil(AtomDates.short(p.trialEndsOn!));
  }
  final until = p.paidUntil ?? p.periodEndsOn;
  if (until != null) return l.acctPaidUntilDay(AtomDates.short(until));
  if (p.legacyUntil case final d?) return l.acctFreeUntil(AtomDates.day(d));
  return p.package?.name ?? l.planTitle;
}

/// "Basic package · Multi-outlet · 3 outlets".
String planSummary(AppLocalizations l, BillingOverview p) => [
  p.package?.name ?? l.acctBasicPackage,
  p.multiOutlet ? l.acctMultiOutlet : l.acctSingleOutlet,
  if (p.multiOutlet && p.outlets > 0) l.acctOutletCount(p.outlets),
].join(' · ');

/// Days from [today] to [day], never below zero.
int daysLeft(DateTime day, DateTime today) =>
    AtomDates.daysFrom(day, today: today).clamp(0, 100000);

/// "17 days left", "Ends today".
String daysLeftLabel(AppLocalizations l, DateTime day, DateTime today) {
  final n = daysLeft(day, today);
  return n == 0 ? l.acctEndsToday : l.acctDaysLeft(n);
}

/// The add-on row's badge and second line (12.6): Free trial · N days
/// left, Free until 31 Dec 2026, On, Stops 30 Nov, Ended, Off.
({String badge, AtomTone tone, String sub}) addonRow(
  AppLocalizations l,
  BillingAddon a, {
  required DateTime today,
}) {
  final about = a.description ?? '';
  switch (a.state) {
    case AddonState.legacy:
      final until = a.legacyUntil ?? a.endsOn;
      return (
        badge: l.acctFree,
        tone: AtomTone.blue,
        sub: until == null ? about : l.acctFreeUntil(AtomDates.day(until)),
      );
    case AddonState.trial:
      final ends = a.endsOn;
      return (
        badge: l.acctFreeTrial,
        tone: AtomTone.amber,
        sub: ends == null
            ? l.acctFreeTrial
            : a.renew
            ? l.acctFreeTrialLeft(daysLeftLabel(l, ends, today))
            : l.acctTrialStops(AtomDates.short(ends)),
      );
    case AddonState.active:
      if (a.stopping) {
        return (
          badge: l.acctOn,
          tone: AtomTone.green,
          sub: l.acctSwitchedOffUntil(AtomDates.short(a.endsOn!)),
        );
      }
      return (badge: l.acctOn, tone: AtomTone.green, sub: about);
    case AddonState.lapsed:
      return (badge: l.acctEnded, tone: AtomTone.rose, sub: about);
    case AddonState.off:
      return (badge: l.acctOff, tone: AtomTone.grey, sub: about);
  }
}

/// What Switch an add-on on (12.7) offers for [a].
enum AddonChoice {
  /// First time on: a free trial ("Try it free for 15 days").
  tryFree,

  /// Trial used: on now, a bill for the rest of the period.
  payNow,

  /// On: switching it off.
  switchOff,

  /// Switched off but still running: keep it on after all.
  keepOn,
}

/// The one thing 12.7 can do for [a]: the server decides trial or bill by
/// itself (`POST billing/addons/{key}` with `on`), so the app only says
/// which will happen.
AddonChoice addonChoice(BillingAddon a) {
  if (a.stopping) return AddonChoice.keepOn;
  if (a.on) return AddonChoice.switchOff;
  return a.trialAvailable ? AddonChoice.tryFree : AddonChoice.payNow;
}

/// The add-ons a renewal starts with: the ones on and carrying on.
Set<String> defaultRenewalAddons(BillingOverview p) => {
  for (final a in p.addons)
    if (a.on && a.renew && a.state != AddonState.legacy) a.key,
};

/// The period a renewal starts on: the account's own when it is offered,
/// else the shortest on offer.
int defaultPeriod(BillingOverview p) {
  final offer = p.periodsOnOffer;
  if (offer.isEmpty) return 1;
  final mine = p.periodMonths;
  return mine != null && offer.contains(mine) ? mine : offer.first;
}

/// An add-on that can't be bought for [months] (no price), so its box is
/// off for that period.
bool addonOffered(BillingOverview p, String key, int months) =>
    p.item(key)?.priceFor(months) != null;

/// "December renewal" for a bill: the month it pays for, else its kind.
String billTitle(AppLocalizations l, Invoice b) {
  final from = b.coversFrom;
  final kind = b.kindLabel ?? l.acctBill;
  if (from == null) return kind;
  final month = DateFormat('MMMM').format(from);
  return b.kind == 'package' ? l.acctRenewal(month) : '$kind · $month';
}

/// "To pay", "Part paid", "Paid", "Cancelled", "Late".
({String label, AtomTone tone}) billStatus(AppLocalizations l, Invoice b) =>
    switch (b.status) {
      InvoiceStatus.paid => (label: l.acctPaid, tone: AtomTone.green),
      InvoiceStatus.voided => (label: l.acctCancelled, tone: AtomTone.grey),
      InvoiceStatus.partPaid => (label: l.acctPartPaid, tone: AtomTone.amber),
      _ when b.overdue => (label: l.acctLate, tone: AtomTone.rose),
      _ => (label: l.acctToPay, tone: AtomTone.amber),
    };

/// "Being checked", "Received", "Not found", "Reversed".
({String label, AtomTone tone}) paymentStatus(
  AppLocalizations l,
  BillPayment p,
) => switch (p.status) {
  PaymentStatus.received => (label: l.acctReceived, tone: AtomTone.green),
  PaymentStatus.rejected => (label: l.acctNotFound, tone: AtomTone.rose),
  PaymentStatus.reversed => (label: l.acctReversed, tone: AtomTone.rose),
  PaymentStatus.pending => (label: l.acctBeingChecked, tone: AtomTone.blue),
};

/// The methods "I've paid" offers, in the canvas's order, labelled short
/// ("Bank", not "Bank transfer").
List<({String key, String label})> payMethods(
  AppLocalizations l,
  Map<String, String> methods,
) {
  const order = ['bank', 'jazzcash', 'easypaisa', 'cash', 'cheque'];
  final short = {
    'bank': l.acctBank,
    'jazzcash': l.acctJazzCash,
    'easypaisa': l.acctEasypaisa,
    'cash': l.acctCash,
    'cheque': l.acctCheque,
  };
  final keys = [...(methods.isEmpty ? order : methods.keys)];
  keys.sort((a, b) {
    final ia = order.indexOf(a), ib = order.indexOf(b);
    return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
  });
  return [for (final k in keys) (key: k, label: short[k] ?? methods[k] ?? k)];
}

/// Why "Send payment" (12.8) can't go yet, or null: the server's own rules
/// (`BrandBillingService::PAY_RULES`).
String? payProblem(
  AppLocalizations l, {
  required int? amount,
  required String? method,
  required DateTime? paidOn,
  required bool hasScreenshot,
  required DateTime today,
  String reference = '',
}) {
  if (method == null) return l.acctPayNoMethod;
  if (amount == null || amount < 1) return l.acctPayNoAmount;
  if (amount > 10000000) return l.acctPayTooLarge;
  if (paidOn == null) return l.acctPayNoDay;
  final day = DateTime(paidOn.year, paidOn.month, paidOn.day);
  final now = DateTime(today.year, today.month, today.day);
  if (day.isAfter(now)) return l.acctPayFutureDay;
  if (reference.trim().length > 100) {
    return l.acctPayRefTooLong;
  }
  if (!hasScreenshot) return l.acctPayNoScreenshot;
  return null;
}
