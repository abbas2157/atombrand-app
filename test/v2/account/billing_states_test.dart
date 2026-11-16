import 'package:atombrand_app/l10n/app_localizations.dart';
import 'package:atombrand_app/v2/core/access/access.dart';
import 'package:atombrand_app/v2/design/design.dart';
import 'package:atombrand_app/v2/features/account/data/billing_models.dart';
import 'package:atombrand_app/v2/features/account/data/plan_logic.dart';
import 'package:atombrand_app/v2/features/home/data/home_models.dart';
import 'package:atombrand_app/v2/features/stock/data/stock_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every billing state the server can send, read into its enum.
void main() {
  final l = lookupAppLocalizations(const Locale('en'));

  group('PlanStatus', () {
    test('reads each status; missing is none, unknown runs', () {
      expect(PlanStatus.fromKey('none'), PlanStatus.none);
      expect(PlanStatus.fromKey('trial'), PlanStatus.trial);
      expect(PlanStatus.fromKey('active'), PlanStatus.active);
      expect(PlanStatus.fromKey('ended'), PlanStatus.ended);
      expect(PlanStatus.fromKey(null), PlanStatus.none);
      expect(PlanStatus.fromKey('paused_by_admin'), PlanStatus.active);
    });
  });

  group('access state', () {
    test('each server state, and ok for missing or unknown', () {
      expect(AccountStatus.fromAccessState('ok'), AccountStatus.ok);
      expect(AccountStatus.fromAccessState('due'), AccountStatus.due);
      expect(AccountStatus.fromAccessState('late'), AccountStatus.late);
      expect(AccountStatus.fromAccessState('overdue'), AccountStatus.overdue);
      expect(AccountStatus.fromAccessState('readonly'), AccountStatus.readOnly);
      expect(AccountStatus.fromAccessState('removed'), AccountStatus.removed);
      expect(AccountStatus.fromAccessState('none'), AccountStatus.noPlan);
      expect(AccountStatus.fromAccessState(null), AccountStatus.ok);
      expect(AccountStatus.fromAccessState('weird'), AccountStatus.ok);
    });
  });

  group('bills', () {
    Invoice bill(String? status, {bool overdue = false}) => Invoice.fromJson({
      'id': 1,
      'number': 'INV-1',
      'status': ?status,
      'overdue': overdue,
      'total': 100,
      'due': 100,
    });

    test('status, owed and overdue', () {
      expect(bill('open').status, InvoiceStatus.open);
      expect(bill('part_paid').status, InvoiceStatus.partPaid);
      expect(bill('paid').status, InvoiceStatus.paid);
      expect(bill('void').status, InvoiceStatus.voided);
      expect(bill(null).status, InvoiceStatus.open);

      expect(bill('open').open, isTrue);
      expect(bill('part_paid').open, isTrue);
      expect(bill('paid').open, isFalse);
      expect(bill('void').open, isFalse);

      // Only a bill still owed can be overdue.
      expect(bill('open', overdue: true).overdue, isTrue);
      expect(bill('part_paid', overdue: true).overdue, isTrue);
      expect(bill('paid', overdue: true).overdue, isFalse);
      expect(bill('void', overdue: true).overdue, isFalse);
    });

    test('the pill for each status', () {
      expect(billStatus(l, bill('paid')).label, 'Paid');
      expect(billStatus(l, bill('void')).label, 'Cancelled');
      expect(billStatus(l, bill('part_paid')).label, 'Part paid');
      expect(billStatus(l, bill('open', overdue: true)).label, 'Late');
      expect(billStatus(l, bill('open')).label, 'To pay');
    });
  });

  group('payments', () {
    BillPayment pay(String? status, {String? number = 'RCT-1'}) =>
        BillPayment.fromJson({
          'amount_claimed': 100,
          'status': ?status,
          'number': ?number,
        });

    test('status and receipt', () {
      expect(pay('pending').status, PaymentStatus.pending);
      expect(pay('received').status, PaymentStatus.received);
      expect(pay('rejected').status, PaymentStatus.rejected);
      expect(pay('reversed').status, PaymentStatus.reversed);
      expect(pay(null).status, PaymentStatus.pending);

      expect(pay('received').hasReceipt, isTrue);
      expect(pay('received', number: null).hasReceipt, isFalse);
      expect(pay('pending').hasReceipt, isFalse);
    });

    test('the pill for each status', () {
      expect(paymentStatus(l, pay('received')).label, 'Received');
      expect(paymentStatus(l, pay('rejected')).tone, AtomTone.rose);
      expect(paymentStatus(l, pay('reversed')).tone, AtomTone.rose);
      expect(paymentStatus(l, pay('pending')).tone, AtomTone.blue);
    });
  });

  group('add-on state', () {
    test('AddonEnd reads its state; missing is off', () {
      AddonState of(Object? s) =>
          AddonEnd.fromJson({'key': 'team', 'name': 'Team', 'state': s}).state;
      expect(of('trial'), AddonState.trial);
      expect(of('active'), AddonState.active);
      expect(of('lapsed'), AddonState.lapsed);
      expect(of('legacy'), AddonState.legacy);
      expect(of(null), AddonState.off);
    });

    test('StockAccess: missing is active, trial is a trial', () {
      expect(StockAccess.fromJson(const {}).state, AddonState.active);
      expect(StockAccess.fromJson(const {}).trial, isFalse);
      expect(StockAccess.fromJson({'state': 'trial'}).trial, isTrue);
      expect(
        StockAccess.fromJson({'state': 'lapsed'}).state,
        AddonState.lapsed,
      );
    });
  });
}
