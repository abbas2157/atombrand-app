import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'copy_key.dart';

/// The phone's copy of the brand's rows, for the Offline add-on.
///
/// Written by hand, with no generated code: one table, `copy_rows`, holds
/// every snapshot row as the server's own JSON, keyed by the snapshot's
/// table name, the outlet scope the copy is for and the row's id. So a new
/// table in `GET sync/snapshot` needs no change here, and nothing has to
/// be regenerated when the brand sync contract grows. Screens read rows
/// back through `SyncStore.rows` / `SyncStore.row` and parse them with the
/// same `fromJson` they use for API answers.
///
/// Only the copy. What this phone has made and not sent lives next door
/// in `OutboxDb`, with a key of its own: this can always be downloaded
/// again, a day of deliveries cannot.
class AtomDb extends GeneratedDatabase {
  AtomDb(super.e);

  /// Opens the phone's encrypted copy.
  AtomDb.open() : super(_openEncrypted());

  static const table = 'copy_rows';

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  Iterable<DatabaseSchemaEntity> get allSchemaEntities => const [];

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await customStatement(
        'CREATE TABLE IF NOT EXISTS $table ('
        'tbl TEXT NOT NULL, '
        'scope INTEGER NOT NULL, '
        'id INTEGER NOT NULL, '
        'updated_at TEXT, '
        'temp_id TEXT, '
        'data TEXT NOT NULL, '
        'PRIMARY KEY (tbl, scope, id))',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS copy_rows_temp ON $table (temp_id)',
      );
    },
  );

  /// Everything the copy holds, gone: a wipe, a revoke, or signing out.
  /// The key goes with it, so what is left on disk cannot be read.
  Future<void> wipe() async {
    await customStatement('DELETE FROM $table');
    await CopyKey.forget();
  }
}

/// The copy's file, opened with its own SQLCipher key.
///
/// On its own isolate (`createInBackground`): a sync writes hundreds of
/// rows at a time, and every read and write is decrypted, so on this
/// isolate it would hold up frames while the seller scrolls. The key is
/// a plain string, so it crosses to that isolate as it is.
QueryExecutor _openEncrypted() => LazyDatabase(() async {
  // Throws CopyLocked while the PIN has not opened it: nothing should ask
  // before then (the providers wait for CopyKey.opened).
  final key = await CopyKey.read();
  final file = await CopyKey.file();
  return NativeDatabase.createInBackground(
    file,
    setup: (db) {
      // A raw 32-byte key: SQLCipher takes it as it is instead of
      // stretching a passphrase on every open.
      db.execute("PRAGMA key = \"x'$key'\";");
      db.execute('PRAGMA foreign_keys = ON;');
      // The app and a background run never mean to write at once (see
      // BackgroundSync); if they ever do, the second waits for the first
      // rather than failing with "database is locked".
      db.execute('PRAGMA busy_timeout = 5000;');
    },
  );
});
