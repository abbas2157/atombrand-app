import '../../../core/api/api_client.dart';
import '../../../core/db/sync_store.dart';
import 'bulk_models.dart';

/// Bulk requests and deals read from the phone's own copy (the Offline
/// add-on, docs/brand-app-sync.md tables `bulk_requests`, `quotes`,
/// `deals`, `deliveries`, `deal_payments`), shaped as the online calls
/// answer so the screens need no second model.
class BulkCopy {
  const BulkCopy(this.store, {required this.shopId});

  final SyncStore store;
  final int shopId;

  Map<String, dynamic> _request(Map<String, dynamic> r) => {
    'id': r['id'],
    'uuid': r['uuid'],
    'status': Json.str(r['status']) ?? 'New Lead',
    'full_name': r['full_name'],
    'phone': r['phone'],
    'quantity': r['quantity'],
    'product_title': r['product_title'],
    'product': r['product_id'] == null ? null : {'id': r['product_id']},
    'from': Json.str(r['from']) == 'sellers' ? 'seller' : 'buyer',
    'target_price': r['target_price'],
    'needed_by': r['needed_by'],
    'created_at': r['created_at'],
    'address': r['address'],
    'reason': r['reason'],
  };

  bool _matches(Map<String, dynamic> r, String? q, List<String> keys) {
    final term = (q ?? '').trim().toLowerCase();
    if (term.isEmpty) return true;
    return keys.any((k) => (Json.str(r[k]) ?? '').toLowerCase().contains(term));
  }

  /// `GET bulk-orders?from=&status=` from the copy.
  Future<BulkRequestsPage> requests({
    required String from,
    String? status,
    String? search,
  }) async {
    final rows = await store.rows('bulk_requests', shopId: shopId);
    final items = <Map<String, dynamic>>[];
    final counts = <String, int>{};
    for (final r in rows) {
      final st = Json.str(r['status']) ?? 'New Lead';
      final f = Json.str(r['from']) ?? 'buyers';
      if (f != from) continue;
      counts[st] = (counts[st] ?? 0) + 1;
      if (status != null && st != status) continue;
      if (!_matches(r, search, ['full_name', 'phone', 'product_title'])) {
        continue;
      }
      items.add(_request(r));
    }
    items.sort(
      (a, b) => (Json.integer(b['id']) ?? 0) - (Json.integer(a['id']) ?? 0),
    );
    return BulkRequestsPage.fromJson({
      'items': items,
      'pagination': {'current_page': 1, 'last_page': 1, 'total': items.length},
      'counts': counts,
      'all_count': counts.values.fold<int>(0, (a, b) => a + b),
    });
  }

  /// `GET bulk-orders/{id}`, as much as the copy holds.
  Future<BulkDossier?> dossier(int id) async {
    final r = await store.row('bulk_requests', id, shopId: shopId);
    if (r == null) return null;
    return BulkDossier.fromJson({'request': _request(r)});
  }

  /// `GET bulk-orders/{id}/quotes` from the copy.
  Future<RequestQuotes> quotes(int requestId) async {
    final rows = await store.rows('quotes', shopId: shopId);
    final mine =
        [
          for (final q in rows)
            if (Json.integer(q['bulk_order_id']) == requestId) q,
        ]..sort(
          (a, b) =>
              (Json.integer(b['revision']) ?? 0) -
              (Json.integer(a['revision']) ?? 0),
        );
    final deals = await store.rows('deals', shopId: shopId);
    Map<String, dynamic>? deal;
    for (final d in deals) {
      if (Json.integer(d['bulk_order_id']) == requestId &&
          Json.str(d['status']) != 'lost') {
        deal = d;
      }
    }
    return RequestQuotes.fromJson({
      'quotes': [
        for (final q in mine)
          {...q, 'advance': _advance(q['total'], q['advance_pct'])},
      ],
      'deal': deal == null
          ? null
          : {
              'id': deal['id'],
              'number': deal['number'],
              'status': deal['status'],
            },
    });
  }

  int _advance(Object? total, Object? pct) =>
      ((Json.integer(total) ?? 0) * (Json.integer(pct) ?? 0) / 100).round();

  Map<String, dynamic> _deal(Map<String, dynamic> d) {
    final items = Json.list(d['items']);
    var units = 0, delivered = 0;
    for (final i in items) {
      final m = Json.map(i);
      units += Json.integer(m['qty']) ?? 0;
      delivered += Json.integer(m['delivered_qty']) ?? 0;
    }
    return {
      ...d,
      'units': units,
      'delivered_units': delivered,
      'advance': _advance(d['total'], d['advance_pct']),
      'quote': d['quote_id'] == null ? null : {'id': d['quote_id']},
    };
  }

  /// `GET deals?status=` from the copy.
  Future<DealsPage> deals({String? status, String? search}) async {
    final rows = await store.rows('deals', shopId: shopId);
    final items =
        [
          for (final d in rows)
            if ((status == null || Json.str(d['status']) == status) &&
                _matches(d, search, ['number', 'buyer_name', 'buyer_phone']))
              _deal(d),
        ]..sort(
          (a, b) => (Json.integer(b['id']) ?? 0) - (Json.integer(a['id']) ?? 0),
        );
    return DealsPage.fromJson({
      'items': items,
      'pagination': {'current_page': 1, 'last_page': 1, 'total': items.length},
    });
  }

  /// `GET deals/{id}` from the copy.
  Future<Deal?> deal(int id) async {
    final d = await store.row('deals', id, shopId: shopId);
    if (d == null) return null;
    final deliveries =
        [
          for (final n in await store.rows('deliveries', shopId: shopId))
            if (Json.integer(n['deal_id']) == id) n,
        ]..sort(
          (a, b) => (Json.integer(b['id']) ?? 0) - (Json.integer(a['id']) ?? 0),
        );
    final payments =
        [
          for (final p in await store.rows('deal_payments', shopId: shopId))
            if (Json.integer(p['deal_id']) == id) p,
        ]..sort(
          (a, b) => (Json.integer(a['id']) ?? 0) - (Json.integer(b['id']) ?? 0),
        );
    return Deal.fromJson({
      ..._deal(d),
      'deliveries': deliveries,
      'payments': payments,
    });
  }
}
