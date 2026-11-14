// Money, words, dates and ids are shown on every screen and checked before
// anything is saved, so their rules are pinned here.

import 'package:atombrand_app/v2/core/format/dates.dart';
import 'package:atombrand_app/v2/core/format/ids.dart';
import 'package:atombrand_app/v2/core/format/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('money', () {
    test('groups by thousands with the Rs prefix', () {
      expect(formatRs(0), 'Rs 0');
      expect(formatRs(950), 'Rs 950');
      expect(formatRs(8400), 'Rs 8,400');
      expect(formatRs(141600), 'Rs 141,600');
      expect(formatRs(12500000), 'Rs 12,500,000');
      expect(formatRs(-500), '-Rs 500');
    });

    test('amount in words counts lakh and crore', () {
      expect(amountInWords(0), '');
      expect(amountInWords(1), 'One rupee');
      expect(amountInWords(8400), 'Eight thousand four hundred rupees');
      expect(amountInWords(48500), 'Forty-eight thousand five hundred rupees');
      expect(
        amountInWords(148500),
        'One lakh forty-eight thousand five hundred rupees',
      );
      expect(amountInWords(25000000), 'Two crore fifty lakh rupees');
      expect(amountInWords(101), 'One hundred one rupees');
    });
  });

  group('dates', () {
    final today = DateTime(2026, 11, 4, 15, 30);

    test('formats days', () {
      expect(AtomDates.day(DateTime(2026, 11, 4)), '4 Nov 2026');
      expect(AtomDates.short(DateTime(2026, 12, 3)), '3 Dec');
      expect(AtomDates.api(DateTime(2026, 1, 9)), '2026-01-09');
    });

    test('counts whole days, ignoring the time', () {
      expect(AtomDates.daysFrom(DateTime(2026, 11, 4, 1), today: today), 0);
      expect(AtomDates.daysFrom(DateTime(2026, 11, 5), today: today), 1);
      expect(AtomDates.daysFrom(DateTime(2026, 10, 25), today: today), -10);
    });

    test('payment days are today or earlier', () {
      expect(AtomDates.isAllowedPaymentDay(today, today: today), isTrue);
      expect(
        AtomDates.isAllowedPaymentDay(DateTime(2025, 1, 1), today: today),
        isTrue,
      );
      expect(
        AtomDates.isAllowedPaymentDay(DateTime(2026, 11, 5), today: today),
        isFalse,
      );
    });

    test('parse never throws', () {
      expect(AtomDates.parse('2026-11-04'), DateTime(2026, 11, 4));
      expect(AtomDates.parse(''), isNull);
      expect(AtomDates.parse('soon'), isNull);
      expect(AtomDates.parse(42), isNull);
    });
  });

  group('ids', () {
    test('mobile numbers', () {
      expect(AtomIds.normaliseMobile('0301 4567890'), '03014567890');
      expect(AtomIds.normaliseMobile('+92 301 4567890'), '03014567890');
      expect(AtomIds.normaliseMobile('0421234567'), isNull);
      // Grouped 4-4-3, as the boards write it.
      expect(AtomIds.formatMobile('03014567890'), '0301 4567 890');
    });

    test('mobile typed as 0300 1234 567', () {
      String type(String t) => MobileInputFormatter()
          .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: t))
          .text;
      expect(type('03009990611'), '0300 9990 611');
      expect(type('030099906119'), '0300 9990 611');
      expect(type('030'), '030');
      expect(type('+923009990611'), '+923009990611');
      expect(AtomIds.normaliseMobile(type('03009990611')), '03009990611');
    });

    test('IMEI needs 15 digits and a valid check digit', () {
      expect(AtomIds.isValidImei('490154203237518'), isTrue);
      expect(AtomIds.isValidImei('490154203237519'), isFalse);
      expect(AtomIds.isValidImei('49015420323751'), isFalse);
      expect(AtomIds.isValidImei('4901542032375180'), isFalse);
      expect(AtomIds.isValidImei('49015420323751A'), isFalse);
    });
  });
}
