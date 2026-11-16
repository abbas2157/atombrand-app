import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/format/dates.dart';

/// The brand sync contract (`docs/brand-app-sync.md`, Offline add-on).
///
/// The format the app speaks. The server answers `sync_version` with every
/// call; a higher number means the phone must update before syncing.
const syncVersion = 1;

/// How long this phone may work without reaching the server
/// (`sync/check` → `offline`).
@immutable
class OfflineWindow {
  const OfflineWindow({
    this.allowed = false,
    this.until,
    this.days = 0,
    this.addon = 'off',
    this.dropCopy = false,
    this.deviceRegistered = false,
  });

  /// The brand has the add-on, a plan, and this phone is registered.
  final bool allowed;

  /// The earliest of 30 days, the plan's paid-until and the add-on's end.
  final DateTime? until;
  final int days;

  /// `off`, `trial`, `active` or `lapsed`.
  final String addon;

  /// The copy is no longer allowed: send the outbox, then delete it.
  final bool dropCopy;
  final bool deviceRegistered;

  factory OfflineWindow.fromJson(Object? raw) {
    final j = Json.map(raw);
    return OfflineWindow(
      allowed: Json.flag(j['allowed']),
      until: AtomDates.parse(j['until']),
      days: Json.integer(j['days']) ?? 0,
      addon: Json.str(j['addon']) ?? 'off',
      dropCopy: Json.flag(j['drop_copy']),
      deviceRegistered: Json.flag(j['device_registered']),
    );
  }
}

/// One phone signed in (`sync/check` → `device`, `GET devices`).
@immutable
class SyncDevice {
  const SyncDevice({
    required this.id,
    this.name,
    this.platform,
    this.appVersion,
    this.thisDevice = false,
    this.signedIn = true,
    this.lastSeenAt,
    this.lastSyncAt,
    this.offlineUntil,
    this.unsent = 0,
    this.revokedAt,
  });

  final int id;
  final String? name;

  /// `android` or `ios`.
  final String? platform;
  final String? appVersion;
  final bool thisDevice;
  final bool signedIn;
  final DateTime? lastSeenAt;
  final DateTime? lastSyncAt;
  final DateTime? offlineUntil;

  /// Changes saved on that phone and not sent: lost if it is signed out.
  final int unsent;
  final DateTime? revokedAt;

  SyncDevice copyWith({DateTime? lastSyncAt}) => SyncDevice(
    id: id,
    name: name,
    platform: platform,
    appVersion: appVersion,
    thisDevice: thisDevice,
    signedIn: signedIn,
    lastSeenAt: lastSeenAt,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    offlineUntil: offlineUntil,
    unsent: unsent,
    revokedAt: revokedAt,
  );

  factory SyncDevice.fromJson(Object? raw) {
    final j = Json.map(raw);
    return SyncDevice(
      id: Json.integer(j['id']) ?? 0,
      name: Json.str(j['name']),
      platform: Json.str(j['platform']),
      appVersion: Json.str(j['app_version']),
      thisDevice: Json.flag(j['this_device']),
      signedIn: j['signed_in'] == null || Json.flag(j['signed_in']),
      lastSeenAt: AtomDates.parse(j['last_seen_at']),
      lastSyncAt: AtomDates.parse(j['last_sync_at']),
      offlineUntil: AtomDates.parse(j['offline_until']),
      unsent: Json.integer(j['unsent_count']) ?? 0,
      revokedAt: AtomDates.parse(j['revoked_at']),
    );
  }
}

/// A team member's phones, for the owner (`GET devices` → `team`).
@immutable
class TeamPhones {
  const TeamPhones({
    required this.memberId,
    required this.name,
    this.devices = const [],
  });

  final int memberId;
  final String name;
  final List<SyncDevice> devices;

  factory TeamPhones.fromJson(Object? raw) {
    final j = Json.map(raw);
    return TeamPhones(
      memberId: Json.integer(j['member_id']) ?? 0,
      name: Json.str(j['name']) ?? '',
      devices: [
        for (final d in Json.list(j['devices'])) SyncDevice.fromJson(d),
      ],
    );
  }
}

/// `GET devices`: this person's phones and, for the owner, the team's.
@immutable
class PhonesSignedIn {
  const PhonesSignedIn({this.mine = const [], this.team = const []});

  final List<SyncDevice> mine;
  final List<TeamPhones> team;

