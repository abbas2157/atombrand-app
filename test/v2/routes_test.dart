// The query helpers build every filtered address, so no screen types a
// query string by hand (and a serial with a space or slash survives).

import 'package:atombrand_app/v2/app/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('orders and products with filters, and bare without', () {
    expect(V2Routes.ordersWith(), V2Routes.orders);
    expect(V2Routes.ordersWith(atompay: true), V2Routes.atompayOrders);
    expect(
      V2Routes.ordersWith(status: 'Delivered', payment: 'unpaid'),
      '/orders?status=Delivered&payment=unpaid',
    );
    expect(V2Routes.productsWith(), V2Routes.products);
    expect(
      V2Routes.productsWith(status: 'On hold'),
      '/products?status=On+hold',
    );
  });

  test('stock helpers encode serials and drop what is unset', () {
    expect(V2Routes.stockIn(), '/stock/in');
    expect(
      V2Routes.stockIn(productId: 4, serial: 'AB 1/2'),
      '/stock/in?product=4&serial=AB+1%2F2',
    );
    expect(V2Routes.moveStock(), V2Routes.stockMove);
    expect(V2Routes.moveStock(serial: 'X1'), '/stock/move?serial=X1');
    expect(
      V2Routes.adjustStock(serial: 'X1', found: true),
      '/stock/adjust?dir=in&serial=X1',
    );
    expect(V2Routes.adjustStock(productId: 9), '/stock/adjust?product=9');
    expect(V2Routes.stockHistoryOf(productId: 9), '/stock/history?product_id=9');
    expect(V2Routes.syncClashOf('a-1'), '/menu/sync/clash?id=a-1');
  });

  test('a parsed address gives the values back', () {
    final u = Uri.parse(V2Routes.adjustStock(serial: 'AB 1/2', found: true));
    expect(u.queryParameters, {'dir': 'in', 'serial': 'AB 1/2'});
  });
}
