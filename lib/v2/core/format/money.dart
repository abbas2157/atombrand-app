/// Money as the app shows it: `Rs 52,300`.
///
/// Whole rupees, commas every three digits (`Rs 141,600`), as on nearly
/// every canvas board and the web dashboard. The owner chose this over the
/// style guide's `Rs 1,48,500` (4 Nov 2026); [groupDigits] is the only
/// place it is decided.
library;

import 'package:flutter/services.dart';

/// `Rs 52,300`. A negative amount is `-Rs 500`.
String formatRs(int amount) {
  final sign = amount < 0 ? '-' : '';
  return '${sign}Rs ${groupDigits(amount.abs())}';
}

/// `52,300`, for places where "Rs" is drawn separately (the keypad).
String groupDigits(int amount) {
  final s = amount.abs().toString();
  final out = StringBuffer(amount < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

/// The amount in words, as under the payment keypad: "Forty-eight thousand
/// five hundred rupees". Counted in crore, lakh and thousand, the way
/// amounts are said in Pakistan, so a missing zero is easy to hear.
///
/// English only for now; Urdu gets its own words when the app is
/// translated.
String amountInWords(int amount) {
  if (amount <= 0) return '';
  const ones = [
    '', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight',
    'nine', 'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen',
    'sixteen', 'seventeen', 'eighteen', 'nineteen', //
  ];
  const tens = [
    '', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy',
    'eighty', 'ninety', //
  ];
  String two(int x) => x < 20
      ? ones[x]
      : tens[x ~/ 10] + (x % 10 == 0 ? '' : '-${ones[x % 10]}');
  String three(int x) {
    final h = x ~/ 100, r = x % 100;
    return [if (h > 0) '${ones[h]} hundred', if (r > 0) two(r)].join(' ');
  }

  final parts = <String>[];
  final crore = amount ~/ 10000000;
  final lakh = (amount % 10000000) ~/ 100000;
  final thousand = (amount % 100000) ~/ 1000;
  final rest = amount % 1000;
  // Above 99 crore the crore count itself needs hundreds.
  if (crore > 0) parts.add('${crore < 100 ? two(crore) : three(crore)} crore');
  if (lakh > 0) parts.add('${two(lakh)} lakh');
  if (thousand > 0) parts.add('${two(thousand)} thousand');
  if (rest > 0) parts.add(three(rest));

  final s = '${parts.join(' ')} ${amount == 1 ? 'rupee' : 'rupees'}';
  return s[0].toUpperCase() + s.substring(1);
}

/// A typed amount with its commas, "64,999", as on the boards' price
/// boxes. Only digits are kept, at most [maxDigits]; read it back with
/// [parseRupees].
class RupeesInputFormatter extends TextInputFormatter {
  const RupeesInputFormatter({this.maxDigits = 8});
  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    if (digits.length > maxDigits) return oldValue;
    if (digits.isEmpty) return TextEditingValue.empty;
    final shown = groupDigits(int.parse(digits));
    // The cursor keeps the same digits on its right.
    final end = newValue.selection.end.clamp(0, newValue.text.length);
    final right = newValue.text
        .substring(end)
        .replaceAll(RegExp('[^0-9]'), '')
        .length;
    var at = shown.length;
    for (var seen = 0; at > 0 && seen < right;) {
      at--;
      if (shown[at] != ',') seen++;
    }
    return TextEditingValue(
      text: shown,
      selection: TextSelection.collapsed(offset: at),
    );
  }
}

/// The rupees in a box filled through [RupeesInputFormatter]; 0 when empty.
int parseRupees(String text) =>
    int.tryParse(text.replaceAll(RegExp('[^0-9]'), '')) ?? 0;
