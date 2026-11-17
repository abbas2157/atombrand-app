import 'dart:io';

import 'package:atombrand_app/v2/core/api/api_result.dart';
import 'package:atombrand_app/v2/features/sync/data/sync_models.dart';
import 'package:atombrand_app/v2/features/sync/data/sync_repository.dart';

/// A brand sync server that answers whatever the test sets, and remembers
/// what it was sent.
class FakeSync implements SyncRepository {
  FakeSync({Map<String, dynamic>? check})
    : checkAnswer = ApiOk(SyncCheck.fromJson(checkJson(check)));

  static Map<String, dynamic> checkJson([Map<String, dynamic>? more]) => {
    'allowed': true,
    'wipe': false,
    'reason': null,
    'offline': {
      'allowed': true,
      'until': '2026-12-14T09:10:00+05:00',
      'days': 30,
      'addon': 'active',
      'drop_copy': false,
      'device_registered': true,
    },
    'plan': {'state': 'ok', 'paid_until': '2027-01-13', 'read_only': false},
    'outlet_ids': null,
    'scope_key': 'scope-1',
    'sync_version': 1,
    'app': {
      'latest_version': '2.1.0',
      'min_version': '2.0.0',
      'update_needed': false,
    },
    'server_time': '2026-11-14T09:10:00+05:00',
    ...?more,
  };

  ApiResult<SyncCheck> checkAnswer;

  List<ApiResult<SyncPage>> snapshotPages = [];
  List<ApiResult<SyncPage>> changesPages = [];

  /// Answers one batch at a time; empty answers every action `done`.
  List<ApiResult<OutboxSent>> sendAnswers = [];

  final List<List<OutboxAction>> sent = [];
  final List<Map<String, Map<String, File>>> sentFiles = [];
  final List<({DateTime since, String? table, int after})> changesCalls = [];
  int checks = 0;
  int lastUnsent = -1;

  @override
  Future<ApiResult<SyncCheck>> check({int unsent = 0}) async {
    checks++;
    lastUnsent = unsent;
    return checkAnswer;
  }

  @override
  Future<ApiResult<SyncPage>> snapshot({
    String? table,
    int after = 0,
    int limit = 500,
  }) async => snapshotPages.isEmpty
      ? ApiOk(SyncPage.fromJson(const {'table': 'account', 'rows': []}))
      : snapshotPages.removeAt(0);

  @override
  Future<ApiResult<SyncPage>> changes({
    required DateTime since,
    String? table,
    int after = 0,
    int limit = 500,
  }) async {
    changesCalls.add((since: since, table: table, after: after));
    return changesPages.isEmpty
        ? ApiOk(SyncPage.fromJson(const {'table': 'account', 'rows': []}))
        : changesPages.removeAt(0);
  }

  @override
  Future<ApiResult<SyncFilePage>> files({
    String? table,
    int after = 0,
    int limit = 500,
    DateTime? since,
  }) async => ApiOk(SyncFilePage.fromJson(const {'table': '', 'rows': []}));

  @override
  Future<ApiResult<List<int>>> fetchFile(String url) async =>
      const ApiOk([1, 2, 3]);

  @override
  Future<ApiResult<OutboxSent>> send(
    List<OutboxAction> actions, {
    Map<String, Map<String, File>> files = const {},
    int unsent = 0,
  }) async {
    sent.add(actions);
    sentFiles.add(files);
    if (sendAnswers.isEmpty) {
      return ApiOk(
        OutboxSent.fromJson({
          'results': [
            for (final a in actions)
              {'id': a.id, 'action': a.action, 'status': 'done'},
          ],
          'done': actions.length,
        }),
      );
    }
    return sendAnswers.removeAt(0);
  }
}

/// One page of the snapshot or the changes.
ApiResult<SyncPage> page(
  String table, {
  List<Map<String, dynamic>> rows = const [],
  String? nextTable,
  int? nextAfter,
  String? serverTime,
  String? nextSince,
}) => ApiOk(
  SyncPage.fromJson({
    'table': table,
    'rows': rows,
    if (nextTable != null) 'next': {'table': nextTable, 'after': nextAfter},
    'server_time': serverTime,
    'next_since': nextSince,
  }),
);
