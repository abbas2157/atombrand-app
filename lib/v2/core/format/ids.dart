import 'package:flutter/services.dart';

/// Pakistani mobile numbers and IMEI / serial numbers: checks, display and
/// input masks.
abstract final class AtomIds {
  /// Digits only.
  static String digits(String s) => s.replaceAll(RegExp(r'\D'), '');

  /// A mobile number the server accepts: `03XXXXXXXXX` (11 digits). A
  /// `+92` or `92` prefix is turned into the leading 0.
  static String? normaliseMobile(String input) {
    var d = digits(input);
    if (d.startsWith('92') && d.length == 12) d = '0${d.substring(2)}';
    return RegExp(r'^03\d{9}$').hasMatch(d) ? d : null;
  }

  /// `0301 4567 890`, as the boards write it.
  static String formatMobile(String input) {
    // "+923004916866" (website leads) reads as 0300 4916 866 too
    final d = normaliseMobile(input) ?? digits(input);
    if (d.length != 11) return input;
    return '${d.substring(0, 4)} ${d.substring(4, 8)} ${d.substring(8)}';
  }

  /// An IMEI is exactly 15 digits whose last digit is the Luhn check digit.
  /// On a phone box, this is how the IMEI barcode is told apart from the
  /// serial and the EAN.
  static bool isValidImei(String input) {
    final d = digits(input);
    if (d.length != 15 || d != input.trim()) return false;
    var sum = 0;
    for (var i = 0; i < 15; i++) {
      var n = d.codeUnitAt(i) - 48;
      // Every second digit from the left (index 1, 3, …) is doubled.
      if (i.isOdd) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
    }
    return sum % 10 == 0;
  }
}

/// Types a mobile number as `0301 4567 890` while the person types digits.
/// A number starting `+92` or `92` is left as typed (up to 13 digits), so a
/// pasted international number still reads right.
class MobileInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    final d = AtomIds.digits(raw);
    final String text;
    if (raw.trimLeft().startsWith('+') || d.startsWith('92')) {
      final capped = d.length > 12 ? d.substring(0, 12) : d;
      text = raw.trimLeft().startsWith('+') ? '+$capped' : capped;
    } else {
      final capped = d.length > 11 ? d.substring(0, 11) : d;
      final b = StringBuffer();
      for (var i = 0; i < capped.length; i++) {
        if (i == 4 || i == 8) b.write(' ');
        b.write(capped[i]);
      }
      text = b.toString();
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// A WhatsApp chat with [phone] (`0300…` or `92300…`), with [text] typed.
Uri whatsAppUri(String phone, {String? text}) {
  final d = AtomIds.digits(phone);
  final intl = d.startsWith('0') ? '92${d.substring(1)}' : d;
  return Uri.parse(
    'https://wa.me/$intl${text == null ? '' : '?text=${Uri.encodeComponent(text)}'}',
  );
}
