import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/billing_models.dart';
import '../data/billing_repository.dart';
import '../data/plan_logic.dart';
import 'account_parts.dart';
import 'choose_plan_sheet.dart';

/// Plan & billing (12.6, owner): the state badge and the plan in the navy
/// header, four KPIs, the bill to pay, the add-ons, renewing, the payments
/// sent and the bills with their PDFs. How to pay Atomshop is on I've paid
/// (12.8). Every amount is Atomshop's.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(billingProvider);
    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: data.when(
        skipLoadingOnRefresh: true,
        loading: () => Column(
          children: [
            const _Head(plan: null),
            const Padding(
              padding: EdgeInsets.all(16),
              child: AtomLoadingCard(count: 4),
            ),
          ],
        ),
        error: (e, _) => Column(
          children: [
            const _Head(plan: null),
            Expanded(
              child: AccountError(
                error: e,
                onRetry: () => ref.invalidate(billingProvider),
              ),
            ),
          ],
        ),
        data: (p) => Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => ref.refresh(billingProvider.future),
              child: ListView(
                padding: EdgeInsets.only(
                  bottom: 24 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  _Head(plan: p),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: _Body(plan: p),
                  ),
                ],
              ),
            ),
            const AtomNavyStatusStrip(),
          ],
        ),
      ),
    );
  }
}

/// Opens 12.8 for [bill].
void _pay(BuildContext context, Invoice? bill) =>
    context.push(V2Routes.paidOf(bill: bill?.number));

/// The navy header: ‹ Plan & billing and the state badge, then the plan.
class _Head extends StatelessWidget {
  const _Head({required this.plan});
  final BillingOverview? plan;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = plan;
    final badge = p == null ? null : planBadge(l, p);
    final pkg = p?.package;
    final months = p?.periodMonths;
    final price = months == null ? null : pkg?.priceFor(months);
    final open = p?.openInvoices.firstOrNull;
    return AtomNavyHeader(
      bottom: p == null ? 0 : 16,
      top: Row(
        children: [
          AtomNavyIconButton(
            icon: LucideIcons.chevronLeft,
            label: l.commonBack,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                l.planTitle,
                style: AtomText.heading.copyWith(color: Colors.white),
              ),
            ),
          ),
          if (badge != null) AtomPill(label: badge.label, tone: badge.tone),
        ],
      ),
      child: p == null
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AtomColors.nav2,
                borderRadius: BorderRadius.circular(AtomRadius.sheet),
                border: Border.all(color: AtomColors.navLine),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planSummary(l, p),
                    style: AtomText.secondary.copyWith(
                      color: AtomColors.navText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    planHeadline(l, p),
                    style: AtomText.successTitle.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (months != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      [
                        periodAdverb(l, months),
                        if (price != null) formatRs(price),
                        l.acctAddonsFollow,
                      ].join(' · '),
                      style: AtomText.secondary.copyWith(
                        color: AtomColors.navText,
                      ),
                    ),
                  ],
                  if (open != null && open.due > 0) ...[
                    const SizedBox(height: 12),
                    AtomButton(
                      label: l.acctPayAmount(formatRs(open.due)),
                      kind: AtomButtonKind.light,
                      expand: false,
                      onPressed: () => _pay(context, open),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.plan});
  final BillingOverview plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = plan;
    final today = AtomDates.now();
    final until = p.paidUntil ?? p.periodEndsOn ?? p.trialEndsOn;
    final open = p.openInvoices;
    final addons = p.addons.where((a) => a.addon != null).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (p.message != null && p.accessState != AccountStatus.ok) ...[
          AtomNote(
            kind: switch (p.accessState) {
              AccountStatus.readOnly => AtomNoteKind.problem,
              AccountStatus.late ||
              AccountStatus.overdue => AtomNoteKind.warning,
              _ => AtomNoteKind.info,
            },
            message: p.message!,
          ),
          const SizedBox(height: 14),
        ],
        AtomKpiGrid(
          kpis: [
            AtomKpi(
              valueSize: 16,
              label: l.acctPlan,
              value: p.periodMonths == null
                  ? (p.status == PlanStatus.trial
                        ? l.acctFreeTrial
                        : l.acctNoneYet)
                  : periodLabel(l, p.periodMonths!),
              note: p.multiOutlet ? l.acctMultiOutlet : l.acctSingleOutlet,
            ),
            AtomKpi(
              valueSize: 16,
              label: l.acctPaidUntil,
              value: until == null ? '—' : AtomDates.day(until),
              note: until == null
                  ? l.acctNoPlanYet
                  : daysLeftLabel(l, until, today),
            ),
            AtomKpi(
              valueSize: 16,
              label: l.acctAmountDue,
              value: formatRs(p.due),
              valueColour:
                  switch (p.accessState) {
                    AccountStatus.late ||
                    AccountStatus.overdue ||
                    AccountStatus.readOnly => true,
                    _ => false,
                  }
                  ? AtomColors.rose
                  : null,
              note: open.isEmpty
                  ? l.acctNothingToPay
                  : l.acctOpenBills(open.length),
            ),
            AtomKpi(
              valueSize: 16,
              label: l.acctCredit,
              value: formatRs(p.credit),
              note: p.discountPct > 0
                  ? l.acctSpecialPricePct(_pct(p.discountPct))
                  : l.acctNoSpecialPrice,
            ),
          ],
        ),
        if (open.isNotEmpty) ...[
          AccountLabel(l.acctToPay),
          for (final (i, b) in open.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            AccountActionCard(
              icon: LucideIcons.fileText,
              tone: AtomTone.amber,
              border: AtomColors.amberLine,
              title: b.number,
              sub: [
                billTitle(l, b),
                if (b.dueOn != null) l.acctDueOn(AtomDates.short(b.dueOn!)),
                formatRs(b.due),
              ].join(' · '),
              action: l.acctPay,
              onTap: () => _pay(context, b),
            ),
          ],
        ],
        if (addons.isNotEmpty) ...[
          AccountLabel(l.acctAddons),
          AccountCard(
            children: [
              for (final a in addons) _AddonRow(addon: a, today: today),
            ],
          ),
        ],
        // Always offered: the sheet asks Atomshop for the price, and says
        // so plainly when a period isn't sold.
        AccountLabel(l.acctRenewTitle),
        AccountActionCard(
          icon: LucideIcons.calendar,
          title: l.acctHowLongLine(
            _periodsLine(
              l,
              p.periodsOnOffer.isEmpty ? billingPeriods : p.periodsOnOffer,
            ),
          ),
          sub: l.acctRenewSub,
          action: l.commonChoose,
          onTap: () => showChoosePlanSheet(context, plan: p),
        ),
        AccountLabel(l.acctYourPayments),
        AccountCard(
          children: [
            if (p.payments.isEmpty) AccountLine(text: l.accountNoPaymentsYet),
            for (final pay in p.payments)
              AccountLine(
                text: [
                  if (pay.paidOn != null) AtomDates.short(pay.paidOn!),
                  pay.methodLabel ?? pay.method ?? '',
                  formatRs(pay.amountReceived ?? pay.amountClaimed),
                ].where((s) => s.isNotEmpty).join(' · '),
                sub: pay.status == PaymentStatus.rejected ? pay.reason : null,
                pill: AtomPill(
                  label: paymentStatus(l, pay).label,
                  tone: paymentStatus(l, pay).tone,
                ),
                linkLabel: pay.hasReceipt ? l.acctReceipt : null,
                onLink: pay.hasReceipt
                    ? () =>
                          shareServerPdf(context, ref, receiptPdf(pay.number!))
                    : null,
              ),
          ],
        ),
        AccountLabel(l.acctBills),
        AccountCard(
          children: [
            if (p.invoices.isEmpty) AccountLine(text: l.accountNoBillsYet),
            for (final b in p.invoices)
              AccountLine(
                bold: b.number,
                text: b.coversFrom == null
                    ? (b.kindLabel ?? '')
                    : b.kind == 'package'
                    ? DateFormat('MMMM').format(b.coversFrom!)
                    : billTitle(l, b),
                pill: AtomPill(
                  label: billStatus(l, b).label,
                  tone: billStatus(l, b).tone,
                ),
                linkLabel: l.acctPdf,
                onLink: () => shareServerPdf(context, ref, billPdf(b.number)),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
          child: Text(
            l.acctPricesNote,
            style: AtomText.small.copyWith(color: AtomColors.faint),
          ),
        ),
      ],
    );
  }
}

