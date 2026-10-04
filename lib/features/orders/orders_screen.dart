import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/models/json.dart';
import '../../data/models/order.dart';
import '../../data/repositories/orders_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/paged_list.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/status_badge.dart';
import 'order_tile.dart';

/// F8, Orders (DESIGN.md §4.3): Retail | Instalment, search, status chips,
/// cards grouped by day under sticky headers. Long press for quick actions.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key, this.initialType, this.initialStatus});

  final String? initialType;
  final String? initialStatus;

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  late OrderFeed _type = _feedFrom(widget.initialType);
  late String? _status = widget.initialStatus;
  final _search = TextEditingController();
  Timer? _debounce;
  late final _list = PagedController<OrderSummary>(
    (page) => ref.read(ordersRepositoryProvider).orders(type: _type, status: _status, q: _search.text.trim(), page: page),
  );

  static OrderFeed _feedFrom(String? s) => s == 'instalment' ? OrderFeed.instalment : OrderFeed.retail;

  @override
  void initState() {
    super.initState();
    _list.refresh();
  }

  @override
  void didUpdateWidget(OrdersScreen old) {
    super.didUpdateWidget(old);
    // The dashboard deep-links here with a new filter.
    if (old.initialType != widget.initialType || old.initialStatus != widget.initialStatus) {
      _type = _feedFrom(widget.initialType);
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

  void _clearSearch() {
    _search.clear();
    _debounce?.cancel();
    setState(() {});
    _list.refresh();
  }

  void _setType(OrderFeed t) {
    if (t == _type) return;
    setState(() {
      _type = t;
      _status = null;
    });
    _list.refresh();
  }

  void _setStatus(String? s) {
    setState(() => _status = s);
    _list.refresh();
  }

  Future<void> _open(OrderSummary o) async {
    final changed = await context.push<bool>('/orders/${_type.name}/${o.uuid}');
    if (changed == true) _list.refresh(showSpinner: false);
  }

  @override
  Widget build(BuildContext context) {
    final statuses = ref.watch(configProvider).value?.orderStatuses ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: ListenableBuilder(
        listenable: _list,
        builder: (context, _) {
          final raw = _list.firstPage?.raw ?? const <String, dynamic>{};
          final statusCounts = asMap(raw['counts']);
          final typeCounts = asMap(raw['type_counts']);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _TypeSwitch(
                  selected: _type,
                  counts: {
                    for (final t in OrderFeed.values)
                      if (typeCounts[t.name] != null) t: asInt(typeCounts[t.name]),
                  },
                  onChanged: _setType,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: TextField(
                  controller: _search,
                  onChanged: _onSearch,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search by product',
                    prefixIcon: const Icon(Icons.search_rounded),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(tooltip: 'Clear search', icon: const Icon(Icons.close_rounded), onPressed: _clearSearch),
                  ),
                ),
              ),
              SizedBox(
                height: 58,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 6, 8, 4),
                  children: [
                    for (final s in [null, ...statuses])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _StatusChip(
                          label: s == null ? 'All' : orderStatusLabel(s),
                          n: s == null
                              ? (statusCounts.isEmpty ? null : statusCounts.values.fold<int>(0, (a, v) => a + asInt(v)))
                              : (statusCounts[s] == null ? null : asInt(statusCounts[s])),
                          selected: _status == s,
                          onTap: () => _setStatus(s),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _OrdersList(
                  controller: _list,
                  query: _search.text.trim(),
                  status: _status,
                  totalValue: asIntOrNull(raw['total_value']),
                  onClearSearch: _clearSearch,
                  onShowAll: () => _setStatus(null),
                  onOpen: _open,
                  onLongPress: (o) => showOrderQuickActions(context, ref, o, _type),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Retail | Instalment, full width. The active side is soft indigo with a
/// tick; counts show when the server sends them.
class _TypeSwitch extends StatelessWidget {
  const _TypeSwitch({required this.selected, required this.counts, required this.onChanged});
  final OrderFeed selected;
  final Map<OrderFeed, int> counts;
  final ValueChanged<OrderFeed> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.divider),
      ),
      child: Row(
        children: [
          for (final f in OrderFeed.values)
            Expanded(
              child: Semantics(
                selected: f == selected,
                button: true,
                child: InkWell(
                  onTap: () => onChanged(f),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 48,
                    decoration: BoxDecoration(
                      color: f == selected ? p.primarySoft2 : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          f == selected
                              ? Icons.check_rounded
                              : (f == OrderFeed.retail ? Icons.shopping_bag_outlined : Icons.calendar_month_outlined),
                          size: 18,
                          color: f == selected ? p.primary : p.muted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          counts[f] == null ? f.label : '${f.label} (${count(counts[f])})',
                          style: t.labelLarge?.copyWith(color: f == selected ? p.primary : p.muted),
                        ),
                      ],
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

/// Status filter pill: 36 px visual inside a 48 px tap target.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.n, required this.selected, required this.onTap});
  final String label;
  final int? n;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final fg = selected ? p.primary : p.text;
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
            decoration: BoxDecoration(
              color: selected ? p.primarySoft2 : p.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: selected ? p.primary.withValues(alpha: 0.35) : p.border, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: t.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w600)),
                if (n != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    count(n),
                    style: t.labelMedium?.copyWith(
                      color: selected ? p.primary : p.muted,
                      fontWeight: FontWeight.w600,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({
    required this.controller,
    required this.query,
    required this.status,
    required this.totalValue,
    required this.onClearSearch,
    required this.onShowAll,
    required this.onOpen,
    required this.onLongPress,
  });

  final PagedController<OrderSummary> controller;
  final String query;
  final String? status;
  final int? totalValue;
  final VoidCallback onClearSearch;
  final VoidCallback onShowAll;
  final ValueChanged<OrderSummary> onOpen;
  final ValueChanged<OrderSummary> onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;

    Widget scrollable(List<Widget> slivers) => RefreshIndicator(
          onRefresh: () => c.refresh(showSpinner: false),
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.extentAfter < 400) c.loadMore();
              return false;
            },
            child: CustomScrollView(physics: const AlwaysScrollableScrollPhysics(), slivers: slivers),
          ),
        );
    Widget single(Widget child) => scrollable([SliverFillRemaining(hasScrollBody: false, child: child)]);

    if (c.loading && c.items.isEmpty) {
      return Semantics(
        label: 'Loading orders',
        child: Shimmer(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: const [
              Bone(width: 170, height: 14),
              SizedBox(height: 18),
              OrderTileBone(),
              SizedBox(height: 10),
              OrderTileBone(),
              SizedBox(height: 10),
              OrderTileBone(),
            ],
          ),
        ),
      );
    }
    if (c.error != null && c.items.isEmpty) {
      return single(ErrorView(message: c.error!, onRetry: c.refresh));
    }
    if (c.items.isEmpty) {
      if (query.isNotEmpty) {
        return single(_EmptyMessage(
          art: const _SearchArt(),
          title: 'No orders match ‘$query’',
          body: 'Try another product name, or check the spelling.',
          action: FilledButton(onPressed: onClearSearch, child: const Text('Clear search')),
        ));
      }
      if (status != null) {
        return single(_EmptyMessage(
          art: const _ListArt(),
          title: 'No ${orderStatusLabel(status!)} orders',
          body: 'Orders with this status will appear here.',
          action: OutlinedButton(onPressed: onShowAll, child: const Text('Show all orders')),
        ));
      }
      return single(const _EmptyMessage(
        art: _ListArt(),
        title: 'No orders yet',
        body: 'Orders from your store will appear here',
      ));
    }

    final total = c.firstPage?.pagination.total ?? c.items.length;
    final summary = [
      '${count(total)} ${total == 1 ? 'order' : 'orders'}',
      if (totalValue != null) '${money(totalValue)} total',
    ].join(' · ');

    final groups = <String, List<OrderSummary>>{};
    for (final o in c.items) {
      groups.putIfAbsent(dayLabel(o.createdAt), () => []).add(o);
    }

    return scrollable([
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        sliver: SliverToBoxAdapter(
          child: Text(summary, style: t.bodySmall?.copyWith(fontSize: 13, color: p.muted, fontFeatures: tabularFigures)),
        ),
      ),
      for (final g in groups.entries)
        SliverMainAxisGroup(
          slivers: [
            SliverPersistentHeader(pinned: true, delegate: _DayHeader(g.key, p.page, t.bodySmall?.copyWith(color: p.muted))),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: g.value.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final o = g.value[i];
                  return OrderTile(order: o, onTap: () => onOpen(o), onLongPress: () => onLongPress(o));
                },
              ),
            ),
          ],
        ),
      SliverToBoxAdapter(
        child: c.loadingMore
            ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
            : const SizedBox(height: 24),
      ),
    ]);
  }
}

/// "Today", "Yesterday", or "30 Sep 2026".
String dayLabel(String? createdAt, {DateTime? now}) {
  final d = parseServerDate(createdAt);
  if (d == null) return 'Earlier';
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final day = DateUtils.dateOnly(d);
  if (day == today) return 'Today';
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
  return formatDate(createdAt);
}

class _DayHeader extends SliverPersistentHeaderDelegate {
  const _DayHeader(this.title, this.background, this.style);
  final String title;
  final Color background;
  final TextStyle? style;

  @override
  double get minExtent => 38;
  @override
  double get maxExtent => 38;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Semantics(
        header: true,
        child: Container(
          color: background,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          alignment: Alignment.bottomLeft,
          child: Text(title.toUpperCase(), style: style?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.4)),
        ),
      );

  @override
  bool shouldRebuild(covariant _DayHeader old) => old.title != title || old.background != background;
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.art, required this.title, required this.body, this.action});
  final Widget art;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Column(
        children: [
          art,
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: p.muted, height: 1.5)),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

