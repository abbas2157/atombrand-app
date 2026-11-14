// The order JSON from the brand server (OrdersController), parsed into what
// the screens show, and the words the order page says about itself.

import 'package:atombrand_app/l10n/app_localizations.dart';
import 'package:atombrand_app/v2/features/orders/data/order_rules.dart';
import 'package:atombrand_app/v2/features/orders/data/order_texts.dart';
import 'package:atombrand_app/v2/features/orders/data/orders_models.dart';
import 'package:atombrand_app/v2/features/orders/data/receipt_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _summary({
  String status = 'Delivered',
  int total = 112500,
  int paid = 50000,
}) => {
  'uuid': 'u-1',
  'id': 48224,
  'status': status,
  'status_label': status == 'Varification' ? 'Confirming' : status,
  'total_deal_price': total,
  'advance_price': total,
  'is_cash': true,
  'city': 'Lahore',
  'product': {'id': 5, 'title': 'Zenvo Refrigerator 14 cft', 'picture': null},
  'variant': 'Silver',
  'created_at': '2026-11-02 16:18:00',
  'type': 'cash',
  'outlet': {
    'id': 1,
    'name': 'Head office',
    'is_main': true,
    'label': 'Head office',
  },
  'paid': paid,
  'balance': total - paid,
  'payment_state': paid == 0 ? 'unpaid' : (paid >= total ? 'paid' : 'part'),
};

Map<String, dynamic> _detail({String status = 'Delivered', int paid = 50000}) =>
    {
      'type': 'retail',
      'order': {..._summary(status: status, paid: paid), 'quantity': 1},
      'product': {
        'id': 5,
        'title': 'Zenvo Refrigerator 14 cft',
        'pr_number': 'PR-5',
        'variant': 'Silver',
      },
      'customer': {
        'name': 'Faisal Qureshi',
        'phone': '03214410779',
        'email': 'faisal.q@gmail.com',
        'customer_since': '2025-03-01',
        'verified': true,
        'address': 'House 41, Street 7',
        'area': 'Johar Town',
        'city': 'Lahore',
      },
      'history': [
        {
          'status': 'Delivered',
          'role': 'brand_agent',
          'changed_by': {'name': 'Usman Ali', 'role': 'brand_agent'},
          'payload': {
            'recieved_by': 'Faisal Qureshi',
            'serial': 'ZR14-2610-00482',
            'collected': 'Rs. 50,000 · Cash on delivery',
          },
          'created_at': '2026-11-04 15:15:00',
        },
        {
          'status': 'Processing',
          'role': 'brand',
          'changed_by': {'name': 'Asad Raza', 'role': 'brand'},
          'payload': [],
          'created_at': '2026-11-03 10:20:00',
        },
      ],
      'payments': [
        {
          'id': 9,
          'amount': paid,
          'method': 'cod',
          'method_label': 'Cash on delivery',
          'reference': null,
          'receipt': null,
          'paid_on': '2026-11-04',
          'recorded_by': 'Usman Ali',
        },
      ],
      'payment_methods': ['cod', 'bank', 'cash'],
      'next_statuses': ['Completed'],
      'also_bought': [],
      'locked': false,
      'locked_reason': null,
      'actions': [],
    };

