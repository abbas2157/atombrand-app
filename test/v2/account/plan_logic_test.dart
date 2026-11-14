import 'package:atombrand_app/l10n/app_localizations.dart';
import 'package:atombrand_app/v2/core/access/access.dart';
import 'package:atombrand_app/v2/design/design.dart';
import 'package:atombrand_app/v2/features/account/data/billing_models.dart';
import 'package:atombrand_app/v2/features/account/data/plan_logic.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _billing({
  String state = 'ok',
  String status = 'active',
  bool paused = false,
  List<Map<String, dynamic>> open = const [],
  List<Map<String, dynamic>> addons = const [],
  List<int> periods = const [1, 3, 12],
}) => {
  'account': {
    'shop_type': 'multi',
    'outlets': 3,
    'status': status,
    'period_months': 3,
    'period_ends_on': '2026-11-30',
    'paid_until': '2026-11-30',
    'trial_ends_on': status == 'trial' ? '2026-11-20' : null,
    'credit': 500,
    'discount_pct': '10.00',
  },
  'access': {'state': state, 'days_late': 3, 'due': 21000, 'paused': paused},
  'periods': periods,
  'items': [
    {
      'key': 'package',
      'kind': 'package',
      'name': 'Basic package',
      'prices': {'1': 5000, '3': 14000, '6': null, '12': 50000},
    },
    {
      'key': 'inventory',
      'kind': 'addon',
      'name': 'Inventory',
      'trial_days': 15,
      'prices': {'1': 1000, '3': 2800, '12': null},
    },
  ],
  'addons': addons,
  'open_invoices': open,
  'invoices': open,
  'payments': [
    {
      'number': 'RCT-1',
      'amount_claimed': 5000,
      'status': 'received',
      'method': 'bank',
      'method_label': 'Bank transfer',
      'paid_on': '2026-11-02',
    },
    {'amount_claimed': 100, 'status': 'pending'},
  ],
  'payee': {'bank_name': 'Meezan', 'iban': '', 'jazzcash': '03001234567'},
  'methods': {'cash': 'Cash', 'bank': 'Bank transfer', 'jazzcash': 'JazzCash'},
};

