import 'package:atombrand_app/v2/features/bulk/data/bulk_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a seller request dossier reads the sourcing block', () {
    final d = BulkDossier.fromJson({
      'request': {
        'id': 88,
        'status': null,
        'full_name': 'Hall Road Electronics',
        'phone': '03001234567',
        'quantity': '12',
        'product_title': 'OXY 55in, new model',
        'product': null,
        'from': 'seller',
        'target_price': 41000,
        'needed_by': '2026-11-20',
        'seller': {
          'id': 31,
          'name': 'Hall Road Electronics',
          'code': 'S10422',
          'verified': true,
        },
        'whatsapp': 'https://wa.me/923001234567',
        'comments': [],
      },
      'requester': null,
      'sourcing': {
        'seller': {
          'id': 31,
          'name': 'Hall Road Electronics',
          'verified': true,
          'city': 'Lahore',
          'on_atomshop_since': '2025-08-14',
          'deals_with_you': 3,
          'deals_amount': 1250000,
          'paid_on_time': 2,
          'other_open_requests': 1,
          'other_requests': [
            {
              'id': 91,
              'product_title': 'OXY 32in LED',
              'quantity': 20,
              'status': 'Quoted',
            },
          ],
        },
        'item': {
          'typed': true,
          'product_id': null,
          'title': 'OXY 55in, new model',
          'quantity': 12,
        },
        'target_price': 41000,
        'needed_by': '2026-11-20',
        'note': 'Black only.',
        'deliver_to': {
          'address': 'Shop 4, Hall Road',
          'city': 'Lahore',
          'area': 'Hall Road',
        },
        'live_quote': {
          'id': 55,
          'number': 'QT-0007',
          'revision': 2,
          'status': 'sent',
          'total': 498000,
          'advance_pct': 30,
          'advance': 149400,
          'valid_until': '2026-11-21',
          'expired': false,
          'items': [
            {
              'title': 'OXY 55in',
              'qty': 12,
              'unit_price': 41500,
              'discount_pct': '0.00',
              'line_total': 498000,
            },
          ],
        },
        'answer': {
          'action': 'change_asked',
          'label': 'Change asked',
          'message': 'Can you do Rs. 39,500 a unit?',
          'pending': true,
          'at': '2026-11-14T09:12:00+05:00',
        },
        'history': [
          {
            'kind': 'event',
            'action': 'quoted',
            'label': 'Quote sent',
            'actor': 'brand',
            'details': 'QT-0007',
            'by': 'Ali Raza',
            'at': '2026-11-13T10:00:00+05:00',
          },
        ],
        'deal': null,
        'commission': {
          'amount': 0,
          'type': 'percent',
          'value': 0,
          'label': 'No Atomshop fee',
          'on_total': 498000,
        },
      },
    });
    expect(d.isSeller, isTrue);
    expect(d.request.status, RequestStatus.fresh);
    expect(d.request.quantity, 12);
    final s = d.sourcing!;
    expect(s.typed, isTrue);
    expect(s.seller!.dealsWithYou, 3);
    expect(s.seller!.otherRequests.single.status, RequestStatus.quoted);
    expect(s.deliverTo, 'Shop 4, Hall Road, Hall Road, Lahore');
    expect(s.liveQuote!.name, 'QT-0007 rev 2');
    expect(s.liveQuote!.items.single.discountPct, 0);
    expect(s.answer!.pending, isTrue);
    expect(s.history.single.by, 'Ali Raza');
    expect(s.commission!.label, 'No Atomshop fee');
  });

  test('a deal reads items, deliveries and payments', () {
    final d = Deal.fromJson({
      'id': 7,
      'number': 'BD-0007',
      'status': 'delivering',
      'status_label': 'Delivering',
      'buyer_name': 'Green Hostels',
      'outlet': {'id': 2, 'name': 'Head office'},
      'units': 30,
      'delivered_units': 18,
      'total': 1650000,
      'paid': 990000,
      'balance': 660000,
      'from': 'buyer',
      'seller': null,
      'commission': null,
      'advance_pct': 30,
      'advance': 495000,
      'balance_terms': 'before_each',
      'quote': {'id': 3, 'label': 'QT-0003 rev 1'},
      'items': [
        {
          'id': 11,
          'title': 'Washer · White',
          'qty': 20,
          'unit_price': 55000,
          'line_total': 1100000,
          'delivered_qty': 18,
          'remaining': 2,
        },
      ],
      'deliveries': [
        {
          'id': 1,
          'number': 'DN-0001',
          'delivered_on': '2026-11-07',
          'received_by': 'Kamran',
          'items': [
            {
              'deal_item_id': 11,
              'qty': 2,
              'serials': ['A', 'B'],
            },
          ],
        },
      ],
      'payments': [
        {
          'id': 1,
          'amount': 495000,
          'method': 'bank',
          'method_label': 'Bank transfer',
          'paid_on': '2026-11-06',
        },
      ],
    });
    expect(d.status, DealStatus.delivering);
    expect(d.leftUnits, 12);
    expect(d.paidShare, closeTo(0.6, 0.001));
    expect(d.items.single.remaining, 2);
    expect(d.deliveries.single.serials, ['A', 'B']);
    expect(d.deliveries.single.units, 2);
    expect(d.payments.single.methodLabel, 'Bank transfer');
    expect(d.quoteLabel, 'QT-0003 rev 1');
    expect(d.fromSeller, isFalse);
  });

  test('a deal from the copy works out its units and advance', () {
    final d = Deal.fromJson({
      'id': 7,
      'number': 'BD-0007',
      'status': 'open',
      'total': 100000,
      'advance_pct': 25,
      'seller_id': 31,
      'items': [
        {
          'id': 1,
          'title': 'AC',
          'qty': 4,
          'unit_price': 25000,
          'line_total': 100000,
          'delivered_qty': 1,
        },
      ],
    });
    expect(d.units, 4);
    expect(d.deliveredUnits, 1);
    expect(d.advance, 25000);
    expect(d.balance, 100000);
    expect(d.fromSeller, isTrue);
  });

  test('a request page reads counts, seller counts and tiles when sent', () {
    final p = BulkRequestsPage.fromJson({
      'items': [
        {'id': 1, 'status': 'Contacted', 'full_name': 'A', 'from': 'buyer'},
      ],
      'pagination': {'current_page': 1, 'last_page': 2, 'total': 21},
      'counts': {'New Lead': 3, 'Contacted': 1},
      'seller_counts': {'waiting': 1, 'change_asked': 2, 'open': 3, 'total': 9},
    });
    expect(p.items.single.status, RequestStatus.contacted);
    expect(p.page.hasMore, isTrue);
    expect(p.counts[RequestStatus.fresh], 3);
    expect(p.sellerCounts.badge, 3);
    expect(p.tiles, isNull);
  });

  test('quote options read products, variants and the fixed choices', () {
    final o = QuoteOptions.fromJson({
      'products': [
        {
          'id': 5,
          'title': 'Acme X1',
          'price': 60000,
          'memories': [
            {'id': 2, 'title': '128 GB', 'price': 65000},
          ],
          'colors': [
            {'id': 4, 'title': 'Black'},
          ],
        },
      ],
      'balance_terms': [
        {'key': 'before_each', 'label': 'Before each delivery'},
      ],
      'payment_methods': [
        {'key': 'bank', 'label': 'Bank transfer'},
      ],
      'lost_reasons': ['Price too high', 'Other'],
    });
    expect(o.product(5)!.memories.single.price, 65000);
    expect(o.product(6), isNull);
    expect(o.balanceTerms.single.label, 'Before each delivery');
    expect(o.lostReasons, hasLength(2));
  });
}
