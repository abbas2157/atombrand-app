import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/models/product.dart';
import '../../data/repositories/catalogue_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/status_badge.dart';

final productFormOptionsProvider = FutureProvider<ProductFormOptions>(
  (ref) => ref.watch(catalogueRepositoryProvider).formOptions(),
);

/// Product detail: Edit · Feature on brand page · Delete (§3.2).
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  ProductDetail? _p;
  String? _error;
  bool _busy = false;
  bool _changed = false;

  CatalogueRepository get _repo => ref.read(catalogueRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final p = await _repo.product(widget.id);
      if (mounted) setState(() => _p = p);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _guard(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) await showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleFeatured() => _guard(() async {
        final featured = await _repo.toggleFeatured(widget.id);
        _changed = true;
        if (mounted) showToast(context, featured ? 'Featured on your brand page.' : 'Removed from your brand page.');
        await _load();
      });

  Future<void> _delete() async {
    final p = _p!.summary;
    final ok = await confirm(
      context,
      title: 'Delete product?',
      message: '"${p.title}" will be removed from your catalogue. This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repo.delete(widget.id);
      if (!mounted) return;
      showToast(context, 'Product deleted.');
      context.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      // Ever-ordered products can't be deleted: offer out-of-stock instead.
      if (e.isConflict && p.canManageStock && !p.isOutOfStock) {
        final markOut = await confirm(
          context,
          title: "Can't delete this product",
          message: '${e.message}\n\nMark it out of stock instead, so buyers can no longer order it?',
          confirmLabel: 'Mark out of stock',
        );
        if (markOut) {
          await _guard(() async {
            await _repo.setStock(widget.id, available: false);
            _changed = true;
            await _load();
          });
        }
      } else {
        await showApiError(context, e);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    final saved = await context.push<bool>('/products/${widget.id}/edit');
    if (saved == true) {
      _changed = true;
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Product'),
          actions: [
            if (p != null) ...[
              IconButton(
                tooltip: p.summary.brandFeatured ? 'Remove from brand page' : 'Feature on brand page',
                onPressed: _busy ? null : _toggleFeatured,
                icon: Icon(p.summary.brandFeatured ? Icons.star_rounded : Icons.star_outline_rounded),
              ),
              PopupMenuButton<String>(
                tooltip: 'More',
                onSelected: (v) {
                  if (v == 'delete') _delete();
                  if (v == 'view') openExternal(context, p.summary.publicUrl);
                },
                itemBuilder: (_) => [
                  if (p.summary.isLive && p.summary.publicUrl != null)
                    const PopupMenuItem(value: 'view', child: Text('View on AtomShop')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete product')),
                ],
              ),
            ],
          ],
        ),
        body: p == null
            ? (_error != null ? ErrorView(message: _error!, onRetry: _load) : const Center(child: CircularProgressIndicator()))
            : Stack(
                children: [
                  RefreshIndicator(onRefresh: _load, child: _body(p)),
                  if (_busy) const LinearProgressIndicator(),
                ],
              ),
        bottomNavigationBar: p == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _edit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit product'),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _body(ProductDetail d) {
    final t = Theme.of(context).textTheme;
    final p = d.summary;
    final options = ref.watch(productFormOptionsProvider).value;
    String names(List<int> ids, List<VariantOption>? opts) =>
        ids.map((id) => opts?.where((o) => o.id == id).firstOrNull?.label ?? '#$id').join(', ');
    String priced(List<VariantPrice> vs, List<VariantOption>? opts) => vs
        .map((v) => '${opts?.where((o) => o.id == v.id).firstOrNull?.label ?? '#${v.id}'}: ${money(v.price)}')
        .join('\n');

    final images = [if (p.picture != null) p.picture!, ...d.gallery.map((g) => g.url)];
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (p.status == 'Pending') ...[
          const InfoBanner('In review. AtomShop checks every new product and every edit before it goes live.'),
          const SizedBox(height: 12),
        ],
        if (images.isNotEmpty)
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => NetThumb(images[i], size: 200, radius: AppRadius.card),
            ),
          ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.title, style: t.titleLarge),
              if (d.detailPageTitle != null) Text(d.detailPageTitle!, style: t.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  StatusBadge.product(p.status),
                  if (p.brandFeatured) const StatusBadge('Featured', BadgeTone.warning),
                ],
              ),
              const SizedBox(height: 8),
              KeyValue('Price', money(p.price), emphasize: true),
              KeyValue('Minimum advance', money(p.minAdvancePrice)),
              KeyValue('Stock', count(p.stock)),
              KeyValue('PR number', p.prNumber),
              KeyValue('Category', p.category?.title),
              KeyValue('Shown under brand', p.displayBrand?.title),
              KeyValue('Last updated', formatDateTime(p.updatedAt)),
            ],
          ),
        ),
        if (d.colors.isNotEmpty || d.memories.isNotEmpty || d.sizes.isNotEmpty) ...[
          const SectionTitle('Variants'),
          AppCard(
            child: Column(
              children: [
                if (d.colors.isNotEmpty) KeyValue('Colours', names(d.colors, options?.colors)),
                if (d.memories.isNotEmpty) KeyValue('Storage', priced(d.memories, options?.memories)),
                if (d.sizes.isNotEmpty) KeyValue('Sizes', priced(d.sizes, options?.sizes)),
              ],
            ),
          ),
        ],
        if (d.short != null) ...[
          const SectionTitle('Short description'),
          AppCard(child: Text(d.short!, style: t.bodyMedium)),
        ],
        if (d.long != null && stripHtml(d.long!).isNotEmpty) ...[
          const SectionTitle('Full description'),
          AppCard(child: Text(stripHtml(d.long!), style: t.bodyMedium)),
        ],
      ],
    );
  }
}

/// Plain-text preview of the HTML `long` description.
String stripHtml(String html) => html
    .replaceAll(RegExp(r'<br\s*/?>|</p>|</li>|</h\d>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll(RegExp(r'\n{3,}'), '\n\n')
    .trim();
