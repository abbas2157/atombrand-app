import 'package:cached_network_image/cached_network_image.dart';
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
import '../../widgets/skeleton.dart';
import '../../widgets/status_badge.dart';
import 'inventory_logic.dart';
import 'inventory_tab.dart' show UnitsStepper;
import 'product_detail_logic.dart';

final productFormOptionsProvider = FutureProvider<ProductFormOptions>(
  (ref) => ref.watch(catalogueRepositoryProvider).formOptions(),
);

/// Product detail (DESIGN.md §4.9): gallery, a banner saying what the
/// status means and what to do, price, stock you can change in place,
/// performance and the description. Edit · Feature · Delete.
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
  int? _draftUnits;
  bool _stockSaved = false;
  final _stockKey = GlobalKey();

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

  Future<void> _saveStock(int units) => _guard(() async {
        await _repo.setStock(widget.id, available: units > 0, stock: units > 0 ? units : null);
        _changed = true;
        await _load();
        if (!mounted) return;
        setState(() {
          _draftUnits = null;
          _stockSaved = true;
        });
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

  void _showStock() {
    final ctx = _stockKey.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), alignment: 0.1);
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    final pal = AppPalette.of(context);
    final canView = p != null && p.summary.isLive && p.summary.publicUrl != null;
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
                icon: p.summary.brandFeatured
                    ? Icon(Icons.star_rounded, color: pal.accent)
                    : const Icon(Icons.star_outline_rounded),
              ),
              PopupMenuButton<String>(
                tooltip: 'More actions',
                onSelected: (v) {
                  if (v == 'delete') _delete();
                  if (v == 'view') openExternal(context, p.summary.publicUrl);
                },
                itemBuilder: (_) => [
                  if (canView)
                    const PopupMenuItem(
                      value: 'view',
                      child: ListTile(leading: Icon(Icons.open_in_new_rounded), title: Text('View on atomshop.pk')),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline_rounded, color: pal.danger),
                      title: Text('Delete product', style: TextStyle(color: pal.danger)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        body: p == null
            ? (_error != null ? ErrorView(message: _error!, onRetry: _load) : const _DetailSkeleton())
            : Stack(
                children: [
                  RefreshIndicator(onRefresh: _load, child: _body(p)),
                  if (_busy) const LinearProgressIndicator(),
                ],
              ),
        bottomNavigationBar: p == null
            ? null
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: pal.card,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: pal.isDark ? 0.4 : 0.08), blurRadius: 20, offset: const Offset(0, -6))],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(
                      children: [
                        if (canView) ...[
                          OutlinedButton.icon(
                            onPressed: () => openExternal(context, p.summary.publicUrl),
                            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                            icon: const Icon(Icons.visibility_outlined, size: 20),
                            label: const Text('Preview'),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _busy ? null : _edit,
                            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            label: const Text('Edit product'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _body(ProductDetail d) {
    final p = d.summary;
    final banner = bannerOf(d);
    final options = ref.watch(productFormOptionsProvider).value;
    final images = [if (p.picture != null) p.picture!, ...d.gallery.map((g) => g.url).where((u) => u != p.picture)];
    final features = keyFeatures(d.short);
    final blocks = descriptionBlocks(d.long);
    final row = InvRow(p, _draftUnits == null ? null : InvEdit(on: _draftUnits! > 0 || p.isLive, units: _draftUnits!));

    String names(List<int> ids, List<VariantOption>? opts) =>
        ids.map((id) => opts?.where((o) => o.id == id).firstOrNull?.label ?? '#$id').join(', ');
    String priced(List<VariantPrice> vs, List<VariantOption>? opts) => vs
        .map((v) => '${opts?.where((o) => o.id == v.id).firstOrNull?.label ?? '#${v.id}'}: ${money(v.price)}')
        .join('\n');

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        ProductGallery(images: images, muted: banner == ProductBanner.closed, onAddPhotos: _edit),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StatusBanner(
                kind: banner,
                detail: d,
                onView: p.publicUrl == null ? null : () => openExternal(context, p.publicUrl),
                onUpdateStock: _showStock,
                onFix: _edit,
              ),
              const SizedBox(height: 16),
              _TitleBlock(d),
              const SizedBox(height: 16),
              _PriceCard(d),
              if (d.colors.isNotEmpty || d.memories.isNotEmpty || d.sizes.isNotEmpty) ...[
                const SizedBox(height: 12),
                _Card(
                  title: 'Options',
                  child: Column(
                    children: [
                      if (d.colors.isNotEmpty) KeyValue('Colours', names(d.colors, options?.colors)),
                      if (d.memories.isNotEmpty) KeyValue('Storage', priced(d.memories, options?.memories)),
                      if (d.sizes.isNotEmpty) KeyValue('Sizes', priced(d.sizes, options?.sizes)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              KeyedSubtree(
                key: _stockKey,
                child: _StockCard(
                  row: row,
                  updatedAt: p.updatedAt,
                  lockedNote: switch (banner) {
                    ProductBanner.live || ProductBanner.outOfStock => null,
                    ProductBanner.closed => 'Closed products keep their stock. Buyers can’t order until it’s live again.',
                    ProductBanner.onHold => 'Stock can be changed again once AtomShop resumes this product.',
                    _ => 'You can set stock once AtomShop approves this product.',
                  },
                  busy: _busy,
                  saved: _stockSaved && _draftUnits == null,
                  onChanged: (n) => setState(() {
                    _stockSaved = false;
                    _draftUnits = n == p.stock ? null : n;
                  }),
                  onCancel: () => setState(() => _draftUnits = null),
                  onSave: () => _saveStock(row.units),
                ),
              ),
              if (d.performance != null) ...[
                const SizedBox(height: 12),
                _PerformanceCard(d.performance!, paused: banner == ProductBanner.closed || banner == ProductBanner.onHold),
              ],
              if (features.isNotEmpty) ...[
                const SizedBox(height: 12),
                _Card(title: 'Key features', child: _Features(features)),
              ],
              // Hidden when it only repeats the key features as a list.
              if (blocks.isNotEmpty && !_sameAsFeatures(blocks, features)) ...[
                const SizedBox(height: 12),
                _Card(title: 'Full description', child: _Description(blocks)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  const _Card({this.title, this.trailing, required this.child, this.color, this.border});

  final String? title;
  final Widget? trailing;
  final Widget child;
  final Color? color;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? p.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: border ?? Colors.transparent, width: 1.5),
        boxShadow: p.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(child: Text(title!, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// Full-width swipeable photos with a counter and dots; tap for full screen.
class ProductGallery extends StatefulWidget {
  const ProductGallery({super.key, required this.images, required this.onAddPhotos, this.muted = false});

  final List<String> images;
  final VoidCallback onAddPhotos;
  final bool muted;

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final images = widget.images;
    const white = Colors.white; // Product shots are cut out on white.

    if (images.isEmpty) {
      return Material(
        color: p.card,
        child: InkWell(
          onTap: widget.onAddPhotos,
          child: SizedBox(
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined, size: 40, color: p.muted),
                const SizedBox(height: 8),
                Text('Add photos', style: t.titleSmall?.copyWith(color: p.primary)),
                Text('Products with photos sell far better', style: t.bodySmall?.copyWith(color: p.muted)),
              ],
            ),
          ),
        ),
      );
    }

    Widget photo(String url) => CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          errorWidget: (_, _, _) => Icon(Icons.broken_image_outlined, size: 40, color: p.muted),
        );

    final gallery = SizedBox(
      height: 288,
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: white,
              child: PageView.builder(
                itemCount: images.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => Semantics(
                  button: true,
                  label: 'Photo ${i + 1} of ${images.length}. Open full screen',
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      fullscreenDialog: true,
                      builder: (_) => _PhotoViewer(images: images, initial: i),
                    )),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      child: widget.muted
                          ? ColorFiltered(
                              colorFilter: const ColorFilter.matrix([
                                0.5, 0.4, 0.1, 0, 20, //
                                0.3, 0.6, 0.1, 0, 20,
                                0.3, 0.4, 0.3, 0, 20,
                                0, 0, 0, 0.85, 0,
                              ]),
                              child: photo(images[i]),
                            )
                          : photo(images[i]),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (images.length > 1) ...[
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xB810122B), borderRadius: BorderRadius.circular(13)),
                child: Text(
                  '${_index + 1}/${images.length}',
                  style: t.labelSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, fontFeatures: tabularFigures),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < images.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _index ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _index ? p.primary : const Color(0xFFC9CCD8),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (images.length > 1) return gallery;
    return Column(
      children: [
        gallery,
        Container(
          color: p.card,
          padding: const EdgeInsets.only(left: 16, right: 4),
          child: Row(
            children: [
              Icon(Icons.photo_library_outlined, size: 20, color: p.muted),
              const SizedBox(width: 10),
              Expanded(child: Text('Add more photos to sell better', style: t.bodySmall?.copyWith(fontSize: 13, color: p.muted))),
              TextButton(onPressed: widget.onAddPhotos, child: const Text('Add photos')),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.images, required this.initial});

  final List<String> images;
  final int initial;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late int _index = widget.initial;
  late final _pages = PageController(initialPage: widget.initial);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Close photo',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${_index + 1} of ${widget.images.length}'),
      ),
      body: PageView.builder(
        controller: _pages,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 4,
          child: Center(
            child: ColoredBox(
              color: Colors.white,
              child: CachedNetworkImage(imageUrl: widget.images[i], fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

/// What the status means and what to do next.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.kind,
    required this.detail,
    required this.onView,
    required this.onUpdateStock,
    required this.onFix,
  });

  final ProductBanner kind;
  final ProductDetail detail;
  final VoidCallback? onView;
  final VoidCallback onUpdateStock;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;

    if (kind == ProductBanner.live) {
      return Semantics(
        container: true,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.only(left: 14, right: 4),
          decoration: BoxDecoration(color: p.positive.bg, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: p.positive.fg,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: p.positive.fg.withValues(alpha: 0.25), spreadRadius: 4)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Live on atomshop.pk', style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: p.positive.fg))),
              if (onView != null)
                TextButton.icon(
                  onPressed: onView,
                  style: TextButton.styleFrom(foregroundColor: p.positive.fg),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('View'),
                ),
            ],
          ),
        ),
      );
    }

    final reviewed = formatDateTime(detail.reviewedAt);
    final (Tone tone, IconData icon, String title, String body, String? action, VoidCallback? onAction) = switch (kind) {
      ProductBanner.outOfStock => (
          p.negative,
          Icons.warning_amber_rounded,
          'Live, but out of stock',
          "Buyers can see it but can't order. Add stock to start selling again.",
          'Update stock',
          onUpdateStock,
        ),
      ProductBanner.rejected => (
          p.negative,
          Icons.cancel_outlined,
          detail.rejectionReason == null ? 'Not approved' : 'Not approved · ${detail.rejectionReason}',
          "AtomShop couldn't approve this product. Fix what's wrong and save it to send it for review again.",
          'Fix & resubmit',
          onFix,
        ),
      ProductBanner.review => (
          p.info,
          Icons.schedule_rounded,
          'In review',
          "AtomShop is reviewing this product. Usually takes 1–2 days. We'll let you know when it's live.",
          null,
          null,
        ),
      ProductBanner.onHold => (
          p.warning,
          Icons.pause_circle_outline_rounded,
          'On hold · hidden from buyers',
          'AtomShop has paused this product, so buyers can’t see it. Contact AtomShop to resume it.',
          null,
          null,
        ),
      ProductBanner.closed => (
          p.neutral,
          Icons.lock_outline_rounded,
          'Closed · hidden from buyers',
          'This product is closed and hidden from buyers. Past orders aren’t affected.',
          null,
          null,
        ),
      _ => (
          p.neutral,
          Icons.info_outline_rounded,
          detail.summary.status,
          'Buyers can’t order this product right now.',
          null,
          null,
        ),
    };

    return Semantics(
      container: true,
      liveRegion: kind == ProductBanner.outOfStock || kind == ProductBanner.rejected,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(14)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: tone.fg),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: tone.fg)),
                  const SizedBox(height: 2),
                  Text(body, style: t.bodySmall?.copyWith(fontSize: 13, height: 1.45, color: p.text)),
                  if (kind == ProductBanner.rejected && reviewed.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Reviewed $reviewed', style: t.bodySmall?.copyWith(color: p.muted)),
                  ],
                  if (action != null) ...[
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: onAction,
                      style: FilledButton.styleFrom(
                        backgroundColor: tone.fg,
                        foregroundColor: p.isDark ? p.bg : Colors.white,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      child: Text(action),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.tone});

  final String label;
  final Tone? tone;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: tone?.bg ?? p.card,
        borderRadius: BorderRadius.circular(999),
        border: tone == null ? Border.all(color: p.border) : null,
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          style: t.labelSmall?.copyWith(
            fontSize: 12,
            fontWeight: tone == null ? FontWeight.w600 : FontWeight.w700,
            color: tone?.fg ?? p.text,
            fontFeatures: tabularFigures,
          ),
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock(this.d);
  final ProductDetail d;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final p = d.summary;
    final tone = switch (bannerOf(d)) {
      ProductBanner.live => pal.positive,
      ProductBanner.outOfStock || ProductBanner.rejected => pal.negative,
      ProductBanner.review => pal.info,
      ProductBanner.onHold => pal.warning,
      _ => pal.neutral,
    };
    final label = d.isRejected ? 'Rejected' : productStatusLabel(p.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(p.title, style: t.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w700, height: 1.25)),
        if (d.detailPageTitle != null && d.detailPageTitle != p.title) ...[
          const SizedBox(height: 4),
          Text(d.detailPageTitle!, style: t.bodyMedium?.copyWith(color: pal.muted)),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (p.prNumber != null) _Chip(p.prNumber!),
            if (p.category != null) _Chip(p.category!.title),
            if (p.displayBrand != null) _Chip('Brand: ${p.displayBrand!.title}'),
            _Chip(label, tone: tone),
          ],
        ),
      ],
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard(this.d);
  final ProductDetail d;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final p = d.summary;
    final plan = d.plan;
    final label = t.labelSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: pal.muted);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Price', style: label),
                    Text(
                      money(p.price),
                      style: t.headlineSmall?.copyWith(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.4, fontFeatures: tabularFigures),
                    ),
                  ],
                ),
              ),
              if (p.minAdvancePrice > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Minimum advance', style: label),
                      Text(money(p.minAdvancePrice), style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontFeatures: tabularFigures)),
                    ],
                  ),
                ),
            ],
          ),
          if (plan != null && plan.months > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: pal.primarySoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: pal.ring),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HOW BUYERS SEE IT',
                    style: t.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: pal.primary),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'From ${money(plan.monthly)}/month', style: const TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: ' · ${plan.months} months'),
                    ]),
                    style: t.bodyLarge?.copyWith(fontFeatures: tabularFigures),
                  ),
                  if (p.minAdvancePrice > 0)
                    Text(
                      '${money(p.minAdvancePrice)} advance, then ${plan.months} monthly payments',
                      style: t.bodySmall?.copyWith(color: pal.muted, fontFeatures: tabularFigures),
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

class _StockCard extends StatelessWidget {
  const _StockCard({
    required this.row,
    required this.updatedAt,
    required this.lockedNote,
    required this.busy,
    required this.saved,
    required this.onChanged,
    required this.onCancel,
    required this.onSave,
  });

  final InvRow row;
  final String? updatedAt;

  /// Why stock can't be changed here, or null when it can.
  final String? lockedNote;
  final bool busy;
  final bool saved;
  final ValueChanged<int> onChanged;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final r = row;
    final locked = lockedNote != null;
    final level = r.level;
    final dirty = r.units != r.savedUnits;
    final out = !locked && r.units == 0 && !r.savedOn;
    final color = locked
        ? pal.muted
        : switch (level) {
            InvLevel.low => pal.warning.fg,
            InvLevel.out => pal.negative.fg,
            InvLevel.ok => pal.positive.fg,
            _ => pal.muted,
          };
    final untracked = level == InvLevel.untracked && !dirty;
    final updated = formatDateTime(updatedAt);
    return _Card(
      title: 'Stock',
      trailing: updated.isEmpty ? null : Text('Updated $updated', style: t.bodySmall?.copyWith(color: pal.muted)),
      color: out ? Color.alphaBlend(pal.negative.bg.withValues(alpha: 0.45), pal.card) : null,
      border: out ? pal.negative.fg.withValues(alpha: 0.3) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: untracked ? 'Units not set, for sale' : '${r.units} units, ${r.levelText}',
                  excludeSemantics: true,
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: 8,
                    children: [
                      Text(
                        untracked ? 'Not set' : count(r.units),
                        style: (untracked ? t.titleLarge : t.headlineMedium)?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: untracked ? pal.muted : (locked ? pal.muted : (level == InvLevel.ok ? pal.text : color)),
                          fontFeatures: tabularFigures,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          untracked
                              ? 'For sale'
                              : r.units == 0
                                  ? 'Out of stock'
                                  : level == InvLevel.low
                                      ? 'Low stock'
                                      : 'In stock',
                          style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: untracked ? pal.positive.fg : color),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!locked)
                SizedBox(
                  width: 160,
                  child: UnitsStepper(
                    units: r.units,
                    showEmpty: untracked,
                    emptyHint: 'Units',
                    highlight: dirty,
                    onChanged: busy ? null : onChanged,
                  ),
                ),
            ],
          ),
          if (lockedNote != null) ...[
            const SizedBox(height: 8),
            Text(lockedNote!, style: t.bodySmall?.copyWith(fontSize: 13, color: pal.muted)),
          ],
          if (dirty) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: pal.divider),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${r.savedUnits > 0 ? count(r.savedUnits) : (r.savedOn ? 'Not set' : 'Out')} →${count(r.units)} · not saved',
                    style: t.bodySmall?.copyWith(fontSize: 13, color: pal.muted, fontFeatures: tabularFigures),
                  ),
                ),
                OutlinedButton(
                  onPressed: busy ? null : onCancel,
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 14)),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: busy ? null : onSave,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 16)),
                  child: Text(r.units == 0 ? 'Mark out of stock' : 'Save stock'),
                ),
              ],
            ),
          ],
          if (saved) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.check_rounded, size: 18, color: pal.positive.fg),
                const SizedBox(width: 6),
                Text('Stock saved · buyers see it now', style: t.bodySmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: pal.positive.fg)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard(this.perf, {required this.paused});

  final ProductPerformance perf;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    Widget tile(String label, String value) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: pal.surface, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: t.labelSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: pal.muted)),
              const SizedBox(height: 2),
              Text(value, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontFeatures: tabularFigures)),
            ],
          ),
        );
    final tiles = [
      tile('Units sold', count(perf.unitsSold)),
      tile('Revenue', money(perf.revenue)),
      if (perf.pageViews != null) tile('Page views', count(perf.pageViews)),
      tile('Bulk requests', count(perf.bulkRequests)),
    ];
    final lastSale = formatShortDate(perf.lastSaleAt);
    return _Card(
      title: 'Performance',
      trailing: Text('Last 30 days', style: t.bodySmall?.copyWith(color: pal.muted)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (paused) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: pal.neutral.bg, borderRadius: BorderRadius.circular(999)),
              child: Text(
                'Paused while hidden · numbers from before',
                style: t.labelSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: pal.neutral.fg),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Opacity(
            opacity: paused ? 0.45 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < tiles.length; i += 2) ...[
                  if (i > 0) const SizedBox(height: 8),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: tiles[i]),
                        const SizedBox(width: 8),
                        Expanded(child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox()),
                      ],
                    ),
                  ),
                ],
                if (perf.dailyUnits.length > 1) ...[
                  const SizedBox(height: 14),
                  Text('Units sold per day', style: t.labelSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: pal.muted)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 52,
                    child: CustomPaint(painter: _SparkPainter(perf.dailyUnits, pal.primary, pal.primarySoft2)),
                  ),
                ],
                if (lastSale.isNotEmpty && perf.unitsSold == 0) ...[
                  const SizedBox(height: 8),
                  Text('No sales since $lastSale', style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: pal.negative.fg)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.line, this.fill);

  final List<int> values;
  final Color line;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    // A 5-day moving average reads better than daily spikes of 0 and 1.
    final smooth = [
      for (var i = 0; i < values.length; i++)
        () {
          final w = values.sublist((i - 2).clamp(0, values.length), (i + 3).clamp(0, values.length));
          return w.reduce((a, b) => a + b) / w.length;
        }(),
    ];
    final max = smooth.fold<double>(0, (a, b) => b > a ? b : a);
    final pts = [
      for (var i = 0; i < smooth.length; i++)
        Offset(size.width * i / (smooth.length - 1), size.height - 4 - (max == 0 ? 0 : smooth[i] / max) * (size.height - 8)),
    ];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.values != values || old.line != line;
}

