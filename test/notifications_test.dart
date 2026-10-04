import 'package:atombrand_app/data/repositories/notifications_repository.dart';
import 'package:atombrand_app/features/notifications/notification_logic.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotification _n(String type, {String? screen, Map<String, dynamic> data = const {}}) =>
    AppNotification.fromJson({'id': 1, 'type': type, 'title': 't', 'body': 'b', 'screen': screen, 'data': data});

void main() {
  test('the three real types land in their category', () {
    expect(categoryOf(_n('brand_new_order', screen: 'order')), NotifCategory.orders);
    expect(categoryOf(_n('brand_new_bulk_request', screen: 'bulk_request')), NotifCategory.leads);
    expect(categoryOf(_n('brand_product_reviewed', screen: 'product')), NotifCategory.products);
    expect(categoryOf(_n('brand_instalment_overdue', screen: 'order')), NotifCategory.payments);
    expect(categoryOf(_n('atomshop_announcement')), NotifCategory.atomshop);
  });

  test('a product taken off sale is urgent; an approval is not', () {
    expect(isUrgent(_n('brand_product_reviewed', screen: 'product', data: {'status': 'On hold'})), isTrue);
    expect(isUrgent(_n('brand_product_reviewed', screen: 'product', data: {'status': 'Published'})), isFalse);
    expect(isUrgent(_n('brand_instalment_overdue')), isTrue);
    expect(isUrgent(_n('brand_new_order', screen: 'order')), isFalse);
  });

  test('groups and time labels', () {
    final now = DateTime(2026, 10, 4, 18);
    expect(groupOf('2026-10-04 12:43:00', now: now), 'Today');
    expect(timeLabel('2026-10-04 12:43:00', now: now), '12:43 PM');
    expect(timeLabel('2026-10-04 00:05:00', now: now), '12:05 AM');
    expect(groupOf('2026-10-03 22:00:00', now: now), 'Yesterday');
    expect(timeLabel('2026-10-03 22:00:00', now: now), 'Yesterday');
    expect(groupOf('2026-09-29 10:00:00', now: now), 'This week');
    expect(timeLabel('2026-09-28 10:00:00', now: now), '28 Sep');
    expect(groupOf('2026-09-20 10:00:00', now: now), 'Earlier');
    expect(groupOf(null), 'Earlier');
  });
}
