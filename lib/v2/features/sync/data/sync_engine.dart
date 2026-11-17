import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_result.dart';
import '../../../core/db/outbox_db.dart';
import '../../../core/api/atom_server.dart';
import '../../../core/db/copy_photos.dart';
import '../../../core/db/outbox_actions.dart';
import '../../../core/db/outbox_files.dart';
import '../../../core/db/sync_store.dart';
import 'sync_models.dart';
import 'sync_repository.dart';

/// The steps Sending… (10.5) shows, each a kind of outbox action.
enum SyncGroup {
  /// Order steps, deliveries, hand-overs and payments.
  ordersAndPayments,

  /// Bulk deal deliveries and payments, and request statuses.
  bulk,

  /// Stock in, adjustments and transfers.
  stock;

  static SyncGroup of(String action) => switch (action.split('.').first) {
    'deal' || 'bulk' => bulk,
    'stock' => stock,
    _ => ordersAndPayments,
  };
}

/// Where a sync has got to, for the Sync centre (10.1) and the banners.
enum SyncPhase {
  idle,
  checking,

  /// The outbox is going up. The person may keep working.
  sending,

  /// The server's changes are coming down.
  downloading,

  /// The photos that go with them: product pictures, delivery and receipt photos.
  photos,
  done,

  /// It stopped. It carries on later from the same place.
  failed,
}

/// Why a sync stopped without finishing, when the reason changes what the
/// app shows rather than just "try again".
enum SyncStop {
  /// No signal, or the server could not be reached.
  offline,

  /// This phone may not use the app: the copy, the photos and the keys go
  /// (`sync/check` → `wipe`).
  wiped,

  /// Offline working has ended for the account: the outbox goes up, then
  /// the copy is deleted and the app works online only (10.10).
  offlineEnded,

  /// Too old to sync. The outbox is kept and the update is asked for
  /// (10.6); nothing on the phone is lost.
  updateNeeded,

  /// The add-on is off for this account, or this phone is not registered.
  notAllowed,

  /// Something else; [SyncOutcome.message] says what.
  failed,
}

/// What one run did.
@immutable
class SyncOutcome {
  const SyncOutcome({
    required this.ok,
    this.stop,
    this.message,
    this.sent = 0,
    this.needsAttention = 0,
    this.rows = 0,
    this.check,
  });

  final bool ok;
  final SyncStop? stop;
  final String? message;

  /// Outbox rows the server applied.
  final int sent;

  /// Outbox rows it would not apply: they wait for the person.
  final int needsAttention;

  /// Rows written into the copy.
  final int rows;
  final SyncCheck? check;
}

/// What a run is doing, as it goes.
@immutable
class SyncProgress {
  const SyncProgress({
    this.phase = SyncPhase.idle,
    this.sent = 0,
    this.toSend = 0,
    this.table,
    this.rows = 0,
    this.sentBy = const {},
    this.toSendBy = const {},
  });

  /// Applied so far and to send in this run, by [SyncGroup] (10.5's
  /// steps).
  final Map<SyncGroup, int> sentBy;
  final Map<SyncGroup, int> toSendBy;

  final SyncPhase phase;
  final int sent;
  final int toSend;

  /// The snapshot table coming down, for "Getting others' changes".
  final String? table;
  final int rows;

  /// 0–100, for the bar on 10.5. Zero when there is nothing to send.
  int get percent => toSend == 0 ? 0 : ((sent / toSend) * 100).round();
}

