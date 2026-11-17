import '../../../../l10n/app_localizations.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/ids.dart';
import 'stock_models.dart';

/// The stock screens' rules, kept apart from the widgets so they are tested
/// on their own. Serial checks mirror `SellerStockService::serialProblem`.

// ───────────────────────────────────────────────────────────── serials

/// Typed or pasted numbers: one per line (commas too), trimmed, blanks out.
/// The server splits the same way (`SellerStockService::parseSerials`).
List<String> splitSerials(String text) => [
  for (final s in text.split(RegExp(r'[\r\n,]+')))
    if (s.trim().isNotEmpty) s.trim(),
];

/// One number on the stock-in list, and what is wrong with it.
typedef SerialLine = ({String serial, String? problem});

/// Checks each number for [tracking]. A repeat is flagged and left out of
/// the count; a number already in stock ([inStock], upper-cased) too.
List<SerialLine> checkSerials(
  AppLocalizations l,
  List<String> serials,
  Tracking tracking, {
  Set<String> inStock = const {},
}) {
  final seen = <String>{};
  return [
    for (final s in serials)
      (serial: s, problem: _serialProblem(l, s, tracking, seen, inStock)),
  ];
}

String? _serialProblem(
  AppLocalizations l,
  String s,
  Tracking tracking,
  Set<String> seen,
  Set<String> inStock,
) {
  final key = s.toUpperCase();
  if (!seen.add(key)) return l.stockSerialTwice;
  if (tracking == Tracking.imei) {
    if (!RegExp(r'^\d{15}$').hasMatch(s)) return l.stockSerialImei15;
    if (!AtomIds.isValidImei(s)) return l.stockSerialCheckDigit;
  } else if (s.length < 3 || s.length > 60) {
    return l.stockSerialLength;
  }
  if (inStock.contains(key)) return l.stockSerialInStock;
  return null;
}

/// The numbers that will be sent.
List<String> goodSerials(List<SerialLine> lines) => [
  for (final l in lines)
    if (l.problem == null) l.serial,
];

/// Why Add to stock is off, or null when it can go.
String? stockInProblem(
  AppLocalizations l, {
  required StockWarehouse? warehouse,
  required VariantOption? variant,
  required List<SerialLine> serials,
  required int autoQty,
  required int max,
}) {
  if (warehouse == null) return l.stockChooseWarehouse;
  if (variant == null) return l.stockChooseProduct;
  if (variant.tracking == Tracking.auto) {
    if (autoQty < 1) return l.stockInEnterQty;
    if (autoQty > max) return l.stockInMax(max);
    return null;
  }
  final good = goodSerials(serials).length;
  final what = variant.tracking == Tracking.imei
      ? l.stockTrackingImei
      : l.stockTrackingSerial;
  if (good == 0) return l.stockInScanEach(what);
  if (good > max) return l.stockInMax(max);
  return null;
}

/// The next auto numbers, from the server's next one: `ZNVTV-0042` and 3
/// → `ZNVTV-0042, ZNVTV-0043…`. Null when the shape isn't PREFIX-digits.
String? autoNumbersPreview(AppLocalizations l, String? next, int qty) {
  if (next == null || qty < 1) return null;
  final m = RegExp(r'^(.*?)(\d+)$').firstMatch(next);
  if (m == null) return next;
  final digits = m.group(2)!;
  final start = int.parse(digits);
  String at(int i) =>
      '${m.group(1)}${(start + i).toString().padLeft(digits.length, '0')}';
  if (qty == 1) return at(0);
  if (qty == 2) return '${at(0)}, ${at(1)}';
  return l.stockAutoRange(at(0), at(qty - 1));
}

// ───────────────────────────────────────────────────────────── levels

/// The level bar's two parts, as fractions of the widest row: what is
/// available, and what is held.
({double available, double held}) levelBar(
  int available,
  int held,
  int widest,
) {
  final max = widest < 1 ? 1 : widest;
  double f(int n) => (n / max).clamp(0.0, 1.0);
  return (available: f(available), held: f(held));
}

/// Where a variant's units are: per outlet when there are several
/// ("Lahore 14 · Karachi 6"), else per warehouse ("Head office store 3").
String whereLine(
  AppLocalizations l,
  StockVariant v,
  List<StockWarehouse> warehouses, {
  required bool byOutlet,
}) {
  final byId = {for (final w in warehouses) w.id: w};
  final sums = <String, int>{};
  for (final b in v.byWarehouse) {
    final w = byId[b.warehouseId];
    if (w == null) continue;
    final name = byOutlet ? (w.outlet ?? w.name) : w.name;
    sums[name] = (sums[name] ?? 0) + b.onHand;
  }
  if (sums.isEmpty) return l.stockWhereNone;
  return [for (final e in sums.entries) '${e.key} ${e.value}'].join(' · ');
}

/// "In stock", "Low" or "Out of stock".
String stateLabel(AppLocalizations l, String state) => switch (state) {
  'out' => l.stockStateOut,
  'low' => l.stockStateLow,
  _ => l.stockStateIn,
};

