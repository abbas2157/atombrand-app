import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../../../core/app_providers.dart';
import '../../../core/format/dates.dart';
import '../../../core/session/session_controller.dart';

/// This app's version, shown in the menu and Settings and sent with
/// feedback. Keep it in step with `version:` in pubspec.yaml.
const appVersion = '2.0.0';

/// The person signed in and their brand (`GET profile`: `{user, brand}`).
@immutable
class MyProfile {
  const MyProfile({
    required this.name,
    this.email,
    this.phone,
    this.pictureUrl,
    this.brandName,
    this.brandSlug,
    this.brandUrl,
    this.brandStatus,
  });

  final String name;

  /// The owner signs in with it, so it is sent back unchanged on save.
  final String? email;
  final String? phone;

  /// No brand person has their own photo yet; kept for the menu and the
  /// unlock screen, which show one when there is.
  final String? pictureUrl;
  final String? brandName;
  final String? brandSlug;

  /// The brand page on atomshop.pk (`brand.public_url`).
  final String? brandUrl;

  /// The brand's status on Atomshop (`brand.status`); `active` means the
  /// brand page is live on atomshop.pk.
  final String? brandStatus;

  factory MyProfile.fromJson(Object? data) {
    final d = Json.map(data);
    final u = Json.map(d['user']);
    final b = Json.map(d['brand']);
    return MyProfile(
      name: Json.str(u['name']) ?? '',
      email: Json.str(u['email']),
      phone: Json.str(u['phone']),
      pictureUrl: Json.str(u['profile_picture_url']),
      brandName: Json.str(b['title']),
      brandSlug: Json.str(b['slug']),
      brandUrl: Json.str(b['public_url']),
      brandStatus: Json.str(b['status']),
    );
  }

  MyProfile copyWith({String? name, String? phone}) => MyProfile(
    name: name ?? this.name,
    email: email,
    phone: phone ?? this.phone,
    pictureUrl: pictureUrl,
    brandName: brandName,
    brandSlug: brandSlug,
    brandUrl: brandUrl,
    brandStatus: brandStatus,
  );
}

/// Where someone is signed in (`GET sessions`): one row per app
/// sign-in.
@immutable
class SignedInDevice {
  const SignedInDevice({
    required this.id,
    required this.name,
    required this.thisDevice,
    this.platform,
    this.lastUsedAt,
    this.signedInAt,
  });

  final int id;
  final String name;
  final String? platform;
  final bool thisDevice;
  final DateTime? lastUsedAt;
  final DateTime? signedInAt;

  factory SignedInDevice.fromJson(Object? raw) {
    final j = Json.map(raw);
    return SignedInDevice(
      id: Json.integer(j['id']) ?? 0,
      name: Json.str(j['name']) ?? '',
      platform: Json.str(j['platform']),
      thisDevice: Json.flag(j['this_device']),
      lastUsedAt: AtomDates.parse(j['last_used_at']),
      signedInAt: AtomDates.parse(j['signed_in_at']),
    );
  }
}

/// My devices, and for an owner with the Team add-on, each agent's.
@immutable
class Devices {
  const Devices({required this.mine, this.team = const []});
  final List<SignedInDevice> mine;
  final List<(String name, List<SignedInDevice> devices)> team;

  factory Devices.fromJson(Object? data) {
    final d = Json.map(data);
    return Devices(
      mine: [
        for (final r in Json.list(d['devices'])) SignedInDevice.fromJson(r),
      ],
      team: [
        for (final m in Json.list(d['team']))
          (
            Json.str(Json.map(m)['name']) ?? '',
            [
              for (final r in Json.list(Json.map(m)['devices']))
                SignedInDevice.fromJson(r),
            ],
          ),
      ],
    );
  }
}

/// What feedback is (`SellerFeedback::KINDS`).
enum FeedbackKind { idea, problem, praise }

/// Account and settings calls (atomshop `Api\BrandApp\ProfileController`,
/// `CoreController`, `AccountController`, `AuthController`).
abstract interface class SettingsRepository {
  /// `GET profile`.
  Future<ApiResult<MyProfile>> profile();

  /// `POST profile/update` (owner): name and email are required, so the
  /// email goes back as it was.
  Future<ApiResult<void>> updateProfile({
    required String name,
    required String email,
    String? phone,
  });