/// A clipboard with empty rows (no orders yet).
class _ListArt extends StatelessWidget {
  const _ListArt();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(size: const Size(180, 140), painter: _ListPainter(AppPalette.of(context))),
      );
}

class _ListPainter extends CustomPainter {
  const _ListPainter(this.p);
  final AppPalette p;

  @override
  void paint(Canvas canvas, Size size) {
    RRect rr(double x, double y, double w, double h, double r) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));
    canvas.drawOval(Rect.fromCenter(center: const Offset(90, 128), width: 124, height: 14), Paint()..color = p.divider);
    canvas.drawCircle(const Offset(90, 66), 60, Paint()..color = p.primarySoft2);
    canvas.drawRRect(rr(54, 24, 72, 96, 10), Paint()..color = p.card);
    canvas.drawRRect(
      rr(54, 24, 72, 96, 10),
      Paint()
        ..color = p.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRRect(rr(74, 16, 32, 16, 5), Paint()..color = p.primary);
    for (final (y, w) in const [(48.0, 28.0), (70.0, 22.0), (92.0, 26.0)]) {
      canvas.drawRRect(rr(68, y, 12, 12, 3), Paint()..color = p.primarySoft2);
      canvas.drawRRect(rr(86, y + 3, w, 6, 3), Paint()..color = p.divider);
    }
    canvas.drawCircle(const Offset(148, 40), 5, Paint()..color = p.accent);
  }

  @override
  bool shouldRepaint(covariant _ListPainter old) => old.p != p;
}

