import 'dart:convert';

import 'package:drift/drift.dart';

import 'atom_db.dart';
import 'copy_key.dart';
import 'outbox_db.dart';

/// Reads and writes the phone's copy: the snapshot rows, where sync has
/// reached, and the outbox.
///
/// A snapshot row arrives as the server's own JSON and is kept whole in
/// `copy_rows` (see [AtomDb]), under its table name and `shopId` (the
/// outlet scope the copy is for: the outlet id, or 0 for the whole brand;
/// the name is the outbox file's column, kept so its schema is unchanged).
/// Nothing is mapped column by column, so a new table or field in
/// `GET sync/snapshot` never breaks a sync and needs no generated code.
class SyncStore {
  SyncStore(this.db, this.outbox, {this.userId});

  /// The copy: the server's rows, re-downloadable, key wrapped by the PIN.
  final AtomDb db;

  /// What this phone made and has not sent. A different file and a
  /// different key, so it stays readable when the copy cannot be opened.
  final OutboxDb outbox;

  /// The person signed in. What they save is marked as theirs, and only
  /// theirs is sent, counted or shown. Null (a test) sees everything.
  final int? userId;

  Expression<bool> _mine($OutboxEntriesTable o) {
    final me = userId;
    return me == null
        ? const Constant(true)
        : (o.userId.equals(me) | o.userId.isNull());
  }

  static const _t = AtomDb.table;

  /// When a parent row goes, the rows that hang off it go too (§5):
  /// `{parent: [(child table, the child's key to the parent)]}`.
  static const cascade = <String, List<(String, String)>>{
    'orders': [('order_payments', 'order_id'), ('order_history', 'order_id')],
    'atompay_orders': [
      ('order_payments', 'order_id'),
      ('order_history', 'order_id'),
    ],
    'deals': [('deliveries', 'deal_id'), ('deal_payments', 'deal_id')],
  };

  /// The snapshot's tables (`GET sync/snapshot` → `tables`), in the order
  /// the server walks them. Stock tables come only with the Inventory
  /// add-on and `stock.view`; the rest by role.
  static const tables = [
    'account',
    'outlets',
    'team',
    'products',
    'orders',
    'atompay_orders',
    'order_payments',
    'order_history',
    'bulk_requests',
    'quotes',
    'deals',
    'deliveries',
    'deal_payments',
    'warehouses',
    'stock_products',
    'stock_variants',
    'stock_balances',
    'stock_units',
    'stock_holds',
    'notifications',
  ];

  // ───────────────────────────────────────────────── writing the copy

  /// Upserts one page of [table]. Rows with no id are skipped rather than
  /// failing the whole page.
  Future<int> upsert(
    String table,
    List<Map<String, dynamic>> rows, {
    required int shopId,
  }) async {
    if (rows.isEmpty) return 0;
    var written = 0;
    await db.batch((b) {
      for (final row in rows) {
        final id = _asInt(row['id']);
        if (id == null) continue;
        b.customStatement(
          'INSERT OR REPLACE INTO $_t '
          '(tbl, scope, id, updated_at, temp_id, data) '
          'VALUES (?, ?, ?, ?, ?, ?)',
          [
            table,
            shopId,
            id,
            row['updated_at']?.toString(),
            row['phone_temp_id']?.toString(),
            jsonEncode(row),
          ],
        );
        written++;
      }
    });
    return written;
  }

  /// `"replace": true`: the table comes whole, so this scope's rows are
  /// cleared first.
  Future<int> replaceAll(
    String table,
    List<Map<String, dynamic>> rows, {
    required int shopId,
  }) async {
    await clearTable(table, shopId: shopId);
    return upsert(table, rows, shopId: shopId);
  }

  /// One `deletions` row, and what hangs off it ([cascade]).
  Future<void> deleteRow(String table, int rowId, {required int shopId}) async {
    await db.customStatement(
      'DELETE FROM $_t WHERE tbl = ? AND scope = ? AND id = ?',
      [table, shopId, rowId],
    );
    final children = cascade[table];
    if (children == null || children.isEmpty) return;
    for (final (child, fk) in children) {
      for (final r in await rows(child, shopId: shopId)) {
        final id = _asInt(r['id']);
        if (id != null && _asInt(r[fk]) == rowId) {
          await deleteRow(child, id, shopId: shopId);
        }
      }
    }
  }