/// What atomshop.pk can sell of [v]: available in warehouses that sell
/// online.
int availableOnline(StockVariant v, List<StockWarehouse> warehouses) {
  final online = {
    for (final w in warehouses)
      if (w.sellsOnline) w.id,
  };
  var n = 0;
  for (final b in v.byWarehouse) {
    if (online.contains(b.warehouseId)) {
      final a = b.onHand - b.reserved;
      if (a > 0) n += a;
    }
  }
  return n;
}

// ───────────────────────────────────────────────────────────── history

/// How a ledger row changes the count.
enum MoveKind { stockIn, delivered, moved, adjustedIn, adjustedOut }

MoveKind moveKind(String type) => switch (type) {
  'sale_out' => MoveKind.delivered,
  'transfer_out' || 'transfer_in' => MoveKind.moved,
  'adjust_in' => MoveKind.adjustedIn,
  'adjust_out' => MoveKind.adjustedOut,
  _ => MoveKind.stockIn,
};

/// "+3", "−1", or "5" for a move (the count doesn't change).
String moveChange(StockMove m) {
  final n = m.qty.abs();
  return switch (moveKind(m.type)) {
    MoveKind.stockIn || MoveKind.adjustedIn => '+$n',
    MoveKind.delivered || MoveKind.adjustedOut => '−$n',
    MoveKind.moved => '$n',
  };
}

/// "Stock in", "Delivered", "Moved", "Adjusted".
String moveLabel(AppLocalizations l, StockMove m) => switch (moveKind(m.type)) {
  MoveKind.stockIn => l.stockIn,
  MoveKind.delivered => l.stockMoveDelivered,
  MoveKind.moved => l.stockMoveMoved,
  MoveKind.adjustedIn || MoveKind.adjustedOut => l.stockMoveAdjusted,
};

/// The day heading: "Today", "Yesterday · 12 Nov", "Tue 10 Nov".
String historyDay(AppLocalizations l, DateTime day, DateTime today) {
  final d = DateTime(day.year, day.month, day.day);
  final t = DateTime(today.year, today.month, today.day);
  final diff = t.difference(d).inDays;
  if (diff == 0) return l.stockDayToday;
  if (diff == 1) return l.stockDayYesterday(AtomDates.short(d));
  if (d.year != t.year) return AtomDates.day(d);
  return AtomDates.weekday(d);
}

/// Rows grouped by day, newest first as the server sends them.
List<({String day, List<StockMove> rows})> groupByDay(
  AppLocalizations l,
  List<StockMove> rows,
  DateTime today,
) {
  final out = <({String day, List<StockMove> rows})>[];
  for (final r in rows) {
    final d = r.date ?? r.at;
    final label = d == null ? l.stockDayEarlier : historyDay(l, d, today);
    if (out.isNotEmpty && out.last.day == label) {
      out.last.rows.add(r);
    } else {
      out.add((day: label, rows: [r]));
    }
  }
  return out;
}

// ───────────────────────────────────────────────────────────── a serial

/// What a scanned or typed number is.
enum UnitFound { inStock, delivered, removed, notFound }

/// A looked-up number.
class UnitLookup {
  const UnitLookup({
    required this.serial,
    required this.found,
    this.unit,
    this.cameIn,
    this.last,
    this.productId,
    this.heldFor,
  });

  /// The order or deal the unit is held for, when it is.
  final UnitHold? heldFor;

  final String serial;
  final UnitFound found;

  /// The stock product, when known (for Open product).
  final int? productId;

  UnitLookup withProduct(int? id) => UnitLookup(
    serial: serial,
    found: found,
    unit: unit,
    cameIn: cameIn,
    last: last,
    productId: id ?? productId,
    heldFor: heldFor,
  );

  /// The unit when it is in stock.
  final UnitOption? unit;

  /// Its stock-in row, when the ledger has it.
  final StockMove? cameIn;

  /// Its latest ledger row (what took it out).
  final StockMove? last;
}

/// What [serial] is from the server's own answer (`GET stock/units`):
/// null when no unit has exactly that number (or its status is one this app
/// doesn't know), so the caller falls back to the form options and the
/// ledger.
UnitLookup? lookUnitFromServer(String serial, SerialUnits answer) {
  if (!answer.exact) return null;
  final u =
      answer.units.where((u) => u.matches(serial)).firstOrNull ??
      answer.units.firstOrNull;
  if (u == null) return null;
  final cameIn = u.cameIn == null
      ? null
      : StockMove(id: 0, type: 'stock_in', date: u.cameIn, serial: u.serial);
  switch (u.status) {
    case 'in_stock' || 'reserved' || 'held':
      return UnitLookup(
        serial: u.serial,
        found: UnitFound.inStock,
        unit: UnitOption(
          id: u.id,
          serial: u.serial,
          variantId: u.variantId,
          product: u.product,
          variant: u.variant,
          warehouseId: u.warehouseId,
          warehouse: u.warehouse,
        ),
        cameIn: cameIn,
        productId: u.productId,
        heldFor: u.heldFor,
      );
    case 'delivered' || 'sold':
      return UnitLookup(
        serial: u.serial,
        found: UnitFound.delivered,
        cameIn: cameIn,
        productId: u.productId,
        last: StockMove(
          id: 0,
          type: 'sale_out',
          date: u.deliveredOn,
          product: u.product,
          variant: u.variant,
          serial: u.serial,
          why: u.deliveredOn == null ? null : AtomDates.day(u.deliveredOn!),
          refType: u.deliveredForType,
          refId: u.deliveredForId,
        ),
      );
    case 'damaged' || 'removed' || 'lost' || 'adjusted':
      return UnitLookup(
        serial: u.serial,
        found: UnitFound.removed,
        cameIn: cameIn,
        productId: u.productId,
        last: StockMove(
          id: 0,
          type: 'adjust_out',
          product: u.product,
          variant: u.variant,
          serial: u.serial,
        ),
      );
    default:
      return null;
  }
}

