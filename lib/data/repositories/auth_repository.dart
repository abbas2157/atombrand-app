import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/env.dart';
import '../models/account.dart';
import '../models/json.dart';

class Me {
  const Me(this.user, this.brand, this.newBulkRequests);
  final AppUser user;
  final Brand brand;
  final int newBulkRequests;
}

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  Future<AppConfig> config() async => AppConfig.fromJson((await _api.get('config')).map);

  /// Password only; there is never a code at login (§6.1).
  Future<AuthSession> login(String login, String password, {String? fcmToken}) async {
    final res = await _api.post('auth/login', data: {
      'login': login.trim(),
      'password': password,
      'device_name': Env.deviceName,
      'fcm_token': ?fcmToken,
    });
    return AuthSession.fromJson(res.map);
  }

  /// Signs in the brand account whose email matches the Google ID token.
  Future<AuthSession> loginWithGoogle(String idToken, {String? fcmToken}) async {
    final res = await _api.post('auth/google', data: {
      'id_token': idToken,
      'device_name': Env.deviceName,
      'fcm_token': ?fcmToken,
    });
    return AuthSession.fromJson(res.map);
  }

  /// Answers the same whether or not the account exists (§6.2).
  Future<VerificationChallenge> forgotPassword(String login, {String? channel}) async {
    final res = await _api.post('auth/password/forgot', data: {
      'login': login.trim(),
      'channel': ?channel,
    });
    return VerificationChallenge.fromJson(res.map, message: res.message);
  }

  /// Returns the single-use `reset_token` (valid 15 min).
  Future<String> verifyResetCode(String login, String code) async {
    final res = await _api.post('auth/password/verify-code', data: {
      'login': login.trim(),
      'code': code,
    });
    return asStrOr(res.map['reset_token']);
  }

  Future<String> resetPassword(String resetToken, String password, String confirmation) async {
    final res = await _api.post('auth/password/reset', data: {
      'reset_token': resetToken,
      'password': password,
      'password_confirmation': confirmation,
    });
    return res.message;
  }

  Future<VerificationChallenge> sendApplyCode({required String phone, String? email, String? name, String? channel}) async {
    final res = await _api.post('apply/otp/send', data: {
      'phone': phone.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      'channel': ?channel,
    });
    return VerificationChallenge.fromJson(res.map, message: res.message);
  }

  Future<String> apply(Map<String, dynamic> form, String otp) async {
    final res = await _api.post('apply', data: {...form, 'otp': otp});
    return res.message;
  }

  Future<Me> me() async {
    final d = (await _api.get('me')).map;
    return Me(
      AppUser.fromJson(asMap(d['user'])),
      Brand.fromJson(asMap(d['brand'])),
      asInt(asMap(d['badges'])['new_bulk_requests']),
    );
  }

  Future<void> registerFcmToken(String token) => _api.post('fcm-token', data: {'fcm_token': token});

  Future<void> logout() => _api.post('auth/logout');
}

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.watch(apiClientProvider)));
