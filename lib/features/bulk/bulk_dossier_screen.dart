import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/models/bulk.dart';
import '../../data/repositories/orders_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/status_badge.dart';
import 'bulk_screen.dart';

/// Bulk request dossier: the request, its timeline, and the requester's
/// dealings with this brand only (§2.4).
class BulkDossierScreen extends ConsumerStatefulWidget {
  const BulkDossierScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<BulkDossierScreen> createState() => _BulkDossierScreenState();
}

class _BulkDossierScreenState extends ConsumerState<BulkDossierScreen> {
  BulkDossier? _d;
  String? _error;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final d = await ref.read(bulkRepositoryProvider).dossier(widget.id);
      if (mounted) setState(() => _d = d);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _updateStatus() async {
    final d = _d;
    if (d == null) return;
    final statuses = ref.read(configProvider).value?.bulkStatuses ?? const ['New Lead', 'Contacted', 'Quoted', 'Won', 'Lost'];
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BulkStatusSheet(request: d.request, statuses: statuses),
    );
    if (updated == true) {
      _changed = true;
      ref.read(sessionProvider.notifier).refreshBadge();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Bulk request')),
        body: d == null
            ? (_error != null ? ErrorView(message: _error!, onRetry: _load) : const Center(child: CircularProgressIndicator()))
            : RefreshIndicator(onRefresh: _load, child: _body(d)),
        bottomNavigationBar: d == null
            ? null
            : SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.line)),
                  ),
                  child: Row(
                    children: [
                      if (d.request.phone != null) ...[
                        IconButton.outlined(
                          tooltip: 'Call',
                          onPressed: () => callPhone(context, d.request.phone),
                          icon: const Icon(Icons.call_outlined),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (d.request.whatsapp != null) ...[
                        IconButton.outlined(
                          tooltip: 'WhatsApp',
                          onPressed: () => openExternal(context, d.request.whatsapp),
                          icon: const Icon(Icons.chat_outlined),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _updateStatus,
                          icon: const Icon(Icons.edit_note_rounded),
                          label: const Text('Update status'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _body(BulkDossier d) {
    final t = Theme.of(context).textTheme;
    final r = d.request;
    final who = d.requester;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(r.fullName, style: t.titleLarge)),
                  StatusBadge.bulk(r.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  NetThumb(r.product?.picture),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.productTitle ?? 'Product', style: t.titleMedium),
                        Text('Quantity: ${count(r.quantity)}', style: t.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              KeyValue('Phone', r.phone),
              KeyValue('Location', r.location),
              KeyValue('Address', r.address),
              KeyValue('Channel', r.portal),
              KeyValue('Received', formatDateTime(r.createdAt)),
              KeyValue('Reason', r.reason),
            ],
          ),
        ),
        const SectionTitle('Timeline'),
        AppCard(
          child: r.comments.isEmpty
              ? Text('No updates yet. Call the buyer, then record what happened.', style: t.bodySmall)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, c) in r.comments.indexed) ...[
                      if (i > 0) const Divider(height: 20),
                      Row(
                        children: [
                          if (c.status != null) ...[StatusBadge.bulk(c.status!), const SizedBox(width: 8)],
                          Expanded(
                            child: Text(
                              [c.byName, formatDateTime(c.createdAt)].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                              style: t.bodySmall,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                      if (c.comments != null) ...[const SizedBox(height: 6), Text(c.comments!, style: t.bodyMedium)],
                    ],
                  ],
                ),
        ),
        const SectionTitle('Requester'),
        AppCard(
          child: who == null
              ? Text('Guest buyer with no AtomShop account.', style: t.bodySmall)
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(who.name ?? r.fullName, style: t.titleMedium)),
                        if (who.verified) const StatusBadge('Verified', BadgeTone.success),
                      ],
                    ),
                    const SizedBox(height: 6),
                    KeyValue('Phone', who.phone),
                    KeyValue('Email', who.email),
                    KeyValue('City', [who.area, who.city].whereType<String>().join(', ')),
                    KeyValue('Customer ID', who.identifier),
                    KeyValue('Customer since', formatDate(who.customerSince)),
                  ],
                ),
        ),
        const SectionTitle('Dealings with your brand'),
        AppCard(
          child: Column(
            children: [
              KeyValue('Lifetime value', money(d.lifetimeValue), emphasize: true),
              KeyValue('Orders', count(d.orders.length)),
              KeyValue('Instalments paid', count(d.instalmentsPaid)),
              KeyValue('Instalments unpaid', count(d.instalmentsUnpaid)),
              if (d.instalmentsOverdue > 0) KeyValue('Overdue', count(d.instalmentsOverdue)),
              for (final o in d.orders) ...[
                const Divider(height: 20),
                InkWell(
                  onTap: () => context.push('/orders/retail/${o.uuid}'),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.product ?? 'Order', style: t.bodyMedium),
                            Text('${money(o.totalDealPrice)} · ${formatDate(o.createdAt)}', style: t.bodySmall),
                          ],
                        ),
                      ),
                      StatusBadge.order(o.status),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (d.otherRequests.isNotEmpty) ...[
          const SectionTitle('Other requests from this buyer'),
          for (final o in d.otherRequests) ...[
            BulkTile(request: o, onTap: () => context.push('/bulk/${o.id}')),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class _BulkStatusSheet extends ConsumerStatefulWidget {
  const _BulkStatusSheet({required this.request, required this.statuses});

  final BulkRequest request;
  final List<String> statuses;

  @override
  ConsumerState<_BulkStatusSheet> createState() => _BulkStatusSheetState();
}

class _BulkStatusSheetState extends ConsumerState<_BulkStatusSheet> {
  late String _status = widget.request.status;
  final _comment = TextEditingController();
  final _reason = TextEditingController();
  bool _busy = false;
  ApiException? _error;

  @override
  void dispose() {
    _comment.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(bulkRepositoryProvider).updateStatus(
            widget.request.id,
            _status,
            comments: _comment.text.trim(),
            reason: _status == 'Lost' ? _reason.text.trim() : null,
          );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
      if (e.fieldErrors.isEmpty) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Update status', style: t.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in widget.statuses)
                  ChoiceChip(
                    label: Text(s),
                    selected: _status == s,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _status = s),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_status == 'Lost') ...[
              TextField(
                controller: _reason,
                maxLength: 255,
                decoration: InputDecoration(
                  labelText: 'Why was it lost? (optional)',
                  errorText: _error?.fieldError('reason'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _comment,
              maxLength: 1000,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Comment (optional)',
                hintText: 'e.g. Sent a quote for 50 units',
                errorText: _error?.fieldError('comments'),
              ),
            ),
            const SizedBox(height: 12),
            BusyButton(label: 'Save', busy: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
