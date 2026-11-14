/// The words an order page says about itself: the next step, the stepper
/// lines and the history. Pure functions of the order, so the tests pin
/// them.
library;

import '../../../../l10n/app_localizations.dart';
import '../../../core/api/api_client.dart' show Json;
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import 'order_rules.dart';
import 'orders_models.dart';

/// (title, body, button) of the next-step card.
(String, String, String) nextStepWords(
  NextStep step,
  CashOrderDetail o,
  AppLocalizations l, {
  required bool inventory,
}) {
  final first = o.customer?.firstName ?? l.ordersTheCustomer;
  return switch (step) {
    NextStep.startConfirming => (
      l.ordersCallCustomer,
      l.ordersNextCallBody(first),
      l.ordersStartConfirming,
    ),
    NextStep.confirm => (
      l.ordersConfirmOrder,
      inventory ? l.ordersNextConfirmBodyHeld : l.ordersNextConfirmBody,
      l.ordersConfirmOrder,
    ),
    NextStep.deliver => (
      l.ordersMarkDelivered,
      l.ordersNextDeliverBody,
      l.ordersMarkDelivered,
    ),
    NextStep.recordPayment => (
      l.ordersRecordPayment,
      l.ordersNextPayBody(formatRs(o.order.balance)),
      l.ordersRecordPayment,
    ),
    NextStep.complete => (
      l.ordersComplete,
      l.ordersNextCompleteBody,
      l.ordersComplete,
    ),
  };
}

/// The stepper's name for a step.
String stepName(OrderStage s, AppLocalizations l) =>
    s == OrderStage.pending ? l.ordersStepNew : s.label(l);

/// "3 Nov, 10:05 am".
String _at(DateTime d, AppLocalizations l) =>
    l.ordersDayTime(AtomDates.short(d), AtomDates.time(d));

/// "you" for the person signed in, else the name; null when the event has
/// no person (Atomshop, the customer).
String? whoDid(OrderEvent e, AppLocalizations l, {String? me}) {
  final n = e.byName;
  if (n == null || n.isEmpty) return null;
  return n == me ? l.ordersYou : n;
}

/// The line under a step: what happened when it is done, what it asks
/// when it is next, nothing after that.
String stepSub(
  OrderStage s,
  CashOrderDetail o,
  AppLocalizations l, {
  required bool inventory,
  String? me,
}) {
  final steps = OrderStage.steps;
  final at = steps.indexOf(o.stage);
  final i = steps.indexOf(s);
  if (i == at + 1) {
    return switch (s) {
      OrderStage.confirming => l.ordersCallCustomer,
      OrderStage.processing =>
        inventory ? l.ordersSubHeldOnWay : l.ordersSubOnWay,
      OrderStage.delivered => l.ordersSubSerialProof,
      OrderStage.completed => l.ordersPaidInFull,
      _ => '',
    };
  }
  if (i > at) return '';
  final e = o.eventFor(s);
  final who = e == null ? null : whoDid(e, l, me: me);
  String withWho(String what) => [what, ?who].join(' · ');
  return switch (s) {
    OrderStage.pending =>
      o.order.createdAt == null
          ? ''
          : l.ordersSubPlaced(_at(o.order.createdAt!, l)),
    OrderStage.confirming =>
      e?.at == null ? '' : withWho(l.ordersSubCalled(_at(e!.at!, l))),
    OrderStage.processing =>
      e?.at == null
          ? ''
          : withWho(
              inventory
                  ? l.ordersSubUnitHeld(AtomDates.short(e!.at!))
                  : l.ordersSubConfirmed(_at(e!.at!, l)),
            ),
    OrderStage.delivered => switch (Json.str(e?.payload['recieved_by'])) {
      final n? when n.isNotEmpty =>
        '${l.ordersSubReceivedBy(n)}${e?.at == null ? '' : ' · ${AtomDates.short(e!.at!)}'}',
      _ => e?.at == null ? '' : l.ordersSubDelivered(AtomDates.short(e!.at!)),
    },
    OrderStage.completed =>
      e?.at == null ? '' : l.ordersSubCompleted(AtomDates.short(e!.at!)),
    OrderStage.cancelled => '',
  };
}

