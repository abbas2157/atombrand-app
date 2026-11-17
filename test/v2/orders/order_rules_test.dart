// The cash order's rules decide which buttons show; the server refuses the
// rest. Pinned here so a screen never offers a move the server won't take.

import 'package:atombrand_app/l10n/app_localizations.dart';
import 'package:atombrand_app/v2/features/orders/data/order_rules.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l = lookupAppLocalizations(const Locale('en'));
  group('OrderStage', () {
    test('reads the server spelling and its aliases', () {
      expect(OrderStage.fromKey('Varification'), OrderStage.confirming);
      expect(OrderStage.fromKey('Verification'), OrderStage.confirming);
      expect(OrderStage.fromKey('Confirming'), OrderStage.confirming);
      expect(OrderStage.fromKey('Delivered'), OrderStage.delivered);
      expect(OrderStage.fromKey(null), OrderStage.pending);
      expect(OrderStage.fromKey('Instalments'), OrderStage.pending);
    });

    test('sends Varification exactly as the database spells it', () {
      expect(OrderStage.confirming.key, 'Varification');
      expect(OrderStage.confirming.label(l), 'Confirming');
    });

    test('Completed and Cancelled are final', () {
      expect(OrderStage.completed.isFinal, isTrue);
      expect(OrderStage.cancelled.isFinal, isTrue);
      expect(OrderStage.delivered.isFinal, isFalse);
    });
  });

  group('transitions (Order::CASH_TRANSITIONS)', () {
    test('mirror the server table', () {
      expect(cashTransitions[OrderStage.pending], [
        OrderStage.confirming,
        OrderStage.processing,
        OrderStage.cancelled,
      ]);
      expect(cashTransitions[OrderStage.delivered], [OrderStage.completed]);
      expect(cashTransitions[OrderStage.completed], isEmpty);
    });

    test('the server list wins over the table', () {
      expect(allowedMoves(OrderStage.pending, [OrderStage.cancelled]), [
        OrderStage.cancelled,
      ]);
      expect(allowedMoves(OrderStage.processing, null), [
        OrderStage.delivered,
        OrderStage.cancelled,
      ]);
    });

    test('cancel only before delivery', () {
      expect(canCancelOrder(OrderStage.pending, null), isTrue);
      expect(canCancelOrder(OrderStage.processing, null), isTrue);
      expect(canCancelOrder(OrderStage.delivered, null), isFalse);
      expect(canCancelOrder(OrderStage.completed, null), isFalse);
    });

    test('move: owner, several outlets, not finished', () {
      expect(
        canMoveOrder(OrderStage.processing, isOwner: true, multiOutlet: true),
        isTrue,
      );
      expect(
        canMoveOrder(OrderStage.processing, isOwner: false, multiOutlet: true),
        isFalse,
      );
      expect(
        canMoveOrder(OrderStage.processing, isOwner: true, multiOutlet: false),
        isFalse,
      );
      expect(
        canMoveOrder(OrderStage.completed, isOwner: true, multiOutlet: true),
        isFalse,
      );
    });
  });

  group('payment state', () {
    test('from the money', () {
      expect(PaymentState.of(total: 100, paid: 0), PaymentState.unpaid);
      expect(PaymentState.of(total: 100, paid: 40), PaymentState.part);
      expect(PaymentState.of(total: 100, paid: 100), PaymentState.paid);
      expect(
        PaymentState.of(total: 100, paid: 0, stage: OrderStage.cancelled),
        PaymentState.notNeeded,
      );
    });

    test('from the server key', () {
      expect(PaymentState.fromKey('part'), PaymentState.part);
      expect(PaymentState.fromKey('paid'), PaymentState.paid);
      expect(PaymentState.fromKey('unpaid'), PaymentState.unpaid);
      expect(
        PaymentState.fromKey('paid', stage: OrderStage.cancelled),
        PaymentState.notNeeded,
      );
    });
  });

  group('row action (6.1)', () {
    RowAction? act(
      OrderStage s,
      PaymentState p, {
      bool st = true,
      bool pay = true,
    }) => rowActionFor(s, p, canStatus: st, canPay: pay);

    test('follows the board', () {
      expect(act(OrderStage.pending, PaymentState.unpaid), RowAction.confirm);
      expect(
        act(OrderStage.confirming, PaymentState.unpaid),
        RowAction.confirm,
      );
      expect(
        act(OrderStage.processing, PaymentState.unpaid),
        RowAction.deliver,
      );
      expect(
        act(OrderStage.delivered, PaymentState.part),
        RowAction.takePayment,
      );
      expect(act(OrderStage.delivered, PaymentState.paid), RowAction.complete);
      expect(act(OrderStage.completed, PaymentState.paid), RowAction.receipt);
      expect(act(OrderStage.cancelled, PaymentState.notNeeded), isNull);
    });

    test('hides what the role can\'t do', () {
      expect(act(OrderStage.pending, PaymentState.unpaid, st: false), isNull);
      expect(act(OrderStage.delivered, PaymentState.part, pay: false), isNull);
      // A receipt is reading, not doing.
      expect(
        act(OrderStage.completed, PaymentState.paid, st: false, pay: false),
        RowAction.receipt,
      );
    });
  });

  group('next step (6.2)', () {
    test('by status and money', () {
      expect(
        nextStepFor(OrderStage.pending, balance: 100),
        NextStep.startConfirming,
      );
      expect(
        nextStepFor(OrderStage.confirming, balance: 100),
        NextStep.confirm,
      );
      expect(
        nextStepFor(OrderStage.processing, balance: 100),
        NextStep.deliver,
      );
      expect(
        nextStepFor(OrderStage.delivered, balance: 100),
        NextStep.recordPayment,
      );
      expect(nextStepFor(OrderStage.delivered, balance: 0), NextStep.complete);
      expect(nextStepFor(OrderStage.completed, balance: 0), isNull);
      expect(nextStepFor(OrderStage.cancelled, balance: 0), isNull);
    });

    test('a Pending order the server lets skip straight to Processing', () {
      expect(
        nextStepFor(
          OrderStage.pending,
          balance: 100,
          moves: [OrderStage.processing, OrderStage.cancelled],
        ),
        NextStep.confirm,
      );
    });

    test('no step the server didn\'t list', () {
      expect(
        nextStepFor(OrderStage.processing, balance: 100, moves: const []),
        isNull,
      );
    });

    test('moves', () {
      expect(moveOf(NextStep.startConfirming), OrderStage.confirming);
      expect(moveOf(NextStep.confirm), OrderStage.processing);
      expect(moveOf(NextStep.complete), OrderStage.completed);
      expect(moveOf(NextStep.deliver), isNull);
    });
  });

  group('payment maths (6.4)', () {
    test('half rounds to a rupee', () {
      expect(halfOf(62500), 31250);
      expect(halfOf(84999), 42500);
      expect(halfOf(1), 1);
    });

    test('amount problems', () {
      expect(paymentAmountProblem(0, 100, l), 'Enter an amount');
      expect(
        paymentAmountProblem(101, 100, l),
        'More than what is left to pay.',
      );
      expect(paymentAmountProblem(100, 100, l), isNull);
      expect(paymentAmountProblem(50, 100, l), isNull);
      expect(paymentAmountProblem(10, 0, l), 'Nothing is left to pay.');
    });

    test('methods: the brand\'s, then cash', () {
      expect(offeredMethods(['cod', 'bank']), ['cod', 'bank', 'cash']);
      expect(offeredMethods(['cod', 'cash']), ['cod', 'cash']);
      expect(offeredMethods(const []), ['cash']);
      expect(labelOfMethod('cod', l), 'Cash on delivery');
      expect(labelOfMethod('wire', l), 'Wire');
    });
  });

  group('delivery form (6.3)', () {
    String? problem({
      bool inventory = false,
      String serial = '',
      bool someoneElse = false,
      String name = '',
      int cod = 0,
      int left = 1000,
      String? method = 'cod',
    }) => deliveryProblem(
      inventory: inventory,
      serial: serial,
      someoneElse: someoneElse,
      receiverName: name,
      cod: cod,
      left: left,
      codMethod: method,
      l: l,
    );

    test('with Inventory the serial comes first', () {
      expect(problem(inventory: true), 'Scan the serial first');
      expect(problem(inventory: true, serial: 'ZW8-01177'), isNull);
      expect(problem(), isNull);
    });

    test('someone else needs a name', () {
      expect(problem(someoneElse: true), 'Say who received it');
      expect(problem(someoneElse: true, name: 'Ahmed, husband'), isNull);
    });

    test('cash at the door', () {
      expect(problem(cod: 1001), 'More than what is left to pay');
      expect(problem(cod: 500, method: null), 'Pick how they paid');
      expect(problem(cod: 1000), isNull);
    });
  });
}
