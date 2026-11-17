import 'package:flutter/foundation.dart';

import '../core/access/access.dart';
import '../core/session/session_controller.dart';
import 'routes.dart';

/// What this phone knows about the way in: the PIN, the tour, and the lock
/// handing over to Sign in.
@immutable
class WayIn {
  const WayIn({
    this.ready = true,
    this.pinDue = false,
    this.tourDue = false,
    this.readyDue = false,
    this.passwordMode = false,
  });

  /// The lock settings and the tour's memory have been read.
  final bool ready;

  /// A password sign-in still has to set this phone's PIN (2.4).
  final bool pinDue;

  /// The first-time tour (17.7) hasn't been shown on this phone.
  final bool tourDue;

  /// Getting ready (2.7) comes next: the PIN or the outlet was just set and
  /// the Offline add-on is on, so the first copy comes down before Home.
  final bool readyDue;

  /// The app is locked and the person chose to sign in with the password
  /// (3.0 / 3.1 / 3.2 → Sign in). Only Sign in and Forgot password open.
  final bool passwordMode;

  @override
  bool operator ==(Object other) =>
      other is WayIn &&
      other.ready == ready &&
      other.pinDue == pinDue &&
      other.tourDue == tourDue &&
      other.readyDue == readyDue &&
      other.passwordMode == passwordMode;

  @override
  int get hashCode =>
      Object.hash(ready, pinDue, tourDue, readyDue, passwordMode);
}

/// Everything the guards look at, gathered so [resolveRedirect] is a plain
/// function the tests can call.
@immutable
class GuardInput {
  const GuardInput({
    required this.location,
    required this.session,
    this.access = const AccessState(),
    this.wayIn = const WayIn(),
    this.splashHeld = false,
  });

  /// The full location being opened, with its query (`/sign-in?from=…`).
  final Uri location;
  final SessionState session;
  final AccessState access;
  final WayIn wayIn;

  /// The splash is still being held after a cold start (splash_hold.dart).
  final bool splashHeld;
}

