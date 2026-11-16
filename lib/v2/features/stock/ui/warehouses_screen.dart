import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/api/api_result.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/stock_models.dart';
import '../data/stock_repository.dart';
import '../data/stock_rules.dart';
import 'stock_parts.dart';

/// 9.10 Warehouses: each outlet's warehouses with their units and who runs
/// them. Adding and editing needs `stock.manage` (and a signal).
class WarehousesScreen extends ConsumerWidget {
  const WarehousesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(warehouseBookProvider);
    final who = stockWho(ref);
    final book = data.value;
    final manage = book != null && canManageStock(who, book.access);
    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        children: [
          AtomPageHeader(
            title: l.stockWarehouses,
            leading: AtomIconButton(
              icon: LucideIcons.chevronLeft,
              label: l.commonBack,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            actions: [
              if (manage)
                Padding(
                  // with the header's 8: the 16px gutter
                  padding: const EdgeInsets.only(right: 8),
                  child: AtomButton.small(
                    label: l.stockAdd,
                    icon: LucideIcons.plus,
                    kind: AtomButtonKind.primary,
                    onPressed: () => showWarehouseSheet(context, book: book),
                  ),
                ),
            ],
          ),
          Expanded(
            child: data.when(
              skipLoadingOnRefresh: true,
              loading: () => StockLoading(count: 3),
              error: (e, _) => StockFailed(
                error: e,
                onRetry: () => ref.invalidate(warehouseBookProvider),
              ),
              data: (book) => RefreshIndicator(
                onRefresh: () => ref.refresh(warehouseBookProvider.future),
                child: _list(context, book, manage),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(BuildContext context, WarehouseBook book, bool manage) {
    final l = AppLocalizations.of(context);
    final active = [
      for (final w in book.warehouses)
        if (!w.archived) w,
    ];
    final archived = [
      for (final w in book.warehouses)
        if (w.archived) w,
    ];
    // outlets in the server's order, then any warehouse whose outlet isn't
    // listed
    final groups = <({String name, List<StockWarehouse> list})>[];
    final listed = <int>{};
    for (final o in book.outlets) {
      final ws = [
        for (final w in active)
          if (w.outletId == o.id) w,
      ];
      listed.add(o.id);
      if (ws.isNotEmpty) groups.add((name: o.name, list: ws));
    }
    final rest = [
      for (final w in active)
        if (!listed.contains(w.outletId)) w,
    ];
    if (rest.isNotEmpty) groups.add((name: l.stockOther, list: rest));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        if (book.access.readOnly)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: AtomNote(
              kind: AtomNoteKind.warning,
              message: l.stockWhReadOnly,
            ),
          ),
        if (groups.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: AtomMessageState(
              icon: LucideIcons.warehouse,
              title: l.stockNoWarehouses,
              body: l.stockNoWarehousesBody,
            ),
          ),
        for (final g in groups) ...[
          _Label(g.name),
          for (final w in g.list)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _WarehouseCard(
                warehouse: w,
                onEdit: manage
                    ? () =>
                          showWarehouseSheet(context, book: book, warehouse: w)
                    : null,
              ),
            ),
        ],
        if (archived.isNotEmpty) ...[
          _Label(l.stockArchived),
          for (final w in archived)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: StockCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w.name,
                            style: AtomText.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AtomColors.muted,
                            ),
                          ),
                          Text(
                            l.stockArchivedUnits(w.units),
                            style: AtomText.small,
                          ),
                        ],
                      ),
                    ),
                    if (manage)
                      AtomTextLink(
                        label: l.stockBringBack,
                        onTap: () => showWarehouseSheet(
                          context,
                          book: book,
                          warehouse: w,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
    child: Text(text.toUpperCase(), style: AtomText.section),
  );
}

class _WarehouseCard extends StatelessWidget {
  const _WarehouseCard({required this.warehouse, required this.onEdit});

