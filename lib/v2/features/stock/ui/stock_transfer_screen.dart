import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../sync/ui/offline_bar.dart';
import '../data/stock_models.dart';
import '../data/stock_repository.dart';
import '../data/stock_rules.dart';
import 'scanner.dart';
import 'stock_parts.dart';

/// 9.6 Move stock: tick units in one warehouse and move them to another,
/// any warehouse of the brand.
class StockTransferScreen extends ConsumerStatefulWidget {
  const StockTransferScreen({super.key, this.serial, this.productId});

  /// A scanned unit to start with.
  final String? serial;

  /// A stock product to show units of.
  final int? productId;

  @override
  ConsumerState<StockTransferScreen> createState() =>
      _StockTransferScreenState();
}

class _StockTransferScreenState extends ConsumerState<StockTransferScreen> {
  StockWarehouse? _from;
  StockWarehouse? _to;
  int? _productId;
  final _picked = <String>{};
  DateTime _on = DateTime.now();
  final _note = TextEditingController();
  bool _saving = false;
  bool _started = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Map<int, int> _productOf(StockFormOptions o) => {
    for (final v in o.variants) v.id: v.productId,
  };

  void _start(StockFormOptions o) {
    if (_started) return;
    _started = true;
    _productId = widget.productId;
    final s = widget.serial?.toUpperCase();
    final unit = s == null
        ? null
        : o.inStockUnits.where((u) => u.serial.toUpperCase() == s).firstOrNull;
    if (unit != null) {
      _from = o.warehouses.where((w) => w.id == unit.warehouseId).firstOrNull;
      _picked.add(unit.serial);
    }
    _from ??=
        o.warehouses.where((w) => w.isDefault).firstOrNull ??
        o.warehouses.firstOrNull;
    _to = o.allWarehouses.where((w) => w.id != _from?.id).firstOrNull;
  }

  List<UnitOption> _units(StockFormOptions o) {
    final productOf = _productOf(o);
    return [
      for (final u in o.inStockUnits)
        if (u.warehouseId == _from?.id &&
            (_productId == null || productOf[u.variantId] == _productId))
          u,
    ];
  }

  int _count(StockFormOptions o, int id) =>
      o.inStockUnits.where((u) => u.warehouseId == id).length;

  Future<void> _scan(StockFormOptions o) async {
    final l = AppLocalizations.of(context);
    final codes = await scanCodes(
      context,
      many: true,
      title: l.stockScanToMove,
    );
    if (codes.isEmpty || !mounted) return;
    final byKey = {for (final u in o.inStockUnits) u.serial.toUpperCase(): u};
    final found = [for (final c in codes) ?byKey[c.toUpperCase()]];
    final missing = codes.length - found.length;
    setState(() {
      if (found.isNotEmpty &&
          _picked.isEmpty &&
          found.first.warehouseId != _from?.id) {
        _from =
            o.warehouses
                .where((w) => w.id == found.first.warehouseId)
                .firstOrNull ??
            _from;
        if (_to?.id == _from?.id) _to = null;
      }
      _productId = null;
      for (final u in found) {
        if (u.warehouseId == _from?.id) _picked.add(u.serial);
      }
    });
    final elsewhere = found.where((u) => u.warehouseId != _from?.id).length;
    if (missing > 0 || elsewhere > 0) {
      showAtomToast(
        context,
        kind: AtomToastKind.bad,
        message: [
          if (missing > 0) l.stockNotInStockN(missing),
          if (elsewhere > 0) l.stockElsewhereN(elsewhere),
        ].join(' · '),
      );
    }
  }