  /// How many rows of [table] the copy holds in this scope (the Sync
  /// centre's "On this phone").
  Future<int> count(String table, {required int shopId}) async {
    final r = await db
        .customSelect(
          'SELECT COUNT(*) AS n FROM $_t WHERE tbl = ? AND scope = ?',
          variables: [Variable<String>(table), Variable<int>(shopId)],
        )
        .getSingle();
    return r.read<int>('n');
  }

  /// Every row of a table the person may no longer see, for a scope change.
  Future<void> clearTable(String table, {required int shopId}) =>
      db.customStatement('DELETE FROM $_t WHERE tbl = ? AND scope = ?', [
        table,
        shopId,
      ]);

  /// Merges [changes] into one row the phone already holds (a delivery or
  /// payment saved with no signal, shown at once). The next download
  /// replaces it with the server's own version.
  Future<void> patchRow(
    String table,
    int rowId,
    Map<String, dynamic> changes, {
    required int shopId,
  }) async {
    final current = await row(table, rowId, shopId: shopId);
    if (current == null) return;
    await upsert(table, [
      {...current, ...changes},
    ], shopId: shopId);
  }

  // ───────────────────────────────────────────────── reading the copy

  static const _select =
      'SELECT data FROM $_t WHERE tbl = ? AND scope = ? '
      'ORDER BY updated_at DESC, id DESC';

  /// Every row of [table] in this scope, newest change first.
  Future<List<Map<String, dynamic>>> rows(
    String table, {
    required int shopId,
  }) async {
    final result = await db
        .customSelect(
          _select,
          variables: [Variable<String>(table), Variable<int>(shopId)],
        )
        .get();
    return [for (final r in result) ?_decode(r.read<String>('data'))];
  }

  /// One row, or null.
  Future<Map<String, dynamic>?> row(
    String table,
    int rowId, {
    required int shopId,
  }) async {
    final r = await db
        .customSelect(
          'SELECT data FROM $_t WHERE tbl = ? AND scope = ? AND id = ?',
          variables: [
            Variable<String>(table),
            Variable<int>(shopId),
            Variable<int>(rowId),
          ],
        )
        .getSingleOrNull();
    return r == null ? null : _decode(r.read<String>('data'));
  }

  /// [rows], again whenever the copy is written through this store.
  Stream<List<Map<String, dynamic>>> watchRows(
    String table, {
    required int shopId,
  }) => db
      .customSelect(
        _select,
        variables: [Variable<String>(table), Variable<int>(shopId)],
      )
      .watch()
      .map((rs) => [for (final r in rs) ?_decode(r.read<String>('data'))]);

  static Map<String, dynamic>? _decode(String raw) {
    try {
      final j = jsonDecode(raw);
      return j is Map ? Map<String, dynamic>.from(j) : null;
    } on FormatException {
      return null;
    }
  }

  // ───────────────────────────────────────────────── where sync is

  Future<int> cursor(String table, {required int shopId}) async {
    final row =
        await (outbox.select(outbox.syncCursors)..where(
              (c) => c.shopId.equals(shopId) & c.sourceTable.equals(table),
            ))
            .getSingleOrNull();
    return row?.after ?? 0;
  }

  Future<void> setCursor(String table, int after, {required int shopId}) =>
      outbox
          .into(outbox.syncCursors)
          .insertOnConflictUpdate(
            SyncCursorsCompanion.insert(
              shopId: shopId,
              sourceTable: table,
              after: Value(after),
            ),
          );

  /// A fresh download: every cursor for this shop goes back to the start.
  Future<void> resetCursors({required int shopId}) => (outbox.delete(
    outbox.syncCursors,
  )..where((c) => c.shopId.equals(shopId))).go();

  Future<String?> meta(String name, {required int shopId}) async {
    final row =
        await (outbox.select(outbox.syncMeta)
              ..where((m) => m.shopId.equals(shopId) & m.name.equals(name)))
            .getSingleOrNull();
    return row?.value;
  }