void main() {
  final l = lookupAppLocalizations(const Locale('en'));
  final today = DateTime(2026, 11, 13);

  group('BillingOverview.fromJson', () {
    test('reads the account, prices, payee and payments', () {
      final p = BillingOverview.fromJson(_billing());
      expect(p.multiOutlet, isTrue);
      expect(p.outlets, 3);
      expect(p.credit, 500);
      expect(p.discountPct, 10);
      expect(p.package?.prices, {1: 5000, 3: 14000, 12: 50000});
      expect(p.item('inventory')?.priceFor(12), isNull);
      // empty payee values are dropped
      expect(p.payee, {'bank_name': 'Meezan', 'jazzcash': '03001234567'});
      expect(p.payments.first.hasReceipt, isTrue);
      expect(p.payments.last.hasReceipt, isFalse);
      expect(p.periodsOnOffer, [1, 3, 12]);
    });

    test('periods fall back to what the package is priced for', () {
      final p = BillingOverview.fromJson(_billing(periods: const []));
      expect(p.periodsOnOffer, [1, 3, 12]);
    });

    test('a paid bill is never overdue', () {
      final b = Invoice.fromJson({
        'number': 'INV-1',
        'status': 'paid',
        'overdue': true,
        'total': 10,
        'due': 0,
      });
      expect(b.overdue, isFalse);
      expect(b.open, isFalse);
    });
  });

  group('planBadge', () {
    ({String label, AtomTone tone}) badge(Map<String, dynamic> j) =>
        planBadge(l, BillingOverview.fromJson(j));

    test('follows the access state', () {
      expect(badge(_billing()).label, 'Paid');
      expect(badge(_billing(state: 'due')).label, 'Bill waiting');
      expect(badge(_billing(state: 'late')).label, 'Late');
      expect(badge(_billing(state: 'overdue')).tone, AtomTone.rose);
      expect(badge(_billing(state: 'readonly')).label, 'Read-only');
      expect(badge(_billing(state: 'none')).label, 'No plan yet');
      expect(badge(_billing(status: 'trial')).label, 'Free trial');
    });

    test('a payment being checked wins', () {
      expect(
        badge(_billing(state: 'late', paused: true)).label,
        'Being checked',
      );
    });

    test('an open bill while ok still says Bill waiting', () {
      final j = _billing(
        open: [
          {'id': 1, 'number': 'INV-1', 'status': 'open', 'due': 10},
        ],
      );
      expect(badge(j).label, 'Bill waiting');
    });
  });

  group('headline and summary', () {
    test('paid until, trial, none', () {
      expect(
        planHeadline(l, BillingOverview.fromJson(_billing())),
        'Paid until 30 Nov',
      );
      expect(
        planHeadline(l, BillingOverview.fromJson(_billing(status: 'trial'))),
        'Free trial until 20 Nov',
      );
      expect(
        planHeadline(
          l,
          BillingOverview.fromJson(_billing(state: 'none', status: 'none')),
        ),
        'No plan yet',
      );
    });

    test('summary line', () {
      expect(
        planSummary(l, BillingOverview.fromJson(_billing())),
        'Basic package · Multi-outlet · 3 outlets',
      );
    });

    test('days left', () {
      expect(daysLeftLabel(l, DateTime(2026, 11, 30), today), '17 days left');
      expect(daysLeftLabel(l, DateTime(2026, 11, 14), today), '1 day left');
      expect(daysLeftLabel(l, DateTime(2026, 11, 1), today), 'Ends today');
    });
  });

  group('addonRow', () {
    BillingAddon a(Map<String, dynamic> j) =>
        BillingAddon.fromJson({'key': 'inventory', 'name': 'Inventory', ...j});

    test('trial shows the days left', () {
      final r = addonRow(
        l,
        a({'state': 'trial', 'ends_on': '2026-11-19'}),
        today: today,
      );
      expect(r.badge, 'Free trial');
      expect(r.sub, 'Free trial · 6 days left');
    });

    test('legacy is free until 31 Dec 2026', () {
      final r = addonRow(
        l,
        a({'state': 'legacy', 'legacy_until': '2026-12-31'}),
        today: today,
      );
      expect(r.badge, 'Free');
      expect(r.sub, 'Free until 31 Dec 2026');
    });

    test('on, switched off, off, lapsed', () {
      expect(addonRow(l, a({'state': 'active'}), today: today).badge, 'On');
      final stopping = addonRow(
        l,
        a({'state': 'active', 'renew': false, 'ends_on': '2026-11-30'}),
        today: today,
      );
      expect(stopping.sub, 'Switched off · works until 30 Nov');
      expect(addonRow(l, a({'state': 'off'}), today: today).badge, 'Off');
      expect(addonRow(l, a({'state': 'lapsed'}), today: today).badge, 'Ended');
    });
  });

  group('addonChoice', () {
    BillingAddon a(Map<String, dynamic> j) =>
        BillingAddon.fromJson({'key': 'team', 'name': 'Roles', ...j});

    test('off with a trial left: try free', () {
      expect(
        addonChoice(a({'state': 'off', 'trial_available': true})),
        AddonChoice.tryFree,
      );
    });
    test('off with the trial used: pay now', () {
      expect(
        addonChoice(a({'state': 'off', 'trial_available': false})),
        AddonChoice.payNow,
      );
    });
    test('on: switch off; switched off but running: keep on', () {
      expect(addonChoice(a({'state': 'active'})), AddonChoice.switchOff);
      expect(addonChoice(a({'state': 'legacy'})), AddonChoice.switchOff);
      expect(
        addonChoice(
          a({'state': 'active', 'renew': false, 'ends_on': '2026-11-30'}),
        ),
        AddonChoice.keepOn,
      );
    });
  });

  group('renewal defaults', () {
    test('carries on the add-ons that renew, not legacy ones', () {
      final p = BillingOverview.fromJson(
        _billing(
          addons: [
            {'key': 'inventory', 'state': 'active'},
            {'key': 'team', 'state': 'legacy'},
            {'key': 'alerts', 'state': 'trial', 'renew': false},
            {'key': 'ask_atom', 'state': 'off'},
          ],
        ),
      );
      expect(defaultRenewalAddons(p), {'inventory'});
      expect(defaultPeriod(p), 3);
      expect(addonOffered(p, 'inventory', 12), isFalse);
      expect(addonOffered(p, 'inventory', 3), isTrue);
    });
  });

  group('bills and payments', () {
    test('bill title and status', () {
      final b = Invoice.fromJson({
        'number': 'INV-2026-11-0042',
        'kind': 'package',
        'kind_label': 'Plan',
        'covers_from': '2026-12-01',
        'status': 'open',
        'overdue': true,
        'due': 100,
      });
      expect(billTitle(l, b), 'December renewal');
      expect(billStatus(l, b).label, 'Late');
      expect(
        billStatus(l, Invoice.fromJson({'status': 'part_paid'})).label,
        'Part paid',
      );
    });

    test('payment status words', () {
      expect(
        paymentStatus(l, BillPayment.fromJson({'status': 'pending'})).label,
        'Being checked',
      );
      expect(
        paymentStatus(l, BillPayment.fromJson({'status': 'rejected'})).label,
        'Not found',
      );
    });

    test('pay methods in the canvas order, short labels', () {
      final m = payMethods(l, {
        'cash': 'Cash',
        'bank': 'Bank transfer',
        'easypaisa': 'Easypaisa',
      });
      expect([for (final x in m) x.label], ['Bank', 'Easypaisa', 'Cash']);
      expect(payMethods(l, const {}).length, 5);
    });
  });

  group('payProblem', () {
    String? problem({
      int? amount = 5000,
      String? method = 'bank',
      DateTime? paidOn,
      bool shot = true,
      String reference = '',
    }) => payProblem(
      l,
      amount: amount,
      method: method,
      paidOn: paidOn ?? today,
      hasScreenshot: shot,
      today: today,
      reference: reference,
    );

    test('everything there', () => expect(problem(), isNull));
    test('needs a method, an amount and a screenshot', () {
      expect(problem(method: null), 'Choose how you paid');
      expect(problem(amount: 0), 'Type the amount you paid');
      expect(problem(amount: 10000001), 'That amount is too large');
      expect(problem(shot: false), 'Add the payment screenshot');
    });
    test('the day can\'t be in the future, today is fine', () {
      expect(problem(paidOn: DateTime(2026, 11, 13, 23, 59)), isNull);
      expect(problem(paidOn: DateTime(2026, 11, 14)), isNotNull);
    });
    test('transaction ID up to 100 characters', () {
      expect(problem(reference: 'x' * 100), isNull);
      expect(problem(reference: 'x' * 101), isNotNull);
    });
  });

  test('AddonState from billing keys', () {
    expect(
      BillingAddon.fromJson({'key': 'x', 'state': 'legacy'}).state,
      AddonState.legacy,
    );
  });

  group('PlanQuote', () {
    test('reads lines and totals', () {
      final q = PlanQuote.fromJson({
        'lines': [
          {'description': 'Basic package, 3 months', 'amount': 14000},
        ],
        'subtotal': 14000,
        'discount': 1400,
        'credit': 500,
        'total': 12100,
        'branches': 2,
      });
      expect(q.lines.single.amount, 14000);
      expect(q.subtotal - q.discount - q.credit, q.total);
    });
  });
}