String _pct(double v) =>
    '${v == v.roundToDouble() ? v.round() : v.toStringAsFixed(1)}%';

/// "1, 3, 6 or 12 months".
String _periodsLine(AppLocalizations l, List<int> months) {
  if (months.length == 1) return periodLabel(l, months.first);
  final nums = months.map((m) => '$m').toList();
  return l.acctPeriodsOr(
    nums.sublist(0, nums.length - 1).join(', '),
    nums.last,
  );
}

/// `.ad`: an add-on, what it is or its state, and its badge. Opens 12.7.
class _AddonRow extends StatelessWidget {
  const _AddonRow({required this.addon, required this.today});
  final BillingAddon addon;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final a = addon;
    final row = addonRow(AppLocalizations.of(context), a, today: today);
    final key = a.addon!;
    return AtomPressable(
      onTap: () => context.push(V2Routes.addonSwitchOf(key)),
      scaleOnPress: false,
      semanticLabel: '${a.name}, ${row.badge}, ${row.sub}',
      builder: (_, pressed) => Container(
        color: pressed ? AtomColors.head : AtomColors.paper,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: ExcludeSemantics(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.name, style: AtomText.listTitle),
                    if (row.sub.isNotEmpty)
                      Text(row.sub, style: AtomText.small),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AtomPill(label: row.badge, tone: row.tone),
            ],
          ),
        ),
      ),
    );
  }
}

/// A label and a value with Copy (`.payee .line` on 12.8).
class CopyLine extends StatelessWidget {
  const CopyLine({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: AtomInfoLine(label: label, value: value),
        ),
        IconButton(
          tooltip: l.acctCopyLabel(label),
          icon: const Icon(
            LucideIcons.copy,
            size: AtomIcon.inline,
            color: AtomColors.primary,
          ),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (context.mounted) {
              showAtomToast(
                context,
                kind: AtomToastKind.ok,
                message: l.acctCopied(label),
              );
            }
          },
        ),
      ],
    );
  }
}
