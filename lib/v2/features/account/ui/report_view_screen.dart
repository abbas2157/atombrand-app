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
import '../../sync/ui/offline_bar.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/reports_repository.dart';
import 'account_parts.dart';

/// One report (12.5): the period tabs, the summary strip, the Outlet and
/// Method pills, its chart, its table, and Excel / PDF for people with
/// `money.export`.
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

  Future<void> _pickOutlet(List<Outlet> outlets) async {
    final l = AppLocalizations.of(context);
    final id = await showAtomSelect<int>(
      context,
      title: l.acctWhichOutlet,
      selected: _filter.outletId ?? 0,
      options: [
        AtomOption(value: 0, label: l.outletAll),
        for (final o in outlets) AtomOption(value: o.id, label: o.name),
      ],
    );
    if (id == null || !mounted) return;
    setState(
      () => _filter = _filter.copyWith(outletId: () => id == 0 ? null : id),
    );
  }

  Future<void> _pickMethod(Map<String, String> methods) async {
    final l = AppLocalizations.of(context);
    final key = await showAtomSelect<String>(
      context,
      title: l.accountReportWhichMethod,
      selected: _filter.method ?? '',
      options: [
        AtomOption(value: '', label: l.accountReportMethodAny),
        for (final e in methods.entries)
          AtomOption(value: e.key, label: e.value),
      ],
    );
    if (key == null || !mounted) return;
    setState(
      () => _filter = _filter.copyWith(method: () => key.isEmpty ? null : key),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final key = widget.reportKey;
    final data = ref.watch(reportProvider((key, _filter)));
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
          const OfflineBar(),
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
                        icon: LucideIcons.chartColumn,
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
        ],
      ),
    );
  }

  Widget _body(ReportData r) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider.notifier).current;
    final online = ref.watch(onlineProvider).value ?? true;
    final canExport = session?.who.can(BrandPermission.moneyExport) ?? false;
    final outlets = (session?.multiOutlet ?? false)
        ? session!.outlets
        : const <Outlet>[];
    final table = r.phoneTableData;
    final empty = table == null || table.rows.isEmpty;
    final chart = r.charts.firstOrNull;
    final methodName = r.methods[_filter.method];
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterPill(
              label: l.acctOutletIs(r.outletName ?? l.outletAll),
              onTap: outlets.length > 1 ? () => _pickOutlet(outlets) : null,
            ),
            if (r.methods.isNotEmpty)
              _FilterPill(
                label: l.accountReportMethodIs(
                  methodName ?? l.accountReportMethodAny,
                ),
                onTap: () => _pickMethod(r.methods),
              ),
          ],
        ),
        if (chart != null && !empty) ...[
          const SizedBox(height: 10),
          _Chart(chart: chart),
        ],
        const SizedBox(height: 10),
        if (empty)
          AtomMessageState(
            icon: LucideIcons.chartColumn,
            title: l.acctNothingThisPeriod,
            body: l.acctTryAnotherPeriod,
          )
        else
          _Table(table: table, atompay: r.key == 'atompay'),
        if (r.note != null) ...[
          const SizedBox(height: 10),
          AtomNote(kind: AtomNoteKind.info, message: r.note!),
        ],
        if (canExport) ...[
          const SizedBox(height: 10),
          // `.share`: Excel 1.3fr, PDF 1fr, 44 high.
          Row(
            children: [
              Expanded(
                flex: 13,
                child: AtomButton(
                  label: online ? l.acctExcel : l.acctExcelOnline,
                  kind: AtomButtonKind.outline,
                  compact: true,
                  saving: _busy == ReportFormat.excel,
                  onPressed: online && _busy == null
                      ? () => _download(ReportFormat.excel, r.title)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 10,
                child: AtomButton(
                  label: l.acctPdf,
                  icon: AtomBrandIcons.whatsapp,
                  kind: AtomButtonKind.whatsapp,
                  compact: true,
                  saving: _busy == ReportFormat.pdf,
                  onPressed: _busy == null ? () => _sharePdf(r) : null,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// `.pill.grey`: a filter as a pill; tapping it opens the choices.
class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = AtomPill(label: label);
    if (onTap == null) return pill;
    return AtomPressable(
      onTap: onTap,
      semanticLabel: label,
      builder: (_, _) => pill,
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
                  height: 96,
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
                                  : (96 * c.values[i] * scale).clamp(6, 96),
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

/// The report's table as `.tr` rows: three columns (1.1fr 1fr 1fr), the
/// first to the left, the second centred, the amount bold on the right.
/// Wider tables stay in the PDF and Excel. A row with a `uuid` opens its
/// order.
class _Table extends StatelessWidget {
  const _Table({required this.table, required this.atompay});
  final ReportTable table;
  final bool atompay;

  @override
  Widget build(BuildContext context) {
    final cols = table.phoneColumns;
    if (cols.isEmpty) return const SizedBox.shrink();
    const flex = [11, 10, 10];
    final last = cols.length - 1;
    Widget line(List<String> cells, {bool head = false, VoidCallback? onTap}) {
      final row = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                flex: flex[i.clamp(0, 2)],
                child: Text(
                  head ? cells[i].toUpperCase() : cells[i],
                  textAlign: i == 0
                      ? TextAlign.left
                      : i == last
                      ? TextAlign.right
                      : TextAlign.center,
                  style: head
                      ? AtomText.section.copyWith(fontSize: 11)
                      : AtomText.secondary.copyWith(
                          color: i == last && i > 0
                              ? AtomColors.ink
                              : AtomColors.text,
                          fontWeight: i == last && i > 0
                              ? FontWeight.w700
                              : null,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                ),
              ),
            ],
          ],
        ),
      );
      return Material(
        color: head ? AtomColors.head : AtomColors.paper,
        child: onTap == null ? row : InkWell(onTap: onTap, child: row),
      );
    }

    final rows = <Widget>[
      line([for (final c in cols) c.label], head: true),
      for (final r in table.rows)
        line(
          [for (final c in cols) formatCell(r[c.key], c.type)],
          onTap: switch (r['uuid']) {
            final String uuid when uuid.isNotEmpty => () => context.push(
              atompay ? V2Routes.atompayOf(uuid) : V2Routes.orderOf(uuid),
            ),
            _ => null,
          },
        ),
    ];
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AtomDecor.card,
      foregroundDecoration: AtomDecor.cardOutline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, r) in rows.indexed) ...[
            if (i > 0) const Divider(height: 1, color: AtomColors.line),
            r,
          ],
        ],
      ),
    );
  }
}
