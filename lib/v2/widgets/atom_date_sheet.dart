import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/app_localizations.dart';
import '../design/design.dart';
import 'atom_button.dart';
import 'atom_choices.dart';
import 'atom_headers.dart';
import 'atom_pressable.dart';
import 'atom_sheet.dart';

/// The days of [month] laid out Monday first, with nulls before the 1st so
/// the first row lines up under the weekday names.
List<DateTime?> monthGrid(DateTime month) {
  final first = DateTime(month.year, month.month);
  final days = DateTime(month.year, month.month + 1, 0).day;
  final lead = (first.weekday + 6) % 7; // Monday = 0
  return [
    for (var i = 0; i < lead; i++) null,
    for (var d = 1; d <= days; d++) DateTime(month.year, month.month, d),
  ];
}

/// "When was it paid?" (6.3): today, yesterday, two days ago, or any past
/// day on the calendar. Future days can't be picked. Returns the day, or
/// null when closed.
Future<DateTime?> showPastDaySheet(
  BuildContext context, {
  required DateTime selected,
  required DateTime today,
  required String title,
  String? body,
}) {
  return showAtomSheet<DateTime>(
    context,
    builder: (_) => _PastDaySheet(
      selected: selected,
      today: today,
      title: title,
      body: body,
    ),
  );
}

class _PastDaySheet extends StatefulWidget {
  const _PastDaySheet({
    required this.selected,
    required this.today,
    required this.title,
    this.body,
  });

  final DateTime selected;
  final DateTime today;
  final String title;
  final String? body;

  @override
  State<_PastDaySheet> createState() => _PastDaySheetState();
}

class _PastDaySheetState extends State<_PastDaySheet> {
  late DateTime _picked = _day(widget.selected);
  late DateTime _view = DateTime(_picked.year, _picked.month);

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime get _today => _day(widget.today);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final weekdays = [
      for (var i = 0; i < 7; i++)
        DateFormat.E(locale).format(DateTime(2024, 1, 1 + i)).substring(0, 2),
    ];
    final canGoForward =
        _view.year < _today.year ||
        (_view.year == _today.year && _view.month < _today.month);

    DateTime ago(int n) => _today.subtract(Duration(days: n));

    // The sheet scrolls when it is taller than the screen (showAtomSheet).
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Semantics(
            header: true,
            child: Text(widget.title, style: AtomText.heading),
          ),
          if (widget.body != null) ...[
            const SizedBox(height: 2),
            Text(widget.body!, style: AtomText.secondary),
          ],
          const SizedBox(height: 14),
          AtomChoiceGrid<int>(
            columns: 3,
            choices: [
              AtomSegment(0, l.dateToday),
              AtomSegment(1, l.dateYesterday),
              AtomSegment(2, l.dateTwoDaysAgo),
            ],
            selected: [0, 1, 2].where((n) => ago(n) == _picked).firstOrNull,
            onChanged: (n) => setState(() {
              _picked = ago(n);
              _view = DateTime(_picked.year, _picked.month);
            }),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              AtomIconButton(
                icon: LucideIcons.chevronLeft,
                label: l.datePreviousMonth,
                onTap: () => setState(
                  () => _view = DateTime(_view.year, _view.month - 1),
                ),
              ),
              Expanded(
                child: Text(
                  DateFormat.yMMMM(locale).format(_view),
                  textAlign: TextAlign.center,
                  style: AtomText.listTitle,
                ),
              ),
              AtomIconButton(
                icon: LucideIcons.chevronRight,
                label: l.dateNextMonth,
                onTap: canGoForward
                    ? () => setState(
                        () => _view = DateTime(_view.year, _view.month + 1),
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 6),
          _Grid(
            weekdays: weekdays,
            days: monthGrid(_view),
            picked: _picked,
            today: _today,
            locale: locale,
            onPick: (d) => setState(() => _picked = d),
          ),
          const SizedBox(height: 14),
          AtomButton(
            label: l.dateUse(DateFormat('d MMM', locale).format(_picked)),
            onPressed: () => Navigator.of(context).pop(_picked),
          ),
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.weekdays,
    required this.days,
    required this.picked,
    required this.today,
    required this.locale,
    required this.onPick,
  });

  final List<String> weekdays;
  final List<DateTime?> days;
  final DateTime picked;
  final DateTime today;
  final String locale;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[
      for (final w in weekdays)
        Center(
          child: ExcludeSemantics(
            child: Text(
              w,
              style: AtomText.tag.copyWith(color: AtomColors.faint),
            ),
          ),
        ),
      for (final d in days)
        if (d == null) const SizedBox.shrink() else _cell(d),
    ];
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      rows.add(
        Row(
          children: [
            for (var j = i; j < i + 7; j++)
              Expanded(
                child: SizedBox(
                  // Day rows are a full tap target tall.
                  height: j < 7 ? 26 : AtomSize.tapTarget,
                  child: j < cells.length ? cells[j] : null,
                ),
              ),
          ],
        ),
      );
    }
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Column(children: rows),
    );
  }

  Widget _cell(DateTime d) {
    final future = d.isAfter(today);
    final on = d == picked;
    final isToday = d == today;
    return AtomPressable(
      onTap: future ? null : () => onPick(d),
      selected: on,
      scaleOnPress: false,
      focusRadius: AtomRadius.brPill,
      semanticLabel: DateFormat.yMMMMd(locale).format(d),
      builder: (_, pressed) => Center(
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on
                ? AtomColors.primary
                : pressed
                ? AtomColors.surface
                : Colors.transparent,
            border: isToday && !on
                ? Border.all(color: AtomColors.primary, width: 1.5)
                : null,
          ),
          child: Text(
            '${d.day}',
            style: AtomText.body.copyWith(
              fontWeight: on ? FontWeight.w700 : FontWeight.w500,
              color: on
                  ? Colors.white
                  : future
                  ? const Color(0xFFC1C7D0)
                  : AtomColors.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
