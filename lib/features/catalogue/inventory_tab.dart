import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_icons.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/models/product.dart';
import '../../data/repositories/catalogue_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/status_badge.dart';
import '../shell/main_shell.dart';
import 'inventory_logic.dart';
import 'product_cards.dart';

/// Inventory (DESIGN.md §4.8): stock health, filter, and cards whose
/// switch and unit stepper only change a draft. Nothing reaches the server
/// until the brand taps Save on the bar that replaces the bottom nav.
class InventoryTab extends ConsumerStatefulWidget {
  const InventoryTab({super.key});

  @override
  ConsumerState<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends ConsumerState<InventoryTab> with AutomaticKeepAliveClientMixin {
  List<ProductSummary>? _products;
  Object? _error;
  final _edits = <int, InvEdit>{};
  var _filter = InvFilter.all;
  final _search = TextEditingController();
  bool _bulk = false;
  final _selected = <int>{};
  bool _saving = false;
  TabController? _tabs;
  late final ShellNavHidden _nav = ref.read(shellNavHiddenProvider.notifier);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tabs = DefaultTabController.maybeOf(context);
    if (tabs != _tabs) {
      _tabs?.removeListener(_syncNav);
      _tabs = tabs?..addListener(_syncNav);
    }
  }

  @override
  void dispose() {
    _tabs?.removeListener(_syncNav);
    _search.dispose();
    final nav = _nav;
    Future.microtask(() => nav.set(false));
    super.dispose();
  }

  bool get _pending => _edits.isNotEmpty;

  /// The nav hides while this tab shows its save or bulk bar.
  void _syncNav() => _nav.set((_tabs?.index ?? 1) == 1 && (_pending || _bulk));

  void _update(VoidCallback fn) {
    setState(fn);
    _syncNav();
  }

  List<InvRow> get _rows => [for (final p in _products ?? const <ProductSummary>[]) InvRow(p, _edits[p.id])];

  /// Loads every page: counts and filters must match the list exactly, and
  /// a brand's catalogue is small.
  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final repo = ref.read(catalogueRepositoryProvider);
      final all = <ProductSummary>[];
      for (var page = 1; page <= 40; page++) {
        final res = await repo.inventory(page: page);
        all.addAll(res.page.items);
        if (!res.page.pagination.hasMore) break;
      }
      if (!mounted) return;
      _update(() {
        _products = all;
        final byId = {for (final p in all) p.id: p};
        _edits.removeWhere((id, e) => byId[id] == null || !InvRow(byId[id]!, e).changed);
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _edit(InvRow r, {bool? on, int? units}) {
    final e = InvEdit(on: on ?? r.on, units: units ?? r.units);
    _update(() {
      if (InvRow(r.product, e).changed) {
        _edits[r.id] = e;
      } else {
        _edits.remove(r.id);
      }
    });
  }

  void _discard() {
    final undo = Map.of(_edits);
    _update(_edits.clear);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        persist: false,
        content: Text('${plural(undo.length, 'change')} discarded'),
        action: SnackBarAction(label: 'Undo', onPressed: () => _update(() => _edits.addAll(undo))),
      ));
  }

