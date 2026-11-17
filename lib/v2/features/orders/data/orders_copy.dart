import '../../../core/api/api_client.dart' show Json;
import '../../../core/api/api_page.dart';
import '../../../core/db/sync_store.dart';
import 'order_rules.dart';
import 'orders_models.dart';

/// Cash orders read from the phone's copy (Offline add-on) when there is no
/// signal. The copy's `orders` rows carry the customer and product flat
/// (`customer_name`, `product_title`); paid is the sum of the order's
/// `order_payments` (docs/brand-app-sync.md §4).
class OrdersCopy {
  OrdersCopy(this.store, this.shopId, {this.outletNames = const {}});

  final SyncStore store;
  final int shopId;

  /// Outlet id → name, from the session (the copy keeps only the id).
  final Map<int, String> outletNames;

  Future<Map<int, int>> _paidByOrder() async {
    final out = <int, int>{};
    for (final p in await store.rows('order_payments', shopId: shopId)) {
      final id = Json.integer(p['order_id']);
      if (id == null) continue;
      out[id] = (out[id] ?? 0) + (Json.integer(p['amount']) ?? 0);
    }
    return out;
  }

  /// A copy row in the server's list shape.
  Map<String, dynamic> _shape(Map<String, dynamic> row, int paid) {
    final total = Json.integer(row['total_deal_price']) ?? 0;
    final outletId = Json.integer(row['brand_outlet_id']);
    return {
      ...row,
      'paid': paid,
      'balance': (total - paid).clamp(0, total),
      'product': {'title': row['product_title']},
      if (outletId != null)
        'outlet': {'id': outletId, 'name': outletNames[outletId] ?? ''},
    };
  }

  /// Every cash order in the copy that matches [q], newest first, as one
  /// page.
  Future<ApiPage<CashOrder>> list(OrdersQuery q) async {
    final paid = await _paidByOrder();
    final words = q.q.trim().toLowerCase();
    final items = <CashOrder>[];
    for (final row in await store.rows('orders', shopId: shopId)) {
      if (row['type'] == 'atompay') continue;
      final o = CashOrder.fromJson(
        _shape(row, paid[Json.integer(row['id'])] ?? 0),
      );
      if (q.status != null && o.stage != OrderStage.fromKey(q.status)) {
        continue;
      }
      if (q.outletId != null && o.outlet?.id != q.outletId) continue;
      if (q.payment != null && o.payState.name != q.payment) continue;
      final day = o.createdAt;
      if (q.from case final f? when day == null || day.isBefore(f)) continue;
      if (q.to case final t?
          when day == null || !day.isBefore(t.add(const Duration(days: 1)))) {
        continue;
      }
      if (words.isNotEmpty &&
          ![
            o.productTitle,
            o.customerName ?? '',
            o.customerPhone ?? '',
            '${o.id}',
          ].any((s) => s.toLowerCase().contains(words))) {
        continue;
      }
      items.add(o);
    }
    items.sort((a, b) => b.id.compareTo(a.id));
    return ApiPage(items: items, total: items.length);
  }

  /// Counts per status key for the chips, over the copy.
  Future<Map<String, int>> counts(OrdersQuery q) async {
    final page = await list(anyStatus(q));
    final out = <String, int>{};
    for (final o in page.items) {
      out[o.stage.key] = (out[o.stage.key] ?? 0) + 1;
    }
    return out;
  }

  Future<Map<String, dynamic>?> _row(String uuid) async {
    for (final row in await store.rows('orders', shopId: shopId)) {
      if (row['uuid'] == uuid) return row;
    }
    return null;
  }

  /// The order page from the copy, or null when the copy doesn't hold it.
  Future<CashOrderDetail?> detail(String uuid) async {
    final row = await _row(uuid);
    if (row == null) return null;
    final id = Json.integer(row['id']);
    final payments = [
      for (final p in await store.rows('order_payments', shopId: shopId))
        if (Json.integer(p['order_id']) == id) p,
    ];
    final paid = payments.fold<int>(
      0,
      (n, p) => n + (Json.integer(p['amount']) ?? 0),
    );
    final history = [
      for (final h in await store.rows('order_history', shopId: shopId))
        if (Json.integer(h['order_id']) == id) OrderEvent.fromJson(h),
    ]..sort((a, b) => (b.at ?? DateTime(0)).compareTo(a.at ?? DateTime(0)));
    final account = (await store.rows('account', shopId: shopId)).firstOrNull;
    final next = row['next_statuses'];
    final name = Json.str(row['customer_name']);
    return CashOrderDetail(
      order: CashOrder.fromJson(_shape(row, paid)),
      customer: name == null
          ? null
          : OrderCustomer(
              name: name,
              phone: Json.str(row['customer_phone']),
              address: Json.str(row['customer_address']),
            ),
      history: history,
      payments: [for (final p in payments) OrderPaymentRow.fromJson(p)],
      paymentMethods: [
        for (final m in Json.list(account?['payment_methods'])) ?Json.str(m),
      ],
      nextStatuses: next is List
          ? [for (final s in next) OrderStage.fromKey(Json.str(s))]
          : null,
      prNumber: Json.str(row['pr_number']),
      fromCopy: true,
    );
  }

  /// The copy's row id of an order, for showing a change saved here.
  Future<int?> idOf(String uuid) async =>
      Json.integer((await _row(uuid))?['id']);
}
