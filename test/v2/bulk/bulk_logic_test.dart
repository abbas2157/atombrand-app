import 'package:atombrand_app/l10n/app_localizations.dart';
import 'package:atombrand_app/v2/features/bulk/data/bulk_logic.dart';
import 'package:atombrand_app/v2/features/bulk/data/bulk_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final l = lookupAppLocalizations(const Locale('en'));

Deal _deal({
  int total = 300000,
  int paid = 0,
  int advancePct = 30,
  String terms = 'before_last',
  List<DealItem>? items,
}) {
  final it =
      items ??
      const [
        DealItem(
          id: 1,
          title: 'AC',
          qty: 10,
          unitPrice: 20000,
          lineTotal: 200000,
        ),
        DealItem(
          id: 2,
          title: 'TV',
          qty: 5,
          unitPrice: 20000,
          lineTotal: 100000,
        ),
      ];
  return Deal(
    id: 9,
    number: 'BD-0009',
    status: DealStatus.open,
    total: total,
    paid: paid,
    balance: total - paid,
    units: it.fold(0, (s, i) => s + i.qty),
    deliveredUnits: it.fold(0, (s, i) => s + i.deliveredQty),
    advancePct: advancePct,
    advance: (total * advancePct / 100).round(),
    balanceTerms: terms,
    items: it,
  );
}

