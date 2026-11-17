import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/app_icons.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/models/product.dart';
import '../../widgets/feedback.dart';
import '../../widgets/status_badge.dart';
import 'product_logic.dart';

/// Product picture with the featured star; a dashed "Add photo" box when
/// there is none, so a missing image is visible at a glance.
class ProductThumb extends StatelessWidget {
  const ProductThumb(this.p, {super.key, this.size = 72, this.width, this.radius = 12, this.starInset = -6});

  final ProductSummary p;
  final double size;

  /// Defaults to [size] (square).
  final double? width;
  final double radius;
  final double starInset;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final w = width ?? size;
    final missing = Container(
      width: w,
      height: size,
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: pal.border, width: 1.5, strokeAlign: BorderSide.strokeAlignInside),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.imageAdd, size: size * 0.32, color: pal.muted),
          const SizedBox(height: 2),
          Text('Add photo', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: size > 90 ? 12 : 10, color: pal.muted)),
        ],
      ),
    );
    final image = p.picture == null
        ? missing
        : ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              width: w,
              height: size,
              color: pal.surface,
              child: CachedNetworkImage(
                imageUrl: p.picture!,
                fit: BoxFit.contain,
                errorWidget: (_, _, _) => missing,
              ),
            ),
          );
    if (!p.brandFeatured) return image;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        image,
        Positioned(
          top: starInset,
          left: starInset,
          child: Tooltip(
            message: 'Featured on your brand page',
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: pal.accent, shape: BoxShape.circle, border: Border.all(color: pal.card, width: 2)),
              child: const Icon(AppIcons.starFill, size: 13, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

(Color, Color?) _stockColors(AppPalette p, StockLevel level) => switch (level) {
      StockLevel.out => (p.negative.fg, p.negative.bg),
      StockLevel.low => (p.warning.fg, p.warning.bg),
      _ => (p.muted, null),
    };

/// List card: thumb, name, PR · category, price + status + stock, and a
/// problem line with its fix.
class ProductListCard extends StatelessWidget {
  const ProductListCard({super.key, required this.product, required this.onTap, this.onLongPress, this.onFixStock});

  final ProductSummary product;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFixStock;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final p = product;
    final stock = stockOf(p);
    final problem = problemOf(p);
    final (stockFg, _) = _stockColors(pal, stock.level);
    final radius = BorderRadius.circular(AppRadius.card);
    return DecoratedBox(
      decoration: BoxDecoration(color: pal.card, borderRadius: radius, boxShadow: pal.cardShadow),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            Semantics(
              button: true,
              label: [
                p.title,
                money(p.price),
                productStatusLabel(p.status),
                stock.text,
                if (p.brandFeatured) 'featured',
                if (p.picture == null) 'no photo',
                ?problem,
              ].where((s) => s.isNotEmpty).join(', '),
              excludeSemantics: true,
              child: InkWell(
                borderRadius: radius,
                onTap: onTap,
                onLongPress: onLongPress,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProductThumb(p),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.4)),
                            Text(
                              [p.prNumber, p.category?.title].whereType<String>().join(' · '),
                              style: t.bodySmall?.copyWith(color: pal.muted, fontFeatures: tabularFigures),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(money(p.price), style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700, fontFeatures: tabularFigures)),
                                StatusBadge.product(p.status),
                                if (stock.text.isNotEmpty)
                                  Text(
                                    stock.text,
                                    style: t.bodySmall?.copyWith(
                                      color: stockFg,
                                      fontWeight: stock.level == StockLevel.ok ? FontWeight.w400 : FontWeight.w700,
                                      fontFeatures: tabularFigures,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (problem != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: pal.divider))),
                child: Row(
                  children: [
                    Icon(AppIcons.error, size: 16, color: pal.negative.fg),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(problem, style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: pal.negative.fg)),
                      ),
                    ),
                    if (onFixStock != null)
                      TextButton(onPressed: onFixStock, child: const Text('Update stock')),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Grid card: picture on top with the stock as a corner badge, then name,
/// price and status.
class ProductGridCard extends StatelessWidget {
  const ProductGridCard({super.key, required this.product, required this.onTap, this.onLongPress});

  final ProductSummary product;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final p = product;
    final stock = stockOf(p);
    final problem = problemOf(p);
    final (fg, bg) = _stockColors(pal, stock.level);
    final radius = BorderRadius.circular(AppRadius.card);
    return Semantics(
      button: true,
      label: [p.title, money(p.price), productStatusLabel(p.status), stock.text, ?problem]
          .where((s) => s.isNotEmpty)
          .join(', '),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: pal.card, borderRadius: radius, boxShadow: pal.cardShadow),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            onLongPress: onLongPress,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, c) => Stack(
                    children: [
                      ProductThumb(p, size: 128, width: c.maxWidth, radius: 0, starInset: 8),
                      if (stock.text.isNotEmpty)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: bg ?? pal.card.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              stock.level == StockLevel.out ? 'Out' : stock.text,
                              style: t.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 36,
                        child: Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: pal.text)),
                      ),
                      const SizedBox(height: 4),
                      Text(money(p.price), style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700, fontFeatures: tabularFigures)),
                      const SizedBox(height: 6),
                      StatusBadge.product(p.status),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Long-press sheet: edit, stock, feature, and the public page.
Future<void> showProductQuickActions(
  BuildContext context,
  ProductSummary p, {
  required VoidCallback onEdit,
  required VoidCallback? onUpdateStock,
  required VoidCallback onToggleFeatured,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (ctx) {
      final pal = AppPalette.of(ctx);
      final t = Theme.of(ctx).textTheme;
      Widget row(IconData icon, Tone tone, String label, VoidCallback? onTap, {String? note}) => ListTile(
            minTileHeight: 56,
            enabled: onTap != null,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: tone.fg),
            ),
            title: Text(label, style: t.bodyLarge),
            subtitle: note == null ? null : Text(note, style: t.bodySmall),
            onTap: onTap == null
                ? null
                : () {
                    Navigator.pop(ctx);
                    onTap();
                  },
          );
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title, style: t.titleMedium),
                    Text(
                      [p.prNumber, productStatusLabel(p.status), money(p.price)].whereType<String>().join(' · '),
                      style: t.bodySmall?.copyWith(color: pal.muted, fontFeatures: tabularFigures),
                    ),
                  ],
                ),
              ),
              const Divider(),
              row(AppIcons.edit, pal.indigo, 'Edit', onEdit),
              row(
                AppIcons.package,
                pal.positive,
                'Update stock',
                onUpdateStock,
                note: onUpdateStock == null ? 'Available once AtomShop approves it' : null,
              ),
              row(
                p.brandFeatured ? AppIcons.star : AppIcons.starFill,
                pal.lead,
                p.brandFeatured ? 'Remove from brand page' : 'Feature on brand page',
                onToggleFeatured,
              ),
              if (p.publicUrl != null && p.isLive)
                row(AppIcons.externalLink, pal.neutral, 'View on AtomShop', () => openExternal(context, p.publicUrl)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ),
            ],
          ),
        ),
      );
    },
  );
}
