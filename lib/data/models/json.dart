/// Lenient JSON readers. Laravel can send ints as strings and booleans as
/// `0`/`1`, so every model reads through these.
typedef Json = Map<String, dynamic>;

int asInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.round();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.round() ?? fallback;
  if (v is bool) return v ? 1 : 0;
  return fallback;
}

int? asIntOrNull(dynamic v) => v == null ? null : asInt(v);

String? asStr(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

String asStrOr(dynamic v, [String fallback = '']) => asStr(v) ?? fallback;

bool asBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

Json asMap(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

Json? asMapOrNull(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : null;

List<T> asList<T>(dynamic v, T Function(Json) f) =>
    v is List ? v.whereType<Map>().map((e) => f(Map<String, dynamic>.from(e))).toList() : <T>[];

List<String> asStrList(dynamic v) =>
    v is List ? v.where((e) => e != null).map((e) => e.toString()).toList() : <String>[];

List<int> asIntList(dynamic v) => v is List ? v.map((e) => asInt(e)).toList() : <int>[];

/// `data.pagination` from §7.3.
class Pagination {
  const Pagination({this.currentPage = 1, this.lastPage = 1, this.perPage = 15, this.total = 0});

  factory Pagination.fromJson(Json j) => Pagination(
        currentPage: asInt(j['current_page'], 1),
        lastPage: asInt(j['last_page'], 1),
        perPage: asInt(j['per_page'], 15),
        total: asInt(j['total']),
      );

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}

/// A page of a list endpoint. [raw] keeps the sibling keys some lists add
/// next to `items` (`summary`, `counts`, `active`, `type`).
class Paged<T> {
  const Paged(this.items, this.pagination, this.raw);

  factory Paged.fromJson(Json data, T Function(Json) itemFromJson) => Paged(
        asList(data['items'], itemFromJson),
        Pagination.fromJson(asMap(data['pagination'])),
        data,
      );

  final List<T> items;
  final Pagination pagination;
  final Json raw;
}
