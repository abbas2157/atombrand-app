import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/formatters.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/models/dashboard.dart';
import '../../data/repositories/orders_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/stat_card.dart';
import '../orders/order_tile.dart';

final dashboardProvider = FutureProvider.autoDispose<Dashboard>(
  (ref) => ref.watch(ordersRepositoryProvider).dashboard(),
);

/// F5: catalogue, orders, open bulk requests, top products, latest orders.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.read(sessionProvider.notifier).refreshBadge();
    // Keep the spinner up until the reload finishes; errors render in the body.
    await ref.refresh(dashboardProvider.future).then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(signedInProvider);
    final dash = ref.watch(dashboardProvider);
    final brand = session?.brand;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            NetThumb(brand?.logo, size: 34, radius: 17, icon: Icons.storefront_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(brand?.title ?? 'Dashboard', maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    'Hi, ${session?.user.name.split(' ').first ?? ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: switch (dash) {
          AsyncData(:final value) => _DashboardBody(value, publicUrl: brand?.publicUrl),
          AsyncError(:final error) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [ErrorView(message: error.toString(), onRetry: () => ref.invalidate(dashboardProvider))],
            ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody(this.d, {this.publicUrl});

  final Dashboard d;
  final String? publicUrl;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final stats = [
      StatCard(
        icon: Icons.campaign_rounded,
        value: count(d.openBulkRequests),
        caption: 'Open bulk requests',
        color: AppColors.accent,
        onTap: () => context.go('/bulk'),
      ),
      StatCard(
        icon: Icons.receipt_long_rounded,
        value: count(d.ordersLast30),
        caption: 'Orders, last 30 days',
        onTap: () => context.go('/orders'),
      ),
      StatCard(
        icon: Icons.payments_rounded,
        value: money(d.ordersValue),
        caption: 'Order value (${count(d.ordersTotal)} orders)',
        color: AppColors.successFg,
        onTap: () => context.go('/orders'),
      ),
      StatCard(
        icon: Icons.handshake_rounded,
        value: count(d.sellerSourced),
        caption: 'Seller-sourced deals',
        color: AppColors.muted,
        onTap: () => context.go('/orders?type=instalment'),
      ),
      StatCard(
        icon: Icons.check_circle_rounded,
        value: count(d.cataloguePublished),
        caption: 'Live products',
        color: AppColors.successFg,
        onTap: () => context.go('/catalogue?status=Published'),
      ),
      StatCard(
        icon: Icons.hourglass_top_rounded,
        value: count(d.cataloguePending),
        caption: 'In review',
        color: AppColors.warningFg,
        onTap: () => context.go('/catalogue?status=Pending'),
      ),
      StatCard(
        icon: Icons.remove_shopping_cart_rounded,
        value: count(d.catalogueOutOfStock),
        caption: 'Out of stock',
        color: AppColors.dangerFg,
        onTap: () => context.go('/catalogue?status=Out%20of%20Stock'),
      ),
      StatCard(
        icon: Icons.inventory_2_rounded,
        value: count(d.catalogueTotal),
        caption: 'Products in catalogue',
        onTap: () => context.go('/catalogue'),
      ),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth >= 600 ? 4 : 2;
          final w = (c.maxWidth - 12 * (cols - 1)) / cols;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [for (final s in stats) SizedBox(width: w, child: s)],
          );
        }),
        SectionTitle(
          'Latest orders',
          trailing: d.latestOrders.isEmpty ? null : TextButton(onPressed: () => context.go('/orders'), child: const Text('See all')),
        ),
        if (d.latestOrders.isEmpty)
          AppCard(
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'No orders yet. Share your brand page to bring in buyers.',
              actionLabel: publicUrl == null ? null : 'Share brand page',
              onAction: publicUrl == null ? null : () => SharePlus.instance.share(ShareParams(uri: Uri.parse(publicUrl!))),
            ),
          )
        else
          for (final o in d.latestOrders) ...[
            OrderTile(order: o, onTap: () => context.push('/orders/retail/${o.uuid}')),
            const SizedBox(height: 12),
          ],
        if (d.topProducts.isNotEmpty) ...[
          const SectionTitle('Top products'),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final (i, p) in d.topProducts.indexed) ...[
                  if (i > 0) const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    leading: NetThumb(p.picture, size: 40),
                    title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodyMedium),
                    trailing: Text('${count(p.units)} sold', style: t.labelMedium?.copyWith(fontFeatures: tabularFigures)),
                    onTap: () => context.push('/products/${p.id}'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
