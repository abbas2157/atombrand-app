import 'dart:convert';

import 'package:atombrand_app/v2/core/services/fcm_service.dart';
import 'package:atombrand_app/v2/core/services/login_device.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../../../core/app_providers.dart';
import '../../../core/session/session.dart';

/// Sign-in, password and Apply calls (docs/BRAND_APP.md §6, §8.1 in
/// atomshop; base path `api/brand-app`).
abstract interface class AuthRepository {
  /// `POST auth/login`. [login] is the owner's email (or phone) or a team
  /// member's mobile number.
  Future<ApiResult<BrandSession>> signIn({
    required String login,
    required String password,
  });

  /// `POST me/password`: a team member's own password (2.4). Answers
  /// `{must_change_password: false}`.
  Future<ApiResult<void>> setAgentPassword(String password);

  /// `POST auth/logout`: revokes this phone's token. Best effort; the
  /// session on the phone ends either way.
  Future<void> signOut();

  /// Forgot password, step 1: `POST auth/password/forgot`. Answers the
  /// same whether or not the account exists, so it can't be used to find
  /// brand partners. Gives the code's lifetime in seconds.
  Future<ApiResult<int>> sendResetCode({
    required String login,
    required ResetChannel channel,
  });

  /// Step 2: `POST auth/password/verify-code`. Gives the reset token.
  Future<ApiResult<String>> verifyResetCode({
    required String login,
    required String code,
  });

  /// Step 3: `POST auth/password/reset`.
  Future<ApiResult<void>> resetPassword({
    required String resetToken,
    required String password,
  });

  /// Apply to list your brand (2.3), step 1: `POST apply/otp/send`. Gives
  /// the code's lifetime in seconds.
  Future<ApiResult<int>> sendApplyCode({
    required String phone,
    String? email,
    String? name,
    ResetChannel? channel,
  });

  /// Step 2: `POST apply`. A 409 means an account or an open application
  /// already exists; its message says which.
  Future<ApiResult<void>> apply(BrandApplication application);

  /// `GET config` (public): the commission percentages Apply offers, the
  /// support contacts and OTP rules.
  Future<ApiResult<Map<String, dynamic>>> config();
}

/// What Apply sends (`POST apply`).
class BrandApplication {
  const BrandApplication({
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    required this.businessType,
    required this.percentage,
    required this.otp,
    this.category,
    this.website,
    this.productsCount,
    this.message,
  });

  final String name;
  final String email;
  final String phone;
  final String company;
  final String businessType;
  final num percentage;
  final String otp;
  final String? category;
  final String? website;
  final int? productsCount;
  final String? message;

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'company': company,
    'business_type': businessType,
    'percentage': percentage,
    'otp': otp,
    'category': ?category,
    'website': ?website,
    'products_count': ?productsCount,
    'message': ?message,
  };
}

/// Where the reset code goes.
enum ResetChannel {
  whatsapp('whatsapp'),
  email('email');

  const ResetChannel(this.key);
  final String key;
}

class ApiAuthRepository implements AuthRepository {
  const ApiAuthRepository(this._api, {this.device = readLoginDevice});
  final ApiClient _api;

  /// This phone's platform and name, for Devices & sessions (19.3).
  final Future<LoginDevice> Function() device;

  @override
  Future<ApiResult<BrandSession>> signIn({
    required String login,
    required String password,
  }) async {
    final fcmToken = await FcmService.getToken();
    final phone = await device();
    final result = await _api.post<(BrandSession, bool)>(
      'auth/login',
      body: {
        'login': login,
        'password': password,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
        // Sync contract §2 (mirrored for brand-app/sync): without `device_id` the phone is never
        // registered, and the server then refuses it an offline copy
        // (`offline.device_registered: false`) however the account is
        // billed.
        'device_id': ?phone.id,
        'platform': ?phone.platform,
        'device_name': ?phone.name,
        'app_version': ?phone.version,
      },
      parse: (data) {
        final map = Json.map(data);
        final brand = map['brand'];
        // A brand Atomshop has not approved yet can't sign in (2.2).
        final status = brand is Map ? Json.str(brand['status']) : null;
        final verified =
            status == null || !const {'pending', 'Pending'}.contains(status);
        return (BrandSession.fromLogin(map), verified);
      },
      // A wrong password is a 401 too; it must not end a locked session
      // that is waiting behind Sign in.
      reportAppWide: false,
    );
    return switch (result) {
      ApiOk(value: (final session, true)) => ApiOk(session),
      ApiOk() => const ApiErr(
        ApiFailure(
          ApiFailureKind.ownerOnly,
          statusCode: 403,
          body: {'reason': unverifiedBrandReason},
        ),
      ),
      ApiErr(:final failure) => ApiErr(failure),
    };
  }

  @override
  Future<ApiResult<void>> setAgentPassword(String password) => _api.post(
    'me/password',
    body: {'password': password, 'password_confirmation': password},
    parse: (_) {},
  );

  @override
  Future<void> signOut() async {
    await _api.post('auth/logout', parse: (_) => null);
  }

  @override
  Future<ApiResult<int>> sendResetCode({
    required String login,
    required ResetChannel channel,
  }) => _api.post(
    'auth/password/forgot',
    body: {'login': login, 'channel': channel.key},
    parse: (data) => Json.integer(Json.map(data)['expires_in']) ?? 600,
  );

  @override
  Future<ApiResult<String>> verifyResetCode({
    required String login,
    required String code,
  }) => _api.post(
    'auth/password/verify-code',
    body: {'login': login, 'code': code},
    parse: (data) => Json.str(Json.map(data)['reset_token'])!,
  );

  @override
  Future<ApiResult<void>> resetPassword({
    required String resetToken,
    required String password,
  }) => _api.post(
    'auth/password/reset',
    body: {
      'reset_token': resetToken,
      'password': password,
      'password_confirmation': password,
    },
    parse: (_) {},
  );

  @override
  Future<ApiResult<int>> sendApplyCode({
    required String phone,
    String? email,
    String? name,
    ResetChannel? channel,
  }) => _api.post(
    'apply/otp/send',
    body: {
      'phone': phone,
      'email': ?email,
      'name': ?name,
      'channel': ?channel?.key,
    },
    parse: (data) => Json.integer(Json.map(data)['expires_in']) ?? 600,
    reportAppWide: false,
  );

  @override
  Future<ApiResult<void>> apply(BrandApplication application) => _api.post(
    'apply',
    body: application.toJson(),
    parse: (_) {},
    reportAppWide: false,
  );

  @override
  Future<ApiResult<Map<String, dynamic>>> config() =>
      _api.get('config', parse: Json.map);
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ApiAuthRepository(ref.read(apiClientProvider)),
);

/// The password typed at the last sign-in, as a hash and in memory only, so
/// 2.4 can check "Not the temporary password" (the server doesn't). Gone
/// when the app closes or the agent's password is saved.
final lastSignInPasswordProvider =
    NotifierProvider<LastSignInPassword, String?>(LastSignInPassword.new);

class LastSignInPassword extends Notifier<String?> {
  @override
  String? build() => null;

  static String hashOf(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  void remember(String password) => state = hashOf(password);

  void forget() => state = null;
}

/// Why a sign-in that the server accepted is still refused on the phone:
/// the brand isn't approved yet (2.2, "not verified yet").
const unverifiedBrandReason = 'unverified_brand';
