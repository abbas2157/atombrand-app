import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/models/json.dart';
import '../../data/repositories/notifications_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/paged_list.dart';
import '../../widgets/skeleton.dart';
import '../catalogue/inventory_logic.dart' show plural;
import '../dashboard/dashboard_screen.dart';
import 'notification_logic.dart';

/// The inbox behind the dashboard bell (DESIGN.md §4.13): filter chips with
/// unread counts, a pinned "needs your action" card, then notifications
/// grouped under sticky Today / Yesterday / This week / Earlier headers.
/// Tap opens what it's about; swipe left or long-press to mark read.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late final _controller = PagedController<AppNotification>(
    (page) => ref.read(notificationsRepositoryProvider).list(page: page),
  )..refresh();
  NotifCategory? _filter;
  Set<int>? _selected;

  NotificationsRepository get _repo => ref.read(notificationsRepositoryProvider);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markRead(Iterable<int> ids) async {
    final set = ids.toSet();
    if (set.isEmpty) return;
    _controller.replaceWhere((x) => set.contains(x.id) && !x.isRead, (x) => x.markedRead());
    try {
      for (final id in set) {
        await _repo.markRead(id);
      }
    } on ApiException {
      // Shown read here; the server catches up on the next refresh.
    }
    ref.invalidate(unreadNotificationsProvider);
  }

  Future<void> _open(AppNotification n) async {
    if (_selected != null) return _toggle(n);
    if (!n.isRead) await _markRead([n.id]);
    final route = n.route;
    if (route != null && mounted) context.push(route);
  }

  void _toggle(AppNotification n) => setState(() {
        final s = _selected!;
        s.contains(n.id) ? s.remove(n.id) : s.add(n.id);
        if (s.isEmpty) _selected = null;
      });

  Future<void> _markAllRead() async {
    try {
      await _repo.markAllRead();
      _controller.replaceWhere((x) => !x.isRead, (x) => x.markedRead());
      ref.invalidate(unreadNotificationsProvider);
      if (mounted) showToast(context, 'All marked read');
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final items = _controller.items;
        final unread = items.where((n) => !n.isRead).length;
        final selecting = _selected != null;
        return PopScope(
          canPop: !selecting,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) setState(() => _selected = null);
          },
          child: Scaffold(
            appBar: AppBar(
              leading: selecting
                  ? IconButton(tooltip: 'Cancel selection', icon: const Icon(Icons.close_rounded), onPressed: () => setState(() => _selected = null))
                  : null,
              title: Text(selecting ? '${_selected!.length} selected' : 'Notifications'),
              actions: [
                if (!selecting)
                  TextButton(
                    onPressed: unread == 0 ? null : _markAllRead,
                    style: TextButton.styleFrom(foregroundColor: pal.onHeader, disabledForegroundColor: pal.onHeaderMuted),
                    child: const Text('Mark all read'),
                  ),
                // The settings gear joins here once the API has per-type
                // preferences (BRAND_APP.md, "Wanted for the Notifications design").
              ],
            ),
            body: _body(items),
            bottomNavigationBar: selecting
                ? _SelectionBar(
                    count: _selected!.length,
                    onSelectAll: () => setState(() => _selected = {for (final n in _visible(items)) n.id}),
                    onMarkRead: () async {
                      final ids = _selected!;
                      setState(() => _selected = null);
                      await _markRead(ids);
                      if (context.mounted) showToast(context, '${plural(ids.length, 'notification')} marked read');
                    },
                  )
                : null,
          ),
        );
      },
    );
  }

  List<AppNotification> _visible(List<AppNotification> items) =>
      _filter == null ? items : items.where((n) => categoryOf(n) == _filter).toList();

  Widget _body(List<AppNotification> items) {
    final c = _controller;
    if (c.loading && items.isEmpty) return const _InboxSkeleton();
    if (c.error != null && items.isEmpty) return ErrorView(message: c.error!, onRetry: c.refresh);

    final pal = AppPalette.of(context);
    final unreadBy = <NotifCategory, int>{};
    final present = <NotifCategory>{};
    for (final n in items) {
      final cat = categoryOf(n);
      present.add(cat);
      if (!n.isRead) unreadBy[cat] = (unreadBy[cat] ?? 0) + 1;
    }
    final unreadAll = asIntOrNull(c.firstPage?.raw['unread_count']) ?? items.where((n) => !n.isRead).length;
    final visible = _visible(items);
    final groups = <String, List<AppNotification>>{};
    for (final n in visible) {
      groups.putIfAbsent(groupOf(n.createdAt), () => []).add(n);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardProvider);
        ref.invalidate(unreadNotificationsProvider);
        await c.refresh(showSpinner: false);
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (s) {
          if (s.metrics.extentAfter < 400 && c.hasMore && !c.loadingMore) c.loadMore();
          return false;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (items.isNotEmpty && present.length > 1)
              SliverToBoxAdapter(
                child: _FilterChips(
                  value: _filter,
                  present: [for (final cat in NotifCategory.values) if (present.contains(cat)) cat],
                  unreadAll: unreadAll,
                  unreadBy: unreadBy,
                  onChanged: (f) => setState(() => _filter = f),
                ),
              ),
            if (_filter == null) const SliverToBoxAdapter(child: _ActionCard()),
            if (visible.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _Empty(filtered: _filter != null && items.isNotEmpty, onShowAll: () => setState(() => _filter = null)),
              )
            else
              for (final g in groupOrder)
                if (groups[g] != null)
                  SliverMainAxisGroup(
                    slivers: [
                      SliverPersistentHeader(pinned: true, delegate: _GroupHeader(g, pal.page)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _Group(
                            children: [
                              for (final n in groups[g]!)
                                _NotificationRow(
                                  key: ValueKey(n.id),
                                  n: n,
                                  selected: _selected?.contains(n.id),
                                  onTap: () => _open(n),
                                  onLongPress: () => setState(() => (_selected ??= {}).add(n.id)),
                                  onMarkRead: () => _markRead([n.id]),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
            if (c.loadingMore)
              const SliverToBoxAdapter(
                child: Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

Tone _toneOf(AppPalette p, NotifCategory c) => switch (c) {
      NotifCategory.orders => p.indigo,
      NotifCategory.leads => p.lead,
      NotifCategory.payments => p.positive,
      NotifCategory.stock => p.warning,
      NotifCategory.products => p.info,
      NotifCategory.atomshop => p.violet,
    };

IconData _iconOf(AppNotification n) => switch (categoryOf(n)) {
      NotifCategory.orders => Icons.receipt_long_outlined,
      NotifCategory.leads => Icons.campaign_outlined,
      NotifCategory.payments => Icons.payments_outlined,
      NotifCategory.stock => Icons.inventory_2_outlined,
      NotifCategory.products => isUrgent(n) ? Icons.pause_circle_outline_rounded : Icons.verified_outlined,
      NotifCategory.atomshop => Icons.campaign_rounded,
    };

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.value, required this.present, required this.unreadAll, required this.unreadBy, required this.onChanged});

  final NotifCategory? value;
  final List<NotifCategory> present;
  final int unreadAll;
  final Map<NotifCategory, int> unreadBy;
  final ValueChanged<NotifCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    Widget chip(String label, int count, bool on, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Semantics(
            button: true,
            selected: on,
            label: '$label${count > 0 ? ', $count unread' : ''}',
            excludeSemantics: true,
            child: Material(
              color: on ? pal.primarySoft2 : pal.card,
              shape: StadiumBorder(side: BorderSide(color: on ? pal.ring : pal.border, width: 1.5)),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onTap,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: t.labelLarge?.copyWith(fontSize: 13, color: on ? pal.primary : pal.text)),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          height: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: on ? pal.primary : pal.neutral.bg, borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            '$count',
                            style: t.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: on ? pal.onPrimary : pal.text, fontFeatures: tabularFigures),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
    return SizedBox(
      height: 60,
      child: ShaderMask(
        // Fade the right edge instead of cutting a chip off.
        shaderCallback: (r) => const LinearGradient(colors: [Colors.black, Colors.black, Colors.transparent], stops: [0, 0.88, 1]).createShader(r),
        blendMode: BlendMode.dstIn,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 10, 32, 10),
          children: [
            chip('All', unreadAll, value == null, () => onChanged(null)),
            for (final c in present) chip(categoryLabels[c]!, unreadBy[c] ?? 0, value == c, () => onChanged(c)),
          ],
        ),
      ),
    );
  }
}

/// "N things need your action", from data the app already has: new bulk
/// leads (badge) and products out of stock (dashboard). Hidden when clear.
class _ActionCard extends ConsumerWidget {
  const _ActionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final leads = ref.watch(signedInProvider)?.newBulkRequests ?? 0;
    final oos = ref.watch(dashboardProvider).value?.catalogueOutOfStock ?? 0;
    final rows = [
      if (leads > 0) ('${plural(leads, 'new bulk lead')} to call', '/bulk'),
      if (oos > 0) ("${plural(oos, 'product')} out of stock, buyers can't order", '/catalogue?status=Out%20of%20Stock'),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    final n = rows.length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: Color.alphaBlend(pal.negative.bg.withValues(alpha: 0.6), pal.card),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: pal.negative.fg.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: pal.negative.fg),
                const SizedBox(width: 10),
                Text(
                  '$n ${n == 1 ? 'thing needs' : 'things need'} your action',
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: pal.negative.fg),
                ),
              ],
            ),
          ),
          for (final (label, route) in rows)
            InkWell(
              onTap: () => context.go(route),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.fromLTRB(48, 8, 12, 8),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: pal.negative.fg.withValues(alpha: 0.12)))),
                child: Row(
                  children: [
                    Expanded(child: Text(label, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500, fontFeatures: tabularFigures))),
                    Icon(Icons.chevron_right_rounded, color: pal.muted),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupHeader extends SliverPersistentHeaderDelegate {
  const _GroupHeader(this.title, this.background);
  final String title;
  final Color background;

  @override
  double get minExtent => 40;
  @override
  double get maxExtent => 40;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Semantics(
        header: true,
        child: Container(
          color: background,
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppPalette.of(context).muted,
                ),
          ),
        ),
      );

  @override
  bool shouldRebuild(_GroupHeader old) => old.title != title || old.background != background;
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: pal.card, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: pal.cardShadow),
      child: Column(
        children: [
          for (final (i, c) in children.indexed) ...[
            if (i > 0) Divider(height: 1, color: pal.divider),
            c,
          ],
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    super.key,
    required this.n,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.onMarkRead,
  });

  final AppNotification n;

  /// null when not selecting.
  final bool? selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final cat = categoryOf(n);
    final urgent = isUrgent(n);
    final tone = urgent ? pal.negative : _toneOf(pal, cat);
    final unread = !n.isRead;
    final time = timeLabel(n.createdAt).isEmpty ? (n.timeAgo ?? '') : timeLabel(n.createdAt);
    final bg = selected == true
        ? pal.primarySoft2
        : unread
            ? Color.alphaBlend(pal.primary.withValues(alpha: pal.isDark ? 0.12 : 0.05), pal.card)
            : pal.card;

    final row = Material(
      color: bg,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: selected == true
                      ? Container(
                          decoration: BoxDecoration(color: pal.primary, shape: BoxShape.circle),
                          child: Icon(Icons.check_rounded, color: pal.onPrimary),
                        )
                      : Container(
                          decoration: BoxDecoration(color: tone.bg, shape: BoxShape.circle),
                          child: Icon(_iconOf(n), size: 22, color: tone.fg),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title,
                        style: t.bodyMedium?.copyWith(
                          fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                          color: urgent ? pal.negative.fg : pal.text,
                          height: 1.35,
                        ),
                      ),
                      if (n.body.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          n.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall?.copyWith(fontSize: 13, color: pal.muted, height: 1.4, fontFeatures: tabularFigures),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(time, style: t.bodySmall?.copyWith(fontSize: 12, color: pal.muted, fontFeatures: tabularFigures)),
                    if (unread) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(color: urgent ? pal.danger : pal.primary, shape: BoxShape.circle),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final semantic = Semantics(
      label: [if (unread) 'Unread', if (urgent) 'Needs action', n.title, n.body, time].where((s) => s.isNotEmpty).join('. '),
      selected: selected,
      button: true,
      excludeSemantics: true,
      customSemanticsActions: unread ? {const CustomSemanticsAction(label: 'Mark read'): onMarkRead} : null,
      child: row,
    );

    if (!unread || selected != null) return semantic;
    // Swipe left to mark read; the row stays (the API can't delete yet).
    return Dismissible(
      key: ValueKey('swipe-${n.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onMarkRead();
        return false;
      },
      background: Container(
        color: pal.primary,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done_all_rounded, color: pal.onPrimary),
            const SizedBox(height: 2),
            Text('Mark read', style: t.labelSmall?.copyWith(color: pal.onPrimary, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      child: semantic,
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({required this.count, required this.onSelectAll, required this.onMarkRead});
  final int count;
  final VoidCallback onSelectAll;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: pal.card,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: pal.isDark ? 0.4 : 0.1), blurRadius: 20, offset: const Offset(0, -6))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              TextButton(onPressed: onSelectAll, style: TextButton.styleFrom(minimumSize: const Size(0, 48)), child: const Text('Select all')),
              const Spacer(),
              FilledButton.icon(
                onPressed: onMarkRead,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                icon: const Icon(Icons.done_all_rounded, size: 20),
                label: Text('Mark $count read'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.filtered, required this.onShowAll});
  final bool filtered;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 24, 36, 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(decoration: BoxDecoration(color: pal.primarySoft2, shape: BoxShape.circle)),
                  Icon(Icons.notifications_rounded, size: 60, color: pal.primary),
                  Positioned(
                    right: 12,
                    top: 16,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(color: pal.success, shape: BoxShape.circle, border: Border.all(color: pal.page, width: 2)),
                      child: Icon(Icons.check_rounded, size: 15, color: pal.onSuccess),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(filtered ? 'Nothing here yet' : 'No notifications yet', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            filtered ? 'Try another filter, or show all.' : 'New orders, leads and alerts will show up here.',
            textAlign: TextAlign.center,
            style: t.bodyMedium?.copyWith(color: pal.muted),
          ),
          if (filtered) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onShowAll, style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)), child: const Text('Show all')),
          ],
        ],
      ),
    );
  }
}

class _InboxSkeleton extends StatelessWidget {
  const _InboxSkeleton();

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          Container(
            decoration: BoxDecoration(color: pal.card, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: pal.cardShadow),
            child: Column(
              children: [
                for (var i = 0; i < 5; i++)
                  const Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Bone(width: 44, height: 44, radius: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [Bone(height: 14), SizedBox(height: 8), Bone(width: 200, height: 12)],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
