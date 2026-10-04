import 'dart:async';
import '../../core/app_icons.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/models/dashboard.dart';
import '../../data/models/product.dart';
import '../../data/repositories/catalogue_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/paged_list.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/status_badge.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard/dashboard_widgets.dart';
import 'product_cards.dart';
import 'inventory_tab.dart';
import 'product_logic.dart';

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
          bottom: TabBar(
            labelColor: AppPalette.of(context).onHeader,
            unselectedLabelColor: AppPalette.of(context).onHeaderMuted,
            indicatorColor: AppPalette.of(context).accent,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'Products'),
              Tab(text: 'Inventory'),
            ],
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

// ---------------------------------------------------------------------------
// Products

/// Products (DESIGN.md §4.7): overview counts, search, status chips, list or
/// grid. Problems (no stock, no photo) show on the card itself.
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
  bool _grid = false;
  bool _fabExtended = true;
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

  void _setStatus(String? s) {
    setState(() => _status = s);
    _list.refresh();
  }

  Future<void> _reload() async {
    ref.invalidate(dashboardProvider);
    await _list.refresh(showSpinner: false);
  }

  Future<void> _open(String location) async {
    final changed = await context.push<bool>(location);
    if (changed == true) await _reload();
  }

  Future<void> _updateStock(ProductSummary p) async {
    final n = await askStock(context, initial: p.stock > 0 ? p.stock : 1, title: 'Units in stock');
    if (n == null) return;
    try {
      await ref.read(catalogueRepositoryProvider).setStock(p.id, available: true, stock: n);
      if (mounted) showToast(context, 'In stock: ${count(n)} units.');
      await _reload();
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _toggleFeatured(ProductSummary p) async {
    try {
      final featured = await ref.read(catalogueRepositoryProvider).toggleFeatured(p.id);
      if (mounted) showToast(context, featured ? 'Featured on your brand page.' : 'Removed from your brand page.');
      await _list.refresh(showSpinner: false);
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  void _quickActions(ProductSummary p) => showProductQuickActions(
    context,
    p,
    onEdit: () => _open('/products/${p.id}/edit'),
    onUpdateStock: canSetStock(p) ? () => _updateStock(p) : null,
    onToggleFeatured: () => _toggleFeatured(p),
  );

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final extended = n.metrics.pixels < 24;
    if (extended != _fabExtended) setState(() => _fabExtended = extended);
    if (n.metrics.extentAfter < 400) _list.loadMore();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final statuses = ref.watch(configProvider).value?.productStatuses ?? const [];
    final dash = ref.watch(dashboardProvider).value;
    return ListenableBuilder(
      listenable: _list,
      builder: (context, _) {
        final c = _list;
        final catalogueEmpty =
            !c.loading && c.error == null && c.items.isEmpty && _status == null && _search.text.isEmpty;
        return Scaffold(
          floatingActionButton: catalogueEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _open('/products/new'),
                  isExtended: _fabExtended,
                  tooltip: 'Add product',
                  icon: const Icon(AppIcons.add),
                  label: const Text('Add product'),
                ),
          body: RefreshIndicator(
            onRefresh: _reload,
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [if (!catalogueEmpty) ..._header(context, statuses, dash), ..._body(context, catalogueEmpty)],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _header(BuildContext context, List<String> statuses, Dashboard? dash) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final c = _list;
    final total = c.firstPage?.pagination.total ?? c.items.length;
    final counts = <String?, int>{
      if (dash != null) ...{
        null: dash.catalogueTotal,
        'Published': dash.cataloguePublished,
        'Pending': dash.cataloguePending,
        'Out of Stock': dash.catalogueOutOfStock,
      },
    };
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        sliver: SliverToBoxAdapter(
          child: Column(
            children: [
              if (dash != null) ...[
                _OverviewStrip(dash: dash, selected: _status, onPick: _setStatus),
                const SizedBox(height: 12),
              ],
              _SearchField(controller: _search, onChanged: _onSearch, hint: 'Search products'),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 58,
          child: Stack(
            children: [
              ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 6, 40, 4),
                children: [
                  for (final s in [null, ...statuses])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: s == null ? 'All' : productStatusLabel(s),
                        n: counts[s],
                        selected: _status == s,
                        onTap: () => _setStatus(s),
                      ),
                    ),
                ],
              ),
              // Fades chips out at the edge instead of cutting them off.
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: 44,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [p.page.withValues(alpha: 0), p.page], stops: const [0, 0.8]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      if (_status == 'Out of Stock' && c.items.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          sliver: SliverToBoxAdapter(
            child: Material(
              color: p.negative.bg,
              borderRadius: BorderRadius.circular(AppRadius.control),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.control),
                onTap: () => DefaultTabController.of(context).animateTo(1),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Icon(AppIcons.warning, size: 20, color: p.negative.fg),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "${count(total)} ${total == 1 ? "product can't" : "products can't"} be bought. Update stock in Inventory →",
                            style: t.bodySmall?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: p.negative.fg,
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
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  c.loading && c.items.isEmpty ? '' : '${count(total)} ${total == 1 ? 'product' : 'products'}',
                  style: t.bodySmall?.copyWith(fontSize: 13, color: p.muted, fontFeatures: tabularFigures),
                ),
              ),
              _ViewToggle(grid: _grid, onChanged: (g) => setState(() => _grid = g)),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _body(BuildContext context, bool catalogueEmpty) {
    final c = _list;
    Widget fill(Widget child) => SliverFillRemaining(hasScrollBody: false, child: child);
    if (c.loading && c.items.isEmpty) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          sliver: SliverToBoxAdapter(
            child: Semantics(
              label: 'Loading products',
              child: const Shimmer(
                child: Column(
                  children: [
                    _ProductBone(),
                    SizedBox(height: 10),
                    _ProductBone(),
                    SizedBox(height: 10),
                    _ProductBone(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ];
    }
    if (c.error != null && c.items.isEmpty) return [fill(ErrorView(message: c.error!, onRetry: c.refresh))];
    if (catalogueEmpty) return [fill(_EmptyCatalogue(onAdd: () => _open('/products/new')))];
    if (c.items.isEmpty) {
      return [
        fill(
          EmptyState(
            icon: AppIcons.searchEmpty,
            message: _search.text.isEmpty
                ? 'No products with this status.'
                : 'No products match ‘${_search.text.trim()}’.',
            actionLabel: 'Show all products',
            onAction: () {
              _search.clear();
              _setStatus(null);
            },
          ),
        ),
      ];
    }
    final items = c.items;
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        sliver: _grid
            ? SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 250,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) => ProductGridCard(
                  product: items[i],
                  onTap: () => _open('/products/${items[i].id}'),
                  onLongPress: () => _quickActions(items[i]),
                ),
              )
            : SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) => ProductListCard(
                  product: items[i],
                  onTap: () => _open('/products/${items[i].id}'),
                  onLongPress: () => _quickActions(items[i]),
                  onFixStock: () => _updateStock(items[i]),
                ),
              ),
      ),
      SliverToBoxAdapter(
        child: c.loadingMore
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            : const SizedBox.shrink(),
      ),
      // Room for the FAB, so it never sits on a price or stock line.
      const SliverToBoxAdapter(child: SizedBox(height: 96)),
    ];
  }
}

/// Total · Live · In review · Out of stock, from the dashboard counts. Each
/// box filters the list.
class _OverviewStrip extends StatelessWidget {
  const _OverviewStrip({required this.dash, required this.selected, required this.onPick});
  final Dashboard dash;
  final String? selected;
  final ValueChanged<String?> onPick;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final boxes = [
      (null, 'Total', dash.catalogueTotal),
      ('Published', 'Live', dash.cataloguePublished),
      ('Pending', 'In review', dash.cataloguePending),
      ('Out of Stock', 'Out of stock', dash.catalogueOutOfStock),
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, b) in boxes.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                button: true,
                selected: selected == b.$1,
                label: '${b.$2}: ${b.$3}',
                excludeSemantics: true,
                child: Material(
                  color: p.card,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    onTap: () => onPick(b.$1),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 60),
                      padding: const EdgeInsets.fromLTRB(10, 9, 6, 9),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.control),
                        border: Border.all(color: selected == b.$1 ? p.primary : Colors.transparent, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            count(b.$3),
                            style: t.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: b.$1 == 'Out of Stock' && b.$3 > 0 ? p.negative.fg : p.text,
                              fontFeatures: tabularFigures,
                            ),
                          ),
                          Text(b.$2, style: t.bodySmall?.copyWith(color: p.muted, height: 1.25)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.n, required this.selected, required this.onTap});
  final String label;
  final int? n;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      label: n == null ? label : '$label, $n',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Center(
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? p.primarySoft2 : p.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: selected ? p.primary.withValues(alpha: 0.35) : p.border, width: 1.5),
            ),
            child: Text(
              n == null ? label : '$label (${count(n)})',
              style: t.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? p.primary : p.text,
                fontFeatures: tabularFigures,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.grid, required this.onChanged});
  final bool grid;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    Widget button(bool isGrid, IconData icon, String label) => IconButton(
      tooltip: label,
      isSelected: grid == isGrid,
      onPressed: () => onChanged(isGrid),
      style: IconButton.styleFrom(
        fixedSize: const Size(44, 44),
        backgroundColor: grid == isGrid ? p.primarySoft2 : Colors.transparent,
        foregroundColor: grid == isGrid ? p.primary : p.muted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 20),
    );
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(false, AppIcons.listView, 'List view'),
          button(true, AppIcons.grid, 'Grid view'),
        ],
      ),
    );
  }
}

