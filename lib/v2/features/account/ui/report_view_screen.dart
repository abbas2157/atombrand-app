import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/api/api_result.dart';
import '../../../core/net/network_status.dart';
import '../../../core/pdf/phone_pdf.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/reports_repository.dart';
import 'account_parts.dart';

/// One report (12.5): the period tabs, the summary strip, its chart, its
/// table, and Excel / PDF for people with `money.export`.
class ReportViewScreen extends ConsumerStatefulWidget {
  const ReportViewScreen({
    super.key,
    required this.reportKey,
    this.period,
    this.outletId,
  });

  final String reportKey;

  /// The period Reports was on, when it is one of these tabs.
  final String? period;
  final int? outletId;

  @override
  ConsumerState<ReportViewScreen> createState() => _ReportViewScreenState();
}

const _tabs = [
  ReportPeriod.today,
  ReportPeriod.month,
  ReportPeriod.year,
  ReportPeriod.all,
];

class _ReportViewScreenState extends ConsumerState<ReportViewScreen> {
  late ReportFilter _filter = ReportFilter(
    period: switch (ReportPeriod.values
        .where((p) => p.key == widget.period)
        .firstOrNull) {
      final p? when _tabs.contains(p) => p,
      _ => reportDefaultPeriod(widget.reportKey),
    },
    outletId: widget.outletId,
  );
  ReportFormat? _busy;