/// The cancel reasons an event carries ("Customer changed their mind"),
/// with the note after them.
String? cancelWhy(OrderEvent e) {
  final parts = [
    ?Json.str(e.payload['reasons']),
    ?Json.str(e.payload['reason']),
  ].where((s) => s.trim().isNotEmpty).toList();
  return parts.isEmpty ? null : parts.join('. ');
}

/// One line of the history.
String eventText(
  OrderEvent e,
  AppLocalizations l, {
  String? me,
  bool inventory = false,
}) {
  final who = whoDid(e, l, me: me);
  String withWho(String what) => [what, ?who].join(' · ');
  final p = e.payload;
  if (Json.str(p['moved_to']) case final to?) {
    final from = Json.str(p['moved_from']);
    return withWho(
      from == null ? l.ordersEvMovedTo(to) : l.ordersEvMovedFromTo(from, to),
    );
  }
  return switch (e.stage) {
    OrderStage.pending =>
      who == null ? l.ordersPlacedOnline : withWho(l.ordersEvPlaced),
    OrderStage.confirming => withWho(l.ordersEvStarted),
    OrderStage.processing => withWho(
      inventory ? l.ordersEvConfirmedHeld : l.ordersEvConfirmed,
    ),
    OrderStage.delivered => withWho(
      [
        switch (Json.str(p['recieved_by'])) {
          final n? when n.isNotEmpty => l.ordersEvDeliveredTo(n),
          _ => l.ordersStageDelivered,
        },
        if (Json.str(p['collected']) case final c? when c.isNotEmpty)
          l.ordersEvCollected(c.replaceFirst('Rs. ', 'Rs ')),
      ].join(', '),
    ),
    OrderStage.completed => withWho(l.ordersEvCompleted),
    OrderStage.cancelled => withWho(switch (cancelWhy(e)) {
      final w? => l.ordersEvCancelledWhy(w),
      _ => l.ordersStageCancelled,
    }),
  };
}

/// "Rs 62,500 by Bank transfer · ref MZN-88213 · you".
String paymentText(OrderPaymentRow p, AppLocalizations l, {String? me}) {
  final who = p.recordedBy == null
      ? null
      : (p.recordedBy == me ? l.ordersYou : p.recordedBy);
  return [
    l.ordersEvPayment(formatRs(p.amount), p.methodName(l).toLowerCase()),
    if (p.reference case final r? when r.isNotEmpty) l.ordersRef(r),
    ?who,
  ].join(' · ');
}

/// The history, newest first: the order's events and its payments
/// together, each as (time, line).
List<(String, String)> historyLines(
  CashOrderDetail o,
  AppLocalizations l, {
  String? me,
  bool inventory = false,
}) {
  final rows = <(DateTime, String)>[
    for (final e in o.history)
      if (e.at != null) (e.at!, eventText(e, l, me: me, inventory: inventory)),
    for (final p in o.payments)
      if (p.paidOn != null) (p.paidOn!, paymentText(p, l, me: me)),
  ]..sort((a, b) => b.$1.compareTo(a.$1));
  if (!o.history.any((e) => e.stage == OrderStage.pending) &&
      o.order.createdAt != null) {
    rows.add((o.order.createdAt!, l.ordersPlacedOnline));
  }
  return [
    for (final (t, s) in rows)
      (
        t.hour == 0 && t.minute == 0
            ? AtomDates.short(t)
            : '${AtomDates.short(t)} ${AtomDates.time(t)}',
        s,
      ),
  ];
}

/// "Rs 50,000 · Cash on delivery · 4 Nov · recorded by Usman Ali".
String paymentLine(OrderPaymentRow p, AppLocalizations l, {String? me}) {
  final who = p.recordedBy == null
      ? null
      : (p.recordedBy == me ? l.ordersYou : p.recordedBy);
  return [
    p.methodName(l),
    if (p.paidOn != null) AtomDates.short(p.paidOn!),
    if (p.reference case final r? when r.isNotEmpty) l.ordersRef(r),
    if (who != null) l.ordersRecordedBy(who),
  ].join(' · ');
}
