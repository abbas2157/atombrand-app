/// The rules of a brand's cash order, mirrored from the server so the app
/// offers only what the server will take (`Order::CASH_TRANSITIONS`,
/// `BrandOrderService`). The server re-checks every move; these only decide
/// what to show. Pure Dart, so the tests pin them.
library;

import '../../../../l10n/app_localizations.dart';

/// Where a cash order is. [key] is the server's value: `Varification` is the
/// real (misspelt) database value and is sent exactly like that.
enum OrderStage {
  pending('Pending'),
  confirming('Varification'),
  processing('Processing'),
  delivered('Delivered'),
  completed('Completed'),
  cancelled('Cancelled');

  const OrderStage(this.key);

  /// The server's status value.
  final String key;

  /// What the app calls it (`BrandOrderService::STATUS_LABELS`).
  String label(AppLocalizations l) => switch (this) {
    pending => l.ordersStagePending,
    confirming => l.ordersStageConfirming,
    processing => l.ordersStageProcessing,
    delivered => l.ordersStageDelivered,
    completed => l.ordersStageCompleted,
    cancelled => l.ordersStageCancelled,
  };

  /// Reads a server status; `Verification` and `Confirming` are accepted
  /// for `Varification`. Unknown values (an old `Instalments`) read as
  /// [pending] so a screen never breaks on them.
  static OrderStage fromKey(String? key) => switch (key) {
    'Varification' || 'Verification' || 'Confirming' => confirming,
    'Processing' => processing,
    'Delivered' => delivered,
    'Completed' => completed,
    'Cancelled' => cancelled,
    _ => pending,
  };

  bool get isFinal => this == completed || this == cancelled;

  /// The steps of the stepper (6.2), in order. Cancelled is not one.
  static const steps = [pending, confirming, processing, delivered, completed];
}

/// `Order::CASH_TRANSITIONS`: where a cash order may go next.
const cashTransitions = <OrderStage, List<OrderStage>>{
  OrderStage.pending: [
    OrderStage.confirming,
    OrderStage.processing,
    OrderStage.cancelled,
  ],
  OrderStage.confirming: [OrderStage.processing, OrderStage.cancelled],
  OrderStage.processing: [OrderStage.delivered, OrderStage.cancelled],
  OrderStage.delivered: [OrderStage.completed],
  OrderStage.completed: [],
  OrderStage.cancelled: [],
};

/// The moves the server listed (`next_statuses`), or the table's when it
/// sent none (the phone's copy, an old server).
List<OrderStage> allowedMoves(OrderStage from, List<OrderStage>? fromServer) =>
    fromServer ?? cashTransitions[from] ?? const [];

/// Unpaid, part paid, paid, or not needed (a cancelled order).
enum PaymentState {
  unpaid,
  part,
  paid,
  notNeeded;

  String label(AppLocalizations l) => switch (this) {
    unpaid => l.ordersPayUnpaid,
    part => l.ordersPayPart,
    paid => l.ordersPayPaid,
    notNeeded => l.ordersPayNotNeeded,
  };

  /// `BrandOrderService::paymentState`, and Not needed once cancelled.
  static PaymentState of({
    required int total,
    required int paid,
    OrderStage? stage,
  }) {
    if (stage == OrderStage.cancelled) return notNeeded;
    if (paid <= 0) return unpaid;
    return paid >= total ? PaymentState.paid : part;
  }

  /// The server's `payment_state` (`unpaid`, `part`, `paid`).
  static PaymentState fromKey(String? key, {OrderStage? stage}) {
    if (stage == OrderStage.cancelled) return notNeeded;
    return switch (key) {
      'paid' => paid,
      'part' => part,
      _ => unpaid,
    };
  }
}

/// The one button on a row of the Orders list (6.1).
enum RowAction { confirm, deliver, takePayment, complete, receipt }

/// The row's button, as the board: Confirm on a new order, Mark delivered
/// when it is out, Take payment or Complete once delivered, Receipt when
/// done. Null when there is nothing to do, or the person may not do it.
RowAction? rowActionFor(
  OrderStage stage,
  PaymentState pay, {
  required bool canStatus,
  required bool canPay,
}) => switch (stage) {
  OrderStage.pending ||
  OrderStage.confirming => canStatus ? RowAction.confirm : null,
  OrderStage.processing => canStatus ? RowAction.deliver : null,
  OrderStage.delivered =>
    pay == PaymentState.paid
        ? (canStatus ? RowAction.complete : null)
        : (canPay ? RowAction.takePayment : null),
  OrderStage.completed => RowAction.receipt,
  OrderStage.cancelled => null,
};

