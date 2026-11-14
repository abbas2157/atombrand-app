import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/session/session.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../sync/ui/offline_bar.dart';
import '../data/stock_models.dart';
import '../data/stock_repository.dart';
import '../data/stock_rules.dart';
import 'stock_parts.dart';

/// 9.4 Product stock: the figures, variants, where it is, its units, the
/// latest changes, the website and how its units are numbered.
class ProductStockScreen extends ConsumerStatefulWidget {
  const ProductStockScreen({super.key, required this.productId});

  /// The stock product (`GET stock` `items[].id`).
  final int productId;

  @override
  ConsumerState<ProductStockScreen> createState() => _ProductStockScreenState();
}

class _ProductStockScreenState extends ConsumerState<ProductStockScreen> {
  bool _delivered = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(productStockProvider(widget.productId));
    final who = stockWho(ref);
    final p = data.value;
    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        children: [
          AtomFlowBar(
            title: p?.title,
            trailing: [
              AtomIconButton(
                icon: LucideIcons.clock,
                label: l.stockHistoryTitle,
                onTap: () => context.push(
                  V2Routes.stockHistoryOf(productId: widget.productId),
                ),
              ),
              if (p?.catalogueProductId != null &&
                  (who?.can(BrandPermission.catalogueEdit) ?? false))
                AtomIconButton(
                  icon: LucideIcons.pencil,
                  label: l.stockEditProduct,
                  onTap: () => context.push(
                    V2Routes.productEditOf(p!.catalogueProductId!),
                  ),
                ),
            ],
          ),
          const OfflineBar(),
          Expanded(
            child: data.when(
              skipLoadingOnRefresh: true,
              loading: () => StockLoading(count: 4),
              error: (e, _) => StockFailed(
                error: e,
                onRetry: () =>
                    ref.invalidate(productStockProvider(widget.productId)),
              ),
              data: (p) => RefreshIndicator(
                onRefresh: () =>
                    ref.refresh(productStockProvider(widget.productId).future),
                child: _body(p, who),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(ProductStock p, Who? who) {
    final l = AppLocalizations.of(context);
    final onHand = p.variants.fold<int>(0, (s, v) => s + v.onHand);
    final held = p.variants.fold<int>(0, (s, v) => s + v.held);
    final available = p.variants.fold<int>(0, (s, v) => s + v.available);
    final stocked = p.warehouses.where((w) => w.onHand > 0).length;
    final canChange = canChangeStock(who, p.access);
    final inStock = [
      for (final u in p.units)
        if (!u.delivered) u,
    ];
    final delivered = [
      for (final u in p.units)
        if (u.delivered) u,
    ];
    final live = p.websiteStatus == 'Published';
    final online = p.variants.fold<int>(
      0,
      (s, v) => s + availableOnline(v, p.warehouses),
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        // the title block under the bar
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const AtomIconTile(
                icon: LucideIcons.package,
                tone: AtomTone.grey,
                size: 56,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title, style: AtomText.pageTitle),
                    Text(
                      [
                        ?p.prNumber,
                        l.stockNumberedBy(p.tracking.label(l)),
                      ].join(' · '),
                      style: AtomText.small,
                    ),
                  ],
                ),
              ),
              if (p.websiteStatus != null)
                AtomPill(
                  label: live ? l.stockLive : p.websiteStatus!,
                  tone: live ? AtomTone.green : AtomTone.grey,
                ),
            ],
          ),
        ),
        AtomKpiGrid(
          kpis: [
            AtomKpi(
              label: l.stockStateIn,
              value: '$onHand',
              note: l.stockWarehousesN(stocked),
            ),
            AtomKpi(
              label: l.stockHeldForOrders,
              value: '$held',
              note: l.stockOrdersAndDeals,
            ),
            AtomKpi(
              label: l.stockAvailable,
              value: '$available',
              note: l.stockCanSellNow,
            ),
            AtomKpi(label: l.stockDelivered90, value: '${p.delivered90}'),
          ],
        ),
        if (canChange) ...[
          const SizedBox(height: 12),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: AtomButton(
                  label: l.stockIn,
                  compact: true,
                  onPressed: () =>
                      context.push(V2Routes.stockIn(productId: p.id)),
                ),
              ),
              Expanded(
                child: AtomButton(
                  label: l.stockMove,
                  kind: AtomButtonKind.outline,
                  compact: true,
                  onPressed: () =>
                      context.push(V2Routes.moveStock(productId: p.id)),
                ),
              ),
              Expanded(
                child: AtomButton(
                  label: l.stockAdjust,
                  kind: AtomButtonKind.outline,
                  compact: true,
                  onPressed: () =>
                      context.push(V2Routes.adjustStock(productId: p.id)),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        StockBlock(
          title: l.stockVariants,
          child: _Table(
            heads: [
              l.stockColVariant,
              l.stockStateIn,
              l.stockHeld,
              l.stockColAvail,
            ],
            rows: [
              for (final v in p.variants)
                (
                  title: v.name.isEmpty ? l.stockStandard : v.name,
                  sub: v.price > 0 ? formatRs(v.price) : null,
                  cells: ['${v.onHand}', '${v.held}', '${v.available}'],
                  warn: v.state == 'in' ? null : stateInk(v.state),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StockBlock(
          title: l.stockByWarehouse,
          child: _Table(
            heads: [
              l.stockWarehouse,
              l.stockTitle,
              l.stockHeld,
              l.stockColAvail,
            ],
            rows: [
              for (final w in p.warehouses)
                (
                  title: w.name,
                  sub: [
                    ?w.outlet,
                    w.sellsOnline ? l.stockSellsOnline : l.stockNotOnline,
                  ].join(' · '),
                  cells: ['${w.onHand}', '${w.held}', '${w.available}'],
                  warn: null,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StockCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: AtomSegmented<bool>(
                  segments: [
                    AtomSegment(false, l.stockSegInStock(inStock.length)),
                    AtomSegment(true, l.stockSegDelivered(delivered.length)),
                  ],
                  selected: _delivered,
                  onChanged: (v) => setState(() => _delivered = v),
                ),
              ),
              if ((_delivered ? delivered : inStock).isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _delivered ? l.stockNothingDelivered : l.stockNoUnits,
                    style: AtomText.secondary,
                  ),
                ),
              for (final u in (_delivered ? delivered : inStock).take(100))
                _UnitRow(unit: u),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StockBlock(
          title: l.stockRecentChanges,
          trailing: AtomTextLink(
            label: l.stockAll,
            onTap: () => context.push(V2Routes.stockHistoryOf(productId: p.id)),
          ),
          child: p.recent.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Text(l.stockNoChanges, style: AtomText.secondary),
                )
              : Column(
                  children: [
                    for (final m in p.recent)
                      MoveRow(move: m, showProduct: false),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        StockBlock(
          title: l.stockOnAtomshop,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Column(
              children: [
                StockLine(
                  label: l.stockShowsAs,
                  value: AtomPill(
                    label: live && online > 0
                        ? l.stockStateIn
                        : (live
                              ? l.stockStateOut
                              : (p.websiteStatus ?? l.stockNotListed)),
                    tone: live && online > 0 ? AtomTone.green : AtomTone.grey,
                  ),
                ),
                StockLine(
                  label: l.stockCountsFrom,
                  value: stockValue(l.stockOnlineWarehouses),
                ),
                StockLine(
                  label: l.stockAvailableOnline,
                  value: stockValue('$online'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        StockBlock(
          title: l.stockDetails,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Column(
              children: [
                if (p.prNumber != null)
                  StockLine(
                    label: l.stockPrNumber,
                    value: stockValue(p.prNumber!),
                  ),
                StockLine(
                  label: l.stockUnitsNumberedBy,
                  value: stockValue(p.tracking.label(l)),
                ),
                if (p.tracking == Tracking.auto && p.autoPrefix != null)
                  StockLine(
                    label: l.stockPrefix,
                    value: stockValue(p.autoPrefix!),
                  ),
                if (p.websiteStatus != null)
                  StockLine(
                    label: l.stockOnWebsite,
                    value: stockValue(p.websiteStatus!),
                  ),
              ],
            ),
          ),
        ),
        if (canChange && p.canChangeTracking) ...[
          const SizedBox(height: 12),
          _Numbering(product: p),
        ],
      ],
    );
  }
}

typedef _Row = ({String title, String? sub, List<String> cells, Color? warn});

/// The canvas's `.tbl`: a name column and three figures.
class _Table extends StatelessWidget {
  const _Table({required this.heads, required this.rows});

  final List<String> heads;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    Widget cell(String t, {TextStyle? style, bool first = false}) => Expanded(
      flex: first ? 3 : 1,
      child: Text(
        t,
        textAlign: first ? TextAlign.start : TextAlign.end,
        style: style,
      ),
    );
    final head = AtomText.tag.copyWith(color: AtomColors.faint);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                for (var i = 0; i < heads.length; i++)
                  cell(heads[i], style: head, first: i == 0),
              ],
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                AppLocalizations.of(context).stockNothingYet,
                style: AtomText.secondary,
              ),
            ),
          for (final r in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AtomColors.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.title,
                          style: AtomText.body.copyWith(color: AtomColors.ink),
                        ),
                        if (r.sub != null && r.sub!.isNotEmpty)
                          Text(r.sub!, style: AtomText.small),
                      ],
                    ),
                  ),
                  for (var i = 0; i < r.cells.length; i++)
                    cell(
                      r.cells[i],
                      style: AtomText.money.copyWith(
                        fontSize: 14,
                        color: i == r.cells.length - 1 && r.warn != null
                            ? r.warn
                            : AtomColors.ink,
                        fontWeight: i == r.cells.length - 1 && r.warn != null
                            ? FontWeight.w700
                            : FontWeight.w500,
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

class _UnitRow extends StatelessWidget {
  const _UnitRow({required this.unit});

  final StockUnit unit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final u = unit;
    final line = u.delivered
        ? [
            ?u.variant,
            if (u.deliveredForId != null)
              u.deliveredForDeal
                  ? l.stockUnitBulkDeal('${u.deliveredForId}')
                  : l.stockUnitOrder('${u.deliveredForId}'),
            if (u.deliveredOn != null) AtomDates.short(u.deliveredOn!),
          ]
        : [
            ?u.variant,
            ?u.warehouse,
            if (u.cameIn != null) l.stockUnitCameIn(AtomDates.short(u.cameIn!)),
          ];
    final (label, tone) = switch (u.status) {
      'in_stock' => (l.stockStateIn, AtomTone.green),
      'delivered' => (l.stockMoveDelivered, AtomTone.grey),
      'damaged' => (l.stockRemoved, AtomTone.rose),
      final s => (s.replaceAll('_', ' '), AtomTone.grey),
    };
    return Container(
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
                  u.serial,
                  style: AtomText.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AtomColors.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(line.join(' · '), style: AtomText.small),
              ],
            ),
          ),
          AtomPill(label: label, tone: tone),
        ],
      ),
    );
  }
}

/// A ledger row (`.ev`, history rows).
class MoveRow extends StatelessWidget {
  const MoveRow({super.key, required this.move, this.showProduct = true});

  final StockMove move;
  final bool showProduct;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = move;
    final kind = moveKind(m.type);
    final (icon, tone, ink) = switch (kind) {
      MoveKind.stockIn => (
        LucideIcons.arrowDownToLine,
        AtomTone.green,
        AtomColors.green,
      ),
      MoveKind.delivered => (LucideIcons.truck, AtomTone.blue, AtomColors.ink),
      MoveKind.moved => (
        LucideIcons.arrowLeftRight,
        AtomTone.amber,
        AtomColors.amberInk,
      ),
      MoveKind.adjustedIn => (
        LucideIcons.slidersHorizontal,
        AtomTone.rose,
        AtomColors.green,
      ),
      MoveKind.adjustedOut => (
        LucideIcons.slidersHorizontal,
        AtomTone.rose,
        AtomColors.rose,
      ),
    };
    final title = showProduct
        ? variantTitle(m.product ?? '', m.variant ?? '')
        : [moveLabel(l, m), ?m.variant, ?m.serial].join(' · ');
    final line1 = showProduct
        ? [moveLabel(l, m), ?m.warehouse].join(' · ')
        : [
            ?m.warehouse,
            if (m.date != null) AtomDates.short(m.date!),
          ].join(' · ');
    final line2 = [?m.why, ?m.by].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AtomIconTile(icon: icon, tone: tone, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  title,
                  style: AtomText.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AtomColors.ink,
                  ),
                ),
                if (line1.isNotEmpty) Text(line1, style: AtomText.small),
                if (showProduct && m.serial != null)
                  Text(m.serial!, style: AtomText.small),
                if (line2.isNotEmpty)
                  Text(
                    line2,
                    style: AtomText.small.copyWith(color: AtomColors.faint),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            moveChange(m),
            style: AtomText.money.copyWith(
              color: ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// How units are numbered: IMEI, serial, or numbered for me with a prefix.
/// Shown only while the product has no units (the server refuses after).
class _Numbering extends ConsumerStatefulWidget {
  const _Numbering({required this.product});

  final ProductStock product;

  @override
  ConsumerState<_Numbering> createState() => _NumberingState();
}

class _NumberingState extends ConsumerState<_Numbering> {
  late Tracking _tracking = widget.product.tracking;
  late final _prefix = TextEditingController(
    text: widget.product.autoPrefix ?? '',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _prefix.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (_tracking == Tracking.auto) {
      final problem = prefixProblem(l, _prefix.text);
      if (problem != null) {
        setState(() => _error = problem);
        return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final r = await ref
        .read(stockRepositoryProvider)
        .setTracking(widget.product.id, _tracking, prefix: _prefix.text);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (r) {
      case ApiOk():
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: l.stockNumberingSaved,
        );
        refreshStock(ref);
      case ApiErr(:final failure):
        setState(() => _error = failure.fieldErrors['auto_prefix']);
        if (_error == null) {
          showAtomToast(
            context,
            kind: AtomToastKind.bad,
            message: sayStockFailure(context, failure),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final choices = [
      (Tracking.imei, l.stockTrackingImei, l.stockNumImeiHint),
      (Tracking.serial, l.stockNumSerial, l.stockNumSerialHint),
      (Tracking.auto, l.stockNumAuto, l.stockNumAutoHint),
    ];
    final changed =
        _tracking != widget.product.tracking ||
        (_tracking == Tracking.auto &&
            _prefix.text.trim() != (widget.product.autoPrefix ?? ''));
    final p = _prefix.text.trim().toUpperCase();
    return StockBlock(
      title: l.stockNumTitle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            for (final (t, label, hint) in choices)
              AtomOptionCard(
                title: label,
                subtitle: hint,
                selected: _tracking == t,
                onTap: () => setState(() => _tracking = t),
              ),
            if (_tracking == Tracking.auto)
              AtomTextField(
                label: l.stockPrefix,
                labelNote: l.stockPrefixNote,
                controller: _prefix,
                error: _error,
                hint: p.isEmpty ? null : l.stockPrefixHint(p),
                onChanged: (_) => setState(() => _error = null),
              ),
            AtomButton(
              label: l.stockSaveNumbering,
              kind: AtomButtonKind.outline,
              compact: true,
              saving: _saving,
              onPressed: changed ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}
