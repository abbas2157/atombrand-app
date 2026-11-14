import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'db_key.dart';

part 'outbox_db.g.dart';

/// What an outbox row is waiting for.
enum OutboxEntryState {
  /// Not sent yet, or sent and told to try again (`retry: true`).
  waiting,

  /// The server would not apply it: the seller fixes or discards it
  /// (Needs attention, §6.1 of the sync contract).
  needsAttention,
}

/// Saves made on this phone, in the order they were made (§6).
///
/// [id] is a uuid made here, so sending the same row twice never runs the
/// action twice: the server answers from its log instead.
class OutboxEntries extends Table {
  /// The order the rows are sent in.
  IntColumn get seq => integer().autoIncrement()();

  TextColumn get id => text().unique()();
  TextColumn get action => text()();

  /// The action's fields, as JSON.
  TextColumn get data => text()();

  /// What the seller saw, for the server's money checks (§6.3).
  TextColumn get seen => text().withDefault(const Constant('{}'))();

  /// The photos the action carries, as JSON: the server's field name
  /// (`instalment_pictrue`, `id_card_front_side`, …) against a file kept
  /// in the app's own storage. The camera's file is copied there when the
  /// action is queued, so a save still has its photo days later.
  TextColumn get files => text().withDefault(const Constant('{}'))();

  /// The real time of the action, not of the sending.
  DateTimeColumn get at => dateTime()();

  /// This phone's temporary id for the record the action makes.
  TextColumn get tempId => text().nullable()();

  /// The shop it was done in, for an owner of several shops.
  IntColumn get shopId => integer().nullable()();

  /// Who made it. The server applies an action as whoever owns the token
  /// it comes with, so a payment taken by one seller must never go up
  /// under the next one to sign in on this phone. Null on rows made before
  /// this was kept; they count as the signed-in person's.
  IntColumn get userId => integer().nullable()();

  IntColumn get state =>
      intEnum<OutboxEntryState>().withDefault(const Constant(0))();

  /// Why the server would not apply it (`seen_changed`, `changed`, …).
  TextColumn get reason => text().nullable()();
  TextColumn get message => text().nullable()();

  /// How many times it has been sent, so a row that keeps failing can be
  /// held back rather than tried in a loop.
  IntColumn get tries => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastTriedAt => dateTime().nullable()();
}

/// How far the phone has read each table of the snapshot or the changes,
/// per shop: an owner of several shops downloads each one.
class SyncCursors extends Table {
  IntColumn get shopId => integer()();

  /// A snapshot table name (`customers`, `orders`, … or `deletions`).
  /// Not `tableName`: drift keeps that name for the SQL table's own.
  TextColumn get sourceTable => text()();

  /// The last row id this phone has of that table.
  IntColumn get after => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {shopId, sourceTable};
}

/// The rest of the sync state, per shop: `since`, the scope key, when the
/// last sync finished, and how long this phone may stay away (11.6).
///
/// Key and value rather than columns, because what sync keeps track of is
/// still settling and a new key should not need a migration.
class SyncMeta extends Table {
  IntColumn get shopId => integer()();
  TextColumn get name => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {shopId, name};
}

/// Changes downloaded while the copy was shut behind the PIN, waiting to
/// be applied when it opens.
///
/// A locked phone can't write the copy (its key is wrapped by the PIN),
/// but it can still fetch what changed — in the background, or with the
/// app open and the lock up. Each page is **sealed** before it is kept:
/// encrypted to the copy's public key, which anyone may hold, so that
/// only the private key — unwrapped by the PIN — can open it. Kept here,
/// in the file a locked phone can write, it reveals nothing without the
/// PIN; when the PIN opens the copy the pages are applied in order and
/// dropped, so the copy is current the moment it opens, with or without
/// a signal.
class StagedPages extends Table {
  IntColumn get seq => integer().autoIncrement()();
  IntColumn get shopId => integer()();

