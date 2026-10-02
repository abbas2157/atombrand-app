import 'package:intl/intl.dart';

/// Money and date formatting per BRAND_APP.md §2.6.
final _thousands = NumberFormat('#,##0', 'en_US');
final _date = DateFormat('d MMM y', 'en_US');
final _dateTime = DateFormat('d MMM y, h:mm a', 'en_US');

/// `30000` → `Rs. 30,000`.
String money(num? value) => 'Rs. ${_thousands.format(value ?? 0)}';

String count(num? value) => _thousands.format(value ?? 0);

/// Server dates are `YYYY-MM-DD HH:MM:SS` already in Asia/Karachi time, so
/// they are parsed as wall-clock values and never converted.
DateTime? parseServerDate(String? raw) =>
    (raw == null || raw.isEmpty) ? null : DateTime.tryParse(raw);

/// `24 Sep 2026`.
String formatDate(String? raw) {
  final d = parseServerDate(raw);
  return d == null ? '' : _date.format(d);
}

/// `24 Sep 2026, 3:05 PM`.
String formatDateTime(String? raw) {
  final d = parseServerDate(raw);
  if (d == null) return '';
  // Date-only values have no meaningful time part.
  return raw!.length <= 10 ? _date.format(d) : _dateTime.format(d);
}
