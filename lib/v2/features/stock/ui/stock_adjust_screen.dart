import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../sync/data/offline_saves.dart';
import '../../sync/ui/offline_bar.dart';
import '../data/stock_models.dart';
import '../data/stock_repository.dart';
import '../data/stock_rules.dart';
import 'scanner.dart';
import 'stock_parts.dart';

/// 9.7 Adjust stock: remove a unit (damaged, lost, a recount…) or add one
/// found. A reason and a note are always asked for.
class StockAdjustScreen extends ConsumerStatefulWidget {
  const StockAdjustScreen({
    super.key,
    this.serial,
    this.found = false,
    this.productId,
  });

  /// The unit (out) or the number found (in).
  final String? serial;

  /// Start on Found a unit.
  final bool found;

  /// Narrows the units and products to one stock product.
  final int? productId;

  @override
  ConsumerState<StockAdjustScreen> createState() => _StockAdjustScreenState();
}

class _StockAdjustScreenState extends ConsumerState<StockAdjustScreen> {
  late bool _out = !widget.found;
  UnitOption? _unit;
  VariantOption? _variant;
  StockWarehouse? _warehouse;
  late final _serial = TextEditingController(
    text: widget.found ? widget.serial ?? '' : '',
  );
  final _note = TextEditingController();
  String? _reason;
  DateTime _on = DateTime.now();
  bool _saving = false;
  bool _started = false;
  String? _serverError;

  @override
  void dispose() {
    _serial.dispose();
    _note.dispose();
    super.dispose();
  }

  void _start(StockFormOptions o) {
    if (_started) return;
    _started = true;
    final s = widget.serial?.toUpperCase();
    if (!widget.found && s != null) {
      _unit = o.inStockUnits
          .where((u) => u.serial.toUpperCase() == s)
          .firstOrNull;
    }
    if (widget.productId != null) {
      _variant = o.variants
          .where((v) => v.productId == widget.productId)
          .firstOrNull;
    }
    _warehouse =
        o.warehouses.where((w) => w.isDefault).firstOrNull ??
        o.warehouses.firstOrNull;
    _reason = _out
        ? o.outReasons.first
        : (o.inReasons.contains('Found') ? 'Found' : o.inReasons.first);
  }

  Future<void> _pickUnit(StockFormOptions o) async {
    final l = AppLocalizations.of(context);
    final productOf = {for (final v in o.variants) v.id: v.productId};
    final picked = await showAtomSelect<String>(
      context,
      title: l.stockUnitToRemove,
      searchHint: l.stockSerialOrProduct,
      selected: _unit?.serial,
      options: [
        for (final u in o.inStockUnits)
          if (widget.productId == null ||
              productOf[u.variantId] == widget.productId)
            AtomOption(
              value: u.serial,
              label: u.serial,
              subtitle: [u.title, ?u.warehouse].join(' · '),
              keywords: [u.title],
            ),
      ],
    );
    if (picked != null) {
      setState(
        () => _unit = o.inStockUnits.firstWhere((u) => u.serial == picked),
      );
    }
  }

