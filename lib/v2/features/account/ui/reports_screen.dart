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

/// Reports (12.4, `money.reports`): the period chips, the four headline
/// numbers, the last six months, then each report the person can open,
/// grouped. Every figure is the server's.
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
    final home = data.value;
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
                  if (home != null && home.outlets.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _OutletPick(
                      outlets: home.outlets,
                      value: _filter.outletId,
                      onChanged: (id) => setState(
                        () => _filter = _filter.copyWith(outletId: () => id),
                      ),
                    ),
                  ],
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
        final p => h.labels[p.key] ?? p.label(l),
      };

  List<Widget> _body(ReportsHome h, bool canExport, bool online) {
    final t = h.periods[_filter.period.key] ?? const ReportTotals();
    final access = ref.watch(accessProvider);
    final l = AppLocalizations.of(context);
    return [
      AccountLabel(l.acctSalesPeriod(_periodLabel(l, h))),
      AtomKpiGrid(
        kpis: [
          AtomKpi(label: l.acctCashOrders, value: formatRs(t.cashSales)),
          AtomKpi(label: l.acctPaymentsReceived, value: formatRs(t.received)),
          AtomKpi(label: l.acctAtompayPaid, value: formatRs(t.atompayPaid)),
          AtomKpi(label: l.acctBulkWon, value: formatRs(t.bulkWon)),
        ],
      ),
      if (h.months.isNotEmpty) ...[
        AccountLabel(l.acctLast6Months),
        _MonthsChart(months: h.months),
      ],
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

  /// The server lists only what the brand and person may open; the stock
  /// report also needs the Inventory add-on on this phone's view.
  bool _shown(ReportCard c, AccessState access) =>
      c.key != 'stock' || access.addons == null || access.has(Addon.inventory);
}

/// "Outlet: All outlets", opening the searchable list.
class _OutletPick extends StatelessWidget {
  const _OutletPick({
    required this.outlets,
    required this.value,
    required this.onChanged,
  });

  final List<({int id, String name})> outlets;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final name = outlets.where((o) => o.id == value).firstOrNull?.name;
    return AtomSelectField<int>(
      label: l.acctOutlet,
      value: value ?? 0,
      valueLabel: name ?? l.outletAll,
      sheetTitle: l.acctWhichOutlet,
      options: [
        AtomOption(value: 0, label: l.outletAll),
        for (final o in outlets) AtomOption(value: o.id, label: o.name),
      ],
      onChanged: (id) => onChanged(id == 0 ? null : id),
    );
  }
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
                icon: LucideIcons.fileChartColumn,
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

/// Six months as bars: cash orders, with received in a lighter bar beside.
class _MonthsChart extends StatelessWidget {
  const _MonthsChart({required this.months});
  final List<({String label, int cashSales, int received})> months;

  @override
  Widget build(BuildContext context) {
    final top = months.fold<int>(
      1,
      (m, x) => [m, x.cashSales, x.received].reduce((a, b) => a > b ? a : b),
    );
    final l = AppLocalizations.of(context);
    return Semantics(
      label: [
        for (final m in months)
          l.acctMonthSemantics(
            m.label,
            formatRs(m.cashSales),
            formatRs(m.received),
          ),
      ].join('; '),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          decoration: AtomDecor.card,
          child: Column(
            children: [
              SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final m in months)
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _Bar(
                              fraction: m.cashSales / top,
                              colour: AtomColors.primary,
                            ),
                            const SizedBox(width: 3),
                            _Bar(
                              fraction: m.received / top,
                              colour: AtomColors.chartBar,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final m in months)
                    Expanded(
                      child: Text(
                        m.label,
                        textAlign: TextAlign.center,
                        style: AtomText.small,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Key(colour: AtomColors.primary, label: l.acctCashOrders),
                  const SizedBox(width: 16),
                  _Key(colour: AtomColors.chartBar, label: l.acctReceived),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.colour});
  final double fraction;
  final Color colour;

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: fraction <= 0 ? 0 : (120 * fraction).clamp(4, 120),
    decoration: BoxDecoration(
      color: colour,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
    ),
  );
}

class _Key extends StatelessWidget {
  const _Key({required this.colour, required this.label});
  final Color colour;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: colour,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: AtomText.small),
    ],
  );
}
