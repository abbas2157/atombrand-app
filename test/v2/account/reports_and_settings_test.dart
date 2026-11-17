import 'package:atombrand_app/l10n/app_localizations.dart';
import 'package:atombrand_app/v2/features/account/data/reports_repository.dart';
import 'package:atombrand_app/v2/features/account/data/shop_settings.dart';
import 'package:atombrand_app/v2/features/notifications/data/notifications_repository.dart';
import 'package:atombrand_app/v2/features/settings/data/settings_rules.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reports', () {
    test('filter query: custom dates only for custom, outlet when set', () {
      expect(const ReportFilter().query, {'period': 'month'});
      final f = ReportFilter(
        period: ReportPeriod.custom,
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 11, 13),
        outletId: 4,
      );
      expect(f.query, {
        'period': 'custom',
        'from': '2026-10-01',
        'to': '2026-11-13',
        'outlet': 4,
      });
      expect(
        ReportFilter(period: ReportPeriod.year, from: DateTime(2026)).query,
        {'period': 'year'},
      );
    });

    test('cells by column type', () {
      expect(formatCell(40000, ColumnType.money), 'Rs 40,000');
      expect(formatCell('1250', ColumnType.int), '1,250');
      expect(formatCell(2.25, ColumnType.num), '2.3');
      expect(formatCell('Total', ColumnType.money), 'Total');
      expect(formatCell(null, ColumnType.text), '');
      expect(columnType('weird'), ColumnType.text);
    });

    test('home groups cards in the server order', () {
      final h = ReportsHome.fromJson({
        'periods': {
          'month': {'cash_sales': 10, 'received': 5},
        },
        'reports': [
          {'key': 'orders', 'title': 'Order summary', 'group': 'Orders'},
          {'key': 'bulk', 'title': 'Bulk deals', 'group': 'Bulk deals'},
          {'key': 'payments', 'title': 'Payments', 'group': 'Orders'},
        ],
      });
      expect([for (final (g, _) in h.groups) g], ['Orders', 'Bulk deals']);
      expect(h.groups.first.$2.length, 2);
      expect(h.periods['month']?.cashSales, 10);
    });

    test('report data: summary formatted, table columns in order', () {
      final r = ReportData.fromJson({
        'key': 'orders',
        'title': 'Order summary',
        'period': {'key': 'month', 'label': 'October 2026'},
        'summary': [
          {'label': 'Cash orders', 'value': 12, 'type': 'int'},
          {'label': 'Value', 'value': 480000, 'type': 'money'},
        ],
        'charts': [
          {
            'label': 'Orders by status',
            'spec': {
              'type': 'hbar',
              'labels': ['Delivered'],
              'series': [
                {
                  'data': [5],
                },
              ],
            },
          },
        ],
        'tables': [
          {
            'title': 'Orders',
            'columns': [
              {'key': 'date', 'label': 'Date', 'type': 'date'},
              {'key': 'value', 'label': 'Value', 'type': 'money'},
            ],
            'rows': [
              {'date': '2026-10-30', 'value': 40000, 'uuid': 'u1'},
            ],
            'totals': {'date': 'Total', 'value': 40000},
          },
        ],
      });
      expect(r.summary.last.value, 'Rs 480,000');
      expect(r.charts.single.horizontal, isTrue);
      expect(r.tables.single.columns.map((c) => c.key), ['date', 'value']);
      expect(r.periodLabel, 'October 2026');
    });

    test('stock ignores dates; cod-due and stock start on all time', () {
      expect(reportIgnoresDates('stock'), isTrue);
      expect(reportDefaultPeriod('cod-due'), ReportPeriod.all);
      expect(reportDefaultPeriod('orders'), ReportPeriod.month);
    });
  });

  group('shop settings', () {
    final l = lookupAppLocalizations(const Locale('en'));
    const ok = ShopSettings();

    test('defaults are valid', () {
      expect(shopSettingsProblems(l, ok), isEmpty);
    });

    test('at least one way to pay', () {
      final s = ok.copyWith(payCod: false);
      expect(shopSettingsProblems(l, s).keys, contains('pay'));
    });

    test('bank transfer needs name, title and a PK IBAN', () {
      final s = ok.copyWith(payBank: true);
      expect(
        shopSettingsProblems(l, s).keys,
        containsAll(['bank_name', 'bank_title', 'bank_iban']),
      );
      final good = s.copyWith(
        bankName: 'Meezan Bank',
        bankTitle: 'Zenvo Pvt Ltd',
        bankIban: 'pk36 mezn 0002 4501 0123 4567',
      );
      expect(shopSettingsProblems(l, good), isEmpty);
      expect(
        shopSettingsProblems(
          l,
          good.copyWith(bankIban: 'PK36 1234'),
        )['bank_iban'],
        isNotNull,
      );
    });

    test('wallet needs one valid number', () {
      final s = ok.copyWith(payWallet: true);
      expect(shopSettingsProblems(l, s).keys, contains('jazzcash'));
      expect(
        shopSettingsProblems(l, s.copyWith(easypaisa: '0345 6677889')),
        isEmpty,
      );
      expect(
        shopSettingsProblems(l, s.copyWith(jazzcash: '12345')).keys,
        contains('jazzcash'),
      );
    });

    test('ranges and choices', () {
      expect(
        shopSettingsProblems(l, ok.copyWith(confirmHours: 3)).keys,
        contains('confirm_hours'),
      );
      expect(
        shopSettingsProblems(l, ok.copyWith(lowStockAt: 101)).keys,
        contains('low_stock_at'),
      );
      expect(
        shopSettingsProblems(l, ok.copyWith(idleMinutes: 60)).keys,
        contains('idle_minutes'),
      );
      expect(
        shopSettingsProblems(l, ok.copyWith(receiptNote: 'x' * 201)).keys,
        contains('receipt_note'),
      );
    });

    test('equality ignores blank vs null text', () {
      expect(ok.copyWith(bankName: '  '), ok);
      expect(ok.copyWith(confirmHours: 8) == ok, isFalse);
    });

    test('reads GET settings and sends every key', () {
      final s = ShopSettings.fromJson({
        'pay_cod': true,
        'pay_bank': '1',
        'confirm_hours': 8,
        'atom_language': 'roman-ur',
      });
      expect(s.payBank, isTrue);
      expect(s.confirmHours, 8);
      expect(s.toBody().keys, hasLength(13));
      expect(s.toBody()['atom_language'], 'roman-ur');
    });
  });

  group('settings rules', () {
    final l = lookupAppLocalizations(const Locale('en'));

    test('profile name and mobile', () {
      expect(profileProblem(l, 'Asad Raza', '0321 4410779'), isNull);
      expect(profileProblem(l, '', ''), 'Type your name');
      expect(profileProblem(l, 'Asad 2', ''), 'Letters and spaces only');
      expect(profileProblem(l, 'Asad', '123'), isNotNull);
      expect(profileProblem(l, 'Asad', ''), isNull);
    });

    test('password: owner needs the current one; 8+ and matching', () {
      expect(
        passwordProblem(
          l,
          needsCurrent: true,
          current: '',
          next: 'abcdefgh',
          again: 'abcdefgh',
        ),
        'Type your current password',
      );
      expect(
        passwordProblem(
          l,
          needsCurrent: false,
          current: '',
          next: 'abcdefgh',
          again: 'abcdefgh',
        ),
        isNull,
      );
      expect(
        passwordProblem(
          l,
          needsCurrent: false,
          current: '',
          next: 'short',
          again: 'short',
        ),
        'At least 8 characters',
      );
      expect(
        passwordProblem(
          l,
          needsCurrent: false,
          current: '',
          next: 'abcdefgh',
          again: 'abcdefgx',
        ),
        isNotNull,
      );
    });

    test('delete needs internet and the password', () {
      expect(deleteProblem(l, password: 'x', online: false), 'Needs internet');
      expect(
        deleteProblem(l, password: '', online: true),
        'Type your password',
      );
      expect(deleteProblem(l, password: 'x', online: true), isNull);
    });
  });

  group('notification chips', () {
    test('brand types land on their chip', () {
      expect(noticeKindOf('brand_new_order'), NoticeKind.orders);
      expect(noticeKindOf('brand_atompay_assigned'), NoticeKind.atompay);
      expect(noticeKindOf('brand_quote_accepted'), NoticeKind.bulk);
      expect(noticeKindOf('brand_stock_low'), NoticeKind.stock);
      expect(noticeKindOf('brand_product_reviewed'), NoticeKind.products);
      expect(noticeKindOf('brand_billing'), NoticeKind.account);
    });
  });
}
