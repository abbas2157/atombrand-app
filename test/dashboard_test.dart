import 'package:atombrand_app/data/models/dashboard.dart';
import 'package:atombrand_app/data/repositories/notifications_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard without the newer fields parses with them empty', () {
    final d = Dashboard.fromJson({
      'catalogue': {'total': 14, 'published': 10, 'pending': 0, 'out_of_stock': 0},
      'orders': {'total': 39, 'last_30_days': 30, 'value': '4252848', 'seller_sourced': 7},
      'open_bulk_requests': 2,
    });
    expect(d.periods, isEmpty);
    expect(d.ordersPending, isNull);
    expect(d.ordersVerification, isNull);
    expect(d.recovery, isNull);
    expect(d.ordersValue, 4252848);
    expect(d.isNewSeller, isFalse);
  });

  test('periods, status counts and recovery parse when sent', () {
    final d = Dashboard.fromJson({
      'catalogue': {'total': 0},
      'orders': {'total': 0, 'pending': '5', 'verification': 5},
      'periods': {
        '30d': {'revenue': 4252848, 'orders': 39},
        'today': {
          'revenue': 566550,
          'revenue_change_pct': 12,
          'orders': 14,
          'orders_change': -3,
          'series': [
            {'label': '9 AM', 'value': 42000},
            {'label': '11 AM', 'value': '78840'},
          ],
        },
      },
      'recovery': {'financed': 1284600, 'recovered': 873528, 'overdue_instalments': 3},
    });
    expect(d.periods.keys, ['today', '30d']);
    expect(d.periods['today']!.series.last.value, 78840);
    expect(d.periods['today']!.ordersChange, -3);
    expect(d.periods['30d']!.revenueChangePct, isNull);
    expect(d.ordersPending, 5);
    expect(d.recovery!.ratio, closeTo(0.68, 0.001));
    expect(d.isNewSeller, isTrue);
  });

  test('notifications open the screen they are about', () {
    AppNotification n(String screen, Map<String, dynamic> data) =>
        AppNotification.fromJson({'id': 1, 'screen': screen, 'data': data});
    expect(n('order', {'order_type': 'retail', 'order_uuid': 'abc'}).route, '/orders/retail/abc');
    expect(n('bulk_request', {'bulk_request_id': '88'}).route, '/bulk/88');
    expect(n('product', {'product_id': '5'}).route, '/products/5');
    expect(n('order', {}).route, isNull);
  });
}