/// A magnifier over a list (no search results).
class _SearchArt extends StatelessWidget {
  const _SearchArt();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(size: const Size(160, 130), painter: _SearchPainter(AppPalette.of(context))),
      );
}

class _SearchPainter extends CustomPainter {
  const _SearchPainter(this.p);
  final AppPalette p;

  @override
  void paint(Canvas canvas, Size size) {
    RRect rr(double x, double y, double w, double h, double r) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));
    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(const Offset(80, 62), 56, Paint()..color = p.primarySoft2);
    canvas.drawRRect(rr(38, 30, 64, 76, 10), Paint()..color = p.card);
    canvas.drawRRect(rr(38, 30, 64, 76, 10), stroke(p.border, 2));
    for (final (y, w) in const [(44.0, 36.0), (58.0, 44.0), (72.0, 28.0)]) {
      canvas.drawRRect(rr(48, y, w, 6, 3), Paint()..color = p.divider);
    }
    canvas.drawCircle(const Offset(104, 74), 20, Paint()..color = p.card);
    canvas.drawCircle(const Offset(104, 74), 20, stroke(p.primary, 5));
    canvas.drawLine(const Offset(118, 88), const Offset(134, 104), stroke(p.primary, 7));
    canvas.drawLine(const Offset(97, 67), const Offset(111, 81), stroke(p.accent, 3.5));
    canvas.drawLine(const Offset(111, 67), const Offset(97, 81), stroke(p.accent, 3.5));
  }

  @override
  bool shouldRepaint(covariant _SearchPainter old) => old.p != p;
}

