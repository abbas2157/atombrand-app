import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/app_icons.dart';

import '../../core/formatters.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/models/dashboard.dart';
import '../../data/repositories/notifications_repository.dart';
import '../../data/repositories/orders_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/skeleton.dart';
import '../orders/order_tile.dart';
import 'dashboard_widgets.dart';

final dashboardProvider = FutureProvider.autoDispose<Dashboard>(
  (ref) => ref.watch(ordersRepositoryProvider).dashboard(),
);

/// F5, Home (DESIGN.md §4.1): how sales are going and what needs action
/// today. Sections whose data the API doesn't send yet stay hidden.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _period = 'today';

  Future<void> _refresh() async {
    ref.read(sessionProvider.notifier).refreshBadge();
    ref.invalidate(unreadNotificationsProvider);
    // Keep the spinner up until the reload finishes; errors render in the body.
    await ref.refresh(dashboardProvider.future).then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(signedInProvider);
    final dash = ref.watch(dashboardProvider);
    final p = AppPalette.of(context);
    final newSeller = dash.value?.isNewSeller ?? false;

    final Widget body = switch (dash) {
      AsyncData(:final value) when value.isNewSeller => _NewSellerBody(value),
      AsyncData(:final value) => _DashboardBody(
          value,
          newBulkLeads: session?.newBulkRequests ?? 0,
          publicUrl: session?.brand.publicUrl,
          period: _period,
          onPeriod: (k) => setState(() => _period = k),
        ),
      AsyncError(:final error) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [ErrorView(message: error.toString(), onRetry: () => ref.invalidate(dashboardProvider))],
        ),
      _ => const _LoadingBody(),
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.page,
        body: Column(
          children: [
            _Header(
              logo: session?.brand.logo,
              name: session?.brand.title ?? '',
              subtitle: newSeller ? "Let's get your store live" : "Here's your store today",
            ),
            Expanded(child: RefreshIndicator(onRefresh: _refresh, child: body)),
          ],
        ),
      ),
    );
  }
}

