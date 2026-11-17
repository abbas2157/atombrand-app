import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/models/order.dart';

/// One step of the progress tracker.
class ProgressStep {
  const ProgressStep(this.label, {this.done = false, this.current = false, this.date = ''});
  final String label;
  final bool done;
  final bool current;

  /// Short date the step was reached ("30 Sep"), when known.
  final String date;
}

/// Placed → Verification → Processing → Delivered → Completed, from the
/// order's status and history. The step after the last one reached is the
/// current one. Cancelled orders have no tracker (null).
List<ProgressStep>? orderProgress(OrderDetail d) {
  const steps = [
    ('Placed', 'Pending'),
    ('Verification', 'Varification'),
    ('Processing', 'Processing'),
    ('Delivered', 'Delivered'),
    ('Completed', 'Completed'),
  ];
  final status = d.order.status;
  if (status == 'Cancelled') return null;
  final reached = switch (status) {
    'Varification' => 1,
    'Processing' => 2,
    'Delivered' || 'Instalments' => 3,
    'Completed' => 4,
    _ => 0,
  };
  String dateOf(int i) {
    if (i == 0) return formatShortDate(d.order.createdAt);
    final h = d.history.where((h) => h.status == steps[i].$2 || (i == 3 && h.status == 'Instalments'));
    return h.isEmpty ? '' : formatShortDate(h.first.createdAt);
  }

  return [
    for (final (i, s) in steps.indexed)
      ProgressStep(s.$1, done: i <= reached, current: i == reached + 1, date: i <= reached ? dateOf(i) : ''),
  ];
}

enum PaymentState { paid, due, upcoming, overdue }

/// One line of the instalment schedule.
class ScheduleRow {
  const ScheduleRow({
    required this.badge,
    required this.title,
    required this.when,
    required this.amount,
    required this.state,
    this.next = false,
  });

  final String badge;
  final String title;
  final String when;
  final int amount;
  final PaymentState state;

  /// The first payment still to come (not overdue).
  final bool next;
}

/// Turns `instalments[]` into schedule rows. Paid is the server's word;
/// unpaid rows are Overdue before [today], Due on it, Upcoming after.
List<ScheduleRow> scheduleRows(List<Instalment> items, {DateTime? today}) {
  final day = DateUtils.dateOnly(today ?? DateTime.now());
  var n = 0;
  var nextMarked = false;
  return [
    for (final i in items)
      () {
        final isAdvance = (i.type ?? '').toLowerCase() == 'advance';
        if (!isAdvance) n++;
        final due = parseServerDate(i.date);
        final status = (i.status ?? '').toLowerCase();
        final state = status == 'paid'
            ? PaymentState.paid
            : status == 'overdue' || (due != null && DateUtils.dateOnly(due).isBefore(day))
                ? PaymentState.overdue
                : (due != null && DateUtils.isSameDay(due, day))
                    ? PaymentState.due
                    : PaymentState.upcoming;
        final next = !nextMarked && (state == PaymentState.due || state == PaymentState.upcoming);
        if (next) nextMarked = true;
        return ScheduleRow(
          badge: isAdvance ? 'A' : '$n',
          title: isAdvance ? 'Advance' : 'Instalment $n',
          when: state == PaymentState.paid
              ? 'Paid ${formatDate(i.paidDate ?? i.date)}'
              : state == PaymentState.overdue
                  ? 'Was due ${formatDate(i.date)}'
                  : 'Due ${formatDate(i.date)}',
          amount: i.price,
          state: state,
          next: next,
        );
      }(),
  ];
}

/// Sum of unpaid rows that are due today or overdue.
int dueNow(List<ScheduleRow> rows) => rows
    .where((r) => r.state == PaymentState.due || r.state == PaymentState.overdue)
    .fold(0, (sum, r) => sum + r.amount);

/// History statuses in plain words for the activity timeline.
String activityLabel(String status, {String? channel}) => switch (status) {
      'Pending' => channel == null ? 'Order placed' : 'Order placed via $channel',
      'Varification' => 'Sent for verification',
      'Processing' => 'Processing',
      'Delivered' => 'Delivered',
      'Instalments' => 'Instalment plan started',
      'Completed' => 'Completed',
      'Cancelled' => 'Cancelled',
      _ => status,
    };
