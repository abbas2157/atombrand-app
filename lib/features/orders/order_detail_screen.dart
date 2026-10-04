import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/models/order.dart';
import '../../data/repositories/orders_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/status_badge.dart';
import 'order_detail_logic.dart';
import 'order_tile.dart';
import 'status_sheets.dart';

/// Order detail (DESIGN.md §4.4): product, progress, deal, schedule,
/// customer and activity. Status buttons come only from `actions[]`; an empty
/// list (or a locked order) is read-only (§3.3).
///
/// Customer data is personal (CNIC, address) and lives only in this
/// widget's memory: never persisted or logged.
class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.type, required this.uuid});

  final OrderFeed type;
  final String uuid;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  OrderDetail? _detail;
  String? _error;
  bool _busy = false;
  bool _changed = false;
  bool _bannerHidden = false;

  OrdersRepository get _repo => ref.read(ordersRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final d = await _repo.order(widget.type, widget.uuid);
      if (mounted) setState(() => _detail = d);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _runAction(OrderAction action) async {
    StatusInput? input;
    if (action.fields.isEmpty) {
      final ok = await confirm(
        context,
        title: '${action.label}?',
        message: 'Move this order to "${orderStatusLabel(action.status)}".',
        confirmLabel: action.label,
      );
      if (!ok) return;
    } else {
      if (!mounted) return;
      input = await showStatusSheet(context, action);
      if (input == null) return;
    }

    setState(() => _busy = true);
    try {
      await _repo.changeStatus(
        widget.uuid,
        action.status, // sent exactly as given, e.g. `Varification`
        receivedBy: input?.receivedBy,
        deliveredPicture: input?.picture,
        reason: input?.reason,
        flags: input?.flags ?? const {},
      );
      _changed = true;
      if (mounted) showToast(context, 'Order moved to ${orderStatusLabel(action.status)}.');
      await _load();
    } on ApiException catch (e) {
      if (mounted) await showApiError(context, e);
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy(OrderDetail d) async {
    await Clipboard.setData(ClipboardData(text: '#${d.order.id}'));
    if (mounted) showToast(context, 'Order #${d.order.id} copied');
  }

  void _share(OrderDetail d) {
    final o = d.order;
    // Order facts only; never the customer's personal data.
    final text = [
      'Order #${o.id}',
      (d.product ?? o.product)?.title,
      money(o.totalDealPrice),
      orderStatusLabel(o.status),
      formatDateTime(o.createdAt),
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    SharePlus.instance.share(ShareParams(text: text));
  }

  void _report(OrderDetail d) {
    final config = ref.read(configProvider).value;
    final subject = Uri.encodeComponent('Problem with order #${d.order.id}');
    if (config?.supportEmail != null) {
      openExternal(context, 'mailto:${config!.supportEmail}?subject=$subject');
    } else if (config?.supportWhatsapp != null) {
      openExternal(context, config!.supportWhatsapp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    final config = ref.watch(configProvider).value;
    final canReport = config?.supportEmail != null || config?.supportWhatsapp != null;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(d == null ? 'Order' : 'Order #${d.order.id}'),
          actions: d == null
              ? null
              : [
                  IconButton(tooltip: 'Copy order number', onPressed: () => _copy(d), icon: const Icon(Icons.copy_rounded)),
                  PopupMenuButton<String>(
                    tooltip: 'More options',
                    onSelected: (v) => v == 'share' ? _share(d) : _report(d),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'share',
                        child: ListTile(leading: Icon(Icons.share_outlined), title: Text('Share order')),
                      ),
                      if (canReport)
                        const PopupMenuItem(
                          value: 'report',
                          child: ListTile(leading: Icon(Icons.flag_outlined), title: Text('Report a problem')),
                        ),
                    ],
                  ),
                ],
        ),
        body: d == null
            ? (_error != null ? ErrorView(message: _error!, onRetry: _load) : const _DetailSkeleton())
            : RefreshIndicator(onRefresh: _load, child: _body(d)),
        bottomNavigationBar: d == null || d.locked || d.actions.isEmpty ? null : _actionBar(d),
      ),
    );
  }

  Widget _actionBar(OrderDetail d) {
    final p = AppPalette.of(context);
    final cancel = d.actions.where((a) => a.isCancel).toList();
    final forward = d.actions.where((a) => !a.isCancel).toList();
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(color: p.card, border: Border(top: BorderSide(color: p.divider))),
        child: _busy
            ? const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()))
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  for (final a in cancel)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: p.danger),
                      onPressed: () => _runAction(a),
                      child: Text(a.label),
                    ),
                  for (final a in forward) FilledButton(onPressed: () => _runAction(a), child: Text(a.label)),
                ],
              ),
      ),
    );
  }

  Widget _body(OrderDetail d) {
    final instalment = d.type == OrderFeed.instalment || d.deal.financed > 0;
    final showBanner = !_bannerHidden && (d.locked || d.type == OrderFeed.instalment);
    final schedule = scheduleRows(d.instalments);
    final steps = orderProgress(d);
    const gap = SizedBox(height: 16);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (showBanner) ...[
          _LockedBanner(
            text: d.lockedReason ??
                'AtomShop handles verification, payments and recovery for this order. You can track progress here.',
            onDismiss: () => setState(() => _bannerHidden = true),
          ),
          gap,
        ],
        _ProductCard(d),
        gap,
        if (steps != null) _ProgressCard(steps) else _CancelledCard(d),
        gap,
        _DealCard(d, instalment: instalment, dueNow: schedule.isEmpty ? null : dueNow(schedule)),
        if (schedule.isNotEmpty) ...[gap, _ScheduleCard(schedule)],
        if (d.customer != null) ...[gap, _CustomerCard(d.customer!)],
        gap,
        _ActivityCard(d),
        if (d.alsoBought.isNotEmpty) ...[
          const SectionTitle('Customer also bought'),
          for (final ob in d.alsoBought) ...[
            OrderTile(order: ob, onTap: () => context.push('/orders/retail/${ob.uuid}')),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

TextStyle? _cardTitle(BuildContext context) => Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16);

/// Muted label on the left, value on the right; long values wrap and stay
/// right-aligned.
class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.child, this.valueStyle});
  final String label;
  final String? value;
  final Widget? child;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    if (child == null && (value == null || value!.isEmpty)) return const SizedBox.shrink();
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.bodyMedium?.copyWith(fontSize: 13, color: p.muted, height: 1.45)),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.topRight,
              child: child ??
                  Text(
                    value!,
                    textAlign: TextAlign.end,
                    style: (valueStyle ?? t.bodyMedium)?.copyWith(height: 1.45, fontFeatures: tabularFigures),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedBanner extends StatelessWidget {
  const _LockedBanner({required this.text, required this.onDismiss});
  final String text;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
      decoration: BoxDecoration(color: p.info.bg, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 10), child: Icon(Icons.lock_outline_rounded, size: 20, color: p.info.fg)),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.45, color: p.text)),
            ),
          ),
          IconButton(tooltip: 'Dismiss', onPressed: onDismiss, icon: Icon(Icons.close_rounded, size: 20, color: p.info.fg)),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard(this.d);
  final OrderDetail d;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = AppPalette.of(context);
    final o = d.order;
    final product = d.product ?? o.product;
    final variant = product?.variant ?? o.variant;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NetThumb(product?.picture, size: 88, radius: 14),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product?.title ?? 'Product', style: _cardTitle(context)),
                    if (variant != null) Text(variant, style: t.bodySmall?.copyWith(fontSize: 13, color: p.muted)),
                    if (product?.prNumber != null) Text(product!.prNumber!, style: t.bodySmall?.copyWith(fontSize: 13, color: p.muted)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [StatusBadge.order(o.status), StatusBadge.payment(isCash: o.isCash, tenure: o.tenure ?? d.deal.tenure)],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 6),
          _Row('Placed', formatDateTime(o.createdAt)),
          _Row('Quantity', o.quantity?.toString()),
          _Row('Channel', o.portal),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard(this.steps);
  final List<ProgressStep> steps;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final current = steps.where((s) => s.current).map((s) => s.label).firstOrNull;
    final lastDone = steps.lastWhere((s) => s.done, orElse: () => steps.first).label;
    bool reached(int i) => steps[i].done || steps[i].current;
    return Semantics(
      label: current == null ? 'Progress: $lastDone' : 'Progress: $lastDone, next $current',
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(padding: const EdgeInsets.only(left: 8, bottom: 14), child: Text('Progress', style: _cardTitle(context))),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, s) in steps.indexed)
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 24,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(height: 2, color: i == 0 ? Colors.transparent : (reached(i) ? p.primary : p.divider)),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 2,
                                      color: i == steps.length - 1 ? Colors.transparent : (reached(i + 1) ? p.primary : p.divider),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: s.done ? p.primary : (s.current ? p.card : p.surface),
                                  border: s.done ? null : Border.all(color: s.current ? p.primary : p.border, width: 2),
                                  boxShadow: s.current ? [BoxShadow(color: p.primarySoft2, spreadRadius: 4)] : null,
                                ),
                                child: s.done
                                    ? Icon(Icons.check_rounded, size: 15, color: p.onPrimary)
                                    : s.current
                                        ? Center(
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(color: p.primary, shape: BoxShape.circle),
                                            ),
                                          )
                                        : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            s.label,
                            maxLines: 1,
                            style: t.labelSmall?.copyWith(
                              fontSize: 11,
                              fontWeight: s.current ? FontWeight.w700 : (s.done ? FontWeight.w600 : FontWeight.w500),
                              color: s.current ? p.primary : (s.done ? p.text : p.muted),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(s.date, style: t.labelSmall?.copyWith(fontSize: 11, color: p.muted)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Replaces the tracker on cancelled orders.
class _CancelledCard extends StatelessWidget {
  const _CancelledCard(this.d);
  final OrderDetail d;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final entry = d.history.where((h) => h.status == 'Cancelled').firstOrNull;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: p.negative.bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.block_rounded, size: 20, color: p.negative.fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cancelled', style: _cardTitle(context)?.copyWith(color: p.negative.fg)),
                if (entry?.createdAt != null) Text(formatDateTime(entry!.createdAt), style: t.bodySmall?.copyWith(color: p.muted)),
                if (entry?.reason != null) ...[const SizedBox(height: 6), Text(entry!.reason!, style: t.bodyMedium)],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  const _DealCard(this.d, {required this.instalment, this.dueNow});
  final OrderDetail d;
  final bool instalment;
  final int? dueNow;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final deal = d.deal;
    final o = d.order;
    final total = deal.totalDealPrice > 0 ? deal.totalDealPrice : o.totalDealPrice;
    final advance = deal.advancePrice > 0 ? deal.advancePrice : o.advancePrice;
    final pct = deal.recoveryPercent.clamp(0, 100);
    Widget legend(Color c, String label, int value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 6),
                  Text(label, style: t.bodySmall?.copyWith(color: p.muted)),
                ],
              ),
              const SizedBox(height: 2),
              Text(money(value), style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontFeatures: tabularFigures)),
            ],
          ),
        );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Deal', style: _cardTitle(context)),
          const SizedBox(height: 12),
          Text('Total', style: t.bodySmall?.copyWith(color: p.muted)),
          Text(
            money(total),
            style: t.headlineSmall?.copyWith(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.3, fontFeatures: tabularFigures),
          ),
          if (instalment && total > 0) ...[
            const SizedBox(height: 14),
            Semantics(
              label: 'Advance ${money(advance)}, financed ${money(deal.financed)}',
              excludeSemantics: true,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: SizedBox(
                      height: 10,
                      child: Row(
                        children: [
                          Expanded(flex: advance.clamp(1, total), child: Container(color: p.primary)),
                          const SizedBox(width: 2),
                          Expanded(flex: deal.financed.clamp(1, total), child: Container(color: p.primarySoft2)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [legend(p.primary, 'Advance', advance), legend(p.primarySoft2, 'Financed', deal.financed)]),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 6),
            _Row('Plan', '${deal.tenure} months × ${money(deal.monthly)}'),
            _Row('Paid so far', money(deal.paid)),
            // From the schedule when there is one, else the server's `due_left`.
            _Row(
              'Due now',
              money(dueNow ?? deal.dueLeft),
              valueStyle: (dueNow ?? deal.dueLeft) > 0
                  ? t.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: p.negative.fg)
                  : null,
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 14),
            Row(
              children: [
                Semantics(
                  label: '$pct% of the financed amount recovered',
                  excludeSemantics: true,
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: pct / 100,
                          strokeWidth: 8,
                          strokeCap: StrokeCap.round,
                          color: p.primary,
                          backgroundColor: p.divider,
                        ),
                        Center(child: Text('$pct%', style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$pct% recovered', style: _cardTitle(context)?.copyWith(fontWeight: FontWeight.w700)),
                      Text('of ${money(deal.financed)} financed', style: t.bodySmall?.copyWith(fontSize: 13, color: p.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 6),
            _Row('Payment', null, child: StatusBadge.payment(isCash: o.isCash, tenure: o.tenure ?? d.deal.tenure)),
            if (advance > 0 && advance < total) _Row('Advance', money(advance)),
          ],
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard(this.rows);
  final List<ScheduleRow> rows;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final instalments = rows.where((r) => r.badge != 'A');
    final paid = instalments.where((r) => r.state == PaymentState.paid).length;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              children: [
                Expanded(child: Text('Schedule', style: _cardTitle(context))),
                Text('$paid of ${instalments.length} paid', style: t.bodySmall?.copyWith(color: p.muted)),
              ],
            ),
          ),
          for (final r in rows) _ScheduleLine(r),
        ],
      ),
    );
  }
}

