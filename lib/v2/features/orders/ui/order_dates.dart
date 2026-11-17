import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/format/dates.dart';
import '../../../widgets/widgets.dart';

/// The Cash orders list's "Placed" filter (6.1): any time, a preset, or
/// days picked on the calendar. Sent as `from` / `to` (the server filters
/// on the order's date).
@immutable
class PlacedRange {
  const PlacedRange([this.key = 'any', this.from, this.to]);

  /// `any`, `today`, `week`, `days30`, `month` or `pick`.
  final String key;
  final DateTime? from;
  final DateTime? to;

  bool get any => key == 'any';

  static PlacedRange preset(String key, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (key) {
      'today' => PlacedRange(key, today, today),
      'week' => PlacedRange(
        key,
        today.subtract(const Duration(days: 6)),
        today,
      ),
      'days30' => PlacedRange(
        key,
        today.subtract(const Duration(days: 29)),
        today,
      ),
      'month' => PlacedRange(key, DateTime(today.year, today.month), today),
      _ => const PlacedRange(),
    };
  }

  String label(AppLocalizations l) => switch (key) {
    'today' => l.bulkRangeToday,
    'week' => l.bulkRangeWeek,
    'days30' => l.bulkRangeDays30,
    'month' => l.bulkRangeThisMonth,
    'pick' when from != null && to != null =>
      from == to
          ? AtomDates.short(from!)
          : l.bulkRangeDates(AtomDates.short(from!), AtomDates.short(to!)),
    _ => l.bulkAnyTime,
  };

  @override
  bool operator ==(Object other) =>
      other is PlacedRange &&
      other.key == key &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(key, from, to);
}

/// The Placed sheet: the presets, then Pick dates opens the calendar
/// (never past today). Null when closed without a choice.
Future<PlacedRange?> pickPlacedRange(
  BuildContext context,
  PlacedRange current,
) async {
  final l = AppLocalizations.of(context);
  final v = await showAtomSelect<String>(
    context,
    title: l.ordersPlacedTitle,
    selected: current.key,
    options: [
      AtomOption(value: 'any', label: l.bulkAnyTime),
      AtomOption(value: 'today', label: l.bulkRangeToday),
      AtomOption(value: 'week', label: l.bulkRangeWeek),
      AtomOption(value: 'days30', label: l.bulkRangeDays30),
      AtomOption(value: 'month', label: l.bulkRangeThisMonth),
      AtomOption(
        value: 'pick',
        label: l.bulkRangePick,
        subtitle: current.key == 'pick' ? current.label(l) : null,
      ),
    ],
  );
  if (v == null || !context.mounted) return null;
  final now = AtomDates.now();
  if (v != 'pick') return PlacedRange.preset(v, now);
  final today = DateTime(now.year, now.month, now.day);
  final range = await showDateRangePicker(
    context: context,
    firstDate: DateTime(today.year - 3),
    lastDate: today,
    initialDateRange: current.from != null && current.to != null
        ? DateTimeRange(start: current.from!, end: current.to!)
        : null,
    helpText: l.ordersPlacedTitle,
  );
  if (range == null) return null;
  return PlacedRange('pick', range.start, range.end);
}
