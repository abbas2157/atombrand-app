import 'api_client.dart';

/// One page of a brand list: the server's `paginated()` envelope,
/// `{items: [...], pagination: {current_page, last_page, per_page, total}}`,
/// plus any extra keys beside it (`unread_count`, `counts`…) in [extra].
///
/// ```dart
/// _api.get('orders', query: {'page': n},
///     parse: (d) => ApiPage.fromJson(d, CashOrder.fromJson));
/// ```
class ApiPage<T> {
  const ApiPage({
    required this.items,
    this.page = 1,
    this.lastPage = 1,
    this.perPage = 0,
    this.total = 0,
    this.extra = const {},
  });

  final List<T> items;
  final int page;
  final int lastPage;
  final int perPage;
  final int total;

  /// Everything else the answer carried beside the list.
  final Map<String, dynamic> extra;

  bool get hasMore => page < lastPage;

  factory ApiPage.fromJson(Object? data, T Function(Object? item) parse) {
    final d = Json.map(data);
    final p = Json.map(d['pagination']);
    final page = Json.integer(p['current_page']) ?? 1;
    return ApiPage(
      items: [for (final i in Json.list(d['items'])) parse(i)],
      page: page,
      lastPage: Json.integer(p['last_page']) ?? page,
      perPage: Json.integer(p['per_page']) ?? 0,
      total: Json.integer(p['total']) ?? 0,
      extra: {
        for (final e in d.entries)
          if (e.key != 'items' && e.key != 'pagination') e.key: e.value,
      },
    );
  }
}
