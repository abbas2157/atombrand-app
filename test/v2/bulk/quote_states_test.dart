import 'package:atombrand_app/l10n/app_localizations.dart';
import 'package:atombrand_app/v2/design/design.dart';
import 'package:atombrand_app/v2/features/bulk/data/bulk_logic.dart';
import 'package:atombrand_app/v2/features/bulk/data/bulk_models.dart';
import 'package:atombrand_app/v2/features/bulk/ui/bulk_parts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every quote, seller-answer and deal state, read and shown.
void main() {
  final l = lookupAppLocalizations(const Locale('en'));

  Quote quote(String? status, {bool expired = false, int rev = 1}) =>
      Quote.fromJson({
        'id': rev,
        'number': 'QT-0007',
        'revision': rev,
        'status': ?status,
        'expired': expired,
      });

  group('QuoteStatus', () {
    test('reads each status; missing is a draft, unknown reads as sent', () {
      expect(quote('draft').status, QuoteStatus.draft);
      expect(quote('sent').status, QuoteStatus.sent);
      expect(quote('accepted').status, QuoteStatus.accepted);
      expect(quote('superseded').status, QuoteStatus.superseded);
      expect(quote('expired').status, QuoteStatus.expired);
      expect(quote(null).status, QuoteStatus.draft);
      expect(quote('mystery').status, QuoteStatus.sent);
    });

    test('live: only sent and accepted', () {
      expect(QuoteStatus.values.where((s) => s.live), [
        QuoteStatus.sent,
        QuoteStatus.accepted,
      ]);
    });

    test('expired: the flag, or the expired status', () {
      expect(quote('sent').expired, isFalse);
      expect(quote('sent', expired: true).expired, isTrue);
      expect(quote('sent', expired: true).status, QuoteStatus.sent);
      expect(quote('expired').expired, isTrue);
    });

    test('isDraft', () {
      expect(quote('draft').isDraft, isTrue);
      expect(quote(null).isDraft, isTrue);
      expect(quote('sent').isDraft, isFalse);
    });
  });

  group('quoteLook', () {
    test('a pill for each status', () {
      expect(quoteLook(l, quote('draft')), (l.bulkQuoteDraft, AtomTone.grey));
      expect(quoteLook(l, quote('accepted')), (
        l.bulkStatusAccepted,
        AtomTone.green,
      ));
      expect(quoteLook(l, quote('superseded')), (
        l.bulkQuoteSuperseded,
        AtomTone.grey,
      ));
      expect(quoteLook(l, quote('expired')), (
        l.bulkQuoteExpired,
        AtomTone.rose,
      ));
      expect(quoteLook(l, quote('sent')), (l.bulkQuoteSent, AtomTone.amber));
    });

    test('a sent quote past its date shows Expired', () {
      expect(quoteLook(l, quote('sent', expired: true)), (
        l.bulkQuoteExpired,
        AtomTone.rose,
      ));
    });
  });

  group('SellerAction', () {
    SellerAnswer? answer(String? action) =>
        SellerAnswer.fromJson({'action': ?action});

    test('reads each action; unknown is other; missing is no answer', () {
      expect(answer('accepted')!.action, SellerAction.accepted);
      expect(answer('change_asked')!.action, SellerAction.changeAsked);
      expect(answer('declined')!.action, SellerAction.declined);
      expect(answer('cancelled')!.action, SellerAction.cancelled);
      expect(answer('waved')!.action, SellerAction.other);
      expect(answer(null), isNull);
    });

    test('saidNo: declined and cancelled only', () {
      expect(SellerAction.values.where((a) => a.saidNo), [
        SellerAction.declined,
        SellerAction.cancelled,
      ]);
    });
  });

  group('sourcing state from the seller answer', () {
    SourcingState of(SellerAnswer? a, {Quote? live}) => sourcingStateOf(
      status: RequestStatus.quoted,
      answer: a,
      liveQuote: live,
    );

    test('each answer', () {
      expect(
        of(const SellerAnswer(action: SellerAction.accepted)),
        SourcingState.accepted,
      );
      expect(
        of(const SellerAnswer(action: SellerAction.changeAsked, pending: true)),
        SourcingState.changeAsked,
      );
      expect(
        of(const SellerAnswer(action: SellerAction.cancelled)),
        SourcingState.declined,
      );
      // An answer this app doesn't know changes nothing.
      expect(
        of(const SellerAnswer(action: SellerAction.other)),
        SourcingState.quoted,
      );
    });

    test('a lost request: declined if the seller said no, else closed', () {
      SourcingState lost(SellerAction? a) => sourcingStateOf(
        status: RequestStatus.lost,
        answer: a == null ? null : SellerAnswer(action: a),
      );
      expect(lost(SellerAction.declined), SourcingState.declined);
      expect(lost(SellerAction.cancelled), SourcingState.declined);
      expect(lost(null), SourcingState.closed);
    });

    test('a draft is not a quote yet', () {
      expect(
        sourcingStateOf(status: RequestStatus.fresh, liveQuote: quote('draft')),
        SourcingState.fresh,
      );
      expect(
        sourcingStateOf(status: RequestStatus.fresh, liveQuote: quote('sent')),
        SourcingState.quoted,
      );
    });
  });

  group('deals', () {
    test('DealRef reads its status; missing stays null', () {
      DealStatus? of(Object? s) =>
          DealRef.fromJson({'id': 4, 'number': 'BD-4', 'status': s})!.status;
      expect(of('open'), DealStatus.open);
      expect(of('delivering'), DealStatus.delivering);
      expect(of('delivered'), DealStatus.delivered);
      expect(of('paid'), DealStatus.paid);
      expect(of('closed'), DealStatus.closed);
      expect(of('lost'), DealStatus.lost);
      expect(of(null), isNull);
    });

    test('deliveredOrLater: delivered, paid and closed', () {
      expect(DealStatus.values.where((s) => s.deliveredOrLater), [
        DealStatus.delivered,
        DealStatus.paid,
        DealStatus.closed,
      ]);
    });

    test('the request step bar reaches Delivered from Delivered on', () {
      for (final s in DealStatus.values) {
        expect(
          sourcingStepsReached(SourcingState.accepted, dealStatus: s),
          s.deliveredOrLater ? 5 : 4,
          reason: s.name,
        );
      }
      expect(sourcingStepsReached(SourcingState.accepted), 4);
    });
  });
}