  /// PDF: laid out on the phone from the report on screen (the server
  /// sends reports as data), shared on WhatsApp.
  Future<void> _sharePdf(ReportData report) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = ReportFormat.pdf);
    final brand = ref.read(sessionProvider.notifier).current?.brandName;
    try {
      final bytes = await buildReportPdf(reportSheet(l, report, brand: brand));
      await Printing.sharePdf(bytes: bytes, filename: '${report.title}.pdf');
    } on Object {
      if (mounted) {
        showAtomToast(
          context,
          kind: AtomToastKind.bad,
          message: l.acctPdfFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _download(ReportFormat format, String title) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = format);
    final r = await ref
        .read(reportsRepositoryProvider)
        .export(widget.reportKey, _filter, format);
    if (!mounted) return;
    setState(() => _busy = null);
    switch (r) {
      case ApiOk(:final value):
        final name =
            value.filename ??
            '$title.${format == ReportFormat.pdf ? 'pdf' : 'xlsx'}';
        if (format == ReportFormat.pdf) {
          await Printing.sharePdf(bytes: value.bytes, filename: name);
        } else {
          await SharePlus.instance.share(
            ShareParams(
              files: [
                XFile.fromData(
                  value.bytes,
                  name: name,
                  mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                ),
              ],
              fileNameOverrides: [name],
            ),
          );
        }
      case ApiErr(:final failure):
        showAtomToast(
          context,
          kind: AtomToastKind.bad,
          message: failure.kind == ApiFailureKind.notFound
              ? l.acctDownloadsOnPortal
              : sayFailure(l, failure),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final key = widget.reportKey;
    final data = ref.watch(reportProvider((key, _filter)));
    final online = ref.watch(onlineProvider).value ?? true;
    final who = ref.watch(sessionProvider.notifier).current?.who;
    final canExport = who?.can(BrandPermission.moneyExport) ?? false;
    final report = data.value;
    final dated = !reportIgnoresDates(key);
    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtomPageHeader(
            title: report?.title ?? l.acctReport,
            leading: AtomIconButton(
              icon: LucideIcons.chevronLeft,
              label: l.commonBack,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            tabs: dated
                ? [for (final t in _tabs) AtomHeaderTab(t.label(l))]
                : null,
            selectedTab: dated ? _tabs.indexOf(_filter.period).clamp(0, 3) : 0,
            onTab: dated
                ? (i) => setState(
                    () => _filter = _filter.copyWith(period: _tabs[i]),
                  )
                : null,
          ),
          if (report != null && report.summary.isNotEmpty)
            AtomSummaryBar(
              items: [
                for (final s in report.summary.take(3)) (s.label, s.value),
              ],
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.refresh(reportProvider((key, _filter)).future),
              child: switch (data) {
                AsyncValue(value: final r?) => _body(r),
                AsyncError(:final error) => ListView(
                  children: [
                    if (error is ApiFailure &&
                        error.kind == ApiFailureKind.notFound)
                      AtomMessageState(
                        icon: LucideIcons.fileChartColumn,
                        title: l.acctReportMissing,
                      )
                    else
                      AccountError(
                        error: error,
                        onRetry: () =>
                            ref.invalidate(reportProvider((key, _filter))),
                      ),
                  ],
                ),
                _ => ListView(
                  padding: const EdgeInsets.all(16),
                  children: const [AtomLoadingCard(count: 5)],
                ),
              },
            ),
          ),
          if (report != null && canExport)
            Container(
              decoration: const BoxDecoration(
                color: AtomColors.paper,
                border: Border(top: BorderSide(color: AtomColors.line)),
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                10 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AtomButton(
                      label: online ? l.acctExcel : l.acctExcelOnline,
                      kind: AtomButtonKind.outline,
                      saving: _busy == ReportFormat.excel,
                      onPressed: online && _busy == null
                          ? () => _download(ReportFormat.excel, report.title)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AtomButton(
                      label: l.acctPdf,
                      icon: AtomBrandIcons.whatsapp,
                      kind: AtomButtonKind.whatsapp,
                      saving: _busy == ReportFormat.pdf,
                      onPressed: _busy == null ? () => _sharePdf(report) : null,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(ReportData r) {
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (r.periodLabel != null && !reportIgnoresDates(r.key))
              AtomPill(label: r.periodLabel!),
            AtomPill(label: l.acctOutletIs(r.outletName ?? l.outletAll)),
          ],
        ),
        for (final c in r.charts.take(1)) ...[
          const SizedBox(height: 12),
          _Chart(chart: c),
        ],
        for (final t in r.tables) ...[
          const SizedBox(height: 4),
          if (r.tables.length > 1 && t.title.isNotEmpty) AccountLabel(t.title),
          if (r.tables.length == 1) const SizedBox(height: 8),
          _Table(table: t, atompay: r.key == 'atompay'),
        ],
        if (r.tables.every((t) => t.rows.isEmpty) && r.charts.isEmpty)
          AtomMessageState(
            icon: LucideIcons.fileChartColumn,
            title: l.acctNothingThisPeriod,
            body: l.acctTryAnotherPeriod,
          ),
        if (r.note != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: AtomNote(kind: AtomNoteKind.info, message: r.note!),
          ),
        if (r.madeAt != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 10, 2, 0),
            child: Text(
              l.acctMadeAt(r.madeAt!),
              style: AtomText.small.copyWith(color: AtomColors.faint),
            ),
          ),
      ],
    );
  }
}

/// A report's chart: bars by label, sideways for `hbar`.
class _Chart extends StatelessWidget {
  const _Chart({required this.chart});
  final ReportChart chart;

  @override
  Widget build(BuildContext context) {
    final c = chart;
    final n = c.values.length < c.labels.length
        ? c.values.length
        : c.labels.length;
    if (n == 0) return const SizedBox.shrink();
    final top = c.values.take(n).fold<num>(0, (m, v) => v > m ? v : m);
    final scale = top <= 0 ? 0.0 : 1 / top;
    String fmt(num v) => v == v.roundToDouble() ? '${v.round()}' : '$v';
    return Semantics(
      label:
          '${c.label}: ${[for (var i = 0; i < n; i++) '${c.labels[i]} ${fmt(c.values[i])}'].join(', ')}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: AtomDecor.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(c.label, style: AtomText.secondary),
              const SizedBox(height: 10),
              if (c.horizontal)
                for (var i = 0; i < n; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 96,
                          child: Text(
                            c.labels[i],
                            style: AtomText.small,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (_, box) => Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                height: 12,
                                width: box.maxWidth * c.values[i] * scale,
                                decoration: BoxDecoration(
                                  color: AtomColors.primary,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(fmt(c.values[i]), style: AtomText.small),
                      ],
                    ),
                  )
              else ...[
                SizedBox(
                  height: 110,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < n; i++)
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 14,
                              height: c.values[i] <= 0
                                  ? 0
                                  : (110 * c.values[i] * scale).clamp(4, 110),
                              decoration: const BoxDecoration(
                                color: AtomColors.primary,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (var i = 0; i < n; i++)
                      Expanded(
                        child: Text(
                          c.labels[i],
                          textAlign: TextAlign.center,
                          style: AtomText.small,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A report's table: the first column as the label, the rest beside it,
/// the totals at the foot. A row with a `uuid` opens its order.
class _Table extends StatelessWidget {
  const _Table({required this.table, required this.atompay});
  final ReportTable table;
  final bool atompay;

  @override
  Widget build(BuildContext context) {
    final t = table;
    if (t.columns.isEmpty) return const SizedBox.shrink();
    // Wide tables scroll sideways; narrow ones fill the card.
    final wide = t.columns.length > 3;
    Widget cell(
      String text,
      ReportColumn c, {
      bool head = false,
      bool bold = false,
    }) {
      final numeric = c.type != ColumnType.text && c.type != ColumnType.date;
      return Container(
        width: wide ? 120 : null,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        alignment: numeric ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          text,
          style: (head ? AtomText.small : AtomText.body).copyWith(
            fontWeight: head || bold ? FontWeight.w700 : null,
            color: head ? AtomColors.muted : AtomColors.ink,
          ),
          textAlign: numeric ? TextAlign.right : TextAlign.left,
        ),
      );
    }

    Widget line(List<Widget> cells, {VoidCallback? onTap, Color? fill}) {
      final row = Row(
        children: [for (final c in cells) wide ? c : Expanded(child: c)],
      );
      return Material(
        color: fill ?? AtomColors.paper,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: row,
          ),
        ),
      );
    }

    final rows = <Widget>[
      line([
        for (final c in t.columns) cell(c.label, c, head: true),
      ], fill: AtomColors.head),
      for (final r in t.rows)
        line(
          [for (final c in t.columns) cell(formatCell(r[c.key], c.type), c)],
          onTap: switch (r['uuid']) {
            final String uuid when uuid.isNotEmpty => () => context.push(
              atompay ? V2Routes.atompayOf(uuid) : V2Routes.orderOf(uuid),
            ),
            _ => null,
          },
        ),
      if (t.totals != null)
        line([
          for (final c in t.columns)
            cell(formatCell(t.totals![c.key], c.type), c, bold: true),
        ], fill: AtomColors.head),
    ];
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, r) in rows.indexed) ...[
          if (i > 0) const Divider(height: 1, color: AtomColors.line),
          r,
        ],
      ],
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AtomDecor.card,
      foregroundDecoration: AtomDecor.cardOutline,
      child: wide
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: t.columns.length * 120 + 16, child: body),
            )
          : body,
    );
  }
}
