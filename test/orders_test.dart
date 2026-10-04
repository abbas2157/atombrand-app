import 'package:atombrand_app/data/models/order.dart';
import 'package:atombrand_app/features/orders/orders_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('orders group under Today, Yesterday, then the date', () {
    final now = DateTime(2026, 10, 3, 9, 30);
    expect(dayLabel('2026-10-03 08:15:00', now: now), 'Today');
    expect(dayLabel('2026-10-02 23:59:59', now: now), 'Yesterday');
    expect(dayLabel('2026-09-30 12:00:00', now: now), '30 Sep 2026');
    expect(dayLabel(null, now: now), 'Earlier');
  });

  test('needs action: server flag first, else retail cash at Pending or Verification', () {
    OrderSummary o(Map<String, dynamic> j) => OrderSummary.fromJson({'uuid': 'u', 'id': 1, ...j});
    expect(o({'status': 'Pending', 'is_cash': true}).needsAction, isTrue);
    expect(o({'status': 'Varification', 'is_cash': 1}).needsAction, isTrue);
    expect(o({'status': 'Processing', 'is_cash': true}).needsAction, isFalse);
    expect(o({'status': 'Pending', 'is_cash': false}).needsAction, isFalse);
    expect(o({'status': 'Delivered', 'is_cash': true, 'needs_action': true}).needsAction, isTrue);
    expect(o({'status': 'Pending', 'is_cash': true, 'needs_action': 0}).needsAction, isFalse);
  });

  test('recovery percent is optional on list items', () {
    expect(OrderSummary.fromJson({'uuid': 'u', 'id': 1}).recoveryPercent, isNull);
    expect(OrderSummary.fromJson({'uuid': 'u', 'id': 1, 'recovery_percent': '33'}).recoveryPercent, 33);
  });
}
