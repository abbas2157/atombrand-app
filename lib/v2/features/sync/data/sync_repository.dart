import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../../../core/app_providers.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/login_device.dart';
import 'sync_models.dart';

/// This phone, as `sync/check` is told about it: the `device_id` made once
/// per install (it registers the phone), its name, platform and version.
typedef SyncPhone = Future<LoginDevice> Function();

/// The brand sync calls (`docs/brand-app-sync.md`) and the phones list
/// (§8), under `api/brand-app/`.
///
/// `sync/check` and `devices*` answer every brand. The snapshot, changes
/// and files answer 403 `feature_off` without the Offline add-on, and 422
/// `device_unknown` for a token with no registered phone: call [check]
/// with the `device_id` first.
abstract interface class SyncRepository {
  /// `GET sync/check`: still allowed? wipe? how long offline may last. The
  /// first call with this phone's `device_id` registers it.
  ///
  /// [unsent] is the outbox count, which the owner sees on Phones signed
  /// in.
  Future<ApiResult<SyncCheck>> check({int unsent = 0});

  /// `GET sync/snapshot`: the first download, one page of one table.
  Future<ApiResult<SyncPage>> snapshot({
    String? table,
    int after = 0,
    int limit = 500,
  });

  /// `GET sync/changes`: what changed since [since], then `deletions`.
  Future<ApiResult<SyncPage>> changes({
    required DateTime since,
    String? table,
    int after = 0,
    int limit = 500,
  });

  /// `GET sync/files`: which photos this phone's copy should hold.
  Future<ApiResult<SyncFilePage>> files({
    String? table,
    int after = 0,
    int limit = 500,
    DateTime? since,
  });

  /// One photo's bytes, from the address `sync/files` gave.
  Future<ApiResult<List<int>>> fetchFile(String url);

  /// `POST sync`: the outbox, in order, at most 100 actions a call.
  Future<ApiResult<OutboxSent>> send(
    List<OutboxAction> actions, {
    Map<String, Map<String, File>> files = const {},
    int unsent = 0,
  });
}

/// Phones signed in (§8): for the Sync centre's phones list (10.7).
abstract interface class PhonesRepository {
  /// `GET devices`.
  Future<ApiResult<PhonesSignedIn>> devices();

  /// `POST devices/{id}/revoke`: signs one phone out. Not this phone
  /// (422): use sign out.
  Future<ApiResult<String?>> revoke(int id);

  /// `POST devices/revoke-all`: every other phone of yours, and with
  /// [team] the team's too (owner). Answers how many.
  Future<ApiResult<int>> revokeAll({bool team = false});
}

class ApiSyncRepository implements SyncRepository, PhonesRepository {
  ApiSyncRepository(this._api, {SyncPhone? phone, this.fcmToken})
    : _phone = phone ?? readLoginDevice;

  final ApiClient _api;
  final SyncPhone _phone;

  /// The push token, so Atomshop's "sync now" reaches this phone. Null in
  /// a background run, where Firebase isn't started.
  final Future<String?> Function()? fcmToken;

  /// At most this many actions a call (§6).
  static const batch = 100;

  LoginDevice? _device;

  Future<Map<String, Object>> _deviceFields() async {
    final d = _device ??= await _phone();
    String? fcm;
    try {
      fcm = await fcmToken?.call();
    } catch (_) {}
    return {
      'device_id': ?d.id,
      'device_name': ?d.name,
      if (d.platform == 'android' || d.platform == 'ios')
        'platform': d.platform!,
      'app_version': ?d.version,
      if (fcm != null && fcm.isNotEmpty) 'fcm_token': fcm,
    };
  }

  @override
  Future<ApiResult<SyncCheck>> check({int unsent = 0}) async => _api.get(
    'sync/check',
    query: {
      ...await _deviceFields(),
      'sync_version': syncVersion,
      'unsent': unsent,
    },
    parse: SyncCheck.fromJson,
  );

  @override
  Future<ApiResult<SyncPage>> snapshot({
    String? table,
    int after = 0,
    int limit = 500,
  }) => _api.get(
    'sync/snapshot',
    query: {'table': ?table, 'after': after, 'limit': limit},
    parse: SyncPage.fromJson,
  );

  @override
  Future<ApiResult<SyncPage>> changes({
    required DateTime since,
    String? table,
    int after = 0,
    int limit = 500,
  }) => _api.get(
    'sync/changes',
    query: {
      // Always with a zone on it (`…Z`): a local time written out has
      // none, and the server would read it in its own zone.
      'since': since.toUtc().toIso8601String(),
      'table': ?table,
      'after': after,
      'limit': limit,
    },
    parse: SyncPage.fromJson,
  );

  @override
  Future<ApiResult<SyncFilePage>> files({
    String? table,
    int after = 0,
    int limit = 500,
    DateTime? since,
  }) => _api.get(
    'sync/files',
    query: {
      'table': ?table,
      'after': after,
      'limit': limit,
      'since': ?since?.toUtc().toIso8601String(),
    },
    parse: SyncFilePage.fromJson,
  );

  @override
  Future<ApiResult<List<int>>> fetchFile(String url) => _api.getBytes(url);

  @override
  Future<ApiResult<OutboxSent>> send(
    List<OutboxAction> actions, {
    Map<String, Map<String, File>> files = const {},
    int unsent = 0,
  }) async {
    final body = [for (final a in actions) a.toJson()];
    // The phone registers itself here too if `sync/check` never did.
    final deviceId = (_device ??= await _phone()).id;
    if (files.isEmpty) {
      return _api.post(
        'sync',
        body: {'unsent': unsent, 'device_id': ?deviceId, 'actions': body},
        parse: OutboxSent.fromJson,
      );
    }
    // With photos it is a form: `actions` as JSON text and each photo as
    // files[<action id>][<field>] (§6).
    return _api.postForm(
      'sync',
      fields: {
        'unsent': unsent,
        'device_id': ?deviceId,
        'actions': jsonEncode(body),
      },
      files: {
        for (final action in files.entries)
          for (final field in action.value.entries)
            'files[${action.key}][${field.key}]': field.value,
      },
      parse: OutboxSent.fromJson,
    );
  }

  @override
  Future<ApiResult<PhonesSignedIn>> devices() =>
      _api.get('devices', parse: PhonesSignedIn.fromJson);

  @override
  Future<ApiResult<String?>> revoke(int id) async {
    // The server's sentence says what happens to that phone's copy and its
    // unsent changes; it is the envelope's message, not in `data`.
    final r = await _api.post('devices/$id/revoke', parse: (_) {});
    return switch (r) {
      ApiOk(:final message) => ApiOk(message, message: message),
      ApiErr(:final failure) => ApiErr(failure),
    };
  }

  @override
  Future<ApiResult<int>> revokeAll({bool team = false}) => _api.post(
    'devices/revoke-all',
    body: {if (team) 'team': true},
    parse: (data) => Json.integer(Json.map(data)['revoked']) ?? 0,
  );
}

final _apiSync = Provider<ApiSyncRepository>(
  (ref) => ApiSyncRepository(
    ref.read(apiClientProvider),
    fcmToken: FcmService.getToken,
  ),
);

final syncRepositoryProvider = Provider<SyncRepository>(
  (ref) => ref.watch(_apiSync),
);

final phonesRepositoryProvider = Provider<PhonesRepository>(
  (ref) => ref.watch(_apiSync),
);
