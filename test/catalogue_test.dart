import 'package:atombrand_app/data/models/product.dart';
import 'package:atombrand_app/features/catalogue/product_logic.dart';
import 'package:flutter_test/flutter_test.dart';

ProductSummary _p(String status, int stock) =>
    ProductSummary.fromJson({'id': 1, 'title': 'OXY TV', 'status': status, 'stock': stock});

void main() {
  test('stock follows the status; an untracked 0 is not "out of stock"', () {
    expect(stockOf(_p('Published', 12)).text, '12 in stock');
    expect(stockOf(_p('Published', 3)).level, StockLevel.low);
    expect(stockOf(_p('Published', 3)).text, 'Low · 3 left');
    // Real data: live products with 0 units are in stock in Inventory.
    expect(stockOf(_p('Published', 0)).level, StockLevel.hidden);
    expect(stockOf(_p('Out of Stock', 0)).text, 'Out of stock');
    expect(stockOf(_p('Closed', 0)).level, StockLevel.hidden);
    expect(stockOf(_p('On hold', 6)).level, StockLevel.hidden);
  });

  test('only an Out of Stock product shows a problem line', () {
    expect(problemOf(_p('Out of Stock', 0)), "Out of stock · buyers can't order");
    expect(problemOf(_p('Published', 0)), isNull);
    expect(problemOf(_p('Pending', 0)), isNull);
    expect(canSetStock(_p('Published', 0)), isTrue);
    expect(canSetStock(_p('Pending', 0)), isFalse);
  });
}
