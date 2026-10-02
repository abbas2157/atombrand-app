import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/models/order.dart';
import '../../data/repositories/orders_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/status_badge.dart';
import 'order_tile.dart';
import 'status_sheets.dart';

/// Order detail. Buttons come only from `actions[]`; an empty list (or a
/// locked order) is read-only (§3.3).
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

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(d == null ? 'Order' : 'Order #${d.order.id}')),
        body: d == null
            ? (_error != null ? ErrorView(message: _error!, onRetry: _load) : const Center(child: CircularProgressIndicator()))
            : RefreshIndicator(onRefresh: _load, child: _body(d)),
        bottomNavigationBar: d == null || d.locked || d.actions.isEmpty ? null : _actionBar(d),
      ),
    );
  }

  Widget _actionBar(OrderDetail d) {
    final cancel = d.actions.where((a) => a.isCancel).toList();
    final forward = d.actions.where((a) => !a.isCancel).toList();
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.line))),
        child: _busy
            ? const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()))
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  for (final a in cancel)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.dangerFg),
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
    final t = Theme.of(context).textTheme;
    final o = d.order;
    final p = d.product ?? o.product;
    final c = d.customer;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (d.locked || d.actions.isEmpty) ...[
          InfoBanner(
            d.lockedReason ??
                (d.type == OrderFeed.instalment
                    ? 'Seller-sourced deals are managed by the seller. You can view them only.'
                    : 'This order is read-only.'),
            icon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 12),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NetThumb(p?.picture, size: 64),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p?.title ?? 'Product', style: t.titleMedium),
                        if ((p?.variant ?? o.variant) != null) Text((p?.variant ?? o.variant)!, style: t.bodySmall),
                        if (p?.prNumber != null) Text(p!.prNumber!, style: t.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  StatusBadge.order(o.status),
                  if (d.type == OrderFeed.retail) StatusBadge.payment(isCash: o.isCash, tenure: o.tenure),
                ],
              ),
              const SizedBox(height: 8),
              KeyValue('Placed', formatDateTime(o.createdAt)),
              KeyValue('Quantity', o.quantity?.toString()),
              KeyValue('Channel', o.portal),
              KeyValue('City', o.city),
            ],
          ),
        ),
        const SectionTitle('Deal'),
        AppCard(
          child: Column(
            children: [
              KeyValue('Total', money(d.deal.totalDealPrice), emphasize: true),
              KeyValue('Advance', money(d.deal.advancePrice)),
              if (d.deal.financed > 0) ...[
                KeyValue('Financed', money(d.deal.financed)),
                KeyValue('Plan', '${d.deal.tenure} months × ${money(d.deal.monthly)}'),
                KeyValue('Paid so far', money(d.deal.paid)),
                KeyValue('Due', money(d.deal.dueLeft)),
                KeyValue('Recovered', '${d.deal.recoveryPercent}%'),
              ],
            ],
          ),
        ),
        if (c != null) ...[
          const SectionTitle('Customer'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(c.name ?? 'Customer', style: t.titleMedium)),
                    if (c.verified) const StatusBadge('Verified', BadgeTone.success),
                  ],
                ),
                const SizedBox(height: 6),
                KeyValue('Phone', c.phone),
                KeyValue('Alternate phone', c.alternatePhone),
                KeyValue('Email', c.email),
                KeyValue('Father name', c.fatherName),
                KeyValue('CNIC', c.cnic),
                KeyValue('Address', c.address),
                KeyValue('Area', c.area),
                KeyValue('City', c.city),
                KeyValue('Customer ID', c.identifier),
                KeyValue('Customer since', formatDate(c.customerSince)),
                if (c.phone != null || c.whatsapp != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (c.phone != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => callPhone(context, c.phone),
                            icon: const Icon(Icons.call_outlined),
                            label: const Text('Call'),
                          ),
                        ),
                      if (c.phone != null && c.whatsapp != null) const SizedBox(width: 12),
                      if (c.whatsapp != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => openExternal(context, c.whatsapp),
                            icon: const Icon(Icons.chat_outlined),
                            label: const Text('WhatsApp'),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        if (d.instalments.isNotEmpty) ...[
          const SectionTitle('Instalments'),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final (i, inst) in d.instalments.indexed) ...[
                  if (i > 0) const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    dense: true,
                    title: Text(
                      [inst.type, inst.month].whereType<String>().join(' · '),
                      style: t.bodyMedium,
                    ),
                    subtitle: Text(
                      inst.paidDate != null ? 'Paid ${formatDate(inst.paidDate)}' : 'Due ${formatDate(inst.date)}',
                      style: t.bodySmall,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(money(inst.price), style: t.labelMedium?.copyWith(fontFeatures: tabularFigures)),
                        if (inst.status != null)
                          Text(
                            inst.status!,
                            style: t.bodySmall?.copyWith(
                              color: inst.status == 'Paid' ? AppColors.successFg : AppColors.warningFg,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (d.history.isNotEmpty) ...[
          const SectionTitle('History'),
          AppCard(child: _History(d.history)),
        ],
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

class _History extends StatelessWidget {
  const _History(this.entries);
  final List<OrderHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final (i, h) in entries.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    ),
                    if (i < entries.length - 1) Expanded(child: Container(width: 2, color: AppColors.line)),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(orderStatusLabel(h.status), style: t.titleMedium),
                        Text(
                          [h.changedBy, if (h.role != null) '(${h.role})', formatDateTime(h.createdAt)]
                              .whereType<String>()
                              .where((s) => s.isNotEmpty)
                              .join(' · '),
                          style: t.bodySmall,
                        ),
                        if (h.receivedBy != null) Text('Received by ${h.receivedBy}', style: t.bodyMedium),
                        if (h.reason != null) Text(h.reason!, style: t.bodyMedium),
                        if (h.image != null) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => openExternal(context, h.image),
                            child: Semantics(
                              label: 'Delivery photo',
                              button: true,
                              child: NetThumb(h.image, size: 96, icon: Icons.image_outlined),
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
    );
  }
}