void main() {
  group('quote maths', () {
    test('a line is qty × unit price less the discount, to the rupee', () {
      expect(quoteLineTotal(12, 104999, 3), 1222188); // 1,259,988 × 0.97
      expect(quoteLineTotal(3, 333, 0), 999);
      expect(quoteLineTotal(1, 101, 50), 51); // 50.5 rounds up
      expect(quoteLineTotal(2, 1000, 150), 0); // capped at 100%
    });

    test(
      'totals add the delivery charge and take the advance off the total',
      () {
        final t = quoteTotals(
          const [
            QuoteDraftLine(
              productId: 1,
              qty: 10,
              unitPrice: 104999,
              discountPct: 3,
            ),
            QuoteDraftLine(
              productId: 1,
              qty: 2,
              unitPrice: 104999,
              discountPct: 3,
            ),
          ],
          delivery: 6000,
          advancePct: 30,
        );
        expect(t.units, 12);
        expect(t.gross, 1259988);
        expect(t.discount, 1259988 - (1018490 + 203698));
        expect(t.subtotal, 1018490 + 203698);
        expect(t.total, 1018490 + 203698 + 6000);
        expect(t.advance, ((1018490 + 203698 + 6000) * 0.3).round());
        expect(t.balance, t.total - t.advance);
      },
    );
  });

  group('quote checks', () {
    final today = DateTime(2026, 11, 14);
    Map<String, String> check(
      List<QuoteDraftLine> lines, {
      int delivery = 0,
      DateTime? until,
      int advance = 30,
      String notes = '',
    }) => quoteProblems(
      l,
      lines: lines,
      delivery: delivery,
      validUntil: until ?? DateTime(2026, 11, 21),
      today: today,
      advancePct: advance,
      notes: notes,
    );

    test('a good quote passes', () {
      expect(
        check(const [QuoteDraftLine(productId: 3, qty: 2, unitPrice: 5000)]),
        isEmpty,
      );
    });

    test('each line needs a product, a quantity and a price', () {
      final p = check(const [
        QuoteDraftLine(qty: 1, unitPrice: 10),
        QuoteDraftLine(productId: 1, qty: 0, unitPrice: 10),
        QuoteDraftLine(productId: 1, qty: 1, unitPrice: 0),
        QuoteDraftLine(productId: 1, qty: 1, unitPrice: 10, discountPct: 120),
      ]);
      expect(p['line.0'], contains('choose a product'));
      expect(p['line.1'], contains('quantity'));
      expect(p['line.2'], contains('unit price'));
      expect(p['line.3'], contains('discount'));
    });

    test('no lines, a past date, long notes and a huge total are refused', () {
      expect(check(const [])['lines'], isNotNull);
      expect(
        check(const [
          QuoteDraftLine(productId: 1, qty: 1, unitPrice: 10),
        ], until: DateTime(2026, 11, 13))['valid_until'],
        isNotNull,
      );
      expect(
        check(const [
          QuoteDraftLine(productId: 1, qty: 1, unitPrice: 10),
        ], until: today),
        isEmpty,
        reason: 'valid until today is allowed',
      );
      expect(
        check(const [
          QuoteDraftLine(productId: 1, qty: 1, unitPrice: 10),
        ], notes: 'x' * 501)['notes'],
        isNotNull,
      );
      expect(
        check(const [
          QuoteDraftLine(productId: 1, qty: 100000, unitPrice: 50000000),
        ])['lines'],
        contains('too large'),
      );
    });

    test('the line JSON leaves out an empty storage and colour', () {
      expect(
        const QuoteDraftLine(productId: 4, qty: 2, unitPrice: 9).toJson(),
        {'product_id': 4, 'qty': 2, 'unit_price': 9, 'discount_pct': 0.0},
      );
    });
  });

  group('revisions', () {
    Quote q(int rev, String status) =>
        Quote(id: rev, number: 'QT-0007', revision: rev, status: status);

    test('the first quote is rev 1', () {
      final r = nextRevision(const []);
      expect(r.revision, 1);
      expect(r.replaces, isNull);
    });

    test('sending after a sent one makes the next revision', () {
      final r = nextRevision([q(2, 'sent'), q(1, 'superseded')]);
      expect(r.revision, 3);
      expect(r.replaces?.revision, 2);
      expect(r.draft, isNull);
    });

    test('a draft is changed in place', () {
      final r = nextRevision([q(3, 'draft'), q(2, 'sent')]);
      expect(r.revision, 3);
      expect(r.draft?.revision, 3);
      expect(r.replaces?.revision, 2);
    });
  });

  group('seller request state', () {
    final quote = Quote(
      id: 1,
      number: 'QT-1',
      revision: 1,
      status: 'sent',
      sentAt: DateTime(2026, 11, 10, 10),
    );

    test('new, quoted and accepted', () {
      expect(sourcingStateOf(status: RequestStatus.fresh), SourcingState.fresh);
      expect(
        sourcingStateOf(status: RequestStatus.quoted, liveQuote: quote),
        SourcingState.quoted,
      );
      expect(
        sourcingStateOf(
          status: RequestStatus.quoted,
          liveQuote: quote,
          deal: const DealRef(id: 4, number: 'BD-4'),
        ),
        SourcingState.accepted,
      );
    });

    test('a change asked stays until a new revision', () {
      const asked = SellerAnswer(action: 'change_asked', pending: true);
      expect(
        sourcingStateOf(
          status: RequestStatus.quoted,
          liveQuote: quote,
          answer: asked,
        ),
        SourcingState.changeAsked,
      );
      const answered = SellerAnswer(action: 'change_asked', pending: false);
      expect(
        sourcingStateOf(
          status: RequestStatus.quoted,
          liveQuote: quote,
          answer: answered,
        ),
        SourcingState.quoted,
      );
    });

    test('a decline holds until a newer quote is sent', () {
      final no = SellerAnswer(action: 'declined', at: DateTime(2026, 11, 11));
      expect(
        sourcingStateOf(
          status: RequestStatus.quoted,
          liveQuote: quote,
          answer: no,
        ),
        SourcingState.declined,
      );
      final newer = Quote(
        id: 2,
        number: 'QT-1',
        revision: 2,
        status: 'sent',
        sentAt: DateTime(2026, 11, 12),
      );
      expect(
        sourcingStateOf(
          status: RequestStatus.quoted,
          liveQuote: newer,
          answer: no,
        ),
        SourcingState.quoted,
      );
    });

    test('the brand turning it down is closed', () {
      expect(sourcingStateOf(status: RequestStatus.lost), SourcingState.closed);
      expect(SourcingState.closed.canQuote, isFalse);
      expect(SourcingState.declined.canQuote, isTrue);
    });

    test('steps follow the state and the deal', () {
      expect(sourcingStepsReached(SourcingState.fresh), 1);
      expect(sourcingStepsReached(SourcingState.quoted), 2);
      expect(sourcingStepsReached(SourcingState.changeAsked), 3);
      expect(sourcingStepsReached(SourcingState.accepted), 4);
      expect(
        sourcingStepsReached(SourcingState.accepted, dealStatus: 'paid'),
        5,
      );
    });

    test('needed-by urgency', () {
      final today = DateTime(2026, 11, 14, 18);
      expect(needByOf(DateTime(2026, 11, 17), today: today).urgency, 2);
      expect(needByOf(DateTime(2026, 11, 17), today: today).days, 3);
      expect(needByOf(DateTime(2026, 11, 20), today: today).urgency, 1);
      expect(needByOf(DateTime(2026, 11, 30), today: today).urgency, 0);
      expect(needByOf(DateTime(2026, 11, 12), today: today).days, -2);
      expect(daysLeftText(l, -2), '2 days late');
      expect(daysLeftText(l, 0), 'today');
      expect(percentAbove(149999, 132000), 14);
    });
  });

  group('website requests', () {
    test('row action by status and permission', () {
      expect(
        requestActionOf(RequestStatus.fresh, canQuote: true),
        RequestAction.reply,
      );
      expect(
        requestActionOf(RequestStatus.contacted, canQuote: true),
        RequestAction.sendQuote,
      );
      expect(
        requestActionOf(RequestStatus.contacted, canQuote: false),
        RequestAction.view,
      );
      expect(
        requestActionOf(RequestStatus.won, canQuote: true),
        RequestAction.openDeal,
      );
    });

    test('status choices and the lost reason', () {
      expect(statusChoicesFor(RequestStatus.won), isEmpty);
      expect(
        statusChoicesFor(RequestStatus.lost),
        contains(StatusChoice.backToNew),
      );
      expect(statusProblem(l, StatusChoice.lost, null), isNotNull);
      expect(statusProblem(l, StatusChoice.lost, 'Price too high'), isNull);
      expect(statusProblem(l, StatusChoice.contacted, null), isNull);
    });

    test('unknown statuses are new leads', () {
      expect(RequestStatus.of(null), RequestStatus.fresh);
      expect(RequestStatus.of('Quoted'), RequestStatus.quoted);
    });
  });

  group('deliveries (no credit)', () {
    test('the advance comes before the first delivery', () {
      final d = _deal(paid: 50000); // advance 90,000
      expect(deliveryBlock(d, {1: 1}), isA<AdvanceFirst>());
      expect(deliveryBlock(_deal(paid: 90000), {1: 1}), isNull);
    });

    test('the delivery that completes the deal needs the whole balance', () {
      final d = _deal(paid: 290000);
      final b = deliveryBlock(d, {1: 10, 2: 5});
      expect(b, isA<BalanceFirst>());
      expect((b! as BalanceFirst).due, 10000);
      expect(deliveryBlock(_deal(paid: 300000), {1: 10, 2: 5}), isNull);
    });

    test('before each delivery: the units out so far must be paid for', () {
      final d = _deal(paid: 90000, terms: 'before_each');
      // 5 ACs = 100,000 > 90,000 paid
      final b = deliveryBlock(d, {1: 5});
      expect(b, isA<PayForUnits>());
      expect((b! as PayForUnits).short, 10000);
      expect(deliveryBlock(d, {1: 4}), isNull); // 80,000
      expect(paidCoverLeft(d), 90000);
    });

    test('nothing picked and too many are refused', () {
      final d = _deal(paid: 300000);
      expect(deliveryBlock(d, {}), isA<NothingPicked>());
      expect(deliveryBlock(d, {2: 6}), isA<TooMany>());
    });

    test('value delivered counts what went out before', () {
      final d = _deal(
        items: const [
          DealItem(
            id: 1,
            title: 'AC',
            qty: 10,
            unitPrice: 20000,
            lineTotal: 190000, // 5% off
            deliveredQty: 4,
          ),
        ],
        total: 190000,
      );
      expect(valueDelivered(d), 76000);
      expect(valueDelivered(d, {1: 1}), 95000);
    });

    test('serials: none, or one per unit with no repeats', () {
      expect(splitSerials(' A1 \n\nB2, C3\n'), ['A1', 'B2', 'C3']);
      expect(serialProblem(l, 'AC', 2, const []), isNull);
      expect(serialProblem(l, 'AC', 2, const ['A', 'B']), isNull);
      expect(
        serialProblem(l, 'AC', 3, const ['A', 'B']),
        contains('2 serials for 3'),
      );
      expect(serialProblem(l, 'AC', 2, const ['A', 'A']), contains('twice'));
    });

    test('the form needs who received it', () {
      expect(deliverFormProblem(l, receivedBy: ' ', note: ''), isNotNull);
      expect(deliverFormProblem(l, receivedBy: 'Kamran', note: ''), isNull);
    });
  });

  group('payments', () {
    test('an amount is needed and never more than the balance', () {
      expect(paymentProblem(l, 0, 1000), isNotNull);
      expect(
        paymentProblem(l, 1001, 1000),
        'More than the balance of Rs 1,000',
      );
      expect(paymentProblem(l, 1000, 1000), isNull);
    });

    test('quick amounts: the advance, half and the whole balance', () {
      final q = paymentQuickAmounts(l, _deal(paid: 20000));
      expect(q.map((e) => e.label), ['Advance', 'Half', 'Full balance']);
      expect(q.first.amount, 70000);
      expect(q.last.amount, 280000);
      // once delivering, no advance
      final d = _deal(
        paid: 100000,
        items: const [
          DealItem(
            id: 1,
            title: 'AC',
            qty: 10,
            unitPrice: 30000,
            lineTotal: 300000,
            deliveredQty: 2,
          ),
        ],
      );
      expect(paymentQuickAmounts(l, d).map((e) => e.label), [
        'Half',
        'Full balance',
      ]);
    });

    test('a deal row offers Deliver, then Record payment, then nothing', () {
      expect(dealActionOf(_deal(), canDeal: true), DealAction.deliver);
      expect(dealActionOf(_deal(), canDeal: false), isNull);
      final allOut = _deal(
        items: const [
          DealItem(
            id: 1,
            title: 'AC',
            qty: 1,
            unitPrice: 300000,
            lineTotal: 300000,
            deliveredQty: 1,
          ),
        ],
        paid: 100000,
      );
      expect(dealActionOf(allOut, canDeal: true), DealAction.payment);
    });
  });
}
