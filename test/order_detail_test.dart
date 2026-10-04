import 'package:atombrand_app/data/models/order.dart';
import 'package:atombrand_app/features/orders/order_detail_logic.dart';
import 'package:flutter_test/flutter_test.dart';

OrderDetail _detail(String status, {List<Map<String, dynamic>> history = const []}) => OrderDetail.fromJson({
      'type': 'instalment',
      'order': {'uuid': 'u', 'id': 117, 'status': status, 'created_at': '2026-10-01 07:39:00'},
      'history': history,
    });

void main() {
  test('progress: Pending has Placed done and Verification next', () {
    final s = orderProgress(_detail('Pending'))!;
    expect(s.map((x) => x.label), ['Placed', 'Verification', 'Processing', 'Delivered', 'Completed']);
    expect(s[0].done, isTrue);
    expect(s[0].date, '1 Oct');
    expect(s[1].current, isTrue);
    expect(s.skip(1).any((x) => x.done), isFalse);
  });

  test('progress: Delivered takes its date from history; Instalments counts as delivered', () {
    final s = orderProgress(_detail('Delivered', history: [
      {'status': 'Delivered', 'created_at': '2026-10-05 15:20:00'},
    ]))!;
    expect(s[3].done, isTrue);
    expect(s[3].date, '5 Oct');
    expect(s[4].current, isTrue);
    expect(orderProgress(_detail('Instalments'))![3].done, isTrue);
    expect(orderProgress(_detail('Cancelled')), isNull);
  });

  test('schedule: paid, overdue, due today and the next upcoming one', () {
    Instalment i(String type, String date, {String? status}) =>
        Instalment.fromJson({'id': 1, 'type': type, 'installment_price': 1000, 'installment_date': date, 'status': ?status});
    final rows = scheduleRows([
      i('Advance', '2026-08-01', status: 'Paid'),
      i('Monthly', '2026-09-01', status: 'Paid'),
      i('Monthly', '2026-10-01'),
      i('Monthly', '2026-10-03'),
      i('Monthly', '2026-11-01'),
    ], today: DateTime(2026, 10, 3, 18));
    expect(rows.map((r) => r.badge), ['A', '1', '2', '3', '4']);
    expect(rows.map((r) => r.state), [
      PaymentState.paid,
      PaymentState.paid,
      PaymentState.overdue,
      PaymentState.due,
      PaymentState.upcoming,
    ]);
    expect(rows.where((r) => r.next).single.title, 'Instalment 3');
    expect(dueNow(rows), 2000);
  });
}
