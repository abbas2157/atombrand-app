import 'dart:convert';

import '../../../core/db/outbox_actions.dart';
import '../../../core/db/outbox_db.dart';
import '../../../core/db/sync_store.dart';
import '../../../core/services/uuid.dart';

/// What the person says happened on Fix a serial clash (10.4).
enum ClashChoice {
  /// The same box was counted twice: keep the server's unit, drop the
  /// clashing serials from this change and send the rest.
  dropMine,

  /// The unit is here now: drop the clashing serials from the stock in,
  /// and move the server's unit to this change's warehouse.
  moveHere,

  /// The wrong box was scanned: drop the clashing serials, send the rest,
  /// and scan the right one (a new stock in).
  wrongBox,

  /// Give the whole change up: the server keeps what it has.
  discard,
}

/// The choices a clash on [action] offers, in the board's order.
List<ClashChoice> clashChoices(String action) => switch (action) {
  SyncActionKeys.stockIn => const [
    ClashChoice.dropMine,
    ClashChoice.moveHere,
    ClashChoice.wrongBox,
  ],
  SyncActionKeys.stockTransfer => const [
    ClashChoice.dropMine,
    ClashChoice.discard,
  ],
  _ => const [ClashChoice.discard],
};

/// What a fix did to the outbox.
typedef ClashFixed = ({
  /// The change is gone from the outbox (nothing of it is left to send).
  bool discarded,

  /// The serials still going with the revised change.
  List<String> kept,

  /// A move queued for the server's unit ([ClashChoice.moveHere]).
  String? transferId,
});

/// Applies [choice] to the clashing [entry]. The change keeps its place in
/// the order with a new id (the server wants a new id for changed data,
/// §6.1); a change left with no serials is discarded.
Future<ClashFixed> fixClash(
  SyncStore store,
  OutboxEntry entry, {
  required List<String> clashing,
  required ClashChoice choice,
  String Function() newId = newUuid,
  DateTime Function() now = DateTime.now,
}) async {
  final data = switch (jsonDecode(entry.data)) {
    final Map m => Map<String, dynamic>.from(m),
    _ => <String, dynamic>{},
  };
  final all = OfflineAction.serialsOf(entry.action, data);
  final taken = {for (final s in clashing) s.trim().toLowerCase()};
  final kept = [
    for (final s in all)
      if (!taken.contains(s.toLowerCase())) s,
  ];

  final named = kept.length < all.length;
  final shrink =
      choice != ClashChoice.discard &&
      clashChoices(entry.action).contains(choice) &&
      named &&
      kept.isNotEmpty;
  if (shrink) {
    final revised = Map<String, dynamic>.from(data)..['serials'] = kept;
    if (entry.action == SyncActionKeys.stockIn) revised['qty'] = kept.length;
    await store.revise(entry.id, newId: newId(), data: revised);
  } else {
    // Nothing would be left, or the clash names nothing in this change
    // (an old answer): there is no smaller change to send.
    await store.discard(entry.id);
  }

  String? transferId;
  if (choice == ClashChoice.moveHere &&
      entry.action == SyncActionKeys.stockIn &&
      named &&
      data['warehouse_id'] != null) {
    final move = OfflineAction.stockTransfer(
      serials: [
        for (final s in all)
          if (taken.contains(s.toLowerCase())) s,
      ],
      toWarehouseId: int.parse('${data['warehouse_id']}'),
      note: 'Fixed a serial clash on this phone',
    );
    transferId = newId();
    await store.addToOutbox(
      id: transferId,
      action: move.action,
      data: move.data,
      at: now(),
      shopId: entry.shopId,
    );
  }

  return (
    discarded: !shrink,
    kept: shrink ? kept : const <String>[],
    transferId: transferId,
  );
}
