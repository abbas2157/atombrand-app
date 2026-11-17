import 'package:intl/intl.dart';

/// Dates as the app shows them. Days are local (Asia/Karachi on the
/// sellers' phones); the server sends and takes `Y-m-d`.
abstract final class AtomDates {
  /// The app's clock. Screens read the time here, so tests (and the
  /// screenshot goldens) can fix it.
  static DateTime Function() now = DateTime.now;

  static final _day = DateFormat('d MMM y');
  static final _short = DateFormat('d MMM');
  static final _weekday = DateFormat('EEE d MMM');
  static final _time = DateFormat('h:mm a');
  static final _api = DateFormat('yyyy-MM-dd');
  static final _monthYear = DateFormat('MMM y');

  /// `4 Nov 2026`
  static String day(DateTime d) => _day.format(d);

  /// `4 Nov`
  static String short(DateTime d) => _short.format(d);

  /// `4 Nov` this year, `4 Jan 2027` in another: a next payment that falls
  /// in the new year says so.
  static String shortOrYear(DateTime d) =>
      d.year == now().year ? short(d) : day(d);

  /// `Wed 4 Nov`
  static String weekday(DateTime d) => _weekday.format(d);

  /// `9:42 am`: the boards write am/pm small, as the rest of the app does.
  static String time(DateTime d) => _time.format(d).toLowerCase();

  /// `Nov 2026`
  static String monthYear(DateTime d) => _monthYear.format(d);

  /// `2026-11-04`, for the API.
  static String api(DateTime d) => _api.format(d);

  /// Parses the API's `Y-m-d` (or a full timestamp). Null when empty or
  /// unreadable, never a throw.
  static DateTime? parse(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    // A timestamp with a zone ("…Z", "…+05:00") parses as UTC: show it in
    // the phone's time, not UTC (a lead taken at 2:36 said 21:36).
    return DateTime.tryParse(value.trim())?.toLocal();
  }

  /// Whole days from [today] to [d]: 0 today, 1 tomorrow, -3 three days
  /// ago. Times of day are ignored.
  static int daysFrom(DateTime d, {required DateTime today}) {
    final a = DateTime.utc(today.year, today.month, today.day);
    final b = DateTime.utc(d.year, d.month, d.day);
    return b.difference(a).inDays;
  }

  /// Payment dates can be any past day or today, never the future.
  static bool isAllowedPaymentDay(DateTime d, {required DateTime today}) =>
      daysFrom(d, today: today) <= 0;
}