  final StockWarehouse warehouse;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final w = warehouse;
    return StockCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Row(
            children: [
              const AtomIconTile(
                icon: LucideIcons.warehouse,
                tone: AtomTone.grey,
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  w.name,
                  style: AtomText.listTitle.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onEdit != null)
                AtomButton.small(label: l.stockEdit, onPressed: onEdit),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _WhTag(label: warehouseTypeLabel(l, w.type), tone: AtomTone.grey),
              if (w.isDefault)
                _WhTag(label: l.stockDefault, tone: AtomTone.blue),
              _WhTag(
                label: w.sellsOnline
                    ? l.stockSellsOnAtomshopTag
                    : l.stockNotOnAtomshopTag,
                tone: w.sellsOnline ? AtomTone.green : AtomTone.grey,
              ),
            ],
          ),
          Text(
            [
              l.stockUnitsN(w.units),
              if (w.held > 0) l.stockHeldN(w.held),
              l.stockInChargeOf(w.inCharge?.name ?? l.stockNobodyYet),
            ].join(' · '),
            style: AtomText.secondary,
          ),
          if (w.address != null)
            Text(
              w.address!,
              style: AtomText.small.copyWith(color: AtomColors.faint),
            ),
        ],
      ),
    );
  }
}

/// A warehouse card's tag (`.wh .tags span`): 22 high, 12px.
class _WhTag extends StatelessWidget {
  const _WhTag({required this.label, required this.tone});

  final String label;
  final AtomTone tone;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 22),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: tone == AtomTone.grey ? AtomColors.surface : tone.bg,
      borderRadius: AtomRadius.brTag,
    ),
    child: Text(
      label,
      style: AtomText.small.copyWith(
        fontWeight: FontWeight.w600,
        color: tone == AtomTone.grey ? AtomColors.text : tone.fg,
      ),
    ),
  );
}

/// Add a warehouse ([warehouse] null) or edit one.
Future<void> showWarehouseSheet(
  BuildContext context, {
  required WarehouseBook book,
  StockWarehouse? warehouse,
}) => showAtomSheet<void>(
  context,
  expand: true,
  builder: (_) => _WarehouseSheet(book: book, warehouse: warehouse),
);

class _WarehouseSheet extends ConsumerStatefulWidget {
  const _WarehouseSheet({required this.book, this.warehouse});

  final WarehouseBook book;
  final StockWarehouse? warehouse;

  @override
  ConsumerState<_WarehouseSheet> createState() => _WarehouseSheetState();
}

class _WarehouseSheetState extends ConsumerState<_WarehouseSheet> {
  late final _name = TextEditingController(text: widget.warehouse?.name ?? '');
  late final _address = TextEditingController(
    text: widget.warehouse?.address ?? '',
  );
  late String _type = widget.warehouse?.type ?? 'godown';
  late int? _outletId =
      widget.warehouse?.outletId ??
      (widget.book.outlets.length == 1 ? widget.book.outlets.first.id : null);
  late int? _inCharge = widget.warehouse?.inCharge?.id;
  late bool _online = widget.warehouse?.sellsOnline ?? false;
  late bool _default = widget.warehouse?.isDefault ?? false;
  bool _saving = false;
  Map<String, String> _errors = const {};