  factory PhonesSignedIn.fromJson(Object? data) {
    final d = Json.map(data);
    return PhonesSignedIn(
      mine: [for (final x in Json.list(d['devices'])) SyncDevice.fromJson(x)],
      team: [for (final t in Json.list(d['team'])) TeamPhones.fromJson(t)],
    );
  }
}

/// `GET sync/check`: the light call on every open and every few minutes.
///
/// It answers even when the person may no longer use the app, so [wipe]
/// and [allowed] are read before anything else. The first check with a
/// `device_id` registers the phone.
@immutable
class SyncCheck {
  const SyncCheck({
    required this.allowed,
    required this.wipe,
    this.reason,
    this.offline = const OfflineWindow(),
    this.planState,
    this.paidUntil,
    this.readOnly = false,
    this.outletIds,
    this.scopeKey,
    this.serverTime,
    this.updateNeeded = false,
    this.latestVersion,
    this.minVersion,
    this.version = syncVersion,
    this.device,
    this.isOwner = false,
  });

  /// False: this phone may not use the app. With [wipe], the copy, the
  /// photos and the keys go first, and the person sees [reason] (3.5).
  final bool allowed;
  final bool wipe;
  final String? reason;
  final OfflineWindow offline;

  /// Billing's state (`none`, `ok`, `due`, `late`, `overdue`, `readonly`),
  /// null when billing has never touched the brand.
  final String? planState;
  final DateTime? paidUntil;

  /// Changes are refused (late bill, or restricted by Atomshop). Payments
  /// still go through.
  final bool readOnly;

  /// The outlets the copy covers; null is every outlet.
  final List<int>? outletIds;

  /// The person's role, permissions or outlets. A different key means the
  /// snapshot is downloaded again.
  final String? scopeKey;
  final DateTime? serverTime;

  /// The app is too old to sync: keep the outbox and ask for an update.
  final bool updateNeeded;
  final String? latestVersion;
  final String? minVersion;

  /// The format the server speaks; [syncVersion] is what this app speaks.
  final int version;

  /// This phone as the server has it.
  final SyncDevice? device;
  final bool isOwner;

  /// The server speaks a newer format than this app.
  bool get versionMismatch => version > syncVersion;

  factory SyncCheck.fromJson(Object? data) {
    final d = Json.map(data);
    final app = Json.map(d['app']);
    final plan = Json.map(d['plan']);
    final ids = d['outlet_ids'];
    return SyncCheck(
      allowed: d['allowed'] == null || Json.flag(d['allowed']),
      wipe: Json.flag(d['wipe']),
      reason: Json.str(d['reason']),
      offline: OfflineWindow.fromJson(d['offline']),
      planState: Json.str(plan['state']),
      paidUntil: AtomDates.parse(plan['paid_until']),
      readOnly: Json.flag(plan['read_only']),
      outletIds: ids is List ? [for (final i in ids) ?Json.integer(i)] : null,
      scopeKey: Json.str(d['scope_key']),
      serverTime: AtomDates.parse(d['server_time']),
      updateNeeded: Json.flag(app['update_needed']),
      latestVersion: Json.str(app['latest_version']),
      minVersion: Json.str(app['min_version']),
      version: Json.integer(d['sync_version']) ?? syncVersion,
      device: d['device'] is Map ? SyncDevice.fromJson(d['device']) : null,
      isOwner: Json.flag(Json.map(d['access'])['is_owner']),
    );
  }
}

/// One deleted row (`changes` → the `deletions` table).
@immutable
class SyncDeletion {
  const SyncDeletion({
    required this.table,
    required this.rowId,
    this.rowUuid,
    this.deletedAt,
  });

  final String table;
  final int rowId;
  final String? rowUuid;
  final DateTime? deletedAt;

  factory SyncDeletion.fromJson(Object? raw) {
    final j = Json.map(raw);
    return SyncDeletion(
      table: Json.str(j['table']) ?? '',
      rowId: Json.integer(j['row_id']) ?? 0,
      rowUuid: Json.str(j['row_uuid']),
      deletedAt: AtomDates.parse(j['deleted_at']),
    );
  }
}

/// One page of `sync/snapshot` or `sync/changes`.
///
/// The rows stay as the server sent them: the local database decides what
/// a row means, so this layer carries them unread.
@immutable
class SyncPage {
  const SyncPage({
    required this.table,
    required this.rows,
    this.replace = false,
    this.nextTable,
    this.nextAfter,
    this.tables = const [],
    this.shopId,
    this.serverTime,
    this.nextSince,
    this.version = syncVersion,
    this.fingerprint,
    this.unchanged = false,
  });

