import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/net/network_status.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../sync/ui/offline_bar.dart';
import '../data/reports_repository.dart';
import 'account_parts.dart';

/// Reports (12.4, `money.reports`): the period tabs, the four headline
/// numbers with the line under each, then each report the person can
/// open, grouped. Every figure is the server's.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

const _tabs = [
  ReportPeriod.today,
  ReportPeriod.month,
  ReportPeriod.year,
  ReportPeriod.custom,
];

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportFilter _filter = const ReportFilter();

  Future<void> _tab(int i) async {
    final period = _tabs[i];
    if (period != ReportPeriod.custom) {
      setState(() => _filter = _filter.copyWith(period: period));
      return;
    }
    final now = AtomDates.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _filter.from != null && _filter.to != null
          ? DateTimeRange(start: _filter.from!, end: _filter.to!)
          : DateTimeRange(start: DateTime(now.year, now.month), end: now),
      helpText: AppLocalizations.of(context).acctPeriodCustom,
    );
    if (range == null || !mounted) return;
    setState(
      () => _filter = _filter.copyWith(
        period: ReportPeriod.custom,
        from: () => range.start,
        to: () => range.end,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(reportsHomeProvider(_filter));
    final who = ref.watch(sessionProvider.notifier).current?.who;
    final canExport = who?.can(BrandPermission.moneyExport) ?? false;
    final online = ref.watch(onlineProvider).value ?? true;
    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtomPageHeader(
            title: l.menuReports,
            leading: AtomIconButton(
              icon: LucideIcons.chevronLeft,
              label: l.commonBack,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            tabs: [for (final t in _tabs) AtomHeaderTab(t.label(l))],
            selectedTab: _tabs.indexOf(_filter.period),
            onTab: _tab,
          ),
          const OfflineBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(reportsHomeProvider(_filter).future),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  ...switch (data) {
                    AsyncValue(value: final h?) => _body(h, canExport, online),
                    AsyncError(:final error) => [
                      AccountError(
                        error: error,
                        onRetry: () =>
                            ref.invalidate(reportsHomeProvider(_filter)),
                      ),
                    ],
                    _ => const [
                      SizedBox(height: 16),
                      AtomLoadingCard(count: 4),
                    ],
                  },
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _periodLabel(AppLocalizations l, ReportsHome h) =>
      switch (_filter.period) {
        ReportPeriod.custom when _filter.from != null && _filter.to != null =>
          l.acctDateRange(
            AtomDates.short(_filter.from!),
            AtomDates.short(_filter.to!),
          ),
        // The board names the tab ("Sales · This month"), not the month.
        final p => p.label(l),
      };

  List<Widget> _body(ReportsHome h, bool canExport, bool online) {
    final t = h.periods[_filter.period.key] ?? const ReportTotals();
    final access = ref.watch(accessProvider);
    final l = AppLocalizations.of(context);
    return [
      AccountLabel(l.acctSalesPeriod(_periodLabel(l, h))),
      AtomKpiGrid(
        kpis: [
          AtomKpi(
            label: l.acctCashOrders,
            value: formatRs(t.cashSales),
            note: _count(t.cashOrders, l.accountReportOrders),
          ),
          AtomKpi(
            label: l.acctPaymentsReceived,
            value: formatRs(t.received),
            note: t.stillDue == null
                ? null
                : l.accountReportStillDue(formatRs(t.stillDue!)),
          ),
          AtomKpi(
            label: l.acctAtompayPaid,
            value: formatRs(t.atompayPaid),
            note: _count(t.atompayUnits, l.accountReportUnits),
          ),
          AtomKpi(
            label: l.acctBulkWon,
            value: formatRs(t.bulkWon),
            note: _count(t.bulkDeals, l.accountReportDeals),
          ),
        ],
      ),
      for (final (group, cards) in h.groups)
        if (cards.any((c) => _shown(c, access))) ...[
          AccountLabel(group.isEmpty ? l.menuReports : group),
          AccountCard(
            children: [
              for (final c in cards)
                if (_shown(c, access))
                  _ReportRow(
                    card: c,
                    onTap: () => context.push(
                      Uri(
                        path: V2Routes.reportOf(c.key),
                        queryParameters: {
                          if (_filter.period != ReportPeriod.custom)
                            'period': _filter.period.key,
                          if (_filter.outletId != null)
                            'outlet': '${_filter.outletId}',
                        },
                      ).toString().replaceFirst(RegExp(r'\?$'), ''),
                    ),
                  ),
            ],
          ),
        ],
      if (h.reports.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: AtomMessageState(
            icon: LucideIcons.chartColumn,
            title: l.acctNoReports,
            body: l.acctNoReportsBody,
          ),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 12, 2, 0),
        child: Text(
          !online
              ? l.acctReportsOffline
              : canExport
              ? l.acctReportsCanExport
              : l.acctReportsNoExport,
          style: AtomText.small.copyWith(color: AtomColors.faint),
        ),
      ),
    ];
  }

  /// "18 orders"; "None today" for nothing today; null when not sent.
  String? _count(int? n, String Function(int) say) {
    if (n == null) return null;
    if (n == 0 && _filter.period == ReportPeriod.today) {
      return AppLocalizations.of(context).accountReportNoneToday;
    }
    return say(n);
  }

  /// The server lists only what the brand and person may open; the stock
  /// report also needs the Inventory add-on on this phone's view.
  bool _shown(ReportCard c, AccessState access) =>
      c.key != 'stock' || access.addons == null || access.has(Addon.inventory);
}

/// `.rp`: a report, what it holds, and a chevron.
class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.card, required this.onTap});
  final ReportCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AtomPressable(
      onTap: onTap,
      scaleOnPress: false,
      semanticLabel: [card.title, ?card.description].join(', '),
      builder: (_, pressed) => Container(
        color: pressed ? AtomColors.head : AtomColors.paper,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: ExcludeSemantics(
          child: Row(
            children: [
              const AtomIconTile(
                icon: LucideIcons.chartColumn,
                tone: AtomTone.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.title, style: AtomText.listTitle),
                    if (card.description != null)
                      Text(card.description!, style: AtomText.small),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: AtomIcon.setRow,
                color: AtomColors.chevron,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
