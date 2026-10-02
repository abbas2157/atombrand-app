import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/models/bulk.dart';
import '../../data/models/json.dart';
import '../../data/repositories/orders_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/paged_list.dart';
import '../../widgets/status_badge.dart';

/// F9: the brand's bulk enquiries, tabbed by status with counts.
class BulkScreen extends ConsumerStatefulWidget {
  const BulkScreen({super.key});

  @override
  ConsumerState<BulkScreen> createState() => _BulkScreenState();
}

class _BulkScreenState extends ConsumerState<BulkScreen> {
  String _status = 'New Lead';
  Map<String, int> _counts = {};
  final _search = TextEditingController();
  Timer? _debounce;
  late final _list = PagedController<BulkRequest>(_fetch);

  Future<Paged<BulkRequest>> _fetch(int page) async {
    final res = await ref.read(bulkRepositoryProvider).list(status: _status, q: _search.text.trim(), page: page);
    if (page == 1 && mounted) setState(() => _counts = res.counts);
    return res.page;
  }

  @override
  void initState() {
    super.initState();
    _list.refresh();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _list.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.read(sessionProvider.notifier).refreshBadge();
    await _list.refresh(showSpinner: false);
  }

  void _onSearch(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _list.refresh);
  }

  @override
  Widget build(BuildContext context) {
    final statuses =
        ref.watch(configProvider).value?.bulkStatuses ?? const ['New Lead', 'Contacted', 'Quoted', 'Won', 'Lost'];
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk requests')),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              children: [
                for (final s in statuses)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      showCheckmark: false,
                      selected: _status == s,
                      label: Text(_counts[s] == null ? s : '$s (${count(_counts[s])})'),
                      onSelected: (_) {
                        setState(() => _status = s);
                        _list.refresh();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: TextField(
              controller: _search,
              onChanged: _onSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search name, phone or product',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _search.clear();
                          _onSearch('');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: PagedListView<BulkRequest>(
                controller: _list,
                onRefresh: _refresh,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                empty: EmptyState(
                  icon: Icons.campaign_outlined,
                  message: _status == 'New Lead' && _search.text.isEmpty
                      ? 'No new enquiries. They appear here the moment a buyer asks for a quote.'
                      : 'No requests here.',
                ),
                itemBuilder: (context, r) => BulkTile(
                  request: r,
                  onTap: () async {
                    final changed = await context.push<bool>('/bulk/${r.id}');
                    if (changed == true) _refresh();
                  },
                ),
              ),
          ),
        ],
      ),
    );
  }
}

/// Buyer, product, quantity, city, status, quick call/WhatsApp (§4.5).
class BulkTile extends StatelessWidget {
  const BulkTile({super.key, required this.request, required this.onTap});

  final BulkRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final r = request;
    final meta = [
      if (r.quantity > 0) 'Qty ${count(r.quantity)}',
      if (r.location.isNotEmpty) r.location,
      formatDate(r.createdAt),
    ].where((s) => s.isNotEmpty).join(' · ');
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      child: Row(
        children: [
          NetThumb(r.product?.picture),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(r.fullName, style: t.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge.bulk(r.status),
                  ],
                ),
                if (r.productTitle != null)
                  Text(r.productTitle!, style: t.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(meta, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (r.commentsCount > 0) ...[
                      const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.muted),
                      const SizedBox(width: 2),
                      Text('${r.commentsCount}', style: t.bodySmall),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (r.phone != null)
            IconButton(
              tooltip: 'Call ${r.fullName}',
              icon: const Icon(Icons.call_outlined, color: AppColors.primary),
              onPressed: () => callPhone(context, r.phone),
            ),
          if (r.whatsapp != null)
            IconButton(
              tooltip: 'WhatsApp ${r.fullName}',
              icon: const Icon(Icons.chat_outlined, color: AppColors.successFg),
              onPressed: () => openExternal(context, r.whatsapp),
            ),
        ],
      ),
    );
  }
}