  final String table;
  final List<Map<String, dynamic>> rows;

  /// The table comes whole and replaces what the phone has (`pool_leads`).
  final bool replace;

  /// Where the next page starts; null when this table is finished and no
  /// table is left.
  final String? nextTable;
  final int? nextAfter;

  /// Every table the snapshot covers, in the order to walk them.
  final List<String> tables;
  final int? shopId;

  /// The first page's time is kept as the next `since`.
  final DateTime? serverTime;

  /// `changes` only: it sits 5 seconds behind the clock, so a row can come
  /// twice. Upserting makes that harmless.
  final DateTime? nextSince;
  final int version;

  /// The lead pool as the server has it now. Kept and sent back as `pool`:
  /// while it matches, the pool (about 1,500 rows) is not sent again.
  final String? fingerprint;

  /// The pool was left out because the phone already has it.
  final bool unchanged;

  bool get hasMore => nextTable != null;

  /// `deletions` rows read as deletions; every other table is upserted.
  bool get isDeletions => table == 'deletions';

  List<SyncDeletion> get deletions => [
    for (final r in rows) SyncDeletion.fromJson(r),
  ];

  factory SyncPage.fromJson(Object? data) {
    final d = Json.map(data);
    final next = Json.map(d['next']);
    return SyncPage(
      table: Json.str(d['table']) ?? '',
      rows: [for (final r in Json.list(d['rows'])) Json.map(r)],
      replace: Json.flag(d['replace']),
      nextTable: Json.str(next['table']),
      nextAfter: Json.integer(next['after']),
      tables: [for (final t in Json.list(d['tables'])) ?Json.str(t)],
      shopId: Json.integer(d['shop_id']),
      serverTime: AtomDates.parse(d['server_time']),
      nextSince: AtomDates.parse(d['next_since']),
      version: Json.integer(d['sync_version']) ?? syncVersion,
      fingerprint: Json.str(d['fingerprint']),
      unchanged: Json.flag(d['unchanged']),
    );
  }
}

/// One photo the phone keeps with its copy (`GET sync/files`).
///
/// The list is read through the same scoped query as the snapshot, so it
/// holds exactly the files this person may see.
@immutable
class SyncFile {
  const SyncFile({
    required this.table,
    required this.rowId,
    required this.field,
    required this.path,
    required this.url,
    this.updatedAt,
  });

  final String table;
  final int rowId;

  /// `picture`, `id_card_front_side`, `cnic_front`, …
  final String field;

  /// The path the server stores on the row.
  final String path;

  /// Where to fetch it from, with the app's token.
  final String url;
  final String? updatedAt;

  factory SyncFile.fromJson(Object? raw) {
    final j = Json.map(raw);
    return SyncFile(
      table: Json.str(j['table']) ?? '',
      rowId: Json.integer(j['row_id']) ?? 0,
      field: Json.str(j['field']) ?? '',
      path: Json.str(j['path']) ?? '',
      url: Json.str(j['url']) ?? '',
      updatedAt: Json.str(j['updated_at']),
    );
  }
}

/// One page of `GET sync/files`: the same paging as the snapshot.
@immutable
class SyncFilePage {
  const SyncFilePage({
    required this.table,
    required this.files,
    this.nextTable,
    this.nextAfter,
  });

  final String table;
  final List<SyncFile> files;
  final String? nextTable;
  final int? nextAfter;

  bool get hasMore => nextTable != null;

  factory SyncFilePage.fromJson(Object? data) {
    final d = Json.map(data);
    final next = Json.map(d['next']);
    return SyncFilePage(
      table: Json.str(d['table']) ?? '',
      files: [for (final r in Json.list(d['rows'])) SyncFile.fromJson(r)],
      nextTable: Json.str(next['table']),
      nextAfter: Json.integer(next['after']),
    );
  }
}

/// What the server did with one outbox action.
enum OutboxStatus {
  /// Applied as saved: drop it from the outbox.
  done,

  /// Applied, but the server's result differs: drop it, and write
  /// [OutboxResult.changes] into the local row.
  doneWithChanges,

  /// Not applied. `retry` keeps it for later; otherwise it goes to Needs
  /// attention with Fix or Discard.
  needsAttention;

