import 'package:atombrand_app/v2/features/account/data/reports_repository.dart';
import 'package:atombrand_app/v2/features/menu/data/menu_counts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('menu counts read home.counts, hero and plan', () {
    final c = MenuCounts.fromJson({
      'home': {
        'hero': {'bulk_requests_waiting': 1, 'seller_requests_waiting': 2},
        'counts': {
          'orders': {'to_confirm': 3, 'atompay_to_hand_over': 1},
          'catalogue': {'out_of_stock': 4, 'in_review': 1, 'on_hold': 1},
        },
        'plan': {'paid_until': '2026-11-30'},
      },
    });
    expect(c.ordersToConfirm, 3);
    expect(c.atompayToHandOver, 1);
    expect(c.requestsWaiting, 3);
    expect(c.outOfStock, 4);
    expect(c.productsToCheck, 2);
    expect(c.paidUntil, DateTime(2026, 11, 30));
  });

  test('menu counts a role cannot see stay unknown', () {
    final c = MenuCounts.fromJson({'home': {}});
    expect(c.ordersToConfirm, isNull);
    expect(c.requestsWaiting, isNull);
    expect(c.outOfStock, isNull);
    expect(c.paidUntil, isNull);
  });

  test('a report shows the phone table with its three columns', () {
    final r = ReportData.fromJson({
      'key': 'payments',
      'title': 'Payments received',
      'phone_table': 'month',
      'methods': {'bank': 'Bank transfer'},
      'method': 'bank',
      'tables': [
        {
          'key': 'list',
          'title': 'Payments',
          'columns': [
            {'key': 'date', 'label': 'Date', 'type': 'date'},
            {'key': 'for', 'label': 'For', 'type': 'text'},
            {'key': 'method', 'label': 'Method', 'type': 'text'},
            {'key': 'amount', 'label': 'Amount', 'type': 'money'},
          ],
          'rows': [],
        },
        {
          'key': 'month',
          'title': 'By month',
          'columns': [
            {'key': 'month', 'label': 'Month', 'type': 'text'},
            {'key': 'payments', 'label': 'Payments', 'type': 'text'},
            {'key': 'amount', 'label': 'Amount', 'type': 'money'},
          ],
          'phone': [
            {'key': 'month', 'label': 'Month', 'type': 'text'},
            {'key': 'payments', 'label': 'Payments', 'type': 'text'},
            {'key': 'amount', 'label': 'Amount', 'type': 'money'},
          ],
          'rows': [
            {'month': 'November', 'payments': '2 payments', 'amount': 5000},
          ],
        },
      ],
    });
    expect(r.phoneTableData?.key, 'month');
    expect(r.phoneTableData?.phoneColumns.map((c) => c.key), [
      'month',
      'payments',
      'amount',
    ]);
    expect(r.methods['bank'], 'Bank transfer');
    expect(r.method, 'bank');
    // Without the server's choice, the first three columns.
    expect(r.tables.first.phoneColumns.map((c) => c.key), [
      'date',
      'for',
      'method',
    ]);
  });

  test('report totals read the lines under the numbers', () {
    final t = ReportTotals.fromJson({
      'cash_sales': 10,
      'cash_orders': 2,
      'still_due': 5,
      'atompay_units': 1,
      'bulk_deals': 0,
    });
    expect(t.cashOrders, 2);
    expect(t.stillDue, 5);
    expect(t.atompayUnits, 1);
    expect(t.bulkDeals, 0);
    expect(const ReportFilter(method: 'bank').query['method'], 'bank');
  });
}