  Future<void> _save(StockFormOptions o) async {
    final l = AppLocalizations.of(context);
    final units = [
      for (final u in o.inStockUnits)
        if (u.warehouseId == _from!.id && _picked.contains(u.serial)) u,
    ];
    setState(() => _saving = true);
    final saved = await ref
        .read(stockRepositoryProvider)
        .transfer(
          units: units,
          toWarehouseId: _to!.id,
          on: _on,
          note: _note.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    final n = units.length;
    if (sayStockSaved(context, saved, done: l.stockMovedUnits(n, _to!.name))) {
      refreshStock(ref);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(stockFormOptionsProvider);
    return AtomUnsavedGuard(
      dirty: _picked.isNotEmpty && !_saving,
      child: Scaffold(
        backgroundColor: AtomColors.surface,
        body: Column(
          children: [
            StockFormBar(title: AppLocalizations.of(context).stockMoveTitle),
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
    final units = _units(o);
    final picked = [
      for (final u in o.inStockUnits)
        if (u.warehouseId == _from?.id && _picked.contains(u.serial)) u,
    ].length;
    final problem = moveProblem(l, from: _from, to: _to, picked: picked);
    final canSwap = _to != null && o.warehouses.any((w) => w.id == _to!.id);
    // Every stock product can be picked (the board's "Product: …" chip);
    // the list then shows its units in the From warehouse.
    final products = <int, String>{
      for (final v in o.variants) v.productId: v.product,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Place(
                  label: l.stockFrom,
                  name: _from?.name,
                  line: _from == null
                      ? null
                      : l.stockUnitsN(_count(o, _from!.id)),
                  onTap: () async {
                    final id = await showAtomSelect<int>(
                      context,
                      title: l.stockMoveFrom,
                      selected: _from?.id,
                      options: [
                        for (final w in o.warehouses)
                          AtomOption(
                            value: w.id,
                            label: w.name,
                            subtitle: w.outlet,
                          ),
                      ],
                    );
                    if (id != null && id != _from?.id) {
                      setState(() {
                        _from = o.warehouses.firstWhere((w) => w.id == id);
                        _picked.clear();
                        if (_to?.id == id) _to = null;
                      });
                    }
                  },
                ),
              ),
              if (canSwap)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    // `.swap`: a 44 round white button with a line.
                    child: AtomPressable(
                      semanticLabel: l.stockSwap,
                      onTap: () => setState(() {
                        final f = _from;
                        _from = o.warehouses.firstWhere((w) => w.id == _to!.id);
                        _to = f;
                        _picked.clear();
                      }),
                      builder: (context, pressed) => Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pressed ? AtomColors.head : AtomColors.paper,
                          border: Border.all(color: AtomColors.line2),
                        ),
                        child: const Icon(
                          LucideIcons.arrowLeftRight,
                          size: 18,
                          color: AtomColors.ink,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Center(
                    child: Icon(
                      LucideIcons.arrowRight,
                      color: AtomColors.muted,
                      size: AtomIcon.row,
                    ),
                  ),
                ),
              Expanded(
                child: _Place(
                  label: l.stockTo,
                  name: _to?.name,
                  // a unit count, like From (`.place small`)
                  line: _to == null ? null : l.stockUnitsN(_count(o, _to!.id)),
                  onTap: () async {
                    final id = await showAtomSelect<int>(
                      context,
                      title: l.stockMoveTo,
                      selected: _to?.id,
                      options: [
                        for (final w in o.allWarehouses)
                          if (w.id != _from?.id)
                            AtomOption(
                              value: w.id,
                              label: w.name,
                              subtitle: w.outlet,
                            ),
                      ],
                    );
                    if (id != null) {
                      setState(
                        () =>
                            _to = o.allWarehouses.firstWhere((w) => w.id == id),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (products.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: StockFilterChip(
              label: l.stockProductFilter(
                _productId == null
                    ? l.stockAllProducts
                    : products[_productId] ?? l.stockAllProducts,
              ),
              active: _productId != null,
              onTap: () async {
                final id = await showAtomSelect<int>(
                  context,
                  title: l.stockProduct,
                  selected: _productId ?? 0,
                  options: [
                    AtomOption(value: 0, label: l.stockAllProducts),
                    for (final e in products.entries)
                      AtomOption(value: e.key, label: e.value),
                  ],
                );
                if (id != null) {
                  setState(() {
                    _productId = id == 0 ? null : id;
                    // only ticks of the product shown stay
                    final keep = {for (final u in _units(o)) u.serial};
                    _picked.retainWhere(keep.contains);
                  });
                }
              },
            ),
          ),
        const SizedBox(height: 12),
        StockCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.stockMoveTickUnits,
                        style: AtomText.listTitle,
                      ),
                    ),
                    Text(l.stockTickedN(picked), style: AtomText.small),
                  ],
                ),
              ),
              if (units.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(l.stockNoUnitsHere, style: AtomText.secondary),
                ),
              for (final u in units)
                AtomPressable(
                  onTap: () => setState(() {
                    _picked.contains(u.serial)
                        ? _picked.remove(u.serial)
                        : _picked.add(u.serial);
                  }),
                  semanticLabel: u.serial,
                  toggled: _picked.contains(u.serial),
                  scaleOnPress: false,
                  builder: (context, pressed) => Container(
                    color: pressed ? AtomColors.head : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        AtomCheckbox(on: _picked.contains(u.serial)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.serial,
                                style: AtomText.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AtomColors.ink,
                                ),
                              ),
                              Text(u.title, style: AtomText.small),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AtomButton(
          label: l.stockScanInstead,
          icon: LucideIcons.scanLine,
          kind: AtomButtonKind.outline,
          compact: true,
          onPressed: () => _scan(o),
        ),
        const SizedBox(height: 12),
        StockTwoUp(
          first: StockDayBox(
            label: l.stockMovedOn,
            day: _on,
            onChanged: (d) => setState(() => _on = d),
          ),
          second: AtomTextField(
            label: l.stockNote,
            controller: _note,
            placeholder: l.stockMovePlaceholder,
            inputFormatters: [LengthLimitingTextInputFormatter(300)],
          ),
        ),
        const SizedBox(height: 16),
        if (problem != null) AtomButtonReason(reason: problem),
        AtomButton(
          label: _to == null
              ? l.stockMoveN(picked)
              : l.stockMoveNTo(picked, _to!.name),
          saving: _saving,
          onPressed: problem == null ? () => _save(o) : null,
        ),
        const SizedBox(height: 8),
        Text(
          l.stockHeldCantMove,
          textAlign: TextAlign.center,
          style: AtomText.small,
        ),
      ],
    );
  }
}

class _Place extends StatelessWidget {
  const _Place({
    required this.label,
    required this.name,
    required this.line,
    required this.onTap,
  });

  final String label;
  final String? name;
  final String? line;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final choose = AppLocalizations.of(context).commonChoose;
    return AtomPressable(
      onTap: onTap,
      semanticLabel: '$label: ${name ?? choose}',
      builder: (context, pressed) => Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: pressed ? AtomColors.head : AtomColors.paper,
          borderRadius: AtomRadius.brCard,
          border: Border.all(color: AtomColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: AtomText.small.copyWith(
                color: AtomColors.faint,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            // Up to two lines (the row stretches From and To to the same
            // height), so "Karachi · Tariq Road store" reads in full.
            Text(
              name ?? choose,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AtomText.body.copyWith(
                height: 1.3,
                fontWeight: FontWeight.w700,
                color: name == null ? AtomColors.placeholder : AtomColors.ink,
              ),
            ),
            Text(
              line ?? ' ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AtomText.small,
            ),
          ],
        ),
      ),
    );
  }
}