  static OutboxStatus fromKey(String? key) => switch (key) {
    'done' => done,
    'done_with_changes' => doneWithChanges,
    _ => needsAttention,
  };
}

/// One action waiting to reach the server.
///
/// [id] is made on the phone, so resending never runs the action twice.
@immutable
class OutboxAction {
  const OutboxAction({
    required this.id,
    required this.action,
    required this.data,
    required this.at,
    this.seen = const {},
    this.tempId,
    this.shopId,
  });

  final String id;

  /// `order.status`, `stock.in`, … (`SyncActionKeys`, §6.2).
  final String action;
  final Map<String, dynamic> data;

  /// What the person saw, for the server's checks (§6.3).
  final Map<String, dynamic> seen;

  /// The real time of the action. Payment, order and stock dates are its
  /// day; a time after the server's now counts as now.
  final DateTime at;

  /// The phone's temporary id for the record this action makes.
  final String? tempId;

  /// The shop it was done in, for an owner of several shops.
  final int? shopId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action,
    'data': data,
    'seen': seen,
    // With a zone on it: the server dates payments and stock by it.
    'at': at.toUtc().toIso8601String(),
  };
}

/// The server's answer for one action, in the order it was sent (§6.1).
@immutable
class OutboxResult {
  const OutboxResult({
    required this.id,
    required this.status,
    this.action,
    this.ids = const {},
    this.changes,
    this.message,
    this.reason,
    this.server,
    this.details,
    this.retry = false,
    this.conflict = false,
    this.replayed = false,
    this.raw = const {},
  });

  final String id;
  final OutboxStatus status;
  final String? action;

  /// `{id, uuid}` of the record the action made or changed.
  final Map<String, dynamic> ids;

  /// What the server has instead, for `done_with_changes` (auto numbers).
  final Map<String, dynamic>? changes;
  final String? message;

  /// `seen_changed`, `serial_clash`, … when it needs attention
  /// (`SyncReasons`).
  final String? reason;

  /// What the server has now, for `seen_changed`.
  final Map<String, dynamic>? server;

  /// More about a refusal: `serials` for a clash, field errors, ….
  final Map<String, dynamic>? details;

  /// Send it again later rather than showing it to the person.
  final bool retry;

  /// The server's record moved on: a conflict screen.
  final bool conflict;

  /// The answer came from the server's log: this id had already run.
  final bool replayed;

  /// The answer as it came, kept for the conflict screens.
  final Map<String, dynamic> raw;

  bool get applied => status != OutboxStatus.needsAttention;

  /// `details.serials`, for the serial clash screen.
  List<String> get serials => [
    for (final s in Json.list(details?['serials'])) ?Json.str(s),
  ];

  factory OutboxResult.fromJson(Object? raw) {
    final j = Json.map(raw);
    return OutboxResult(
      id: Json.str(j['id']) ?? '',
      status: OutboxStatus.fromKey(Json.str(j['status'])),
      action: Json.str(j['action']),
      ids: Json.map(j['ids']),
      changes: j['changes'] is Map ? Json.map(j['changes']) : null,
      message: Json.str(j['message']),
      reason: Json.str(j['reason']),
      server: j['server'] is Map ? Json.map(j['server']) : null,
      details: j['details'] is Map ? Json.map(j['details']) : null,
      retry: Json.flag(j['retry']),
      conflict: Json.flag(j['conflict']),
      replayed: Json.flag(j['replayed']),
      raw: j,
    );
  }
}

/// `POST sync`: one answer per action, plus the counts.
@immutable
class OutboxSent {
  const OutboxSent({
    this.results = const [],
    this.done = 0,
    this.needsAttention = 0,
    this.conflicts = 0,
    this.serverTime,
  });

  final List<OutboxResult> results;
  final int done;
  final int needsAttention;
  final int conflicts;
  final DateTime? serverTime;

  factory OutboxSent.fromJson(Object? data) {
    final d = Json.map(data);
    return OutboxSent(
      results: [
        for (final r in Json.list(d['results'])) OutboxResult.fromJson(r),
      ],
      done: Json.integer(d['done']) ?? 0,
      needsAttention: Json.integer(d['needs_attention']) ?? 0,
      conflicts: Json.integer(d['conflicts']) ?? 0,
      serverTime: AtomDates.parse(d['server_time']),
    );
  }
}
