import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/session.dart';
import '../../data/models/order.dart';
import '../../data/repositories/orders_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/paged_list.dart';
import '../../widgets/status_badge.dart';
import 'order_tile.dart';

/// F8: Retail | Instalment feeds with status chips and search.
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

  @override
  Widget build(BuildContext context) {
    final statuses = ref.watch(configProvider).value?.orderStatuses ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<OrderFeed>(
                segments: const [
                  ButtonSegment(value: OrderFeed.retail, label: Text('Retail'), icon: Icon(Icons.storefront_outlined)),
                  ButtonSegment(value: OrderFeed.instalment, label: Text('Instalment'), icon: Icon(Icons.calendar_month_outlined)),
                ],
                selected: {_type},
                onSelectionChanged: (s) {
                  setState(() => _type = s.first);
                  _list.refresh();
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _search,
              onChanged: _onSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by product',
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
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
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                for (final s in [null, ...statuses])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s == null ? 'All' : orderStatusLabel(s)),
                      selected: _status == s,
                      showCheckmark: false,
                      onSelected: (_) {
                        setState(() => _status = s);
                        _list.refresh();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: PagedListView<OrderSummary>(
              controller: _list,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              empty: EmptyState(
                icon: Icons.receipt_long_outlined,
                message: _status == null && _search.text.isEmpty ? 'No orders yet.' : 'No orders with this status.',
              ),
              itemBuilder: (context, o) => OrderTile(
                order: o,
                showPayment: _type == OrderFeed.retail,
                onTap: () async {
                  final changed = await context.push<bool>('/orders/${_type.name}/${o.uuid}');
                  if (changed == true) _list.refresh(showSpinner: false);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