/// Key features as a checklist; long lists show the first 8 until "Show all".
class _Features extends StatefulWidget {
  const _Features(this.items);
  final List<String> items;

  @override
  State<_Features> createState() => _FeaturesState();
}

class _FeaturesState extends State<_Features> {
  static const _first = 8;
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final items = widget.items;
    final more = items.length > _first + 2;
    final shown = more && !_all ? items.take(_first) : items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final f in shown)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(color: pal.positive.bg, shape: BoxShape.circle),
                  child: Icon(Icons.check_rounded, size: 13, color: pal.positive.fg),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(f, style: t.bodyMedium)),
              ],
            ),
          ),
        if (more)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _all = !_all),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 44)),
              child: Text(_all ? 'Show fewer' : 'Show all ${items.length}'),
            ),
          ),
      ],
    );
  }
}

/// Formatted description, cut to about four lines until "Read more".
class _Description extends StatefulWidget {
  const _Description(this.blocks);
  final List<DescBlock> blocks;

  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final body = t.bodyMedium?.copyWith(height: 1.5, color: pal.text);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.blocks.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : (widget.blocks[i].kind == DescKind.heading ? 12 : 6)),
            child: switch (widget.blocks[i].kind) {
              DescKind.heading => Text(widget.blocks[i].text, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              DescKind.bullet => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, right: 10, left: 2),
                      child: Container(width: 5, height: 5, decoration: BoxDecoration(color: pal.muted, shape: BoxShape.circle)),
                    ),
                    Expanded(child: Text(widget.blocks[i].text, style: body)),
                  ],
                ),
              DescKind.paragraph => Text(widget.blocks[i].text, style: body),
            },
          ),
      ],
    );
    final long = widget.blocks.length > 2 || widget.blocks.fold<int>(0, (a, b) => a + b.text.length) > 220;
    if (!long) return content;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: _open
              ? content
              : ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.black, Colors.transparent],
                    stops: [0, 0.6, 1],
                  ).createShader(r),
                  blendMode: BlendMode.dstIn,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 96),
                    child: ClipRect(child: SingleChildScrollView(physics: const NeverScrollableScrollPhysics(), child: content)),
                  ),
                ),
        ),
        TextButton(
          onPressed: () => setState(() => _open = !_open),
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 44)),
          child: Text(_open ? 'Show less' : 'Read more'),
        ),
      ],
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          Bone(height: 288, radius: 0),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone(height: 48, radius: 14),
                SizedBox(height: 16),
                Bone(width: 260, height: 22),
                SizedBox(height: 8),
                Bone(width: 200, height: 14),
                SizedBox(height: 12),
                Row(children: [Bone(width: 64, height: 28, radius: 999), SizedBox(width: 6), Bone(width: 110, height: 28, radius: 999)]),
                SizedBox(height: 16),
                Bone(height: 96, radius: 16),
                SizedBox(height: 12),
                Bone(height: 120, radius: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

bool _sameAsFeatures(List<DescBlock> blocks, List<String> features) =>
    blocks.every((b) => b.kind == DescKind.bullet) &&
    blocks.map((b) => b.text.toLowerCase()).toSet().containsAll(features.map((f) => f.toLowerCase())) &&
    blocks.length == features.length;
