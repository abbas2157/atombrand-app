import '../../data/models/product.dart';

/// Most units the server accepts for one product (§8.5).
const maxUnits = 1000000;

/// Inventory filter, and the bucket each row falls into.
enum InvFilter { all, inStock, low, out }

/// What the stock line of an inventory card says.
enum InvLevel { ok, untracked, low, out, locked }

/// A change the brand made on the card and hasn't saved yet.
class InvEdit {
  const InvEdit({required this.on, required this.units});
  final bool on;
  final int units;
}

/// One product on the Inventory tab with its unsaved edit, if any.
class InvRow {
  const InvRow(this.product, [this.edit]);

  final ProductSummary product;
  final InvEdit? edit;

  int get id => product.id;

  /// Only live (`Published` / `Out of Stock`) products; the server refuses
  /// others with a 409.
  bool get manageable => product.canManageStock || product.isLive || product.isOutOfStock;

  bool get savedOn => product.isLive;
  int get savedUnits => product.stock;
  bool get on => edit?.on ?? savedOn;
  int get units => edit?.units ?? savedUnits;

  bool get changed => on != savedOn || units != savedUnits;

  /// Turned on with no units: the server needs at least 1 to sell it.
  bool get needsUnits => changed && on && units < 1;

  InvLevel get level {
    if (!manageable) return InvLevel.locked;
    if (!on || needsUnits) return InvLevel.out;
    // A saved live product with 0 units isn't tracked; it is still for sale.
    if (units <= 0) return InvLevel.untracked;
    if (units < 5) return InvLevel.low;
    return InvLevel.ok;
  }

  bool matches(InvFilter f) => switch (f) {
        InvFilter.all => true,
        InvFilter.inStock => level == InvLevel.ok || level == InvLevel.untracked,
        InvFilter.low => level == InvLevel.low,
        InvFilter.out => level == InvLevel.out,
      };

  String get levelText => switch (level) {
        InvLevel.ok => '$units in stock',
        InvLevel.untracked => 'For sale · units not set',
        InvLevel.low => 'Low · $units left',
        InvLevel.out => needsUnits ? 'Add units to sell this' : 'Out of stock',
        InvLevel.locked => 'Not live yet',
      };

  /// Units when the product is on, `null` when off (§8.5 only takes stock
  /// with `available: 1`).
  int? get stockToSend => on ? units : null;
}

/// Stock health over the products the brand can manage.
({int ok, int low, int out, int units}) stockHealth(Iterable<InvRow> rows) {
  var ok = 0, low = 0, out = 0, units = 0;
  for (final r in rows) {
    if (!r.manageable) continue;
    if (r.matches(InvFilter.inStock)) ok++;
    if (r.matches(InvFilter.low)) low++;
    if (r.matches(InvFilter.out)) out++;
    units += r.units;
  }
  return (ok: ok, low: low, out: out, units: units);
}

bool matchesQuery(ProductSummary p, String q) {
  final s = q.trim().toLowerCase();
  if (s.isEmpty) return true;
  return p.title.toLowerCase().contains(s) ||
      (p.prNumber?.toLowerCase().contains(s) ?? false) ||
      p.id.toString() == s;
}

/// The Set stock sheet's result for one row: an exact number or added to
/// the current one. Setting units also turns the product on.
InvEdit setStockEdit(InvRow r, {required bool add, required int value}) {
  final units = (add ? r.units + value : value).clamp(0, maxUnits);
  return InvEdit(on: units > 0 ? true : r.on, units: units);
}

String plural(int n, String one, [String? many]) => '$n ${n == 1 ? one : (many ?? '${one}s')}';
