import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/money.dart';
import '../../../core/net/network_status.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/billing_models.dart';
import '../data/billing_repository.dart';
import '../data/plan_logic.dart';

/// Renew or change your plan (from 12.6): how long, which add-ons, the
/// total as Atomshop works it out (`POST billing/quote`), then Get my bill
/// (`POST billing/checkout`).
Future<void> showChoosePlanSheet(
  BuildContext context, {
  required BillingOverview plan,
}) => showAtomSheet<void>(
  context,
  expand: true,
  builder: (_) => ChoosePlanSheet(plan: plan),
);

class ChoosePlanSheet extends ConsumerStatefulWidget {
  const ChoosePlanSheet({super.key, required this.plan});
  final BillingOverview plan;

  @override
  ConsumerState<ChoosePlanSheet> createState() => _ChoosePlanSheetState();
}

class _ChoosePlanSheetState extends ConsumerState<ChoosePlanSheet> {
  late int _months = defaultPeriod(widget.plan);
  late Set<String> _addons = defaultRenewalAddons(widget.plan);
  PlanQuote? _quote;
  String? _quoteError;
  bool _quoting = false;
  bool _saving = false;
  Timer? _debounce;

  /// Answers that arrive after a newer question are dropped.
  int _asked = 0;

  @override
  void initState() {
    super.initState();
    _ask();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// The add-ons that can be chosen: every add-on the app knows with a
  /// price for some period.
  List<BillingAddon> get _choosable => [
    for (final a in widget.plan.addons)
      if (a.addon != null &&
          (widget.plan.item(a.key)?.prices.isNotEmpty ?? false))
        a,
  ];

  /// Only add-ons priced for the period go to the quote.
  Set<String> get _chosen => {
    for (final k in _addons)
      if (addonOffered(widget.plan, k, _months)) k,
  };

  void _changed() {
    _debounce?.cancel();
    setState(() => _quoting = true);
    _debounce = Timer(const Duration(milliseconds: 300), _ask);
  }

  Future<void> _ask() async {
    final asked = ++_asked;
    setState(() => _quoting = true);
    final r = await ref.read(billingRepositoryProvider).quote(_months, _chosen);
    if (!mounted || asked != _asked) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _quoting = false;
      switch (r) {
        case ApiOk(:final value):
          _quote = value;
          _quoteError = null;
        case ApiErr(:final failure):
          _quote = null;
          _quoteError =
              failure.fieldErrors.values.firstOrNull ?? sayFailure(l, failure);
      }
    });
  }

  Future<void> _checkout() async {
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    final r = await ref
        .read(billingRepositoryProvider)
        .checkout(_months, _chosen);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (r) {
      case ApiOk(value: final bill):
        ref.invalidate(billingProvider);
        unawaited(ref.read(accessProvider.notifier).refresh());
        final router = GoRouter.of(context);
        final paid = bill.status == InvoiceStatus.paid || bill.due <= 0;
        // The toast first: this sheet's context is gone once it closes.
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: paid ? l.acctPlanOn : l.acctBillReadyDot(bill.number),
        );
        Navigator.of(context).pop();
        if (!paid) router.push(V2Routes.paidOf(bill: bill.number));
      case ApiErr(:final failure):
        showAtomToast(
          context,
          kind: AtomToastKind.bad,
          message:
              failure.fieldErrors.values.firstOrNull ?? sayFailure(l, failure),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = widget.plan;
    final online = ref.watch(onlineProvider).value ?? true;
    final periods = p.periodsOnOffer;
    final q = _quote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtomSheetHeader(title: l.acctRenewTitle),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            children: [
              AtomSectionLabel(l.acctHowLong, page: false),
              if (periods.length >= 2 && periods.length <= 4)
                AtomChips<int>(
                  chips: [
                    for (final m in periods) AtomChip(m, periodLabel(l, m)),
                  ],
                  selected: _months,
                  onChanged: (m) {
                    _months = m;
                    _changed();
                  },
                )
              else
                Text(periodLabel(l, _months), style: AtomText.listTitle),
              if (_choosable.isNotEmpty) ...[
                const SizedBox(height: 8),
                AtomSectionLabel(l.acctAddons, page: false),
                for (final a in _choosable) ...[
                  _AddonChoice(
                    addon: a,
                    price: p.item(a.key)?.priceFor(_months),
                    selected: _addons.contains(a.key),
                    onTap: addonOffered(p, a.key, _months)
                        ? () {
                            _addons = {..._addons};
                            if (!_addons.remove(a.key)) _addons.add(a.key);
                            _changed();
                          }
                        : null,
                    months: _months,
                  ),
                  const SizedBox(height: 8),
                ],
              ],
              AtomSectionLabel(l.acctYourBill, page: false),
              if (_quoteError != null)
                AtomNote(kind: AtomNoteKind.problem, message: _quoteError!)
              else if (q == null)
                const AtomLoadingRows(count: 2)
              else
                AnimatedOpacity(
                  opacity: _quoting ? .5 : 1,
                  duration: const Duration(milliseconds: 150),
                  child: _QuoteCard(quote: q),
                ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!online)
                AtomButtonReason(reason: l.syncNeedsInternet)
              else if (_quoteError != null)
                AtomButtonReason(reason: l.acctChangePeriod),
              AtomButton(
                label: q == null || q.total <= 0
                    ? l.acctGetBill
                    : l.acctGetBillTotal(formatRs(q.total)),
                saving: _saving,
                onPressed:
                    online && q != null && !_quoting && _quoteError == null
                    ? _checkout
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddonChoice extends StatelessWidget {
  const _AddonChoice({
    required this.addon,
    required this.price,
    required this.selected,
    required this.onTap,
    required this.months,
  });

  final BillingAddon addon;
  final int? price;
  final bool selected;
  final VoidCallback? onTap;
  final int months;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final sub = price == null
        ? l.acctNotSoldFor(periodLabel(l, months))
        : l.acctPriceFor(formatRs(price!), periodLabel(l, months));
    return Opacity(
      opacity: onTap == null ? .55 : 1,
      child: AtomOptionCard(
        title: addon.name,
        subtitle: sub,
        multi: true,
        selected: selected && onTap != null,
        onTap: onTap ?? () {},
      ),
    );
  }
}

/// The quote's lines, any special price and credit, and the total.
class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});
  final PlanQuote quote;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final q = quote;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: AtomDecor.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final line in q.lines)
            AtomInfoLine(label: line.description, value: formatRs(line.amount)),
          if (q.discount > 0)
            AtomInfoLine(
              label: l.acctSpecialPrice,
              value: formatRs(-q.discount),
              valueColor: AtomColors.green,
            ),
          if (q.credit > 0)
            AtomInfoLine(
              label: l.acctYourCredit,
              value: formatRs(-q.credit),
              valueColor: AtomColors.green,
            ),
          const Divider(height: 1, color: AtomColors.line),
          AtomInfoLine(
            label: l.acctTotal,
            value: formatRs(q.total),
            total: true,
          ),
        ],
      ),
    );
  }
}