/// Sends what this phone made and brings down what changed
/// (`docs/brand-app-sync.md`).
///
/// One run is: ask whether this phone may still work (`sync/check`), send
/// the outbox in the order it was made, then download — the whole snapshot
/// the first time, and only what changed after that. The contract's order
/// matters: sending first means the server's answer already includes this
/// phone's own work.
///
/// Nothing is applied twice. Every outbox row carries a uuid the phone
/// made, and the server answers from its log for an id it has already run,
/// so a sync that dies halfway and starts again costs nothing.
class SyncEngine {
  SyncEngine({
    required this.repository,
    required this.store,
    this.photos,
    this.copyPhotos,
    this.onProgress,
    bool Function()? copyOpen,
    this.copyId,
    this.seal,
    this.openSealed,
    this.storedCopyId,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now,
       _copyOpen = copyOpen ?? _always;

  static bool _always() => true;

  /// Whether the copy's key is open. Shut, the outbox still goes — it has
  /// a key of its own, which is the point of keeping them apart — and the
  /// copy is left for the next run after the PIN or fingerprint opens it.
  final bool Function() _copyOpen;

  /// Which copy file the cursors are for ([copyIdKey]). Null leaves the
  /// check out (a host test, with one in-memory copy for its life).
  final String? Function()? copyId;

  /// The copy the cursors and `since` were written against. They live in
  /// the outbox, which outlives the copy: after an upgrade moved the copy
  /// to its own file, or after it started over under a new key, they
  /// describe rows that are not there any more — and a sync that trusted
  /// them would fetch only changes into an empty copy, so customers who
  /// had not changed would never come down.
  static const copyIdKey = 'copy_id';

  /// Seals a page fetched while the copy is shut, so only the copy's key
  /// can open it (`CopyKey.seal`). With these three null, a shut copy is
  /// simply left for the next run after unlock.
  final Future<String?> Function(String text)? seal;

  /// Opens a sealed page once the copy is open (`CopyKey.openSealed`).
  final Future<String?> Function(String blob)? openSealed;

  /// The copy on the phone, readable while it is shut
  /// (`CopyKey.storedId`): staging only makes sense for the copy the
  /// cursors were written against.
  final Future<String?> Function()? storedCopyId;

  /// One applier at a time, across every engine in the process: the app
  /// opening the copy and a sync starting can both reach for the staged
  /// pages, and two walking them at once could land an older change on a
  /// newer one.
  static Future<void> _staging = Future.value();

  final SyncRepository repository;
  final SyncStore store;

  /// Where the photos of a queued save are kept. Null leaves them out:
  /// the actions still go, and the server's own rules decide whether a
  /// photo was required.
  final OutboxFiles? photos;

  /// Where the photos that come **down** with the copy are kept: faces,
  /// CNICs, product pictures. Null leaves them out; the rows still sync.
  final CopyPhotos? copyPhotos;

  final void Function(SyncProgress)? onProgress;
  final DateTime Function() _now;

  /// At most this many actions a call (§6).
  static const batch = ApiSyncRepository.batch;

  /// How many pages of photos one run will walk.
  static const maxPhotoPages = 40;

  /// Photos fetched together during a sync (see `_photos`).
  static const photosAtOnce = 4;

  /// Meta keys kept per shop.
  static const sinceKey = 'since';

  static const scopeKey = 'scope_key';
  static const lastSyncKey = 'last_sync_at';

  /// The end of this phone's offline window, as `sync/check` gave it.
  static const untilKey = 'offline_until';

  void _say(SyncProgress p) => onProgress?.call(p);

  /// One full run for one shop.
  ///
  /// [shopId] is the shop whose copy this is; an owner of several shops
  /// runs this once per shop, each with its own `X-Outlet`.
  Future<SyncOutcome> run({required int shopId}) async {
    _say(const SyncProgress(phase: SyncPhase.checking));

    final waiting = await store.waitingCount();
    final checked = await repository.check(unsent: waiting);
    if (checked case ApiErr(:final failure)) {
      _say(const SyncProgress(phase: SyncPhase.failed));
      return SyncOutcome(
        ok: false,
        stop:
            failure.kind == ApiFailureKind.offline ||
                failure.kind == ApiFailureKind.timeout
            ? SyncStop.offline
            : SyncStop.failed,
        message: failure.message,
      );
    }
    final check = (checked as ApiOk<SyncCheck>).value;

    // The day this phone stops being allowed to work on its own, kept
    // where a restart can still find it. Without this, a phone that is
    // started with no signal would not know its window had closed, which
    // is exactly the phone 3.4 is for.
    final until = check.offline.until;
    Future<void> keepUntil() async {
      // No date is the server saying offline working is not allowed now.
      // The old date goes: kept, it would close the window again (3.4)
      // on a phone the server has since let off, or stand in for a window
      // the server no longer gives.
      if (until == null) {
        await store.deleteMeta(untilKey, shopId: shopId);
        return;
      }
      await store.setMeta(
        untilKey,
        until.toUtc().toIso8601String(),
        shopId: shopId,
      );
    }

    await keepUntil();

    // 1. This phone may not use the app at all.
    if (check.wipe) {
      await store.clearCopy();
      // The photos go with the rows they belong to.
      await copyPhotos?.forgetAll();
      return SyncOutcome(
        ok: false,
        stop: SyncStop.wiped,
        message: check.reason,
        check: check,
      );
    }

    // 2. Too old to speak to the server: keep everything, ask for the
    //    update (10.6). The outbox is never dropped for this.
    if (check.updateNeeded || check.versionMismatch) {
      return SyncOutcome(ok: false, stop: SyncStop.updateNeeded, check: check);
    }

    // 3. Offline working has ended: send what is waiting, then the copy
    //    goes and the app works online only (10.10). A row that needs the
    //    seller holds the copy until it is sorted.
    if (check.offline.dropCopy || !check.offline.allowed) {
      final pushed = await _push(shopId: shopId);
      if (check.offline.dropCopy && pushed.needsAttention == 0) {
        await store.clearCopy();
        // The photos go with the rows they belong to.
        await copyPhotos?.forgetAll();
      }
      return SyncOutcome(
        ok: pushed.needsAttention == 0,
        stop: check.offline.dropCopy
            ? SyncStop.offlineEnded
            : SyncStop.notAllowed,
        sent: pushed.sent,
        needsAttention: pushed.needsAttention,
        check: check,
      );
    }

    // The copy is shut (the phone is locked, or the PIN has not opened it
    // since the app started): send what is waiting, and leave the copy as
    // it is. Nothing on a locked phone should be waiting on a download,
    // and a sale made yesterday should not wait on the PIN to reach the
    // server.
    if (!_copyOpen()) {
      final pushed = await _push(shopId: shopId);
      if (pushed.stop != null) return pushed;
      // What changed is still fetched, sealed, and kept for the moment the
      // copy opens — so a phone unlocked in a basement is as current as
      // its last signal, not as its last unlock.
      final staged = await _stage(shopId: shopId, check: check);
      return SyncOutcome(
        ok: pushed.needsAttention == 0,
        sent: pushed.sent,
        needsAttention: pushed.needsAttention,
        rows: staged,
        check: check,
      );
    }

    // Pages fetched while the copy was shut go in first, in order, so the
    // download below carries on from where they left off. Pages that
    // can't be opened were for another copy: their cursors are worthless,
    // and the copy is rebuilt.
    final stagedOk = await applyStaged(shopId: shopId);

    // 4. The person's role, scope or shops changed: the copy is built
    //    again from the server rather than patched.
    final held = await store.meta(scopeKey, shopId: shopId);
    final copyId = this.copyId?.call();
    final newCopy =
        copyId != null && await store.meta(copyIdKey, shopId: shopId) != copyId;
    final scopeChanged =
        !stagedOk ||
        newCopy ||
        (check.scopeKey != null && held != check.scopeKey);
    if (scopeChanged) {
      await store.clearCopy();
      // The photos go with the rows they belong to.
      await copyPhotos?.forgetAll();
      await store.resetCursors(shopId: shopId);
      // The clear takes the meta with it, and the window was written
      // before it. Put it back, or the phone forgets when it must come
      // up for air — and the *first* sync is always a scope change, so
      // without this a brand-new copy has no window at all and 3.4 can
      // never stop it.
      await keepUntil();
    }

    // 5. The outbox first, so what comes down already holds this phone's
    //    own work.
    final pushed = await _push(shopId: shopId);
    if (pushed.stop != null) return pushed;

    // 6. Then the download: everything the first time, the rest after.
    final since = scopeChanged
        ? null
        : await store.meta(sinceKey, shopId: shopId);
    final pulled = await _pull(shopId: shopId, since: since);
    if (pulled.stop != null) {
      return SyncOutcome(
        ok: false,
        stop: pulled.stop,
        message: pulled.message,
        sent: pushed.sent,
        needsAttention: pushed.needsAttention,
        rows: pulled.rows,
        check: check,
      );
    }

    // 7. The photos on the rows that just came down. Last, and never
    //    fatal: a copy with every row and no photos is worth far more
    //    than no copy, and the next run picks up what is missing.
    await _photos(shopId: shopId, since: since);

    if (check.scopeKey case final k?) {
      await store.setMeta(scopeKey, k, shopId: shopId);
    }
    if (copyId != null) await store.setMeta(copyIdKey, copyId, shopId: shopId);
    await store.setMeta(lastSyncKey, _now().toIso8601String(), shopId: shopId);

    _say(
      SyncProgress(
        phase: SyncPhase.done,
        sent: pushed.sent,
        toSend: pushed.sent,
      ),
    );
    return SyncOutcome(
      ok: true,
      sent: pushed.sent,
      needsAttention: pushed.needsAttention,
      rows: pulled.rows,
      check: check,
    );
  }

  // ───────────────────────────────────────────────── the photos down

  /// Downloads the photos the copy's rows point at.
  ///
  /// Only the ones not already here. A photo is kept under the address
  /// the screens ask for, so a screen that has a photo's address finds
  /// the downloaded one without knowing anything about sync.
  ///
  /// Nothing here can fail a sync. A phone on a thin connection gets its
  /// rows and some of its photos; the rest come next time.
  Future<int> _photos({required int shopId, String? since}) async {
    final store = copyPhotos;
    if (store == null) return 0;
    _say(const SyncProgress(phase: SyncPhase.photos));

    var got = 0;
    String? table;
    var after = 0;
    final from = since == null ? null : DateTime.tryParse(since);

    // A ceiling, so one run cannot sit downloading for ever on a shop
    // with years of photos. The next run carries on from the rows that
    // are still missing one.
    for (var page = 0; page < maxPhotoPages; page++) {
      final listed = await repository.files(
        table: table,
        after: after,
        since: from,
      );
      if (listed case ApiErr()) return got;
      final answer = (listed as ApiOk<SyncFilePage>).value;

      // The ones still to fetch: not here, and not a photo the server
      // said it does not have (asked again after a week, not every sync).
      final wanted = <(String, String)>[];
      for (final file in answer.files) {
        final url = AtomServer.fileUrl(file.path);
        if (url == null || file.url.isEmpty) continue;
        if (await store.has(url) || await store.knownMissing(url)) continue;
        wanted.add((url, file.url));
      }

      // [photosAtOnce] at a time: one after another kept the radio up
      // for the whole first sync, four is what a phone line carries well.
      for (var i = 0; i < wanted.length; i += photosAtOnce) {
        final batch = wanted.skip(i).take(photosAtOnce);
        final lost = await Future.wait([
          for (final (url, from) in batch)
            () async {
              final bytes = await repository.fetchFile(from);
              switch (bytes) {
                case ApiOk(:final value):
                  if (await store.put(url, value)) got++;
                  return false;
                case ApiErr(:final failure)
                    when failure.kind == ApiFailureKind.notFound:
                  await store.markMissing(url);
                  return false;
                case ApiErr(:final failure):
                  return failure.kind == ApiFailureKind.offline ||
                      failure.kind == ApiFailureKind.timeout;
              }
            }(),
        ]);
        // The signal went while fetching: stop, keep what landed.
        if (lost.contains(true)) return got;
      }

      if (!answer.hasMore) break;
      table = answer.nextTable;
      after = answer.nextAfter ?? 0;
    }
    return got;
  }

  // ───────────────────────────────────────────────── the outbox up

  /// Sends what is waiting, oldest first, in batches.
  ///
  /// It stops at the first batch that cannot be sent; what is left waits
  /// for the next run, still in order.
  Future<SyncOutcome> _push({required int shopId}) async {
    var sent = 0;
    var attention = 0;
    final total = await store.waitingCount();
    if (total == 0) return const SyncOutcome(ok: true);

    final toSendBy = <SyncGroup, int>{};
    for (final r in await store.waiting(limit: 1000)) {
      final g = SyncGroup.of(r.action);
      toSendBy[g] = (toSendBy[g] ?? 0) + 1;
    }
    final sentBy = <SyncGroup, int>{};
    SyncProgress now() => SyncProgress(
      phase: SyncPhase.sending,
      sent: sent,
      toSend: total,
      sentBy: Map.unmodifiable(sentBy),
      toSendBy: Map.unmodifiable(toSendBy),
    );
    _say(now());

    while (true) {
      final rows = await store.waiting(limit: batch);
      if (rows.isEmpty) break;
      final byId = {for (final r in rows) r.id: r};

      final answer = await repository.send(
        [for (final r in rows) _actionOf(r)],
        files: _photosOf(rows),
        unsent: await store.waitingCount(),
      );
      if (answer case ApiErr(:final failure)) {
        _say(SyncProgress(phase: SyncPhase.failed, sent: sent, toSend: total));
        return SyncOutcome(
          ok: false,
          stop:
              failure.kind == ApiFailureKind.offline ||
                  failure.kind == ApiFailureKind.timeout
              ? SyncStop.offline
              : SyncStop.failed,
          message: failure.message,
          sent: sent,
          needsAttention: attention,
        );
      }

      final results = (answer as ApiOk<OutboxSent>).value.results;
      // No answer for anything sent: stop rather than loop on the same
      // rows for ever.
      if (results.isEmpty) break;

      var moved = 0;
      for (final r in results) {
        final row = byId[r.id];
        // An answer for something this batch didn't send: not ours to act
        // on (a bad id the server couldn't read back).
        if (row == null) continue;
        switch (r.status) {
          case OutboxStatus.done:
          case OutboxStatus.doneWithChanges:
            // `changes` (auto numbers) is not written into the local row
            // here: the download right after brings the server's own
            // version of every row it touched.
            await store.dropFromOutbox(r.id);
            // Its photos go with it. A row that needs attention keeps
            // them: the person may fix it and send it again.
            await photos?.forget(r.id);
            // A record this phone made before the server named it: the
            // stand-in row goes, and the server's own comes down in the
            // download that follows. The brand server doesn't echo the
            // temp id, so it is read from the row that was sent.
            if (row.tempId case final temp?) {
              await store.dropLocalRow(temp, shopId: shopId);
            }
            sent++;
            moved++;
            final g = SyncGroup.of(row.action);
            sentBy[g] = (sentBy[g] ?? 0) + 1;
          case OutboxStatus.needsAttention:
            // The server's word on it, whole: `retry` can be missing on
            // an old answer, so the reason decides too.
            if (r.retry || SyncReasons.retry.contains(r.reason)) {
              await store.markTried(r.id);
            } else {
              await store.markNeedsAttention(
                r.id,
                reason: r.reason,
                message: r.message,
              );
              await store.keepAnswer(r.id, r.raw);
              attention++;
              moved++;
            }
        }
        _say(now());
      }

      // Everything in this batch was told to try again later: sending more
      // now would only repeat it.
      if (moved == 0) break;
    }

    return SyncOutcome(ok: true, sent: sent, needsAttention: attention);
  }

  /// The photos this batch carries, by action id then field. A file that
  /// has gone from the phone is left out rather than stopping the batch.
  Map<String, Map<String, File>> _photosOf(List<OutboxEntry> rows) {
    final store = photos;
    if (store == null) return const {};
    final out = <String, Map<String, File>>{};
    for (final row in rows) {
      final paths = SyncStore.filesOf(row);
      if (paths.isEmpty) continue;
      final files = store.read(paths);
      if (files.isNotEmpty) out[row.id] = files;
    }
    return out;
  }

  OutboxAction _actionOf(OutboxEntry row) => OutboxAction(
    id: row.id,
    action: row.action,
    data: _json(row.data),
    seen: _json(row.seen),
    at: row.at,
    tempId: row.tempId,
    shopId: row.shopId,
  );

  static Map<String, dynamic> _json(String raw) {
    try {
      final v = jsonDecode(raw);
      return v is Map<String, dynamic> ? v : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  // ───────────────────────────────────────────────── the copy down

  /// Walks the tables, page by page, writing each into the copy.
  ///
  /// [since] null is the first download (`sync/snapshot`); otherwise only
  /// what changed (`sync/changes`). Either way the cursor of each table is
  /// kept, so a run that stops carries on from the same place.
  Future<SyncOutcome> _pull({
    required int shopId,
    required String? since,
    Future<int> Function(SyncPage page, int after)? sink,
    bool changesOnly = false,
  }) async {
    final initial = since == null;
    final when = initial ? null : DateTime.tryParse(since);
    // Staging fetches changes only: a whole snapshot is for an open copy.
    if (changesOnly && (initial || when == null)) {
      return const SyncOutcome(ok: true);
    }
    if (!initial && when == null) {
      // An unreadable `since` would ask the server for everything since
      // the epoch: start again properly instead.
      await store.resetCursors(shopId: shopId);
      return _pull(shopId: shopId, since: null);
    }

    String? table;
    var after = 0;
    var rows = 0;
    String? nextSince;

    while (true) {
      _say(
        SyncProgress(phase: SyncPhase.downloading, table: table, rows: rows),
      );

      final answer = initial
          ? await repository.snapshot(table: table, after: after)
          : await repository.changes(since: when!, table: table, after: after);

      if (answer case ApiErr(:final failure)) {
        _say(SyncProgress(phase: SyncPhase.failed, rows: rows));
        return SyncOutcome(
          ok: false,
          stop: switch (failure.kind) {
            ApiFailureKind.offline ||
            ApiFailureKind.timeout => SyncStop.offline,
            // 403 feature_off: the add-on ended between the check and now.
            ApiFailureKind.featureOff => SyncStop.notAllowed,
            _ => SyncStop.failed,
          },
          message: failure.message,
          rows: rows,
        );
      }

      final page = (answer as ApiOk<SyncPage>).value;

      // The first page's time is what the next run asks from. Taking a
      // later page's would skip whatever changed while this one ran.
      //
      // Kept as UTC: the times come back through `AtomDates.parse`, which
      // moves them to the phone's own zone for showing. Writing that out
      // gives a string with no zone on it, which the server would then
      // read in ITS zone — so a phone set to another zone would ask from
      // the wrong moment and never see those changes again.
      nextSince ??= (initial ? page.serverTime : page.nextSince)
          ?.toUtc()
          .toIso8601String();

      rows += sink != null
          ? await sink(page, after)
          : await _apply(page, shopId: shopId, after: after);

      if (page.table.isNotEmpty) {
        await store.setCursor(
          page.table,
          page.nextTable == page.table ? (page.nextAfter ?? after) : 0,
          shopId: shopId,
        );
      }

      if (!page.hasMore) break;
      table = page.nextTable;
      after = page.nextTable == page.table ? (page.nextAfter ?? 0) : 0;
    }

    if (nextSince != null) {
      await store.setMeta(sinceKey, nextSince, shopId: shopId);
    }
    return SyncOutcome(ok: true, rows: rows);
  }

  /// Fetches what changed while the copy is shut, and keeps it sealed.
  ///
  /// Only plain changes on top of the copy the phone has: a changed scope,
  /// a different copy, or no copy yet all need the copy open, and are left
  /// for the run after unlock.
  Future<int> _stage({required int shopId, required SyncCheck check}) async {
    final seal = this.seal;
    final storedCopyId = this.storedCopyId;
    if (seal == null || storedCopyId == null) return 0;
    final held = await store.meta(scopeKey, shopId: shopId);
    if (check.scopeKey != null && held != check.scopeKey) {
      debugPrint('[sync] copy shut: scope changed, left for the unlock');
      return 0;
    }
    final id = await storedCopyId();
    if (id == null || await store.meta(copyIdKey, shopId: shopId) != id) {
      debugPrint('[sync] copy shut: not the copy the cursors are for ($id)');
      return 0;
    }
    final since = await store.meta(sinceKey, shopId: shopId);
    if (since == null) return 0;
    try {
      final pulled = await _pull(
        shopId: shopId,
        since: since,
        changesOnly: true,
        sink: (page, after) async {
          // The PIN opened the copy part-way through: stop sealing. What
          // is kept goes in now, and the rest is fetched straight into
          // the copy by the next run.
          if (_copyOpen()) throw const _CopyOpened();
          final sealed = await seal(
            jsonEncode({
              'table': page.table,
              'rows': page.rows,
              'replace': page.replace,
              'after': after,
            }),
          );
          // No sealing key: stop here. The cursor has not moved for this
          // page, so the next run fetches it again.
          if (sealed == null) throw const _CantSeal();
          await store.stagePage(sealed, shopId: shopId);
          return page.rows.length;
        },
      );
      debugPrint('[sync] copy shut: ${pulled.rows} changed rows kept sealed');
      return pulled.rows;
    } on _CantSeal {
      debugPrint('[sync] copy shut: no sealing key, nothing kept');
      return 0;
    } on _CopyOpened {
      debugPrint('[sync] the copy opened while sealing: applying now');
      await applyStaged(shopId: shopId);
      return 0;
    }
  }

  /// Applies the pages fetched while the copy was shut, oldest first, and
  /// drops each once it is in. Needs no network: it runs the moment the
  /// PIN opens the copy, so a seller with no signal still sees what came
  /// down in the background.
  ///
  /// False when a page could not be opened — sealed to a copy that is not
  /// this one. Those pages go, and the copy is marked to be rebuilt from a
  /// snapshot, because the cursors moved past what they held.
  Future<bool> applyStaged({required int shopId}) {
    final run = _staging.then((_) => _applyStaged(shopId));
    _staging = run.then((_) {}, onError: (_) {});
    return run;
  }

  Future<bool> _applyStaged(int shopId) async {
    final open = openSealed;
    if (open == null || !_copyOpen()) return true;
    final pages = await store.stagedPages(shopId: shopId);
    if (pages.isNotEmpty) {
      debugPrint('[sync] applying ${pages.length} sealed pages');
    }
    for (final p in pages) {
      final text = await open(p.payload);
      if (text == null) {
        await store.clearStaged(shopId: shopId);
        await store.setMeta(copyIdKey, 'stale', shopId: shopId);
        return false;
      }
      final j = jsonDecode(text) as Map<String, dynamic>;
      final page = SyncPage(
        table: j['table'] as String? ?? '',
        rows: [
          for (final r in j['rows'] as List? ?? const [])
            Map<String, dynamic>.from(r as Map),
        ],
        replace: j['replace'] == true,
      );
      await _apply(page, shopId: shopId, after: j['after'] as int? ?? 0);
      await store.dropStaged(p.seq);
    }
    return true;
  }

  /// One page into the copy.
  Future<int> _apply(
    SyncPage page, {
    required int shopId,
    required int after,
  }) async {
    if (page.isDeletions) {
      for (final d in page.deletions) {
        await store.deleteRow(d.table, d.rowId, shopId: shopId);
      }
      return page.rows.length;
    }
    // `replace` tables come whole. Only the first page clears what is
    // there, or page two would wipe page one.
    if (page.replace && after == 0) {
      return store.replaceAll(page.table, page.rows, shopId: shopId);
    }
    return store.upsert(page.table, page.rows, shopId: shopId);
  }
}

/// Staging stopped: there is no key to seal with yet.
class _CantSeal implements Exception {
  const _CantSeal();
}

/// Staging stopped: the copy opened, so pages go into it directly now.
class _CopyOpened implements Exception {
  const _CopyOpened();
}
