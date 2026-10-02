import 'package:atombrand_app/core/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('money uses Rs. with thousands separators and no decimals', () {
    expect(money(30000), 'Rs. 30,000');
    expect(money(5400000), 'Rs. 5,400,000');
    expect(money(0), 'Rs. 0');
    expect(money(null), 'Rs. 0');
  });

  test('server dates are shown as Karachi wall-clock time', () {
    expect(formatDate('2026-09-24 15:05:00'), '24 Sep 2026');
    expect(formatDateTime('2026-09-24 15:05:00'), '24 Sep 2026, 3:05 PM');
    expect(formatDateTime('2026-03-01'), '1 Mar 2026');
    expect(formatDate(null), '');
    expect(formatDate('not a date'), '');
  });
}