class _ScheduleLine extends StatelessWidget {
  const _ScheduleLine(this.r);
  final ScheduleRow r;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final (chipLabel, tone) = switch (r.state) {
      PaymentState.paid => ('Paid', BadgeTone.success),
      PaymentState.due => ('Due', BadgeTone.warning),
      PaymentState.upcoming => ('Upcoming', BadgeTone.neutral),
      PaymentState.overdue => ('Overdue', BadgeTone.danger),
    };
    final overdue = r.state == PaymentState.overdue;
    final (badgeBg, badgeFg) = switch (r.state) {
      PaymentState.paid => (p.positive.bg, p.positive.fg),
      PaymentState.overdue => (p.negative.bg, p.negative.fg),
      _ => r.next ? (p.primary, p.onPrimary) : (p.surface, p.muted),
    };
    return Semantics(
      label: '${r.title}, ${money(r.amount)}, $chipLabel${r.next ? ', next payment' : ''}, ${r.when}',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: r.next ? p.primarySoft : (overdue ? p.negative.bg.withValues(alpha: 0.5) : null),
          borderRadius: BorderRadius.circular(12),
          border: r.next ? Border.all(color: p.primarySoft2, width: 1.5) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
              child: Text(r.badge, style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: badgeFg)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(r.title, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      if (r.next)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: p.primary, borderRadius: BorderRadius.circular(999)),
                          child: Text('Next', style: t.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: p.onPrimary)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(r.when, style: t.bodySmall?.copyWith(color: p.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  money(r.amount),
                  style: t.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: overdue ? p.negative.fg : p.text,
                    fontFeatures: tabularFigures,
                  ),
                ),
                const SizedBox(height: 4),
                StatusBadge(chipLabel, tone),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard(this.c);
  final OrderCustomer c;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final buttonStyle =OutlinedButton.styleFrom(foregroundColor: p.primary, side: BorderSide(color: p.primary, width: 1.5));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Customer', style: _cardTitle(context)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(c.name ?? 'Customer', style: _cardTitle(context)?.copyWith(fontWeight: FontWeight.w700)),
              c.verified ? const StatusBadge('Verified', BadgeTone.success) : const StatusBadge('Unverified', BadgeTone.neutral),
            ],
          ),
          const SizedBox(height: 8),
          _Row('Phone', c.phone),
          _Row('Alternate phone', c.alternatePhone),
          _Row('Email', c.email),
          _Row('Father name', c.fatherName),
          _Row('CNIC', c.cnic),
          _Row('Address', c.address),
          _Row('Area', c.area),
          _Row('City', c.city),
          _Row('Customer ID', c.identifier),
          _Row('Customer since', formatDate(c.customerSince)),
          if (c.phone != null || c.whatsapp != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (c.phone != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: buttonStyle,
                      onPressed: () => callPhone(context, c.phone),
                      icon: const Icon(Icons.call_outlined, size: 20),
                      label: const Text('Call'),
                    ),
                  ),
                if (c.phone != null && c.whatsapp != null) const SizedBox(width: 12),
                if (c.whatsapp != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: buttonStyle,
                      onPressed: () => openExternal(context, c.whatsapp),
                      icon: const Icon(Icons.chat_outlined, size: 20),
                      label: const Text('WhatsApp'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard(this.d);
  final OrderDetail d;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final o = d.order;
    // The placement itself, unless the history already starts with it.
    final placedInHistory = d.history.any((h) => h.status == 'Pending');
    final entries = [
      if (!placedInHistory)
        (title: activityLabel('Pending', channel: o.portal), notes: <String>[], at: o.createdAt, alert: false, image: null as String?),
      for (final h in d.history)
        (
          title: activityLabel(h.status, channel: o.portal),
          notes: [
            if (h.changedBy != null) 'By ${h.changedBy}${h.role != null ? ' (${h.role})' : ''}',
            if (h.receivedBy != null) 'Received by ${h.receivedBy}',
            ?h.reason,
          ],
          at: h.createdAt,
          alert: h.status == 'Cancelled',
          image: h.image,
        ),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Activity', style: _cardTitle(context)),
          const SizedBox(height: 14),
          for (final (i, e) in entries.indexed)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 14,
                    child: Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(color: e.alert ? p.danger : p.primary, shape: BoxShape.circle),
                        ),
                        if (i < entries.length - 1)
                          Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: p.divider)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: i < entries.length - 1 ? 16 : 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: e.alert ? p.negative.fg : p.text),
                          ),
                          for (final n in e.notes) Text(n, style: t.bodySmall?.copyWith(fontSize: 13, color: p.muted)),
                          if (e.at != null) Text(formatDateTime(e.at), style: t.bodySmall?.copyWith(color: p.muted, fontFeatures: tabularFigures)),
                          if (e.image != null) ...[
                            const SizedBox(height: 8),
                            Semantics(
                              label: 'Delivery photo',
                              button: true,
                              child: InkWell(
                                onTap: () => openExternal(context, e.image),
                                borderRadius: BorderRadius.circular(10),
                                child: NetThumb(e.image, size: 96, icon: Icons.image_outlined),
                              ),
                            ),
                          ],
                        ],
                      ),
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

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    Widget card(Widget child) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: p.cardShadow),
          child: child,
        );
    return Semantics(
      label: 'Loading order',
      child: Shimmer(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            card(const Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Bone(width: 88, height: 88, radius: 14),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Bone(height: 16),
                          SizedBox(height: 10),
                          Bone(width: 80, height: 12),
                          SizedBox(height: 12),
                          Row(children: [Bone(width: 64, height: 24, radius: 999), SizedBox(width: 6), Bone(width: 90, height: 24, radius: 999)]),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18),
                Bone(height: 12),
                SizedBox(height: 12),
                Bone(height: 12),
              ],
            )),
            const SizedBox(height: 16),
            card(Row(
              children: [
                for (var i = 0; i < 5; i++)
                  const Expanded(
                    child: Column(children: [Bone(width: 24, height: 24, radius: 12), SizedBox(height: 8), Bone(width: 44, height: 10)]),
                  ),
              ],
            )),
            const SizedBox(height: 16),
            card(const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone(width: 60, height: 16),
                SizedBox(height: 14),
                Bone(width: 150, height: 26),
                SizedBox(height: 14),
                Bone(height: 10, radius: 5),
                SizedBox(height: 16),
                Bone(height: 12),
                SizedBox(height: 12),
                Bone(height: 12),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