  Future<void> setMeta(String name, String value, {required int shopId}) =>
      outbox
          .into(outbox.syncMeta)
          .insertOnConflictUpdate(
            SyncMetaCompanion.insert(shopId: shopId, name: name, value: value),
          );

  Future<void> deleteMeta(String name, {required int shopId}) => (outbox.delete(
    outbox.syncMeta,
  )..where((m) => m.shopId.equals(shopId) & m.name.equals(name))).go();

  // ───────────────────────────────────────────────── the outbox

  /// Adds a save made on this phone. [id] is the uuid the action keeps for
  /// as long as it lives, so resending never applies it twice.
  Future<void> addToOutbox({
    required String id,
    required String action,
    required Map<String, dynamic> data,
    required DateTime at,
    Map<String, dynamic> seen = const {},
    Map<String, String> files = const {},
    String? tempId,
    int? shopId,
  }) => outbox
      .into(outbox.outboxEntries)
      .insert(
        OutboxEntriesCompanion.insert(
          id: id,
          action: action,
          data: jsonEncode(data),
          at: at,
          seen: Value(jsonEncode(seen)),
          files: Value(jsonEncode(files)),
          tempId: Value(tempId),
          shopId: Value(shopId),
          userId: Value(userId),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  /// The photos one waiting action carries: the server's field name
  /// against the file kept in app storage.
  static Map<String, String> filesOf(OutboxEntry row) {
    try {
      final j = jsonDecode(row.files);
      return j is Map
          ? {
              for (final e in j.entries)
                if (e.value is String) '${e.key}': e.value as String,
            }
          : const {};
    } on FormatException {
      return const {};
    }
  }

  /// What is waiting, oldest first: the order the server must run them in.
  Future<List<OutboxEntry>> waiting({int limit = 100}) =>
      (outbox.select(outbox.outboxEntries)
            ..where(
              (o) => o.state.equalsValue(OutboxEntryState.waiting) & _mine(o),
            )
            ..orderBy([(o) => OrderingTerm(expression: o.seq)])
            ..limit(limit))
          .get();

  /// How many are waiting, for the owner's count on Sync (`unsent`).
  Future<int> waitingCount() async {
    final count = outbox.outboxEntries.seq.count();
    final row =
        await (outbox.selectOnly(outbox.outboxEntries)
              ..addColumns([count])
              ..where(
                outbox.outboxEntries.state.equalsValue(
                      OutboxEntryState.waiting,
                    ) &
                    _mine(outbox.outboxEntries),
              ))
            .getSingle();
    return row.read(count) ?? 0;
  }

  /// What the server would not apply, for Needs attention.
  Future<List<OutboxEntry>> needingAttention() =>
      (outbox.select(outbox.outboxEntries)
            ..where(
              (o) =>
                  o.state.equalsValue(OutboxEntryState.needsAttention) &
                  _mine(o),
            )
            ..orderBy([(o) => OrderingTerm(expression: o.seq)]))
          .get();

  /// Applied: it leaves the outbox, with the answer kept for it.
  Future<void> dropFromOutbox(String id) async {
    await (outbox.delete(
      outbox.outboxEntries,
    )..where((o) => o.id.equals(id))).go();
    await dropAnswer(id);
  }

  /// How many waiting actions carry photos, for the Sync centre's Photos.
  Future<int> waitingPhotos() async {
    final count = outbox.outboxEntries.seq.count();
    final row =
        await (outbox.selectOnly(outbox.outboxEntries)
              ..addColumns([count])
              ..where(
                outbox.outboxEntries.files.isNotValue('{}') &
                    _mine(outbox.outboxEntries),
              ))
            .getSingle();
    return row.read(count) ?? 0;
  }

  /// One outbox row, or null once it has gone.
  Future<OutboxEntry?> entry(String id) => (outbox.select(
    outbox.outboxEntries,
  )..where((o) => o.id.equals(id))).getSingleOrNull();

  // ───────────────────────────────────────────────── the server's answers

  static const _answers = OutboxDb.answersTable;

  /// Keeps the server's whole answer for an action that needs the person:
  /// the conflict screens read `server` and `details` from it.
  Future<void> keepAnswer(String id, Map<String, dynamic> answer) =>
      outbox.customStatement(
        'INSERT OR REPLACE INTO $_answers (id, answer, at) VALUES (?, ?, ?)',
        [id, jsonEncode(answer), DateTime.now().toUtc().toIso8601String()],
      );

  /// The answer kept for [id], or null.
  Future<Map<String, dynamic>?> answerOf(String id) async {
    final r = await outbox
        .customSelect(
          'SELECT answer FROM $_answers WHERE id = ?',
          variables: [Variable<String>(id)],
        )
        .getSingleOrNull();
    return r == null ? null : _decode(r.read<String>('answer'));
  }

  Future<void> dropAnswer(String id) =>
      outbox.customStatement('DELETE FROM $_answers WHERE id = ?', [id]);

  /// Changes a waiting or refused action in place, keeping its place in
  /// the order: the person fixed it (10.4). The server asks for a new id
  /// whenever the data changes (§6.1), so [newId] replaces the old one,
  /// and the row is waiting again.
  Future<bool> revise(
    String id, {
    required String newId,
    String? action,
    required Map<String, dynamic> data,
    Map<String, dynamic>? seen,
  }) async {
    final moved =
        await (outbox.update(
          outbox.outboxEntries,
        )..where((o) => o.id.equals(id))).write(
          OutboxEntriesCompanion(
            id: Value(newId),
            action: action == null ? const Value.absent() : Value(action),
            data: Value(jsonEncode(data)),
            seen: seen == null ? const Value.absent() : Value(jsonEncode(seen)),
            state: const Value(OutboxEntryState.waiting),
            reason: const Value(null),
            message: const Value(null),
            tries: const Value(0),
          ),
        );
    await dropAnswer(id);
    return moved > 0;
  }

  /// Everything this person has not sent, gone: the phone was signed out
  /// by the server (401, revoked, wiped). Only theirs: another person's
  /// rows on a shared phone are not this sign-out's to drop.
  Future<List<String>> forgetOutbox() async {
    final rows = await (outbox.select(
      outbox.outboxEntries,
    )..where(_mine)).get();
    for (final r in rows) {
      await dropFromOutbox(r.id);
    }
    return [for (final r in rows) r.id];
  }

  /// Undo, before it is sent (Waiting to send). Answers false once it has
  /// gone to the server, where undoing is no longer this phone's to do.
  Future<bool> undo(String id) async {
    final gone =
        await (outbox.delete(outbox.outboxEntries)..where(
              (o) =>
                  o.id.equals(id) &
                  o.state.equalsValue(OutboxEntryState.waiting),
            ))
            .go();
    return gone > 0;
  }

  /// The server would not apply it: it waits for the person.
  Future<void> markNeedsAttention(
    String id, {
    String? reason,
    String? message,
  }) => (outbox.update(outbox.outboxEntries)..where((o) => o.id.equals(id)))
      .write(
        OutboxEntriesCompanion(
          state: const Value(OutboxEntryState.needsAttention),
          reason: Value(reason),
          message: Value(message),
          lastTriedAt: Value(DateTime.now()),
        ),
      );

  /// Sent, and the server asked for it again later (`retry: true`).
  Future<void> markTried(String id) async {
    final row = await (outbox.select(
      outbox.outboxEntries,
    )..where((o) => o.id.equals(id))).getSingleOrNull();
    if (row == null) return;
    await (outbox.update(
      outbox.outboxEntries,
    )..where((o) => o.id.equals(id))).write(
      OutboxEntriesCompanion(
        tries: Value(row.tries + 1),
        lastTriedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Discard, from Needs attention: the person gives the change up.
  Future<void> discard(String id) => dropFromOutbox(id);

  /// Try again, from Needs attention: back to waiting, in its old place in
  /// the order. The server runs a refused action again when it is resent
  /// (it only answers from its log for one that was applied), so this is
  /// for a refusal whose cause has gone: the stock came in, the plan was
  /// renewed, the person was given the permission. Answers false when the
  /// row is no longer waiting on the seller.
  Future<bool> retry(String id) async {
    final moved =
        await (outbox.update(outbox.outboxEntries)..where(
              (o) =>
                  o.id.equals(id) &
                  o.state.equalsValue(OutboxEntryState.needsAttention),
            ))
            .write(
              const OutboxEntriesCompanion(
                state: Value(OutboxEntryState.waiting),
                reason: Value(null),
                message: Value(null),
              ),
            );
    if (moved > 0) await dropAnswer(id);
    return moved > 0;
  }

  // ───────────────────────────────────────────────── what this phone did

  /// The next id for a row this phone made before the server named it.
  ///
  /// Negative, counting down. The server's ids are always positive, so
  /// the two can never collide and a row's origin is obvious from its
  /// id alone.
  Future<int> nextLocalId({required int shopId}) async {
    final held = await meta(localIdKey, shopId: shopId);
    final next = (int.tryParse(held ?? '') ?? 0) - 1;
    await setMeta(localIdKey, '$next', shopId: shopId);
    return next;
  }

  static const localIdKey = 'next_local_id';

  /// A row made with no signal (a stock-in, a new product), written into
  /// the copy so it shows straight away. [fields] are the action's own;
  /// the row is this phone's until the server answers, then it goes and
  /// the server's own row replaces it ([dropLocalRow]).
  Future<int> addLocalRow(
    String table, {
    required String tempId,
    required Map<String, dynamic> fields,
    required int shopId,
  }) async {
    final id = await nextLocalId(shopId: shopId);
    await upsert(table, [
      {...fields, 'id': id, 'mine': true, 'phone_temp_id': tempId},
    ], shopId: shopId);
    return id;
  }

  /// The row this phone made has reached the server: it goes, and the
  /// server's own row comes down in the same sync.
  Future<void> dropLocalRow(String tempId, {required int shopId}) =>
      db.customStatement('DELETE FROM $_t WHERE scope = ? AND temp_id = ?', [
        shopId,
        tempId,
      ]);

  /// A date as the server writes one: the day alone, with no zone on it.
  static String day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // ───────────────────────────────────────────────── sealed pages

  /// Keeps a page fetched while the copy was shut. [payload] is already
  /// sealed: nothing readable is stored here.
  Future<void> stagePage(String payload, {required int shopId}) => outbox
      .into(outbox.stagedPages)
      .insert(
        StagedPagesCompanion.insert(
          shopId: shopId,
          payload: payload,
          at: DateTime.now(),
        ),
      );

  /// The pages waiting for [shopId], oldest first: the order they must be
  /// applied in, or an older change would land on top of a newer one.
  Future<List<StagedPage>> stagedPages({required int shopId}) =>
      (outbox.select(outbox.stagedPages)
            ..where((p) => p.shopId.equals(shopId))
            ..orderBy([(p) => OrderingTerm.asc(p.seq)]))
          .get();

  Future<void> dropStaged(int seq) =>
      (outbox.delete(outbox.stagedPages)..where((p) => p.seq.equals(seq))).go();

  /// All of them, for one shop or every shop: the copy started over, or its
  /// scope changed, and pages fetched for the old one mean nothing now.
  Future<void> clearStaged({int? shopId}) {
    final q = outbox.delete(outbox.stagedPages);
    if (shopId != null) q.where((p) => p.shopId.equals(shopId));
    return q.go();
  }

  // ───────────────────────────────────────────────── wipe

  /// Everything this phone holds of the copy, gone. The outbox is kept or
  /// dropped by the caller: a wipe drops it, "offline ended" sends it
  /// first.
  Future<void> clearCopy() async {
    await outbox.transaction(() async {
      await outbox.delete(outbox.syncCursors).go();
      await outbox.delete(outbox.syncMeta).go();
      // Fetched for the copy that is going.
      await outbox.delete(outbox.stagedPages).go();
    });
    try {
      await db.customStatement('DELETE FROM $_t');
    } catch (e) {
      // A wipe or an ended add-on while the phone is locked: the copy
      // can't be opened to empty it, so its file and key go instead.
      // Matched by name as well, in case the database layer wraps it.
      if (e is! CopyLocked && !'$e'.contains('CopyLocked')) rethrow;
      await CopyKey.startOver();
    }
  }

  static int? _asInt(Object? v) => switch (v) {
    int i => i,
    num n => n.toInt(),
    String s => int.tryParse(s) ?? double.tryParse(s)?.toInt(),
    _ => null,
  };
}
