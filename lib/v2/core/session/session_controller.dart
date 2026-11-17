import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/photo_cache.dart';
import 'session.dart';
import 'session_store.dart';

/// Why a person is on the Signed out screen (19.15).
enum SignOutReason {
  /// Nobody has signed in on this phone yet (or the stored session was
  /// gone at launch). A link opened now is kept for after sign-in.
  notSignedIn,

  /// They chose Sign out. Nothing is kept: they start again at Welcome.
  chosen,

  /// A 401: the token expired, was revoked, or the password changed.
  expired,
}

/// The session as the app sees it.
sealed class SessionState {
  const SessionState();
}

/// Reading the stored session at launch.
final class SessionLoading extends SessionState {
  const SessionLoading();
}

final class SignedOut extends SessionState {
  const SignedOut({this.reason = SignOutReason.notSignedIn});

  /// The screen the person was on when a 401 signed them out isn't kept
  /// here: the router keeps it in the `from` of the Signed out route.
  final SignOutReason reason;
}

final class SignedIn extends SessionState {
  const SignedIn(this.session);
  final BrandSession session;
}

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => const SecureSessionStore(),
);

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

/// Owns the session: restore at launch, sign in, switch outlet, sign out.
///
/// The router listens to this, so every change of state moves the person
/// to the right place without any screen pushing routes itself.
class SessionController extends Notifier<SessionState> {
  SessionStore get _store => ref.read(sessionStoreProvider);

  @override
  SessionState build() {
    _restore();
    return const SessionLoading();
  }

  /// How long the launch screen stays up, even when the stored session
  /// reads back at once.
  static const minimumLaunch = Duration(seconds: 3);

  Future<void> _restore() async {
    // Started before the read, so the wait overlaps it rather than adding to it.
    final launch = Future<void>.delayed(minimumLaunch);
    final session = await _store.read();
    await launch;
    // Something else (a sign-in in a test) may have run meanwhile.
    if (state is! SessionLoading) return;
    state = session == null ? const SignedOut() : SignedIn(session);
  }

  BrandSession? get current => switch (state) {
    SignedIn(:final session) => session,
    _ => null,
  };

  Future<void> signIn(BrandSession session) async {
    state = SignedIn(session);
    await _store.write(session);
  }

  /// After the agent chooses their own password, or any refreshed `who`.
  Future<void> updateWho(Who who) => _update((s) => s.copyWith(who: who));

  /// The person picks an outlet; null is every outlet. This also marks the
  /// "Choose outlet" step (2.6) as done.
  Future<void> selectOutlet(int? outletId, String? name) => _update(
    (s) => s.copyWith(
      outletId: () => outletId,
      outletName: () => name,
      outletChosen: true,
    ),
  );

  /// The outlets this person can switch between, freshly read. On a
  /// brand with more than one, a person who has never chosen is sent to
  /// "Choose outlet" (2.6); an outlet that no longer exists is dropped.
  Future<void> setOutlets(List<Outlet> outlets, {bool askToChoose = false}) =>
      _update((s) {
        final kept =
            s.outletId != null && outlets.any((o) => o.id == s.outletId);
        return s.copyWith(
          outlets: outlets,
          outletId: kept ? null : () => null,
          outletName: kept ? null : () => null,
          outletChosen: outlets.length <= 1 || (s.outletChosen && !askToChoose),
        );
      });

  /// After `GET me`: the role, permissions and brand as the server holds
  /// them now.
  Future<void> refreshFromMe(Map<String, dynamic> me) => _update((s) {
    final brand = me['brand'];
    final user = me['user'];
    return s.copyWith(
      who: me['access'] is Map
          ? Who.fromJson(Map<String, dynamic>.from(me['access'] as Map))
          : null,
      name: user is Map ? user['name']?.toString() : null,
      brandName: brand is Map ? () => brand['title']?.toString() : null,
      brandLogo: brand is Map ? () => brand['logo']?.toString() : null,
    );
  });

  Future<void> _update(BrandSession Function(BrandSession) change) async {
    final s = current;
    if (s == null) return;
    final next = change(s);
    state = SignedIn(next);
    await _store.write(next);
  }

  /// Ends the session on this phone. The server call to revoke the token is
  /// the caller's (Sign out in Settings); a 401 needs none.
  Future<void> signOut({SignOutReason reason = SignOutReason.chosen}) async {
    // Several calls fail together when a token dies; sign out once.
    if (state is SignedOut) return;
    state = SignedOut(reason: reason);
    try {
      await _store.clear();
    } catch (e) {
      debugPrint('[session] could not clear the stored session: $e');
    }
    // Photos seen online stay with the person who saw them.
    await PhotoCache.current?.forgetAll();
  }
}