/// Where the person should be instead of [GuardInput.location], or null to
/// let them through. Board 19.17 is the rulebook; the checks run in this
/// order:
///
/// 1. An old app (below the server's minimum version), then maintenance
///    (503), is the only screen.
/// 2. While the session loads (and, signed in, this phone's lock and
///    tour), the splash.
/// 3. Signed out: only the public screens; a 401 lands on Signed out with
///    the route kept for after sign-in. Locked with "Sign in with
///    password" chosen: only Sign in and Forgot password.
/// 4. The way in (2.4 → 2.5 → 2.6 → terms → 16.7 → 2.7): a team member's
///    first password; this phone's PIN; choosing an outlet on a
///    multi-outlet brand; the owner accepts a new version of the terms; the
///    tour; then, after the PIN or the outlet was set with the Offline
///    add-on on, Getting ready before Home.
/// 5. Signed in on a public screen: back to where they were going, or Home.
/// 6. A removed package (or none): only Plan & billing and profile.
/// 7. Per route: owner-only routes and missing permissions for team
///    members; add-on routes when it is off (a lapsed Inventory still
///    opens, read-only).
String? resolveRedirect(GuardInput input) {
  final path = input.location.path;
  final access = input.access;

  // 1. An app too old for the server, then maintenance.
  if (access.updateRequired) {
    return path == V2Routes.updateRequired ? null : V2Routes.updateRequired;
  }
  if (path == V2Routes.updateRequired) return V2Routes.launch;
  if (access.maintenance) {
    return path == V2Routes.maintenance ? null : V2Routes.maintenance;
  }
  if (path == V2Routes.maintenance) return V2Routes.launch;

  // 2. A cold start shows the splash for a moment (1.1, 1.2); a link that
  //    opened the app waits for it.
  if (input.splashHeld) {
    if (path == V2Routes.launch) return null;
    return _with(V2Routes.launch, from: _keep(input.location));
  }

  switch (input.session) {
    // 2. Reading the stored session.
    case SessionLoading():
      if (path == V2Routes.launch) return null;
      return _with(V2Routes.launch, from: _keep(input.location));

    // 3. Signed out.
    case SignedOut(:final reason):
      if (V2Routes.isPublic(path)) return null;
      final from = _keep(input.location);
      switch (reason) {
        case SignOutReason.expired when from != null:
          return _with(V2Routes.signedOut, from: from);
        // A deep link opened while signed out waits for the sign-in.
        case SignOutReason.notSignedIn when from != null:
          return _with(V2Routes.signIn, from: from);
        default:
          return V2Routes.welcome;
      }

    case SignedIn(:final session):
      final who = session.who;
      final wayIn = input.wayIn;

      // 2. This phone's lock and tour are still being read.
      if (!wayIn.ready) {
        if (path == V2Routes.launch) return null;
        return _with(V2Routes.launch, from: _keep(input.location));
      }

      // 3. Locked, signing in again with the password.
      if (wayIn.passwordMode) {
        if (path == V2Routes.signIn ||
            path == V2Routes.forgot ||
            path.startsWith('${V2Routes.forgot}/')) {
          return null;
        }
        return _with(V2Routes.signIn, from: _keep(input.location));
      }

      // Where they were going, carried through the steps on the way in.
      final from = _safeFrom(input.location.queryParameters['from']);
      String step(String route) =>
          path == route ? '' : _with(route, from: from);

      // 4. The team member's own password, this phone's PIN, the outlet,
      // new terms, the tour, Getting ready.
      if (who.mustChangePassword) {
        return _orNull(step(V2Routes.agentPassword));
      }
      if (wayIn.pinDue) return _orNull(step(V2Routes.setPin));
      if (!session.outletChosen) {
        return _orNull(step(V2Routes.chooseOutlet));
      }
      if (who.isOwner && access.mustAcceptTerms) {
        return _orNull(step(V2Routes.terms));
      }
      if (wayIn.tourDue) return _orNull(step(V2Routes.tour));
      if (wayIn.readyDue) return _orNull(step(V2Routes.gettingReady));

      // 5. Nothing left to do on the way in.
      if (V2Routes.isPublic(path) || V2Routes.wayIn.contains(path)) {
        return from ?? V2Routes.home;
      }

      // 6. No package.
      if (access.account.blocksApp) {
        final screen = access.account == AccountStatus.removed
            ? V2Routes.stateRemoved
            : V2Routes.stateNoPlan;
        if (path == screen) return null;
        final open = V2Routes.openWithoutPackage.any(
          (p) => path == p || path.startsWith('$p/'),
        );
        // A team member can't open Plan & billing; the state screen says
        // who can.
        return open && who.isOwner ? null : screen;
      }
      if (path == V2Routes.stateRemoved || path == V2Routes.stateNoPlan) {
        return V2Routes.home;
      }

      // 7. Route rules.
      for (final rule in routeRules) {
        if (!rule.matches(path)) continue;
        if (rule.ownerOnly && !who.isOwner) return V2Routes.notInRole;
        if (rule.anyOf.isNotEmpty && !who.canAny(rule.anyOf)) {
          return V2Routes.notInRole;
        }
        // Unknown add-ons don't redirect yet; the screen waits for them. A
        // lapsed add-on's screens open read-only where the rule allows.
        if (rule.addon case final addon?
            when access.addons != null &&
                !(rule.readWhenLapsed
                    ? access.canRead(addon)
                    : access.has(addon))) {
          return V2Routes.home;
        }
        break;
      }
      return null;
  }
}

/// The location worth coming back to: not the splash, not a public screen.
String? _keep(Uri location) {
  final path = location.path;
  if (path == V2Routes.launch || V2Routes.isPublic(path)) {
    return _safeFrom(location.queryParameters['from']);
  }
  return location.toString();
}

/// Only paths inside the app; never `//host` or a full URL.
String? _safeFrom(String? from) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) {
    return null;
  }
  return from;
}

/// An empty string means "stay"; the router wants null for that.
String? _orNull(String s) => s.isEmpty ? null : s;

String _with(String path, {String? from}) => from == null
    ? path
    : Uri(path: path, queryParameters: {'from': from}).toString();