  /// `s1:<ephemeral public key>:<nonce>:<cipher text>:<mac>`, each base64.
  TextColumn get payload => text()();
  DateTimeColumn get at => dateTime()();
}

/// What this phone made and has not sent yet.
///
/// Its own file, and its own key, **separate from the copy** — because
/// the two are worth different things. The copy is the server's rows and
/// can always be downloaded again; the outbox is a day of collecting that
/// exists nowhere else yet. So the copy's key is wrapped by the PIN
/// (`RULES.md` §5) and this one is not: a seller who forgets their PIN
/// loses a download, never their work.
///
/// It keeps the old `atom.db` file, so nothing that was already queued
/// has to be moved to get here.
@DriftDatabase(tables: [OutboxEntries, SyncCursors, SyncMeta, StagedPages])
class OutboxDb extends _$OutboxDb {
  OutboxDb(super.e);

  OutboxDb.open() : super(_openOutbox());

  /// Carries on from the single database's 3: this file was that one, and
  /// a lower number would look like a downgrade.
  @override
  int get schemaVersion => 8;

  /// The server's whole answer for an action that needs the person
  /// (`reason`, `message`, `server`, `details`, `conflict`), by action id.
  /// Written by hand like the copy's table, so the generated code stays
  /// as it is: the conflict screens need `details.serials` and `server`,
  /// which the row's own columns have no room for.
  static const answersTable = 'outbox_answers';

  Future<void> _createAnswers() => customStatement(
    'CREATE TABLE IF NOT EXISTS $answersTable ('
    'id TEXT NOT NULL PRIMARY KEY, '
    'answer TEXT NOT NULL, '
    'at TEXT NOT NULL)',
  );

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createAnswers();
    },
    onUpgrade: (m, from, to) async {
      // 8: the server's answer for each action that needs attention.
      if (from < 8) await _createAnswers();
      if (from < 2) await m.addColumn(outboxEntries, outboxEntries.files);
      // 4: the copy moved to its own file. Its old tables are left where
      // they are rather than dropped — an upgrade that half-finishes must
      // never be the thing that loses the outbox beside them. They are
      // dead weight on disk and nothing reads them.
      // 5: changes fetched while the copy was shut, sealed.
      if (from < 5) await m.createTable(stagedPages);
      // 6: who made each action.
      if (from < 6) await m.addColumn(outboxEntries, outboxEntries.userId);
      // 7: instalment months were kept as null (the server's "3rd Month"
      // went into a number column whole), so the offline screens said
      // "0th Month". The copy forgets where it had read to, and the next
      // sync brings every row down again with its month. Nothing of this
      // phone's own (the outbox) is touched.
      if (from < 7) {
        await delete(syncCursors).go();
        await (delete(syncMeta)..where((m) => m.name.equals('since'))).go();
      }
    },
  );

  /// Everything this phone has not sent, gone: a wipe or a revoke.
  Future<void> wipe() async {
    await transaction(() async {
      for (final t in allTables) {
        await delete(t).go();
      }
      await customStatement('DELETE FROM $answersTable');
    });
  }
}

/// The outbox file, opened with the phone's own key.
///
/// The same key as before the split, so a phone upgrading opens the file
/// it already had, with the rows it already had in it.
QueryExecutor _openOutbox() => LazyDatabase(() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'atom.db'));
  // With the file passed, an unreadable key is refused, never replaced.
  final key = await DbKey.readOrCreate(file: file);
  // On its own isolate, like the copy: saving and sending never hold up a
  // frame.
  return NativeDatabase.createInBackground(
    file,
    setup: (db) {
      db.execute("PRAGMA key = \"x'$key'\";");
      db.execute('PRAGMA foreign_keys = ON;');
      // The app and a background run never mean to write at once (see
      // BackgroundSync); if they ever do, the second waits for the first
      // rather than failing with "database is locked".
      db.execute('PRAGMA busy_timeout = 5000;');
    },
  );
});