/// Decides what [serial] is from the units in stock and its ledger rows
/// (newest first). In stock wins; else the latest row says delivered or
/// removed; nothing at all is not found.
UnitLookup lookUnit(
  String serial,
  List<UnitOption> inStock,
  List<StockMove> ledger,
) {
  final key = serial.trim().toUpperCase();
  final mine = [
    for (final m in ledger)
      if ((m.serial ?? '').toUpperCase() == key) m,
  ];
  StockMove? cameIn;
  for (final m in mine) {
    if (moveKind(m.type) == MoveKind.stockIn) {
      cameIn = m;
      break;
    }
  }
  for (final u in inStock) {
    if (u.serial.toUpperCase() == key) {
      return UnitLookup(
        serial: u.serial,
        found: UnitFound.inStock,
        unit: u,
        cameIn: cameIn,
        last: mine.firstOrNull,
      );
    }
  }
  if (mine.isEmpty) {
    return UnitLookup(serial: serial.trim(), found: UnitFound.notFound);
  }
  final last = mine.first;
  return UnitLookup(
    serial: last.serial ?? serial.trim(),
    found: switch (moveKind(last.type)) {
      MoveKind.delivered => UnitFound.delivered,
      MoveKind.adjustedOut => UnitFound.removed,
      // in the ledger, not in the in-stock list: moved out of this
      // person's outlets, or another outlet's unit
      _ => UnitFound.notFound,
    },
    cameIn: cameIn,
    last: last,
  );
}

// ───────────────────────────────────────────────────────────── adjust

/// Why the adjust save is off, or null.
String? adjustProblem(
  AppLocalizations l, {
  required bool out,
  required UnitOption? unit,
  required VariantOption? variant,
  required StockWarehouse? warehouse,
  required String serial,
  required String? reason,
  required String note,
}) {
  if (out) {
    if (unit == null) return l.stockAdjustChooseUnit;
  } else {
    if (variant == null) return l.stockChooseProduct;
    if (warehouse == null) return l.stockChooseWarehouse;
    if (variant.tracking != Tracking.auto) {
      final s = serial.trim();
      if (s.isEmpty) {
        return variant.tracking == Tracking.imei
            ? l.stockAdjustEnterImei
            : l.stockAdjustEnterSerial;
      }
      if (variant.tracking == Tracking.imei && !AtomIds.isValidImei(s)) {
        return l.stockAdjustCheckImei;
      }
    }
  }
  if (reason == null) return l.stockAdjustChooseReason;
  if (note.trim().isEmpty) return l.stockAdjustWriteNote;
  return null;
}

/// Why the move is off, or null.
String? moveProblem(
  AppLocalizations l, {
  required StockWarehouse? from,
  required StockWarehouse? to,
  required int picked,
}) {
  if (from == null) return l.stockMoveChooseFrom;
  if (to == null) return l.stockMoveChooseTo;
  if (from.id == to.id) return l.stockMoveDifferent;
  if (picked == 0) return l.stockMoveTickUnits;
  if (picked > 200) return l.stockMoveMax;
  return null;
}

/// Why a warehouse can't be saved, or null.
String? warehouseProblem(
  AppLocalizations l, {
  required String name,
  required int? outletId,
}) {
  if (name.trim().isEmpty) return l.stockWhNameMissing;
  if (name.trim().length > 60) return l.stockWhNameLong;
  if (outletId == null) return l.stockWhChooseOutlet;
  return null;
}

/// A prefix for auto numbers: 2–6 letters or digits.
String? prefixProblem(AppLocalizations l, String prefix) {
  final p = prefix.trim();
  if (!RegExp(r'^[A-Za-z0-9]{2,6}$').hasMatch(p)) {
    return l.stockPrefixRule;
  }
  return null;
}

/// Listed on atomshop.pk: live there, or listed as out of stock (the
/// catalogue product's `Published` or `Out of Stock`), as Products shows.
bool listedOnWebsite(String? websiteStatus) =>
    websiteStatus == 'Published' || websiteStatus == 'Out of Stock';
