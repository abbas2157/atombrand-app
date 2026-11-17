import 'package:atombrand_app/data/models/product.dart';
import 'package:atombrand_app/features/catalogue/inventory_logic.dart';
import 'package:flutter_test/flutter_test.dart';

ProductSummary _p(String status, int stock, {int id = 1, String title = 'OXY TV'}) =>
    ProductSummary.fromJson({'id': id, 'title': title, 'pr_number': 'PR-$id', 'status': status, 'stock': stock});

void main() {
  test('levels: untracked 0 is for sale, low under 5, off is out, review is locked', () {
    expect(InvRow(_p('Published', 12)).level, InvLevel.ok);
    expect(InvRow(_p('Published', 3)).level, InvLevel.low);
    expect(InvRow(_p('Published', 0)).level, InvLevel.untracked);
    expect(InvRow(_p('Published', 0)).matches(InvFilter.inStock), isTrue);
    expect(InvRow(_p('Out of Stock', 0)).level, InvLevel.out);
    expect(InvRow(_p('Pending', 20)).level, InvLevel.locked);
    expect(InvRow(_p('Pending', 20)).matches(InvFilter.all), isTrue);
    expect(InvRow(_p('Pending', 20)).matches(InvFilter.inStock), isFalse);
  });

  test('edits: changed, needs units when turned on with 0, what gets sent', () {
    final oos = _p('Out of Stock', 0);
    expect(InvRow(oos, const InvEdit(on: false, units: 0)).changed, isFalse);
    final onEmpty = InvRow(oos, const InvEdit(on: true, units: 0));
    expect(onEmpty.needsUnits, isTrue);
    expect(onEmpty.level, InvLevel.out);
    final on6 = InvRow(oos, const InvEdit(on: true, units: 6));
    expect(on6.needsUnits, isFalse);
    expect(on6.stockToSend, 6);
    final off = InvRow(_p('Published', 9), const InvEdit(on: false, units: 9));
    expect(off.changed, isTrue);
    expect(off.stockToSend, isNull);
  });

  test('health counts only manageable products and matches the filters', () {
    final rows = [
      InvRow(_p('Published', 12, id: 1)),
      InvRow(_p('Published', 0, id: 2)),
      InvRow(_p('Published', 3, id: 3)),
      InvRow(_p('Out of Stock', 0, id: 4)),
      InvRow(_p('Pending', 20, id: 5)),
    ];
    final h = stockHealth(rows);
    expect((h.ok, h.low, h.out, h.units), (2, 1, 1, 15));
    for (final f in [InvFilter.inStock, InvFilter.low, InvFilter.out]) {
      expect(rows.where((r) => r.manageable && r.matches(f)).length, rows.where((r) => r.matches(f)).length);
    }
  });

  test('Set stock: exact or added, and setting units turns a product on', () {
    final r = InvRow(_p('Out of Stock', 0));
    expect(setStockEdit(r, add: false, value: 10).on, isTrue);
    expect(setStockEdit(r, add: false, value: 10).units, 10);
    expect(setStockEdit(InvRow(_p('Published', 4)), add: true, value: 10).units, 14);
    expect(setStockEdit(InvRow(_p('Published', maxUnits)), add: true, value: 5).units, maxUnits);
  });

  test('search matches name and PR number', () {
    final p = _p('Published', 1, id: 166, title: 'OXY 4318L Gold');
    expect(matchesQuery(p, 'gold'), isTrue);
    expect(matchesQuery(p, 'pr-166'), isTrue);
    expect(matchesQuery(p, '166'), isTrue);
    expect(matchesQuery(p, 'fridge'), isFalse);
    expect(plural(1, 'change'), '1 change');
    expect(plural(3, 'change'), '3 changes');
  });
}