/// Navy band: brand logo, greeting, notification bell.
class _Header extends ConsumerWidget {
  const _Header({required this.logo, required this.name, required this.subtitle});
  final String? logo;
  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final unread = ref.watch(unreadNotificationsProvider).value ?? 0;
    return Container(
      color: p.header,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 20),
          child: Row(
            children: [
              NetThumb(logo, size: 48, radius: 24, icon: AppIcons.store),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Hi there' : 'Hi, $name',
                      style: t.titleLarge?.copyWith(color: p.onHeader),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: t.bodySmall?.copyWith(fontSize: 13, color: p.onHeaderMuted)),
                  ],
                ),
              ),
              IconButton(
                tooltip: unread > 0 ? 'Notifications, $unread unread' : 'Notifications',
                onPressed: () async {
                  await context.push('/notifications');
                  ref.invalidate(unreadNotificationsProvider);
                },
                style: IconButton.styleFrom(
                  fixedSize: const Size(48, 48),
                  backgroundColor: p.onHeader.withValues(alpha: 0.08),
                  foregroundColor: p.onHeader,
                ),
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(unread > 99 ? '99+' : '$unread'),
                  child: const Icon(AppIcons.bell),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody(
    this.d, {
    required this.newBulkLeads,
    required this.period,
    required this.onPeriod,
    this.publicUrl,
  });

  final Dashboard d;
  final int newBulkLeads;
  final String period;
  final ValueChanged<String> onPeriod;
  final String? publicUrl;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final keys = d.periods.keys.toList();
    final selected = keys.contains(period) ? period : (keys.isEmpty ? null : keys.first);
    final current = selected == null ? null : d.periods[selected];
    final periodLabel = selected == null ? '' : PeriodSwitch.label(selected);

    String plural(int n, String one, String many) => n == 1 ? one : many;

    final attention = [
      if ((d.ordersVerification ?? 0) > 0)
        AttentionItem(
          icon: AppIcons.shieldCheck,
          tone: p.info,
          message: plural(d.ordersVerification!, 'Order waiting for verification', 'Orders waiting for verification'),
          count: d.ordersVerification!,
          onTap: () => context.go('/orders?status=Varification'),
        ),
      if (newBulkLeads > 0)
        AttentionItem(
          icon: AppIcons.phoneCall,
          tone: p.lead,
          message: plural(newBulkLeads, 'New bulk lead to call', 'New bulk leads to call'),
          count: newBulkLeads,
          onTap: () => context.go('/bulk'),
        ),
      if (d.catalogueOutOfStock > 0)
        AttentionItem(
          icon: AppIcons.outOfStock,
          tone: p.negative,
          message: plural(d.catalogueOutOfStock, 'Product out of stock', 'Products out of stock'),
          count: d.catalogueOutOfStock,
          onTap: () => context.go('/catalogue?status=Out%20of%20Stock'),
        ),
      if (d.cataloguePending > 0)
        AttentionItem(
          icon: AppIcons.hourglass,
          tone: p.warning,
          message: plural(d.cataloguePending, 'Product in review', 'Products in review'),
          count: d.cataloguePending,
          onTap: () => context.go('/catalogue?status=Pending'),
        ),
    ];

    final kpis = <Widget>[
      if (current != null)
        KpiCard(
          icon: AppIcons.payments,
          tone: p.indigo,
          value: money(current.revenue),
          label: 'Revenue',
          trend: current.revenueChangePct == null ? null : TrendChip(change: current.revenueChangePct!, suffix: '%'),
          onTap: () => context.go('/orders'),
        )
      else
        KpiCard(
          icon: AppIcons.payments,
          tone: p.indigo,
          value: money(d.ordersValue),
          label: 'Order value',
          onTap: () => context.go('/orders'),
        ),
      if (current != null)
        KpiCard(
          icon: AppIcons.orders,
          tone: p.positive,
          value: count(current.orders),
          label: 'Orders',
          trend: current.ordersChange == null ? null : TrendChip(change: current.ordersChange!),
          onTap: () => context.go('/orders'),
        )
      else
        KpiCard(
          icon: AppIcons.orders,
          tone: p.positive,
          value: count(d.ordersLast30),
          label: 'Orders, 30 days',
          onTap: () => context.go('/orders'),
        ),
      if (d.ordersPending != null)
        KpiCard(
          icon: AppIcons.clock,
          tone: p.neutral,
          value: count(d.ordersPending),
          label: 'Pending orders',
          onTap: () => context.go('/orders?status=Pending'),
        )
      else
        KpiCard(
          icon: AppIcons.checkCircle,
          tone: p.neutral,
          value: count(d.cataloguePublished),
          label: 'Live products',
          onTap: () => context.go('/catalogue?status=Published'),
        ),
      KpiCard(
        icon: AppIcons.bulk,
        tone: p.lead,
        value: count(newBulkLeads),
        label: 'New bulk leads',
        onTap: () => context.go('/bulk'),
      ),
    ];

    Widget row(Widget a, Widget b) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)],
          ),
        );

    const gap = SizedBox(height: 20);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (selected != null) ...[
          PeriodSwitch(keys: keys, selected: selected, onChanged: onPeriod),
          gap,
        ],
        row(kpis[0], kpis[1]),
        const SizedBox(height: 12),
        row(kpis[2], kpis[3]),
        gap,
        AttentionCard(items: attention),
        if (current != null && current.series.isNotEmpty) ...[
          gap,
          SalesChartCard(period: current, periodLabel: periodLabel),
        ],
        gap,
        Row(
          children: [
            Expanded(child: Text('Latest orders', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16))),
            if (d.latestOrders.isNotEmpty)
              TextButton(onPressed: () => context.go('/orders'), child: const Text('See all')),
          ],
        ),
        const SizedBox(height: 4),
        if (d.latestOrders.isEmpty)
          AppCard(
            child: EmptyState(
              icon: AppIcons.orders,
              message: 'No orders yet. Share your brand page to bring in buyers.',
              actionLabel: publicUrl == null ? null : 'Share brand page',
              onAction: publicUrl == null ? null : () => SharePlus.instance.share(ShareParams(uri: Uri.parse(publicUrl!))),
            ),
          )
        else
          for (final (i, o) in d.latestOrders.take(4).indexed) ...[
            if (i > 0) const SizedBox(height: 10),
            OrderTile(order: o, onTap: () => context.push('/orders/retail/${o.uuid}')),
          ],
        if (d.topProducts.isNotEmpty) ...[
          gap,
          TopProductsCard(products: d.topProducts, onTap: (x) => context.push('/products/${x.id}')),
        ],
        if (d.recovery != null) ...[
          gap,
          RecoveryCard(recovery: d.recovery!, onOverdueTap: () => context.go('/orders?type=instalment')),
        ],
      ],
    );
  }
}

