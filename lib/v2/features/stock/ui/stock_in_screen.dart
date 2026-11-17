import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/format/dates.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../sync/data/offline_saves.dart';
import '../../sync/ui/offline_bar.dart';
import '../data/stock_models.dart';
import '../data/stock_repository.dart';
import '../data/stock_rules.dart';
import 'scanner.dart';
import 'stock_parts.dart';

/// 9.5 Stock in: units that arrived from the factory, into a warehouse,
/// one serial each (scanned or typed), or numbered by the server.
class StockInScreen extends ConsumerStatefulWidget {
  const StockInScreen({super.key, this.productId, this.serial});

  /// A stock product to start with (its first variant).
  final int? productId;

  /// A scanned serial that wasn't in stock.
  final String? serial;

  @override
  ConsumerState<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends ConsumerState<StockInScreen> {
  StockWarehouse? _warehouse;
  VariantOption? _variant;
  DateTime _receivedOn = DateTime.now();
  final _reference = TextEditingController();
  late final _serials = TextEditingController(text: widget.serial ?? '');
  final _qty = TextEditingController(text: '1');
  final _note = TextEditingController();
  bool _saving = false;
  bool _started = false;
  String? _serverError;

  @override
  void dispose() {
    _reference.dispose();
    _serials.dispose();
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  void _start(StockFormOptions o) {
    if (_started) return;
    _started = true;
    _warehouse =
        o.warehouses.where((w) => w.isDefault).firstOrNull ??
        o.warehouses.firstOrNull;
    if (widget.productId != null) {
      _variant = o.variants
          .where((v) => v.productId == widget.productId)
          .firstOrNull;
    }
  }

  Future<void> _scan() async {
    final codes = await scanCodes(
      context,
      many: true,
      imeiOnly: _variant?.tracking == Tracking.imei,
      title: AppLocalizations.of(context).stockScanEachBox,
    );
    if (codes.isEmpty || !mounted) return;
    final now = _serials.text.trimRight();
    setState(() {
      _serials.text = [if (now.isNotEmpty) now, ...codes].join('\n');
      _serverError = null;
    });
  }

  Future<void> _save(StockFormOptions o, {required bool another}) async {
    final l = AppLocalizations.of(context);
    final v = _variant!;
    final lines = checkSerials(
      l,
      splitSerials(_serials.text),
      v.tracking,
      inStock: _inStock(o),
    );
    final good = goodSerials(lines);
    final auto = v.tracking == Tracking.auto;
    final qty = auto ? (int.tryParse(_qty.text.trim()) ?? 0) : good.length;
    setState(() {
      _saving = true;
      _serverError = null;
    });
    final saved = await ref
        .read(stockRepositoryProvider)
        .stockIn(
          variantId: v.id,
          warehouseId: _warehouse!.id,
          qty: qty,
          receivedOn: _receivedOn,
          serials: auto ? const [] : good,
          reference: _reference.text,
          note: _note.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved case SaveFailed(:final failure)
        when failure.fieldErrors.isNotEmpty) {
      setState(
        () => _serverError =
            failure.fieldErrors['serials'] ?? failure.fieldErrors.values.first,
      );
      return;
    }
    final ok = sayStockSaved(context, saved, done: l.stockAddedUnits(qty));
    if (!ok) return;
    refreshStock(ref);
    if (another) {
      setState(() {
        _serials.clear();
        _qty.text = '1';
        _note.clear();
      });
    } else {
      context.pop();
    }
  }

  Set<String> _inStock(StockFormOptions o) => {
    for (final u in o.inStockUnits) u.serial.toUpperCase(),
  };

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(stockFormOptionsProvider);
    final dirty =
        _serials.text.trim().isNotEmpty || _reference.text.trim().isNotEmpty;
    return AtomUnsavedGuard(
      dirty: dirty && !_saving,
      child: Scaffold(
        backgroundColor: AtomColors.surface,
        body: Column(
          children: [
            StockFormBar(title: AppLocalizations.of(context).stockIn),
            const OfflineBar(),
            Expanded(
              child: options.when(
                loading: () => StockLoading(count: 3),
                error: (e, _) => StockFailed(
                  error: e,
                  onRetry: () => ref.invalidate(stockFormOptionsProvider),
                ),
                data: (o) {
                  _start(o);
                  return _form(o);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form(StockFormOptions o) {
    final l = AppLocalizations.of(context);
    final v = _variant;
    final w = _warehouse;
    final tracking = v?.tracking ?? Tracking.serial;
    final auto = tracking == Tracking.auto;
    final lines = checkSerials(
      l,
      splitSerials(_serials.text),
      tracking,
      inStock: _inStock(o),
    );
    final good = goodSerials(lines).length;
    final qty = int.tryParse(_qty.text.trim()) ?? 0;
    final problem = stockInProblem(
      l,
      warehouse: w,
      variant: v,
      serials: lines,
      autoQty: qty,
      max: o.maxStockIn,
    );
    final units = auto ? qty : good;
    final what = tracking == Tracking.imei ? l.stockImeis : l.stockSerials;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _FormCard(
          title: l.stockWhereArrived,
          children: [
            StockPickBox(
              label: l.stockWarehouse,
              text: w?.name,
              subtitle: w == null
                  ? null
                  : [
                      ?w.outlet,
                      w.sellsOnline
                          ? l.stockSellsOnAtomshop
                          : l.stockNotOnAtomshop,
                    ].join(' · '),
              onTap: () async {
                final picked = await showAtomSelect<int>(
                  context,
                  title: l.stockWarehouse,
                  selected: w?.id,
                  options: [
                    for (final x in o.warehouses)
                      AtomOption(
                        value: x.id,
                        label: x.name,
                        subtitle: x.outlet,
                      ),
                  ],
                );
                if (picked != null) {
                  setState(
                    () => _warehouse = o.warehouses.firstWhere(
                      (x) => x.id == picked,
                    ),
                  );
                }
              },
            ),
            // Received on and Reference side by side (`.two`), the hint
            // under both; stacked at large text.
            StockTwoUp(
              first: StockDayBox(
                label: l.stockReceivedOn,
                day: _receivedOn,
                onChanged: (d) => setState(() => _receivedOn = d),
              ),
              second: AtomTextField(
                label: l.stockReference,
                controller: _reference,
                placeholder: l.stockRefPlaceholder,
                inputFormatters: [LengthLimitingTextInputFormatter(40)],
                onChanged: (_) => setState(() {}),
              ),
            ),
            Text(
              l.stockRefHint,
              style: AtomText.secondary.copyWith(color: AtomColors.faint),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _FormCard(
          title: l.stockWhatArrived,
          children: [
            StockPickBox(
              label: l.stockProductVariant,
              text: v?.title,
              subtitle: v == null
                  ? null
                  : [
                      ?v.sku,
                      l.stockNumberedBy(v.tracking.label(l)),
                    ].join(' · '),
              onTap: () async {
                final picked = await showAtomSelect<int>(
                  context,
                  title: l.stockProductVariant,
                  selected: v?.id,
                  searchHint: l.stockProductOrSku,
                  options: [
                    for (final x in o.variants)
                      AtomOption(
                        value: x.id,
                        label: x.title,
                        subtitle: x.sku,
                        keywords: [?x.sku],
                      ),
                  ],
                );
                if (picked != null) {
                  setState(() {
                    _variant = o.variants.firstWhere((x) => x.id == picked);
                    _serverError = null;
                  });
                }
              },
            ),
            if (v != null && auto) ...[
              AtomTextField(
                label: l.stockHowMany,
                controller: _qty,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                hint: switch (autoNumbersPreview(l, v.nextAutoNumber, qty)) {
                  final s? => l.stockNumberedAs(s),
                  null => l.stockNextNumber,
                },
                error: _serverError,
                onChanged: (_) => setState(() => _serverError = null),
              ),
            ],
            if (v != null && !auto) ...[
              _ScanStrip(onTap: _scan),
              if (lines.isNotEmpty)
                StockCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 10, 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l.stockLinesN(what, lines.length),
                                style: AtomText.listTitle,
                              ),
                            ),
                            AtomButton.small(
                              label: l.commonClear,
                              onPressed: () => setState(() => _serials.clear()),
                            ),
                          ],
                        ),
                      ),
                      for (var i = lines.length - 1; i >= 0; i--)
                        _SerialRow(n: i + 1, line: lines[i]),
                    ],
                  ),
                ),
              AtomTextField(
                label: lines.isEmpty ? what : l.stockTypeMore,
                controller: _serials,
                minLines: 3,
                keyboardType: TextInputType.multiline,
                placeholder: l.stockOnePerLine,
                hint: l.stockPasteHint,
                error: _serverError,
                onChanged: (_) => setState(() => _serverError = null),
              ),
            ],
            AtomTextField(
              label: l.stockNote,
              labelNote: l.stockOptional,
              controller: _note,
              placeholder: l.stockNotePlaceholder,
              inputFormatters: [LengthLimitingTextInputFormatter(300)],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _FormCard(
          title: l.stockSummary,
          children: [
            StockLines(
              children: [
                StockLine(
                  label: l.stockInto,
                  value: stockValue(w?.name ?? '–'),
                ),
                StockLine(
                  label: l.stockProduct,
                  value: stockValue(v?.title ?? '–'),
                ),
                StockLine(label: l.stockUnits, value: stockValue('$units')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (problem != null) AtomButtonReason(reason: problem),
        AtomButton(
          label: l.stockAddToStock,
          saving: _saving,
          onPressed: problem == null ? () => _save(o, another: false) : null,
        ),
        const SizedBox(height: 10),
        AtomButton(
          label: l.stockAddAnother,
          kind: AtomButtonKind.outline,
          onPressed: problem == null && !_saving
              ? () => _save(o, another: true)
              : null,
        ),
        const SizedBox(height: 10),
        StockCancelButton(label: l.commonCancel),
        const SizedBox(height: 16),
        const _RecentStockIn(),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => StockCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        Semantics(header: true, child: Text(title, style: AtomText.listTitle)),
        ...children,
      ],
    ),
  );
}

/// The dark strip that opens the scanner for many boxes.
class _ScanStrip extends StatelessWidget {
  const _ScanStrip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AtomPressable(
    onTap: onTap,
    semanticLabel: AppLocalizations.of(context).stockScanNext,
    // `.strip`: 96 high, a 130×50 frame with the amber line, two lines.
    builder: (context, pressed) => Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pressed ? AtomColors.nav2 : AtomColors.nav,
        borderRadius: AtomRadius.brCard,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 130,
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AtomRadius.brControl,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: 2,
              ),
            ),
            child: Container(height: 2, color: AtomColors.amber),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              AppLocalizations.of(context).stockScanStrip,
              style: AtomText.secondary.copyWith(color: AtomColors.navText),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SerialRow extends StatelessWidget {
  const _SerialRow({required this.n, required this.line});

  final int n;
  final SerialLine line;

  @override
  Widget build(BuildContext context) {
    final bad = line.problem != null;
    return Container(
      color: bad ? AtomColors.roseSoft : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$n',
              style: AtomText.small.copyWith(color: AtomColors.faint),
            ),
          ),
          Expanded(
            child: Text(
              line.serial,
              style: AtomText.body.copyWith(
                color: bad ? AtomColors.rose : AtomColors.ink,
                decoration: bad ? TextDecoration.lineThrough : null,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (bad)
            Text(
              line.problem!,
              style: AtomText.small.copyWith(
                color: AtomColors.rose,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

/// The last few stock-ins (`stock/history?type=stock_in`).
class _RecentStockIn extends ConsumerWidget {
  const _RecentStockIn();

  static const _q = (
    type: 'stock_in',
    period: '30',
    search: '',
    outletId: null,
    productId: null,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(stockHistoryProvider(_q));
    final rows = data.value?.items;
    // Hidden while loading or when it can't be read; empty, it says so.
    if (rows == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    return StockBlock(
      title: l.stockRecentIn,
      trailing: AtomTextLink(
        label: l.stockAll,
        onTap: () => context.push(V2Routes.stockHistory),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Text(l.stockNoRecentIn, style: AtomText.small),
            ),
          for (final m in rows.take(3))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AtomColors.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          variantTitle(m.product ?? '', m.variant ?? ''),
                          style: AtomText.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AtomColors.ink,
                          ),
                        ),
                        Text(
                          [
                            ?m.warehouse,
                            if (m.date != null) AtomDates.short(m.date!),
                            ?m.by,
                          ].join(' · '),
                          style: AtomText.small,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    moveChange(m),
                    style: AtomText.money.copyWith(
                      color: AtomColors.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