class _ProductBone extends StatelessWidget {
  const _ProductBone();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: p.cardShadow,
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Bone(width: 72, height: 72, radius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone(height: 14),
                SizedBox(height: 8),
                Bone(width: 110, height: 12),
                SizedBox(height: 12),
                Row(
                  children: [Bone(width: 80, height: 16), SizedBox(width: 8), Bone(width: 52, height: 22, radius: 999)],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCatalogue extends StatelessWidget {
  const _EmptyCatalogue({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
      child: Column(
        children: [
          const EmptyStoreIllustration(),
          const SizedBox(height: 24),
          Text(
            'Your catalogue is empty',
            textAlign: TextAlign.center,
            style: t.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first product. AtomShop will review it before it goes live.',
            textAlign: TextAlign.center,
            style: t.bodyMedium?.copyWith(color: p.muted, height: 1.5),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              minimumSize: const Size(64, 52),
              padding: const EdgeInsets.symmetric(horizontal: 28),
            ),
            icon: const Icon(AppIcons.add),
            label: const Text('Add product'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Stock count dialog with a stepper (1–1,000,000).
Future<int?> askStock(BuildContext context, {required int initial, required String title}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _StockDialog(initial: initial, title: title),
  );
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
          IconButton.outlined(tooltip: 'Decrease', onPressed: () => _step(-1), icon: const Icon(AppIcons.minus)),
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
          IconButton.outlined(tooltip: 'Increase', onPressed: () => _step(1), icon: const Icon(AppIcons.add)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _valid ? () => Navigator.pop(context, _value) : null, child: const Text('Save')),
      ],
    );
  }
}
