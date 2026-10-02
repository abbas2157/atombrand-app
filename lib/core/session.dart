import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/account.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/orders_repository.dart';
import 'api_client.dart';
import 'push.dart';

sealed class SessionState {
  const SessionState();
}

/// Splash: the stored token hasn't been checked yet.
class SessionLoading extends SessionState {
  const SessionLoading();
}

/// A token exists but `GET me` failed for a non-auth reason (offline).
class SessionUnreachable extends SessionState {
  const SessionUnreachable(this.message);
  final String message;
}

class SignedOut extends SessionState {
  const SignedOut({this.notice});

  /// Why the user was signed out (e.g. a 403 "account not active").
  final String? notice;
}

class SignedIn extends SessionState {
  const SignedIn({required this.user, required this.brand, this.newBulkRequests = 0});
  final AppUser user;
  final Brand brand;
  final int newBulkRequests;

  SignedIn copyWith({AppUser? user, Brand? brand, int? newBulkRequests}) => SignedIn(
        user: user ?? this.user,
        brand: brand ?? this.brand,
        newBulkRequests: newBulkRequests ?? this.newBulkRequests,
      );
}

class SessionNotifier extends Notifier<SessionState> {
  StreamSubscription<String>? _pushSub;

  @override
  SessionState build() {
    ref.read(apiClientProvider).onAuthFailure = _onAuthFailure;
    ref.onDispose(() => _pushSub?.cancel());
    Future.microtask(bootstrap);
    return const SessionLoading();
  }

  AuthRepository get _auth => ref.read(authRepositoryProvider);
  TokenStore get _tokens => ref.read(tokenStoreProvider);

  /// Validates the stored token and loads brand + badge (§5.4).
  Future<void> bootstrap() async {
    state = const SessionLoading();
    final token = await _tokens.load();
    if (token == null) {
      state = const SignedOut();
      return;
    }
    try {
      final me = await _auth.me();
      state = SignedIn(user: me.user, brand: me.brand, newBulkRequests: me.newBulkRequests);
      _startPush();
    } on ApiException catch (e) {
      // 401/403 are routed through _onAuthFailure, which has already signed out.
      if (state is SessionLoading) state = SessionUnreachable(e.message);
    }
  }

  Future<void> signIn(AuthSession session) async {
    await _tokens.save(session.token);
    state = SignedIn(user: session.user, brand: session.brand);
    _startPush();
    unawaited(refreshBadge());
  }

  Future<void> refreshBadge() async {
    final s = state;
    if (s is! SignedIn) return;
    try {
      final n = await ref.read(bulkRepositoryProvider).newCount();
      final now = state;
      if (now is SignedIn) state = now.copyWith(newBulkRequests: n);
    } on ApiException {
      // Badge is best-effort.
    }
  }

  void updateUser(AppUser user) {
    final s = state;
    if (s is SignedIn) state = s.copyWith(user: user);
  }

  void updateBrand(Brand brand) {
    final s = state;
    if (s is SignedIn) state = s.copyWith(brand: brand);
  }

  Future<void> signOut() async {
    try {
      await _auth.logout();
    } on ApiException {
      // Sign out locally even if the server can't be reached.
    }
    await _clear();
    state = const SignedOut();
  }

  void _onAuthFailure(int status, String message) {
    if (state is SignedOut) return;
    unawaited(_clear());
    state = SignedOut(notice: status == 403 ? message : 'Your session has ended. Please sign in again.');
  }

  Future<void> _clear() async {
    await _pushSub?.cancel();
    _pushSub = null;
    await _tokens.clear();
  }

  /// Register the FCM token after sign-in and whenever it rotates.
  Future<void> _startPush() async {
    final push = ref.read(pushServiceProvider);
    Future<void> register(String? t) async {
      if (t == null || state is! SignedIn) return;
      try {
        await _auth.registerFcmToken(t);
      } on ApiException {
        // Retried on next launch.
      }
    }

    await register(await push.currentToken());
    await _pushSub?.cancel();
    _pushSub = push.tokenRefreshes.listen(register);
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(SessionNotifier.new);

/// The signed-in brand context; null for the brief moment between sign-out
/// and the router leaving the Main shell.
final signedInProvider = Provider<SignedIn?>((ref) {
  final s = ref.watch(sessionProvider);
  return s is SignedIn ? s : null;
});

/// `GET config`, falling back to built-in defaults if it can't be loaded.
final configProvider = FutureProvider<AppConfig>((ref) async {
  try {
    return await ref.watch(authRepositoryProvider).config();
  } on ApiException {
    return AppConfig.fallback;
  }
});