  bool get _adding => widget.warehouse == null;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save({String status = 'active'}) async {
    final l = AppLocalizations.of(context);
    if (status == 'archived') {
      final ok = await showAtomConfirm(
        context,
        title: l.stockArchiveTitle(widget.warehouse!.name),
        body: l.stockArchiveBody,
        confirmLabel: l.stockArchive,
        destructive: true,
      );
      if (!ok || !mounted) return;
    }
    setState(() {
      _saving = true;
      _errors = const {};
    });
    final r = await ref
        .read(stockRepositoryProvider)
        .saveWarehouse(
          id: widget.warehouse?.id,
          name: _name.text,
          type: _type,
          outletId: _outletId!,
          address: _address.text,
          sellsOnline: _online,
          isDefault: status == 'active' && _default,
          status: status,
          inChargeId: _inCharge,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (r) {
      case ApiOk(:final value):
        ref.invalidate(warehouseBookProvider);
        refreshStock(ref);
        Navigator.of(context).pop();
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: status == 'archived'
              ? l.stockWhArchived(value.name)
              : l.stockWhSaved(value.name),
        );
      case ApiErr(:final failure):
        if (failure.fieldErrors.isNotEmpty) {
          setState(() => _errors = failure.fieldErrors);
        }
        showAtomToast(
          context,
          kind: AtomToastKind.bad,
          message: sayStockFailure(context, failure),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final book = widget.book;
    final outlet = book.outlets.where((o) => o.id == _outletId).firstOrNull;
    final person = book.inChargeChoices
        .where((c) => c.id == _inCharge)
        .firstOrNull;
    final problem = warehouseProblem(l, name: _name.text, outletId: _outletId);
    final archived = widget.warehouse?.archived ?? false;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          AtomSheetHeader(
            title: _adding ? l.stockAddWarehouse : l.stockEditWarehouse,
          ),
          AtomTextField(
            label: l.stockName,
            controller: _name,
            error: _errors['name'],
            inputFormatters: [LengthLimitingTextInputFormatter(60)],
            onChanged: (_) => setState(() {}),
          ),
          AtomField(
            label: l.stockType,
            error: _errors['type'],
            child: AtomChips<String>(
              chips: [
                AtomChip('factory', l.stockWhTypeFactory),
                AtomChip('godown', l.stockWhTypeGodown),
                AtomChip('store', l.stockWhTypeStore),
              ],
              selected: _type,
              onChanged: (t) => setState(() => _type = t),
            ),
          ),
          AtomSelectField<int>(
            label: l.stockOutlet,
            value: _outletId,
            valueLabel: outlet?.name,
            error: _errors['brand_outlet_id'],
            options: [
              for (final o in book.outlets)
                AtomOption(value: o.id, label: o.name),
            ],
            onChanged: (id) => setState(() => _outletId = id),
          ),
          AtomSelectField<int>(
            label: l.stockInCharge,
            value: _inCharge ?? 0,
            valueLabel: person?.name ?? l.stockNobody,
            error: _errors['in_charge_id'],
            options: [
              AtomOption(value: 0, label: l.stockNobody),
              for (final c in book.inChargeChoices)
                AtomOption(
                  value: c.id,
                  label: c.name,
                  subtitle: c.isOwner ? l.stockOwner : null,
                ),
            ],
            onChanged: (id) => setState(() => _inCharge = id == 0 ? null : id),
          ),
          AtomTextField(
            label: l.stockAddress,
            labelNote: l.stockOptional,
            controller: _address,
            error: _errors['address'],
            inputFormatters: [LengthLimitingTextInputFormatter(255)],
          ),
          _SwitchRow(
            title: l.stockSellsOnAtomshopTag,
            subtitle: l.stockSellsOnlineSub,
            value: _online,
            onChanged: (v) => setState(() => _online = v),
          ),
          _SwitchRow(
            title: l.stockDefaultOutlet,
            subtitle: l.stockDefaultSub,
            value: _default,
            onChanged: (v) => setState(() => _default = v),
          ),
          if (_errors['status'] != null || _errors['is_default'] != null)
            AtomFieldError(_errors['status'] ?? _errors['is_default']!),
          if (problem != null) AtomButtonReason(reason: problem),
          Row(
            spacing: 10,
            children: [
              Expanded(
                flex: 10,
                child: AtomButton(
                  label: _adding || archived ? l.commonCancel : l.stockArchive,
                  kind: AtomButtonKind.outline,
                  compact: true,
                  onPressed: _saving
                      ? null
                      : (_adding || archived
                            ? () => Navigator.of(context).pop()
                            : () => _save(status: 'archived')),
                ),
              ),
              Expanded(
                flex: 14,
                child: AtomButton(
                  label: archived ? l.stockBringBack : l.commonSave,
                  compact: true,
                  saving: _saving,
                  onPressed: problem == null ? () => _save() : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AtomText.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AtomColors.ink,
              ),
            ),
            Text(subtitle, style: AtomText.small),
          ],
        ),
      ),
      AtomSwitch(value: value, onChanged: onChanged, semanticLabel: title),
    ],
  );
}