/// The "Next step" card on the order (6.2).
enum NextStep { startConfirming, confirm, deliver, recordPayment, complete }

/// The next step for an order at [stage] with [balance] left to pay, or
/// null when it is finished. [moves] are the server's next statuses.
NextStep? nextStepFor(
  OrderStage stage, {
  required int balance,
  List<OrderStage>? moves,
}) {
  final next = allowedMoves(stage, moves);
  return switch (stage) {
    OrderStage.pending when next.contains(OrderStage.confirming) =>
      NextStep.startConfirming,
    OrderStage.pending when next.contains(OrderStage.processing) =>
      NextStep.confirm,
    OrderStage.confirming when next.contains(OrderStage.processing) =>
      NextStep.confirm,
    OrderStage.processing when next.contains(OrderStage.delivered) =>
      NextStep.deliver,
    OrderStage.delivered when balance > 0 => NextStep.recordPayment,
    OrderStage.delivered when next.contains(OrderStage.completed) =>
      NextStep.complete,
    _ => null,
  };
}

/// The status a next step moves the order to, or null for a step that is a
/// form of its own (deliver, record a payment).
OrderStage? moveOf(NextStep step) => switch (step) {
  NextStep.startConfirming => OrderStage.confirming,
  NextStep.confirm => OrderStage.processing,
  NextStep.complete => OrderStage.completed,
  NextStep.deliver || NextStep.recordPayment => null,
};

/// Cancel is offered before delivery only (the table has no Cancelled
/// after Delivered for a brand).
bool canCancelOrder(OrderStage stage, List<OrderStage>? moves) =>
    allowedMoves(stage, moves).contains(OrderStage.cancelled);

/// Move to another outlet (6.6): the owner, a brand with more than one
/// outlet, and an order not finished yet.
bool canMoveOrder(
  OrderStage stage, {
  required bool isOwner,
  required bool multiOutlet,
}) => isOwner && multiOutlet && !stage.isFinal;

/// `BrandOrderService::CANCEL_REASONS`: key → what the person reads.
Map<String, String> cancelReasons(AppLocalizations l) => {
  'unreachable': l.ordersCancelUnreachable,
  'changed_mind': l.ordersCancelChangedMind,
  'out_of_stock': l.ordersCancelOutOfStock,
  'no_delivery': l.ordersCancelNoDelivery,
};

/// `BrandPayment::METHODS`: key → label.
Map<String, String> paymentMethodLabels(AppLocalizations l) => {
  'cod': l.ordersMethodCod,
  'bank': l.ordersMethodBank,
  'jazzcash': l.ordersMethodJazzcash,
  'easypaisa': l.ordersMethodEasypaisa,
  'cash': l.ordersMethodCash,
  'cheque': l.ordersMethodCheque,
};

String labelOfMethod(String key, AppLocalizations l) =>
    paymentMethodLabels(l)[key] ??
    (key.isEmpty ? key : key[0].toUpperCase() + key.substring(1));

/// The methods to offer, in the server's order; plain cash always (the
/// server adds it to the brand's Shop settings).
List<String> offeredMethods(List<String> fromServer) {
  final out = <String>[...fromServer];
  if (!out.contains('cash')) out.add('cash');
  return out;
}

/// Half of what is left, rounded to a rupee (the "Half" quick pick).
int halfOf(int left) => (left / 2).round();

/// Why a payment can't be saved yet, or null when it can (6.4): more than
/// nothing, and not more than is left.
String? paymentAmountProblem(int amount, int left, AppLocalizations l) {
  if (left <= 0) return l.ordersPayNothingLeft;
  if (amount <= 0) return l.ordersPayEnterAmount;
  if (amount > left) return l.ordersPayTooMuch;
  return null;
}

/// What stops "Save delivery" (6.3), or null when it can be saved.
///
/// With the Inventory add-on the unit's serial is read first; "Someone
/// else" needs their name; cash collected can't be more than is left and
/// needs a method.
String? deliveryProblem({
  required bool inventory,
  required String serial,
  required bool someoneElse,
  required String receiverName,
  required int cod,
  required int left,
  required String? codMethod,
  required AppLocalizations l,
}) {
  if (inventory && serial.trim().isEmpty) return l.ordersDeliverScanFirst;
  if (someoneElse && receiverName.trim().isEmpty) {
    return l.ordersSayWhoReceived;
  }
  if (cod < 0) return l.ordersDeliverEnterCash;
  if (cod > left) return l.ordersDeliverTooMuch;
  if (cod > 0 && (codMethod == null || codMethod.isEmpty)) {
    return l.ordersPickHowPaid;
  }
  return null;
}
