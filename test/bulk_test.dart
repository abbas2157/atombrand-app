import 'package:atombrand_app/data/models/bulk.dart';
import 'package:atombrand_app/features/bulk/bulk_logic.dart';
import 'package:flutter_test/flutter_test.dart';

BulkComment _c(String? text, {String? status}) => BulkComment.fromJson({'id': 1, 'comments': text, 'status': status});

void main() {
  test('a quote survives the round trip through a comment', () {
    const q = BulkQuote(perUnit: 182000, quantity: 80, validUntil: '10 Oct 2026');
    final text = quoteComment(q, 'Shared the price list on WhatsApp.');
    expect(text, 'Quote: Rs. 182,000/unit × 80 = Rs. 14,560,000 · valid until 10 Oct 2026\nShared the price list on WhatsApp.');
    final back = parseComment(text);
    expect(back.quote!.perUnit, 182000);
    expect(back.quote!.quantity, 80);
    expect(back.quote!.total, 14560000);
    expect(back.quote!.validUntil, '10 Oct 2026');
    expect(back.note, 'Shared the price list on WhatsApp.');
  });

  test('plain comments are notes, and the newest quote wins', () {
    expect(parseComment('Wants a price for 80 units').quote, isNull);
    expect(parseComment('Wants a price for 80 units').note, 'Wants a price for 80 units');
    final latest = latestQuote([
      _c(quoteComment(const BulkQuote(perUnit: 190000, quantity: 80), ''), status: 'Quoted'),
      _c('Asked for a discount', status: 'Contacted'),
      _c(quoteComment(const BulkQuote(perUnit: 182000, quantity: 80), ''), status: 'Quoted'),
    ]);
    expect(latest!.perUnit, 182000);
  });

  test('only New Leads wait, counted in whole days', () {
    BulkRequest r(String status) => BulkRequest.fromJson({'id': 1, 'status': status, 'created_at': '2026-09-28 06:44:00'});
    final now = DateTime(2026, 10, 4, 9);
    expect(waitingDays(r('New Lead'), now: now), 6);
    expect(waitingDays(r('Contacted'), now: now), isNull);
  });

  test('trust hint reads the buyer history with the brand', () {
    BulkDossier d(List<String> statuses, {int overdue = 0}) => BulkDossier.fromJson({
          'request': {'id': 1},
          'orders': [for (final s in statuses) {'uuid': 'u', 'status': s}],
          'instalments': {'overdue': overdue},
        });
    expect(trustHint(d([])).text, 'New buyer, no orders with your brand yet');
    expect(trustHint(d(['Pending', 'Cancelled'])).text, 'New buyer, no completed orders yet');
    expect(trustHint(d(['Delivered', 'Completed', 'Pending'])).text, 'Reliable buyer, 2 orders delivered');
    expect(trustHint(d(['Delivered'], overdue: 2)).warn, isTrue);
  });

  test('pipeline marks the current stage and ends in Lost when lost', () {
    final quoted = pipeline('Quoted');
    expect(quoted.map((s) => s.label), ['New Lead', 'Contacted', 'Quoted', 'Won']);
    expect(quoted[2].current, isTrue);
    expect(quoted[1].done, isTrue);
    final lost = pipeline('Lost');
    expect(lost.last.label, 'Lost');
    expect(lost.last.current, isTrue);
  });
}