  Future<void> _save() async {
    final changed = _rows.where((r) => r.changed).toList();
    final missing = changed.where((r) => r.needsUnits).length;
    if (missing > 0) {
      setState(() => _filter = InvFilter.out);
      showToast(context, 'Add units to ${plural(missing, 'product')} you turned on, then save.');
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(catalogueRepositoryProvider);
    final done = <int>[];
    Object? error;
    for (final r in changed) {
      try {
        await repo.setStock(r.id, available: r.on, stock: r.stockToSend);
        done.add(r.id);
      } catch (e) {
        error ??= e;
      }
    }
    await _load();
    if (!mounted) return;
    _update(() {
      _saving = false;
      _edits.removeWhere((id, _) => done.contains(id));
    });
    if (error == null) {
      _showSaved('Stock updated for ${plural(done.length, 'product')}');
    } else {
      if (done.isNotEmpty) _showSaved('Stock updated for ${plural(done.length, 'product')}. Some didn\'t save.');
      await showApiError(context, error);
    }
  }

  void _showSaved(String message) {
    final pal = AppPalette.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: pal.success, shape: BoxShape.circle),
              child: Icon(AppIcons.check, size: 16, color: pal.onSuccess),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ));
  }

  void _endBulk() => _update(() {
        _bulk = false;
        _selected.clear();
      });

  void _applyToSelected(InvEdit Function(InvRow r) fn) {
    final rows = _rows.where((r) => _selected.contains(r.id) && r.manageable).toList();
    _update(() {
      for (final r in rows) {
        final e = fn(r);
        if (InvRow(r.product, e).changed) {
          _edits[r.id] = e;
        } else {
          _edits.remove(r.id);
        }
      }
      _bulk = false;
      _selected.clear();
    });
  }

  Future<void> _setStock() async {
    final rows = _rows.where((r) => _selected.contains(r.id) && r.manageable).toList();
    final res = await showModalBottomSheet<({bool add, int value})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SetStockSheet(rows: rows),
    );
    if (res == null) return;
    _applyToSelected((r) => setStockEdit(r, add: res.add, value: res.value));
  }

  Future<bool> _confirmLeave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: Text('${plural(_edits.length, 'change')} to your stock ${_edits.length == 1 ? "isn't" : "aren't"} saved yet.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep editing')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final pal = AppPalette.of(context);
    final products = _products;

    if (products == null) {
      if (_error != null) {
        return EmptyState(
          icon: AppIcons.offline,
          message: "Couldn't load your inventory.",
          actionLabel: 'Try again',
          onAction: _load,
        );
      }
      return const _InventorySkeleton();
    }

    final rows = _rows;
    final searched = rows.where((r) => matchesQuery(r.product, _search.text)).toList();
    final list = searched.where((r) => r.matches(_filter)).toList();
    final health = stockHealth(rows);
    final selectable = list.where((r) => r.manageable).map((r) => r.id).toList();
    final allSelected = selectable.isNotEmpty && selectable.every(_selected.contains);

    return PopScope(
      canPop: !_pending && !_bulk,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_bulk) return _endBulk();
        if (await _confirmLeave()) _update(_edits.clear);
      },
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    sliver: SliverList.list(
                      children: [
                        _HealthCard(ok: health.ok, low: health.low, out: health.out, units: health.units),
                        const SizedBox(height: 12),
                        _InvSearch(controller: _search, onChanged: (_) => setState(() {})),
                        const SizedBox(height: 12),
                        _FilterBar(
                          value: _filter,
                          counts: {for (final f in InvFilter.values) f: searched.where((r) => r.matches(f)).length},
                          onChanged: (f) => setState(() => _filter = f),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 52,
                          child: _bulk
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: selectable.isEmpty
                                            ? null
                                            : () => setState(() {
                                                  if (allSelected) {
                                                    _selected.removeAll(selectable);
                                                  } else {
                                                    _selected.addAll(selectable);
                                                  }
                                                }),
                                        child: Row(
                                          children: [
                                            IgnorePointer(child: Checkbox(value: allSelected, onChanged: (_) {})),
                                            Text('Select all (${selectable.length})', style: Theme.of(context).textTheme.titleSmall),
                                          ],
                                        ),
                                      ),
                                    ),
                                    FilledButton.tonal(onPressed: _endBulk, child: const Text('Done')),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        plural(list.length, 'product'),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: pal.muted, fontFeatures: tabularFigures),
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: _saving || rows.every((r) => !r.manageable) ? null : () {
                                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                              _update(() => _bulk = true);
                                            },
                                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 14)),
                                      icon: const Icon(AppIcons.checklist, size: 18),
                                      label: const Text('Bulk edit'),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  if (list.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _InvEmpty(
                        filter: _filter,
                        query: _search.text.trim(),
                        noProducts: rows.isEmpty,
                        onShowAll: () => setState(() {
                          _filter = InvFilter.all;
                          _search.clear();
                        }),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, _) => SizedBox(height: _bulk ? 8 : 12),
                        itemBuilder: (context, i) {
                          final r = list[i];
                          if (_bulk) {
                            return _BulkRow(
                              row: r,
                              selected: _selected.contains(r.id),
                              onTap: r.manageable
                                  ? () => setState(() => _selected.contains(r.id) ? _selected.remove(r.id) : _selected.add(r.id))
                                  : null,
                            );
                          }
                          return InventoryCard(
                            key: ValueKey(r.id),
                            row: r,
                            enabled: !_saving,
                            onToggle: (v) => _edit(r, on: v),
                            onUnits: (n) => _edit(r, units: n),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_bulk)
            _BulkBar(
              selected: _selected.length,
              onClear: () => setState(_selected.clear),
              onSetStock: _setStock,
              onTurnOn: () => _applyToSelected((r) => InvEdit(on: true, units: r.units)),
              onTurnOff: () => _applyToSelected((r) => InvEdit(on: false, units: r.units)),
            )
          else if (_pending)
            _SaveBar(changes: _edits.length, saving: _saving, onDiscard: _discard, onSave: _save),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

Color _levelColor(AppPalette p, InvLevel l) => switch (l) {
      InvLevel.ok || InvLevel.untracked => p.positive.fg,
      InvLevel.low => p.warning.fg,
      InvLevel.out => p.negative.fg,
      InvLevel.locked => p.muted,
    };

BoxDecoration _cardBox(AppPalette p, {Color? color, Color? border}) => BoxDecoration(
      color: color ?? p.card,
      borderRadius: BorderRadius.circular(AppRadius.card),
      border: Border.all(color: border ?? Colors.transparent, width: 1.5),
      boxShadow: p.cardShadow,
    );

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.ok, required this.low, required this.out, required this.units});

  final int ok;
  final int low;
  final int out;
  final int units;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    Widget seg(int n, Color c) => Flexible(
          flex: n,
          child: Container(height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(5))),
        );
    Widget legend(int n, String label, Color c) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: count(n), style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: ' $label'),
              ]),
              style: t.bodySmall?.copyWith(fontSize: 13, color: p.text, fontFeatures: tabularFigures),
            ),
          ],
        );
    final segs = [
      if (ok > 0) seg(ok, p.positive.fg),
      if (low > 0) seg(low, p.warning.fg),
      if (out > 0) seg(out, p.negative.fg),
    ];
    return Semantics(
      container: true,
      label: 'Stock health: $ok in stock, $low low, $out out, ${count(units)} units total',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: _cardBox(p),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: Text('Stock health', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                Text(count(units), style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontFeatures: tabularFigures)),
                Text(' units total', style: t.bodySmall?.copyWith(color: p.muted)),
              ],
            ),
            const SizedBox(height: 10),
            if (segs.isEmpty)
              Container(height: 10, decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(5)))
            else
              Row(children: [for (var i = 0; i < segs.length; i++) ...[if (i > 0) const SizedBox(width: 3), segs[i]]]),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                legend(ok, 'in stock', p.positive.fg),
                legend(low, 'low', p.warning.fg),
                legend(out, 'out', p.negative.fg),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InvSearch extends StatelessWidget {
  const _InvSearch({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    // A barcode button joins this field once products carry a barcode (§8.5).
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search by name or PR number',
        prefixIcon: const Icon(AppIcons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(AppIcons.close),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.value, required this.counts, required this.onChanged});

  final InvFilter value;
  final Map<InvFilter, int> counts;
  final ValueChanged<InvFilter> onChanged;

  static const _labels = {InvFilter.all: 'All', InvFilter.inStock: 'In stock', InvFilter.low: 'Low', InvFilter.out: 'Out'};

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          for (final f in InvFilter.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Semantics(
                  button: true,
                  selected: f == value,
                  label: '${_labels[f]}, ${counts[f]}',
                  excludeSemantics: true,
                  child: Material(
                    color: f == value ? p.card : Colors.transparent,
                    elevation: f == value ? 1 : 0,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(11),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(11),
                      onTap: () => onChanged(f),
                      child: SizedBox(
                        height: 44,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                _labels[f]!,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: t.labelLarge?.copyWith(fontSize: 13, color: f == value ? p.text : p.muted),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              constraints: const BoxConstraints(minWidth: 18),
                              height: 18,
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: f == value ? p.primary : p.border,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                '${counts[f]}',
                                style: t.labelSmall?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: f == value ? p.onPrimary : p.text,
                                  fontFeatures: tabularFigures,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One product: name, PR and status, the "Sell on site" switch and the
/// "Units in stock" stepper, then its stock line.
class InventoryCard extends StatelessWidget {
  const InventoryCard({super.key, required this.row, required this.onToggle, required this.onUnits, this.enabled = true});

  final InvRow row;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onUnits;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final r = row;
    final level = r.level;
    final warn = r.needsUnits;
    final canEdit = enabled && r.manageable;
    final caption = t.labelSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: p.muted);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardBox(
        p,
        color: warn ? Color.alphaBlend(p.negative.bg.withValues(alpha: 0.45), p.card) : null,
        border: r.changed ? p.primary.withValues(alpha: 0.55) : (warn ? p.negative.fg.withValues(alpha: 0.3) : null),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ProductThumb(r.product, size: 52, radius: 12, starInset: -5),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.product.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (r.product.prNumber != null) ...[
                          Text(r.product.prNumber!, style: t.bodySmall?.copyWith(color: p.muted, fontFeatures: tabularFigures)),
                          const SizedBox(width: 8),
                        ],
                        StatusBadge.product(r.product.status),
                        const Spacer(),
                        if (r.changed) ...[
                          Container(width: 7, height: 7, decoration: BoxDecoration(color: p.primary, shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Text('Edited', style: t.labelSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: p.primary)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Sell on site', style: caption),
                    const SizedBox(height: 4),
                    _SellSwitch(value: r.on, onChanged: canEdit ? onToggle : null),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Units in stock', style: caption),
                    const SizedBox(height: 4),
                    UnitsStepper(
                      units: r.units,
                      // A saved live product with 0 units isn't tracked.
                      showEmpty: level == InvLevel.untracked,
                      highlight: r.units != r.savedUnits,
                      onChanged: canEdit && r.on ? onUnits : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: _levelColor(p, level), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r.levelText,
                  style: t.bodySmall?.copyWith(
                    fontSize: 13,
                    fontWeight: level == InvLevel.ok || level == InvLevel.untracked ? FontWeight.w500 : FontWeight.w700,
                    color: level == InvLevel.untracked ? p.muted : _levelColor(p, level),
                    fontFeatures: tabularFigures,
                  ),
                ),
              ),
              if (!r.manageable)
                Text(
                  r.product.status == 'Pending' ? 'Can sell after review' : 'Not live yet',
                  style: t.bodySmall?.copyWith(color: p.muted),
                )
              else if (!r.on)
                Text('Turn on to set units', style: t.bodySmall?.copyWith(color: p.muted)),
            ],
          ),
          if (warn) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: p.negative.bg, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Icon(AppIcons.warning, size: 16, color: p.negative.fg),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'On, but 0 units. Buyers see this as unavailable.',
                      style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: p.negative.fg),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SellSwitch extends StatelessWidget {
  const _SellSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final on = onChanged != null;
    return Semantics(
      toggled: value,
      enabled: on,
      label: 'Sell on site',
      excludeSemantics: true,
      onTap: on ? () => onChanged!(!value) : null,
      child: Opacity(
        opacity: on ? 1 : 0.55,
        child: Material(
          color: p.card,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: p.border, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: on ? () => onChanged!(!value) : null,
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(value: value, onChanged: onChanged, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    value ? 'On' : 'Off',
                    style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: value ? p.primary : p.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// − [number] + with a field you can type in. `null` [onChanged] locks it.
class UnitsStepper extends StatefulWidget {
  const UnitsStepper({
    super.key,
    required this.units,
    required this.onChanged,
    this.showEmpty = false,
    this.highlight = false,
    this.height = 48,
    this.fontSize = 17,
    this.emptyHint = 'Not set',
  });

  final int units;
  final ValueChanged<int>? onChanged;
  final bool showEmpty;
  final bool highlight;
  final double height;
  final double fontSize;

  /// Shown in the field when [showEmpty] (units not tracked).
  final String emptyHint;

  @override
  State<UnitsStepper> createState() => _UnitsStepperState();
}

class _UnitsStepperState extends State<UnitsStepper> {
  late final _ctrl = TextEditingController(text: _text);

  String get _text => widget.showEmpty ? '' : '${widget.units}';

  @override
  void didUpdateWidget(UnitsStepper old) {
    super.didUpdateWidget(old);
    final typed = int.tryParse(_ctrl.text) ?? 0;
    if (typed != widget.units || old.showEmpty != widget.showEmpty) {
      _ctrl.value = TextEditingValue(text: _text, selection: TextSelection.collapsed(offset: _text.length));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final on = widget.onChanged != null;
    final u = widget.units;
    Widget btn(IconData icon, String tip, int? next) => SizedBox(
          width: 44,
          height: widget.height,
          child: IconButton(
            tooltip: tip,
            onPressed: on && next != null ? () => widget.onChanged!(next) : null,
            color: p.primary,
            disabledColor: p.muted.withValues(alpha: 0.5),
            icon: Icon(icon, size: 20),
          ),
        );
    return Opacity(
      opacity: on ? 1 : 0.55,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.highlight ? p.primary : p.border, width: 1.5),
        ),
        child: Row(
          children: [
            btn(AppIcons.minus, 'One fewer', u > 0 ? u - 1 : null),
            Expanded(
              child: TextField(
                controller: _ctrl,
                enabled: on,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
                style: t.titleMedium?.copyWith(fontSize: widget.fontSize, fontWeight: FontWeight.w700, fontFeatures: tabularFigures),
                decoration: InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintText: widget.showEmpty ? widget.emptyHint : null,
                  hintStyle: t.bodySmall?.copyWith(fontSize: 13, color: p.muted),
                  semanticCounterText: '',
                ),
                onChanged: (s) => widget.onChanged?.call((int.tryParse(s) ?? 0).clamp(0, maxUnits)),
              ),
            ),
            btn(AppIcons.add, 'One more', u < maxUnits ? u + 1 : null),
          ],
        ),
      ),
    );
  }
}

class _BulkRow extends StatelessWidget {
  const _BulkRow({required this.row, required this.selected, required this.onTap});

  final InvRow row;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final r = row;
    final pill = !r.manageable
        ? (productStatusLabel(r.product.status), p.neutral)
        : r.on
            ? ('On', Tone(p.primary, p.primarySoft2))
            : ('Off', p.neutral);
    return Semantics(
      checked: selected,
      enabled: onTap != null,
      label: '${r.product.title}, ${r.levelText}, ${pill.$1}',
      excludeSemantics: true,
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.55 : 1,
        child: Material(
          color: selected ? p.primarySoft : p.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: BorderSide(color: selected ? p.primary : Colors.transparent, width: 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 68),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
                child: Row(
                  children: [
                    IgnorePointer(child: Checkbox(value: selected, onChanged: onTap == null ? null : (_) {})),
                    ProductThumb(r.product, size: 44, radius: 10, starInset: -4),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.product.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: _levelColor(p, r.level), shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  r.levelText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.bodySmall?.copyWith(color: p.muted, fontFeatures: tabularFigures),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: pill.$2.bg, borderRadius: BorderRadius.circular(999)),
                      child: Center(
                        widthFactor: 1,
                        child: Text(pill.$1, style: t.labelSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: pill.$2.fg)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.card,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: p.isDark ? 0.4 : 0.1), blurRadius: 20, offset: const Offset(0, -6))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), child: child),
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.changes, required this.saving, required this.onDiscard, required this.onSave});

  final int changes;
  final bool saving;
  final VoidCallback onDiscard;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    return _BottomBar(
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(plural(changes, 'change'), style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontFeatures: tabularFigures)),
                  Text(saving ? 'Saving…' : 'Not saved yet', style: t.bodySmall?.copyWith(color: p.muted)),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: saving ? null : onDiscard,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              child: const Text('Discard'),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: saving ? null : onSave,
              style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
              child: saving
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: p.muted))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulkBar extends StatelessWidget {
  const _BulkBar({
    required this.selected,
    required this.onClear,
    required this.onSetStock,
    required this.onTurnOn,
    required this.onTurnOff,
  });

  final int selected;
  final VoidCallback onClear;
  final VoidCallback onSetStock;
  final VoidCallback onTurnOn;
  final VoidCallback onTurnOff;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final any = selected > 0;
    const size = Size(0, 48);
    return _BottomBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 32,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    any ? '$selected selected' : 'Select products',
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontFeatures: tabularFigures),
                  ),
                ),
                if (any) TextButton(onPressed: onClear, child: const Text('Clear')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: any ? onSetStock : null,
                  style: FilledButton.styleFrom(minimumSize: size, padding: EdgeInsets.zero),
                  child: const Text('Set stock'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: any ? onTurnOn : null,
                  style: OutlinedButton.styleFrom(minimumSize: size, padding: EdgeInsets.zero),
                  child: const Text('Turn on'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: any ? onTurnOff : null,
                  style: OutlinedButton.styleFrom(minimumSize: size, padding: EdgeInsets.zero),
                  child: const Text('Turn off'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bulk "Set stock": an exact number or added to each product's current
/// units, with a before → after preview. It only changes the draft.
class _SetStockSheet extends StatefulWidget {
  const _SetStockSheet({required this.rows});
  final List<InvRow> rows;

  @override
  State<_SetStockSheet> createState() => _SetStockSheetState();
}

class _SetStockSheetState extends State<_SetStockSheet> {
  bool _add = false;
  int _value = 10;

  bool get _valid => _value >= 1 && _value <= maxUnits;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final rows = widget.rows;
    final shown = rows.take(4).toList();
    final turnsOn = rows.where((r) => !r.on).length;

    Widget option(bool add, String title, String sub) {
      final sel = _add == add;
      return Expanded(
        child: Semantics(
          inMutuallyExclusiveGroup: true,
          checked: sel,
          child: Material(
            color: sel ? p.primarySoft : p.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: sel ? p.primary : p.border, width: 2),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _add = add),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: sel ? p.primary : p.text)),
                      const SizedBox(height: 2),
                      Text(sub, style: t.bodySmall?.copyWith(color: sel ? p.primary : p.muted)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Set stock', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              Text('${plural(rows.length, 'product')} selected', style: t.bodySmall?.copyWith(color: p.muted)),
              const SizedBox(height: 14),
              Row(
                children: [
                  option(false, 'Set to exact number', 'Each gets this many'),
                  const SizedBox(width: 8),
                  option(true, 'Add to current stock', 'New units arrived'),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _add ? 'Units to add to each product' : 'Units for each product',
                style: t.labelLarge?.copyWith(color: p.muted),
              ),
              const SizedBox(height: 6),
              UnitsStepper(
                units: _value,
                height: 56,
                fontSize: 22,
                highlight: true,
                onChanged: (v) => setState(() => _value = v),
              ),
              if (!_valid) ...[
                const SizedBox(height: 6),
                Text('Enter 1 – 1,000,000', style: t.bodySmall?.copyWith(color: p.danger)),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    for (var i = 0; i < shown.length; i++)
                      Container(
                        height: 38,
                        decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: p.divider))),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(shown[i].product.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(fontSize: 13, color: p.text)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              shown[i].on ? count(shown[i].units) : 'Off',
                              style: t.bodySmall?.copyWith(fontSize: 13, color: p.muted, fontFeatures: tabularFigures),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(AppIcons.arrowRight, size: 14, color: p.muted),
                            ),
                            ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 28),
                              child: Text(
                                count(setStockEdit(shown[i], add: _add, value: _valid ? _value : 0).units),
                                textAlign: TextAlign.right,
                                style: t.bodySmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: p.text, fontFeatures: tabularFigures),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (rows.length > shown.length)
                      Container(
                        height: 34,
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(border: Border(top: BorderSide(color: p.divider))),
                        child: Text('+ ${plural(rows.length - shown.length, 'more product')}', style: t.bodySmall?.copyWith(color: p.muted)),
                      ),
                  ],
                ),
              ),
              if (turnsOn > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '${plural(turnsOn, 'product')} that ${turnsOn == 1 ? 'is' : 'are'} off will be turned on.',
                  style: t.bodySmall?.copyWith(color: p.muted),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _valid ? () => Navigator.pop(context, (add: _add, value: _value)) : null,
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                      child: Text('Apply to ${rows.length}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'You can check the changes before you save.',
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(color: p.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvEmpty extends StatelessWidget {
  const _InvEmpty({required this.filter, required this.query, required this.noProducts, required this.onShowAll});

  final InvFilter filter;
  final String query;
  final bool noProducts;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final allGood = query.isEmpty && (filter == InvFilter.out || filter == InvFilter.low);
    final (title, body) = noProducts
        ? ('No products yet', 'Products you add show up here once AtomShop approves them.')
        : query.isNotEmpty
            ? ('No products match “$query”', 'Try a different name or PR number.')
            : switch (filter) {
                InvFilter.out => ('Nothing out of stock', 'All your products can be bought right now.'),
                InvFilter.low => ('Nothing running low', 'Every product on sale has 5 or more units.'),
                _ => ('No products here', 'Products show up here when their stock changes.'),
              };
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: allGood ? p.positive.bg : p.primarySoft2, shape: BoxShape.circle),
            child: Icon(
              allGood ? AppIcons.check : AppIcons.package,
              size: 36,
              color: allGood ? p.positive.fg : p.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(body, textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: p.muted)),
          if (!noProducts) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onShowAll,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              child: const Text('Show all products'),
            ),
          ],
        ],
      ),
    );
  }
}

class _InventorySkeleton extends StatelessWidget {
  const _InventorySkeleton();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    Widget card(double h) => Container(
          height: h,
          padding: const EdgeInsets.all(12),
          decoration: _cardBox(p),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Bone(width: 52, height: 52, radius: 12),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Bone(height: 14), SizedBox(height: 8), Bone(width: 110, height: 12)],
                    ),
                  ),
                ],
              ),
              Spacer(),
              Row(
                children: [
                  Expanded(child: Bone(height: 48, radius: 12)),
                  SizedBox(width: 10),
                  Expanded(child: Bone(height: 48, radius: 12)),
                ],
              ),
            ],
          ),
        );
    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        children: [
          card(96),
          const SizedBox(height: 12),
          const Bone(height: 48, radius: 14),
          const SizedBox(height: 12),
          const Bone(height: 50, radius: 14),
          const SizedBox(height: 16),
          for (var i = 0; i < 3; i++) ...[card(150), const SizedBox(height: 12)],
        ],
      ),
    );
  }
}
