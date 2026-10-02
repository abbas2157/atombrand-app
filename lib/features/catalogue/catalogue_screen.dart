import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/models/json.dart';
import '../../data/models/product.dart';
import '../../data/repositories/catalogue_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/paged_list.dart';
import '../../widgets/status_badge.dart';

/// Catalogue tab: Products | Inventory.
class CatalogueScreen extends StatelessWidget {
  const CatalogueScreen({super.key, this.initialStatus});

  final String? initialStatus;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Catalogue'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: AppColors.primary,
            tabs: [Tab(text: 'Products'), Tab(text: 'Inventory')],
          ),
        ),
        body: TabBarView(
          children: [
            ProductsTab(initialStatus: initialStatus),
            const InventoryTab(),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged, required this.hint});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Products

class ProductsTab extends ConsumerStatefulWidget {
  const ProductsTab({super.key, this.initialStatus});

  final String? initialStatus;

  @override
  ConsumerState<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends ConsumerState<ProductsTab> with AutomaticKeepAliveClientMixin {
  late String? _status = widget.initialStatus;
  final _search = TextEditingController();
  Timer? _debounce;
  late final _list = PagedController<ProductSummary>(
    (page) => ref.read(catalogueRepositoryProvider).products(q: _search.text.trim(), status: _status, page: page),
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _list.refresh();
  }

  @override
  void didUpdateWidget(ProductsTab old) {
    super.didUpdateWidget(old);
    if (old.initialStatus != widget.initialStatus) {
      _status = widget.initialStatus;
      _list.refresh();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _list.dispose();
    super.dispose();
  }

  void _onSearch(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _list.refresh);
  }

  Future<void> _open(String location) async {
    final changed = await context.push<bool>(location);
    if (changed == true) _list.refresh(showSpinner: false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final statuses = ref.watch(configProvider).value?.productStatuses ?? const [];
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open('/products/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add product'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _SearchField(controller: _search, onChanged: _onSearch, hint: 'Search products'),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                for (final s in [null, ...statuses])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      showCheckmark: false,
                      label: Text(s == null ? 'All' : productStatusLabel(s)),
                      selected: _status == s,
                      onSelected: (_) {
                        setState(() => _status = s);
                        _list.refresh();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: PagedListView<ProductSummary>(
              controller: _list,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              empty: _status == null && _search.text.isEmpty
                  ? EmptyState(
                      icon: Icons.inventory_2_outlined,
                      message: 'Add your first product. AtomShop reviews it before it goes live.',
                      actionLabel: 'Add product',
                      onAction: () => _open('/products/new'),
                    )
                  : const EmptyState(icon: Icons.search_off_rounded, message: 'No products match.'),
              itemBuilder: (context, p) => ProductTile(product: p, onTap: () => _open('/products/${p.id}')),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thumb, title, PR number, price, status badge, stock count (§4.5).
class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product, this.onTap, this.trailing});

  final ProductSummary product;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = product;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          NetThumb(p.picture, size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(p.title, style: t.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis)),
                    if (p.brandFeatured)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.star_rounded, size: 18, color: AppColors.primary, semanticLabel: 'Featured'),
                      ),
                  ],
                ),
                Text([p.prNumber, p.category?.title].whereType<String>().join(' · '), style: t.bodySmall),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(money(p.price), style: t.titleMedium?.copyWith(fontFeatures: tabularFigures)),
                    const SizedBox(width: 8),
                    Flexible(child: StatusBadge.product(p.status)),
                    const Spacer(),
                    if (trailing == null) Text('Stock ${count(p.stock)}', style: t.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inventory

class InventoryTab extends ConsumerStatefulWidget {
  const InventoryTab({super.key});

  @override
  ConsumerState<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends ConsumerState<InventoryTab> with AutomaticKeepAliveClientMixin {
  String? _availability; // null | in | out
  int _inStock = 0;
  int _outOfStock = 0;
  final _search = TextEditingController();
  final _saving = <int>{};
  Timer? _debounce;
  late final _list = PagedController<ProductSummary>(_fetch);

  @override
  bool get wantKeepAlive => true;

  Future<Paged<ProductSummary>> _fetch(int page) async {
    final res = await ref
        .read(catalogueRepositoryProvider)
        .inventory(q: _search.text.trim(), availability: _availability, page: page);
    if (page == 1 && mounted) {
      setState(() {
        _inStock = res.inStock;
        _outOfStock = res.outOfStock;
      });
    }
    return res.page;
  }

  @override
  void initState() {
    super.initState();
    _list.refresh();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _list.dispose();
    super.dispose();
  }

  void _onSearch(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _list.refresh);
  }

  Future<void> _set(ProductSummary p, {required bool available, int? stock}) async {
    if (available && stock == null) {
      stock = await askStock(context, initial: p.stock > 0 ? p.stock : 1, title: 'Mark "${p.title}" available');
      if (stock == null) return;
    }
    setState(() => _saving.add(p.id));
    try {
      await ref.read(catalogueRepositoryProvider).setStock(p.id, available: available, stock: stock);
      if (mounted) showToast(context, available ? 'In stock: ${count(stock)} units.' : 'Marked out of stock.');
      await _list.refresh(showSpinner: false);
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _saving.remove(p.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _SearchField(controller: _search, onChanged: _onSearch, hint: 'Search name or PR number'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<String?>(
              showSelectedIcon: false,
              segments: [
                const ButtonSegment(value: null, label: Text('All')),
                ButtonSegment(value: 'in', label: Text('In stock ($_inStock)')),
                ButtonSegment(value: 'out', label: Text('Out ($_outOfStock)')),
              ],
              selected: {_availability},
              onSelectionChanged: (s) {
                setState(() => _availability = s.first);
                _list.refresh();
              },
            ),
          ),
        ),
        Expanded(
          child: PagedListView<ProductSummary>(
            controller: _list,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
            empty: const EmptyState(icon: Icons.inventory_outlined, message: 'No products here.'),
            itemBuilder: (context, p) => _InventoryTile(
              product: p,
              saving: _saving.contains(p.id),
              onToggle: (v) => _set(p, available: v),
              onEditStock: () async {
                final n = await askStock(context, initial: p.stock > 0 ? p.stock : 1, title: 'Units in stock');
                if (n != null) await _set(p, available: true, stock: n);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({required this.product, required this.saving, required this.onToggle, required this.onEditStock});

  final ProductSummary product;
  final bool saving;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEditStock;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = product;
    final available = p.isLive;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              NetThumb(p.picture),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title, style: t.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Row(
                      children: [
                        if (p.prNumber != null) Text(p.prNumber!, style: t.bodySmall),
                        const SizedBox(width: 8),
                        StatusBadge.product(p.status),
                      ],
                    ),
                  ],
                ),
              ),
              if (saving)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
                )
              else
                Switch(
                  value: available,
                  onChanged: p.canManageStock ? onToggle : null,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (!p.canManageStock)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Stock can be managed once AtomShop approves this product.', style: t.bodySmall),
            )
          else
            Row(
              children: [
                Text(available ? 'Units in stock' : 'Not available to buyers', style: t.bodySmall),
                const Spacer(),
                if (available)
                  TextButton.icon(
                    onPressed: saving ? null : onEditStock,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(count(p.stock), style: t.titleMedium?.copyWith(fontFeatures: tabularFigures)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Stock count dialog with a stepper (1–1,000,000).
Future<int?> askStock(BuildContext context, {required int initial, required String title}) {
  return showDialog<int>(context: context, builder: (_) => _StockDialog(initial: initial, title: title));
}

class _StockDialog extends StatefulWidget {
  const _StockDialog({required this.initial, required this.title});
  final int initial;
  final String title;

  @override
  State<_StockDialog> createState() => _StockDialogState();
}

class _StockDialogState extends State<_StockDialog> {
  static const _max = 1000000;
  late final _ctrl = TextEditingController(text: '${widget.initial}');

  int get _value => int.tryParse(_ctrl.text) ?? 0;
  bool get _valid => _value >= 1 && _value <= _max;

  void _step(int d) {
    final v = (_value + d).clamp(1, _max);
    setState(() => _ctrl.text = '$v');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Row(
        children: [
          IconButton.outlined(tooltip: 'Decrease', onPressed: () => _step(-1), icon: const Icon(Icons.remove_rounded)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(errorText: _ctrl.text.isEmpty || _valid ? null : '1 – 1,000,000'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(tooltip: 'Increase', onPressed: () => _step(1), icon: const Icon(Icons.add_rounded)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _valid ? () => Navigator.pop(context, _value) : null, child: const Text('Save')),
      ],
    );
  }
}