  Future<void> _scanUnit(StockFormOptions o) async {
    final l = AppLocalizations.of(context);
    final codes = await scanCodes(
      context,
      many: false,
      title: l.stockScanTheUnit,
    );
    if (codes.isEmpty || !mounted) return;
    final key = codes.first.toUpperCase();
    final unit = o.inStockUnits
        .where((u) => u.serial.toUpperCase() == key)
        .firstOrNull;
    if (unit == null) {
      showAtomToast(
        context,
        kind: AtomToastKind.bad,
        message: l.stockNotInStockHere(codes.first),
      );
      return;
    }
    setState(() => _unit = unit);
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final repo = ref.read(stockRepositoryProvider);
    setState(() {
      _saving = true;
      _serverError = null;
    });
    final saved = _out
        ? await repo.adjustOut(
            unit: _unit!,
            reason: _reason!,
            note: _note.text,
            on: _on,
          )
        : await repo.adjustIn(
            variantId: _variant!.id,
            warehouseId: _warehouse!.id,
            serial: _variant!.tracking == Tracking.auto ? null : _serial.text,
            reason: _reason!,
            note: _note.text,
            on: _on,
          );
    if (!mounted) return;
    setState(() => _saving = false);
    final done = _out
        ? l.stockTakenOut(_unit!.serial)
        : (_serial.text.trim().isEmpty
              ? l.stockUnitAddedBack
              : l.stockAddedBack(_serial.text.trim()));
    if (sayStockSaved(context, saved, done: done)) {
      refreshStock(ref);
      context.pop();
    } else if (saved case SaveFailed(:final failure)
        when failure.fieldErrors.isNotEmpty) {
      setState(() => _serverError = failure.fieldErrors.values.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(stockFormOptionsProvider);
    return AtomUnsavedGuard(
      dirty: _note.text.trim().isNotEmpty && !_saving,
      child: Scaffold(
        backgroundColor: AtomColors.paper,
        body: Column(
          children: [
            AtomFlowBar(
              leading: AtomFlowLeading.close,
              title: AppLocalizations.of(context).stockAdjustTitle,
            ),
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
    final reasons = _out ? o.outReasons : o.inReasons;
    final problem =
        _serverError ??
        adjustProblem(
          l,
          out: _out,
          unit: _unit,
          variant: _variant,
          warehouse: _warehouse,
          serial: _serial.text,
          reason: _reason,
          note: _note.text,
        );
    final v = _variant;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        AtomSegmented<bool>(
          segments: [
            AtomSegment(true, l.stockRemoveUnit),
            AtomSegment(false, l.stockFoundUnit),
          ],
          selected: _out,
          onChanged: (out) => setState(() {
            _out = out;
            _serverError = null;
            _reason = out
                ? o.outReasons.first
                : (o.inReasons.contains('Found') ? 'Found' : o.inReasons.first);
          }),
        ),
        const SizedBox(height: 16),
        if (_out)
          _unit == null
              ? Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: AtomButton(
                        label: l.stockChooseUnit,
                        kind: AtomButtonKind.outline,
                        compact: true,
                        onPressed: () => _pickUnit(o),
                      ),
                    ),
                    AtomButton(
                      label: l.stockScan,
                      icon: LucideIcons.scanLine,
                      kind: AtomButtonKind.outline,
                      compact: true,
                      expand: false,
                      onPressed: () => _scanUnit(o),
                    ),
                  ],
                )
              : StockCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const AtomIconTile(
                        icon: LucideIcons.package,
                        tone: AtomTone.rose,
                        size: 40,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_unit!.serial, style: AtomText.listTitle),
                            Text(
                              [_unit!.title, ?_unit!.warehouse].join(' · '),
                              style: AtomText.secondary,
                            ),
                          ],
                        ),
                      ),
                      AtomTextLink(
                        label: l.stockChange,
                        onTap: () => _pickUnit(o),
                      ),
                    ],
                  ),
                )
        else ...[
          StockPickBox(
            label: l.stockProductVariant,
            text: v?.title,
            onTap: () async {
              final id = await showAtomSelect<int>(
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
              if (id != null) {
                setState(
                  () => _variant = o.variants.firstWhere((x) => x.id == id),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          StockPickBox(
            label: l.stockWarehouse,
            text: _warehouse?.name,
            onTap: () async {
              final id = await showAtomSelect<int>(
                context,
                title: l.stockWarehouse,
                selected: _warehouse?.id,
                options: [
                  for (final w in o.warehouses)
                    AtomOption(value: w.id, label: w.name, subtitle: w.outlet),
                ],
              );
              if (id != null) {
                setState(
                  () => _warehouse = o.warehouses.firstWhere((w) => w.id == id),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          if (v?.tracking == Tracking.auto)
            AtomNote(kind: AtomNoteKind.info, message: l.stockAutoNote)
          else
            AtomTextField(
              label: v?.tracking == Tracking.imei
                  ? l.stockTrackingImei
                  : l.stockNumSerial,
              controller: _serial,
              keyboardType: v?.tracking == Tracking.imei
                  ? TextInputType.number
                  : TextInputType.text,
              inputFormatters: [LengthLimitingTextInputFormatter(60)],
              trailing: AtomIconButton(
                icon: LucideIcons.scanLine,
                label: l.stockScan,
                onTap: () async {
                  final codes = await scanCodes(
                    context,
                    many: false,
                    imeiOnly: v?.tracking == Tracking.imei,
                  );
                  if (codes.isNotEmpty) {
                    setState(() => _serial.text = codes.first);
                  }
                },
              ),
              onChanged: (_) => setState(() => _serverError = null),
            ),
        ],
        const SizedBox(height: 16),
        Text(l.stockReason, style: AtomText.fieldLabel),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in reasons)
              _ReasonChip(
                label: r,
                on: _reason == r,
                onTap: () => setState(() => _reason = r),
              ),
          ],
        ),
        const SizedBox(height: 16),
        AtomTextField(
          label: l.stockNote,
          labelNote: l.stockRequired,
          controller: _note,
          minLines: 3,
          keyboardType: TextInputType.multiline,
          placeholder: l.stockWhatHappened,
          inputFormatters: [LengthLimitingTextInputFormatter(300)],
          onChanged: (_) => setState(() => _serverError = null),
        ),
        const SizedBox(height: 12),
        StockDayBox(
          label: l.stockDate,
          day: _on,
          onChanged: (d) => setState(() => _on = d),
        ),
        const SizedBox(height: 16),
        if (problem != null) AtomButtonReason(reason: problem),
        AtomButton(
          label: _out ? l.stockRemoveOne : l.stockAddUnit,
          kind: _out ? AtomButtonKind.danger : AtomButtonKind.primary,
          saving: _saving,
          onPressed: problem == null ? _save : null,
        ),
      ],
    );
  }
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({
    required this.label,
    required this.on,
    required this.onTap,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AtomPressable(
    onTap: onTap,
    semanticLabel: label,
    selected: on,
    focusRadius: AtomRadius.brPill,
    builder: (context, pressed) => Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: on
            ? AtomColors.primarySoft
            : (pressed ? AtomColors.surface : AtomColors.paper),
        borderRadius: AtomRadius.brPill,
        border: Border.all(color: on ? AtomColors.primary : AtomColors.line2),
      ),
      child: Text(
        label,
        style: AtomText.smallButton.copyWith(
          color: on ? AtomColors.primary : AtomColors.ink,
        ),
      ),
    ),
  );
}