/// Long-press sheet: call or WhatsApp the customer, or copy the order #.
/// Contact details come from the order detail, fetched on open and kept in
/// memory only (§8.6).
Future<void> showOrderQuickActions(BuildContext context, WidgetRef ref, OrderSummary o, OrderFeed type) {
  HapticFeedback.mediumImpact();
  final detail = ref.read(ordersRepositoryProvider).order(type, o.uuid);
  return showModalBottomSheet<void>(
    context: context,
    builder: (ctx) {
      final p = AppPalette.of(ctx);
      final t = Theme.of(ctx).textTheme;
      Widget row({
        required IconData icon,
        required Tone tone,
        required String label,
        String? note,
        bool busy = false,
        VoidCallback? onTap,
      }) =>
          ListTile(
            minTileHeight: 56,
            enabled: onTap != null,
            onTap: onTap,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: tone.fg),
            ),
            title: Text(label, style: t.bodyLarge),
            subtitle: note == null ? null : Text(note, style: t.bodySmall),
            trailing: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : null,
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
                    Text('#${o.id} · ${o.product?.title ?? 'Order'}', style: t.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${orderStatusLabel(o.status)} · ${money(o.totalDealPrice)}',
                      style: t.bodySmall?.copyWith(color: p.muted, fontFeatures: tabularFigures),
                    ),
                  ],
                ),
              ),
              const Divider(),
              FutureBuilder<OrderDetail>(
                future: detail,
                builder: (ctx, snap) {
                  final waiting = snap.connectionState != ConnectionState.done;
                  final customer = snap.data?.customer;
                  final missing = waiting ? null : 'Not available for this order';
                  return Column(
                    children: [
                      row(
                        icon: Icons.call_outlined,
                        tone: p.indigo,
                        label: 'Call customer',
                        busy: waiting,
                        note: customer?.phone == null ? missing : null,
                        onTap: customer?.phone == null
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                callPhone(context, customer!.phone);
                              },
                      ),
                      row(
                        icon: Icons.chat_outlined,
                        tone: p.positive,
                        label: 'WhatsApp',
                        busy: waiting,
                        note: customer?.whatsapp == null ? missing : null,
                        onTap: customer?.whatsapp == null
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                openExternal(context, customer!.whatsapp);
                              },
                      ),
                    ],
                  );
                },
              ),
              row(
                icon: Icons.copy_rounded,
                tone: p.neutral,
                label: 'Copy order #${o.id}',
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: '#${o.id}'));
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) showToast(context, 'Order #${o.id} copied');
                },
              ),
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
  ).whenComplete(() => detail.ignore());
}