  /// A team member's own name: `POST me/name` (16.1). Their mobile is
  /// their sign-in, so only the owner changes it.
  Future<ApiResult<void>> updateMyName(String name);

  /// The owner's password: `POST profile/password` with the current one.
  /// The server signs out every other phone.
  Future<ApiResult<void>> changeOwnerPassword({
    required String current,
    required String next,
  });

  /// A team member's own password: `POST me/password` (no current one).
  Future<ApiResult<void>> changeMyPassword(String next);

  /// `GET sessions`.
  Future<ApiResult<Devices>> devices();

  /// `POST sessions/{id}/revoke`.
  Future<ApiResult<void>> signOutDevice(int id);

  /// `POST sessions/revoke-others`: answers how many were signed out.
  Future<ApiResult<int>> signOutOthers();

  /// `POST feedback` (being added on the server; 404 until then).
  Future<ApiResult<void>> feedback(
    FeedbackKind kind,
    String message, {
    File? screenshot,
    String? device,
  });

  /// `POST export` (owner; being added on the server, 404 until then):
  /// answers the email the link goes to.
  Future<ApiResult<String>> export();

  /// `POST me/delete` (owner): deletes the account, password-confirmed.
  Future<ApiResult<void>> deleteAccount({
    required String password,
    String? reason,
  });
}

class ApiSettingsRepository implements SettingsRepository {
  const ApiSettingsRepository(this._api);
  final ApiClient _api;

  @override
  Future<ApiResult<MyProfile>> profile() =>
      _api.get('profile', parse: MyProfile.fromJson);

  @override
  Future<ApiResult<void>> updateProfile({
    required String name,
    required String email,
    String? phone,
  }) => _api.post(
    'profile/update',
    body: {'name': name, 'email': email, 'phone': phone},
    parse: (_) {},
  );

  @override
  Future<ApiResult<void>> updateMyName(String name) =>
      _api.post('me/name', body: {'name': name}, parse: (_) {});

  @override
  Future<ApiResult<void>> changeOwnerPassword({
    required String current,
    required String next,
  }) => _api.post(
    'profile/password',
    body: {
      'current_password': current,
      'password': next,
      'password_confirmation': next,
    },
    parse: (_) {},
  );

  @override
  Future<ApiResult<void>> changeMyPassword(String next) => _api.post(
    'me/password',
    body: {'password': next, 'password_confirmation': next},
    parse: (_) {},
  );

  @override
  Future<ApiResult<Devices>> devices() =>
      _api.get('sessions', parse: Devices.fromJson);

  @override
  Future<ApiResult<void>> signOutDevice(int id) =>
      _api.post('sessions/$id/revoke', parse: (_) {});

  @override
  Future<ApiResult<int>> signOutOthers() => _api.post(
    'sessions/revoke-others',
    parse: (data) => Json.integer(Json.map(data)['revoked']) ?? 0,
  );

  @override
  Future<ApiResult<void>> feedback(
    FeedbackKind kind,
    String message, {
    File? screenshot,
    String? device,
  }) => _api.postForm(
    'feedback',
    fields: {
      'kind': kind.name,
      'message': message,
      'device': ?device,
      'app_version': appVersion,
    },
    files: {'screenshot': ?screenshot},
    parse: (_) {},
  );

  @override
  Future<ApiResult<String>> export() => _api.post(
    'export',
    parse: (data) => Json.str(Json.map(data)['email']) ?? '',
  );

  @override
  Future<ApiResult<void>> deleteAccount({
    required String password,
    String? reason,
  }) => _api.post(
    'me/delete',
    body: {'password': password, 'reason': ?reason},
    parse: (_) {},
  );
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => ApiSettingsRepository(ref.read(apiClientProvider)),
);

Object? _who(Ref ref) => ref.watch(
  sessionProvider.select(
    (s) => s is SignedIn ? (s.session.userId, s.session.outletId) : null,
  ),
);

final myProfileProvider = FutureProvider.autoDispose<MyProfile>((ref) async {
  _who(ref);
  return switch (await ref.read(settingsRepositoryProvider).profile()) {
    ApiOk(:final value) => value,
    ApiErr(:final failure) => throw failure,
  };
});

final devicesProvider = FutureProvider.autoDispose<Devices>((ref) async {
  _who(ref);
  return switch (await ref.read(settingsRepositoryProvider).devices()) {
    ApiOk(:final value) => value,
    ApiErr(:final failure) => throw failure,
  };
});