/// Skeleton cards in the dashboard's shape while the first load runs.
class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    Widget kpi() => const DashCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Bone(width: 36, height: 36, radius: 10), Spacer(), Bone(width: 44, height: 20, radius: 999)]),
              SizedBox(height: 12),
              Bone(width: 110, height: 22),
              SizedBox(height: 8),
              Bone(width: 70),
            ],
          ),
        );
    Widget line() => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Bone(width: 36, height: 36, radius: 10),
              SizedBox(width: 12),
              Expanded(child: Bone()),
              SizedBox(width: 24),
              Bone(width: 24, height: 24, radius: 12),
            ],
          ),
        );
    Widget order() => const OrderTileBone();
    return Semantics(
      label: 'Loading your dashboard',
      child: Shimmer(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const Bone(height: 56, radius: 16),
            const SizedBox(height: 20),
            Row(children: [Expanded(child: kpi()), const SizedBox(width: 12), Expanded(child: kpi())]),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: kpi()), const SizedBox(width: 12), Expanded(child: kpi())]),
            const SizedBox(height: 20),
            DashCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [const Bone(width: 140, height: 18), const SizedBox(height: 8), line(), line(), line()],
              ),
            ),
            const SizedBox(height: 20),
            const Bone(width: 120, height: 18),
            const SizedBox(height: 14),
            order(),
            const SizedBox(height: 10),
            order(),
          ],
        ),
      ),
    );
  }
}

/// A brand with nothing listed yet: one clear next step.
class _NewSellerBody extends StatelessWidget {
  const _NewSellerBody(this.d);
  final Dashboard d;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    Widget step({required Widget lead, required String text, Widget? trailing, VoidCallback? onTap, bool strong = false}) => InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
              child: Row(
                children: [
                  lead,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: t.bodyMedium?.copyWith(
                        color: strong ? p.text : p.muted,
                        fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  ?trailing,
                  if (onTap != null) Icon(AppIcons.chevronRight, color: p.muted),
                ],
              ),
            ),
          ),
        );
    Widget number(int n, {bool active = false}) => Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: active ? p.primary : p.border, width: 2),
          ),
          child: Text('$n', style: t.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: active ? p.primary : p.muted)),
        );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        DashCard(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            children: [
              const EmptyStoreIllustration(),
              const SizedBox(height: 20),
              Text('No orders yet', style: t.headlineSmall?.copyWith(fontSize: 20)),
              const SizedBox(height: 8),
              Text(
                "Add products to your catalogue. Once they're approved and live, orders and bulk leads show up here.",
                textAlign: TextAlign.center,
                style: t.bodyMedium?.copyWith(color: p.muted, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push('/products/new'),
                  style: FilledButton.styleFrom(minimumSize: const Size(64, 52)),
                  icon: const Icon(AppIcons.add),
                  label: const Text('Add your first product'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        DashCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 4), child: DashTitle('Getting started')),
              step(
                lead: number(1),
                text: 'Set up your brand page',
                onTap: () => context.push('/brand-page'),
              ),
              const Divider(indent: 56),
              step(
                lead: number(2, active: true),
                text: 'Add at least 3 products',
                strong: true,
                trailing: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text('${d.catalogueTotal} of 3', style: t.bodySmall?.copyWith(color: p.muted, fontFeatures: tabularFigures)),
                ),
                onTap: () => context.push('/products/new'),
              ),
              const Divider(indent: 56),
              step(lead: number(3), text: 'Go live after a quick review'),
            ],
          ),
        ),
      ],
    );
  }
}