void main() {
  final l = lookupAppLocalizations(const Locale('en'));
  test('a list item', () {
    final o = CashOrder.fromJson(_summary());
    expect(o.number, '#48224');
    expect(o.stage, OrderStage.delivered);
    expect(o.payState, PaymentState.part);
    expect(o.balance, 62500);
    expect(o.outlet?.name, 'Head office');
    expect(o.productLine(l), 'Zenvo Refrigerator 14 cft · Silver · Qty 1');
    expect(o.customerName, isNull);
    expect(o.isAtompay, isFalse);
  });

  test('a copy row (offline) with the customer flat', () {
    final o = CashOrder.fromJson({
      'id': 7,
      'uuid': 'u-7',
      'status': 'Varification',
      'total_deal_price': 1000,
      'product_title': 'TV',
      'customer_name': 'Sara Javed',
      'customer_phone': '03001234567',
    });
    expect(o.stage, OrderStage.confirming);
    expect(o.productTitle, 'TV');
    expect(o.customerName, 'Sara Javed');
    expect(o.payState, PaymentState.unpaid);
    expect(o.balance, 1000);
  });

  test('the detail', () {
    final d = CashOrderDetail.fromJson(_detail());
    expect(d.customer?.firstName, 'Faisal');
    expect(d.customer?.verified, isTrue);
    expect(d.payments.single.methodName(l), 'Cash on delivery');
    expect(d.nextStatuses, [OrderStage.completed]);
    expect(d.serial, 'ZR14-2610-00482');
    expect(d.prNumber, 'PR-5');
    expect(d.eventFor(OrderStage.processing)?.byName, 'Asad Raza');
  });

  group('words', () {
    test('next step on a part-paid delivered order', () {
      final d = CashOrderDetail.fromJson(_detail());
      final step = nextStepFor(
        d.stage,
        balance: d.order.balance,
        moves: d.nextStatuses,
      );
      expect(step, NextStep.recordPayment);
      final (title, body, button) = nextStepWords(
        step!,
        d,
        l,
        inventory: false,
      );
      expect(title, 'Record payment');
      expect(body, startsWith('Rs 62,500 is still to collect.'));
      expect(button, 'Record payment');
    });

    test('Pending names the customer', () {
      final d = CashOrderDetail.fromJson(_detail(status: 'Pending', paid: 0));
      final (title, body, _) = nextStepWords(
        NextStep.startConfirming,
        d,
        l,
        inventory: true,
      );
      expect(title, 'Call the customer');
      expect(body, startsWith('Call Faisal to confirm'));
    });

    test('stepper lines', () {
      final d = CashOrderDetail.fromJson(_detail());
      expect(
        stepSub(OrderStage.delivered, d, l, inventory: false),
        'Received by Faisal Qureshi · 4 Nov',
      );
      expect(
        stepSub(OrderStage.completed, d, l, inventory: false),
        'Paid in full',
      );
      expect(stepName(OrderStage.pending, l), 'New order');
      expect(stepName(OrderStage.confirming, l), 'Confirming');
    });

    test('history: events and payments together, newest first, "you"', () {
      final d = CashOrderDetail.fromJson(_detail());
      final lines = historyLines(d, l, me: 'Usman Ali');
      expect(
        lines.first.$2,
        startsWith('Delivered to Faisal Qureshi, Rs 50,000'),
      );
      expect(lines.first.$2, endsWith('· you'));
      expect(
        lines.map((l) => l.$2),
        contains('Payment Rs 50,000 by cash on delivery · you'),
      );
      expect(lines.last.$2, 'Order placed on atomshop.pk');
    });

    test('cancel reasons and move lines', () {
      final cancel = OrderEvent.fromJson({
        'status': 'Cancelled',
        'changed_by': {'name': 'Asad'},
        'payload': {
          'reasons': 'Customer changed their mind',
          'reason': 'Called twice',
        },
        'created_at': '2026-11-03 11:02:00',
      });
      expect(cancelWhy(cancel), 'Customer changed their mind. Called twice');
      expect(
        eventText(cancel, l, me: 'Asad'),
        'Cancelled: Customer changed their mind. Called twice · you',
      );
      final moved = OrderEvent.fromJson({
        'status': 'Processing',
        'payload': {'moved_from': 'Head office', 'moved_to': 'Karachi outlet'},
      });
      expect(eventText(moved, l), 'Moved from Head office to Karachi outlet');
    });
  });

  group('receipt', () {
    final r = OrderReceipt.fromJson({
      'number': 'BR-3-2026-11-48224',
      'order': {..._summary(status: 'Completed', paid: 112500), 'quantity': 1},
      'sold_by': {
        'brand': 'Zenvo <Appliances>',
        'outlet': 'Head office',
        'address': '21-B Gulberg III',
        'phone': '042 3577 1020',
      },
      'customer': {'name': 'Faisal Qureshi', 'phone': '03214410779'},
      'serial': 'ZR14-2610-00482',
      'delivered_at': '2026-11-04 15:15:00',
      'payments': [
        {
          'amount': 62500,
          'method': 'bank',
          'method_label': 'Bank transfer',
          'paid_on': '2026-11-06',
        },
        {
          'amount': 50000,
          'method': 'cod',
          'method_label': 'Cash on delivery',
          'paid_on': '2026-11-04',
        },
      ],
      'note': '1-year Zenvo warranty.',
    });

    test('money and state', () {
      expect(r.paidTotal, 112500);
      expect(r.left, 0);
      expect(receiptState(r, l), 'Paid in full · 2 payments');
      expect(r.date, DateTime(2026, 11, 6));
    });

    test('payments oldest first', () {
      expect(receiptPaymentLines(r, l), [
        ('4 Nov · Cash on delivery', 'Rs 50,000'),
        ('6 Nov · Bank transfer', 'Rs 62,500'),
      ]);
    });

    test('the PDF lines', () {
      final lines = receiptLines(r, l);
      expect(lines.brand, 'Zenvo <Appliances>');
      expect(lines.amount, 'Rs 112,500');
      expect(lines.amountNote, 'Paid in full · 2 payments');
      expect(lines.rows, contains(('Serial', 'ZR14-2610-00482')));
      expect(lines.rows.last, ('Left to pay', 'Rs 0'));
      expect(lines.note, '1-year Zenvo warranty.');
    });

    test('the WhatsApp message', () {
      final m = receiptMessage(r, l);
      expect(m, contains('cash receipt BR-3-2026-11-48224'));
      expect(m, contains('Total Rs 112,500 · Paid in full'));
    });
  });

  group('orderCountsOf', () {
    test('a folded status adds to its stage instead of replacing it', () {
      // Found on a phone: an old server sends Instalments (read as Pending)
      // after Pending, and Pending showed 0 instead of 4.
      final counts = orderCountsOf([
        {'status': 'Pending', 'count': 4},
        {'status': 'Varification', 'count': 1},
        {'status': 'Delivered', 'count': 2},
        {'status': 'Instalments', 'count': 0},
        {'status': 'Cancelled', 'count': 1},
      ])!;
      expect(counts['Pending'], 4);
      expect(counts['Varification'], 1);
      expect(counts['Delivered'], 2);
      expect(counts['Cancelled'], 1);
    });

    test('no counts from the server reads as null', () {
      expect(orderCountsOf(null), isNull);
    });
  });
}
