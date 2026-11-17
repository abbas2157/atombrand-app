import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_result.dart';
import '../../../core/db/outbox_actions.dart';
import '../../../core/db/outbox_files.dart';
import '../../../core/db/sync_store.dart';
import '../../../core/services/uuid.dart';

/// How a save ended.
///
/// Three outcomes, not two: a save that went to the outbox is **not** the
/// same as one the server took. The server has not run its rules on it,
/// there is no receipt number and no id, and it may still come back as
/// Needs attention. Screens have to say so rather than show a receipt for
/// something that has not happened yet, so the type makes them choose.
@immutable
sealed class Saved<T> {
  const Saved();

  /// The server took it, and answered [SavedOnServer.value].
  bool get onServer => this is SavedOnServer<T>;

  /// It is in the outbox, waiting for a signal.
  bool get onPhone => this is SavedHere<T>;
}

/// The server took it.
@immutable
class SavedOnServer<T> extends Saved<T> {
  const SavedOnServer(this.value);
  final T value;
}

/// No signal: it is in this phone's outbox, in the order it was made.
@immutable
class SavedHere<T> extends Saved<T> {
  const SavedHere({required this.id, this.tempId});

  /// The action's uuid. Made here, so sending it twice never applies it
  /// twice, and the Waiting to send list can find it again.
  final String id;

  /// This phone's name for a record the action makes, which a later
  /// action can point at before the real id exists (`tmp:<temp_id>`).
  final String? tempId;
}

/// It did not save, and waiting will not help: the role, the plan, the
/// server's own refusal.
@immutable
class SaveFailed<T> extends Saved<T> {
  const SaveFailed(this.failure);
  final ApiFailure failure;
}

/// A save that can wait for a signal.
///
/// Every save that the server can replay later goes through here. It tries
/// the server first, because a save that reaches it is finished — its
/// rules have run, the money is the server's figure, and the receipt is
/// real. Only when there is no signal does the save go to the outbox,
/// where the engine sends it in the order it was made.
///
/// What it is **not**: a cache in front of the API. An account without the
/// Offline add-on never queues anything; it calls the server exactly as it
/// always did and gets the same failure when there is no signal.
class OfflineSaves {
  const OfflineSaves({
    required this.store,
    required this.photos,
    required this.shopId,
    required this.enabled,
    required this.isOnline,
    this.newId = newUuid,
    this.onQueued,
  });

  final SyncStore store;

  /// Where a queued save's photos are kept, as a future: the folder is
  /// opened in the background when the app starts, and a save made in
  /// that first second must wait for it rather than drop its photo.
  final Future<OutboxFiles?> Function()? photos;

  /// The shop the save was made in, so an owner of several shops sends it
  /// against the right one.
  final int shopId;

  /// This account works offline (the add-on, and this phone registered).
  final bool enabled;

  /// What the phone last knew about the network. False sends the save
  /// straight to the outbox instead of waiting for a call to time out in
  /// a basement.
  final bool Function() isOnline;

  final String Function() newId;

  /// Told the moment a save goes to the outbox, so the counts the screens
  /// read catch up with it.
  ///
  /// Without this the Sync centre keeps saying "Everything is sent" while
  /// a day of collecting sits on the phone, the menu badge stays empty,
  /// and 3.4's "your work is safe, N held" says nothing is held — the
  /// one screen whose whole job is to be believed.
  final void Function()? onQueued;

  /// A uuid, for a caller that has to name a record before the server
  /// does. A record made offline keeps this id when it reaches the
  /// server (`Action::adoptUuid`), so the two never drift apart.
  String makeId() => newId();

  /// Tries the server, and queues [action] when there is no signal.
  ///
  /// [send] is the ordinary online call. [data] and [seen] are the action
  /// as `Replayer.php` reads it: [data] the call's own fields, [seen] what
  /// the seller had in front of them, which the server checks before it
  /// applies a money action.
  ///
  /// [alsoHere] writes the change into the phone's copy, so the seller
  /// sees what they just did while it is still waiting.
  Future<Saved<T>> save<T>({
    required String action,
    required Map<String, dynamic> data,
    required Future<ApiResult<T>> Function() send,
    Map<String, dynamic> seen = const {},
    Map<String, File> files = const {},
    String? tempId,
    Future<void> Function(SyncStore store, int shopId)? alsoHere,
  }) async {
    assert(
      SyncActionKeys.all.contains(action),
      '$action is not an outbox action the server replays (§6.2)',
    );
    if (!enabled) {
      return switch (await send()) {
        ApiOk(:final value) => SavedOnServer(value),
        ApiErr(:final failure) => SaveFailed(failure),
      };
    }
    if (isOnline()) {
      switch (await send()) {
        case ApiOk(:final value):
          return SavedOnServer(value);
        case ApiErr(:final failure):
          // Only "there is no signal" is worth keeping. A refusal is the
          // server's answer and sending it again would get the same one;
          // a timeout may mean the server took it, and replaying a
          // payment it already has is exactly what the outbox must not
          // do by itself.
          if (failure.kind != ApiFailureKind.offline) {
            return SaveFailed(failure);
          }
      }
    }
    return _queue(
      action: action,
      fields: data,
      seen: seen,
      files: files,
      tempId: tempId,
      alsoHere: alsoHere,
    );
  }

  /// [save], for an action built with [OfflineAction] (the way feature
  /// screens should queue): the key, `data`, `seen` and photos all come
  /// from the builder, so they are exactly what the server replays.
  ///
  /// ```dart
  /// final a = OfflineAction.orderPayment(orderUuid: o.uuid, amount: 5000,
  ///     method: 'cash', seenPaid: o.paid, receipt: photo);
  /// final saved = await saves.saveAction(a,
  ///     send: () => repo.recordPayment(o.uuid, ...),
  ///     alsoHere: (store, shopId) => store.patchRow('orders', o.id, {...}, shopId: shopId));
  /// ```
  Future<Saved<T>> saveAction<T>(
    OfflineAction action, {
    required Future<ApiResult<T>> Function() send,
    String? tempId,
    Future<void> Function(SyncStore store, int shopId)? alsoHere,
  }) => save(
    action: action.action,
    data: action.data,
    seen: action.seen,
    files: action.files,
    send: send,
    tempId: tempId,
    alsoHere: alsoHere,
  );

  /// Writes the action into the outbox, with its photos copied where they
  /// will still be when it is sent.
  Future<Saved<T>> _queue<T>({
    required String action,
    required Map<String, dynamic> fields,
    required Map<String, dynamic> seen,
    required Map<String, File> files,
    required String? tempId,
    required Future<void> Function(SyncStore store, int shopId)? alsoHere,
  }) async {
    final id = newId();
    final data = fields;
    var kept = const <String, String>{};
    if (files.isNotEmpty) {
      final store = await photos?.call();
      if (store != null) kept = await store.keep(id, files);
    }
    await store.addToOutbox(
      id: id,
      action: action,
      data: data,
      // The time it really happened, not the time it is sent: the
      // server dates the payment, the order and the stock move by it.
      at: DateTime.now(),
      seen: seen,
      files: kept,
      tempId: tempId,
      shopId: shopId,
    );
    try {
      await alsoHere?.call(store, shopId);
    } on Object {
      // The copy not showing it yet is a worse screen, not a lost save:
      // the action is already in the outbox, and the next download
      // brings the server's own version of the row.
    }
    onQueued?.call();
    return SavedHere(id: id, tempId: tempId);
  }
}
