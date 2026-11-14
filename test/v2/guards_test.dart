// The guards decide where every person can go: signed out, agents, a
// removed package, add-ons that are off, maintenance. Board 19.17 is the
// rulebook these tests follow.

import 'package:atombrand_app/v2/app/guards.dart';
import 'package:atombrand_app/v2/app/routes.dart';
import 'package:atombrand_app/v2/core/access/access.dart';
import 'package:atombrand_app/v2/core/session/session.dart';
import 'package:atombrand_app/v2/core/session/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

const _owner = BrandSession(
  token: 't',
  userId: 1,
  name: 'Asad Rehman',
  who: Who.owner(),
);

final _agent = BrandSession(
  token: 't',
  userId: 2,
  name: 'Usman',
  who: const Who(
    isOwner: false,
    roleKey: 'order_handler',
    permissions: {'orders.view'},
  ),
);

const _allAddons = AccessState(
  addonStates: {
    Addon.inventory: AddonState.active,
    Addon.team: AddonState.active,
    Addon.askAtom: AddonState.active,
    Addon.alerts: AddonState.active,
    Addon.offline: AddonState.active,
  },
);

String? go(
  String location,
  SessionState session, {
  AccessState access = _allAddons,
}) => resolveRedirect(
  GuardInput(location: Uri.parse(location), session: session, access: access),
);

void main() {
  group('loading', () {
    test('shows the splash and keeps the link', () {
      expect(go('/', const SessionLoading()), isNull);
      expect(go('/orders/12', const SessionLoading()), '/?from=%2Forders%2F12');
    });
  });

  group('signed out', () {
    test('public screens open', () {
      for (final p in [
        V2Routes.welcome,
        V2Routes.signIn,
        V2Routes.forgot,
        V2Routes.forgotCode,
        V2Routes.forgotNew,
        V2Routes.forgotDone,
        V2Routes.signedOut,
      ]) {
        expect(go(p, const SignedOut()), isNull, reason: p);
      }
    });

    test('the splash goes to Welcome', () {
      expect(go('/', const SignedOut()), V2Routes.welcome);
    });

    test('a 401 lands on Signed out with the route kept', () {
      expect(
        go('/orders', const SignedOut(reason: SignOutReason.expired)),
        '/signed-out?from=%2Forders',
      );
    });

    test('choosing Sign out keeps nothing', () {
      expect(
        go('/menu', const SignedOut(reason: SignOutReason.chosen)),
        V2Routes.welcome,
      );
    });

    test('a deep link waits for sign-in', () {
      expect(
        go('/orders/12', const SignedOut()),
        '/sign-in?from=%2Forders%2F12',
      );
      expect(
        go('/?from=/orders/12', const SignedOut()),
        '/sign-in?from=%2Forders%2F12',
      );
    });
  });

  group('signed in', () {
    test('leaving the splash or sign-in goes Home', () {
      expect(go('/', const SignedIn(_owner)), V2Routes.home);
      expect(go('/sign-in', const SignedIn(_owner)), V2Routes.home);
    });

    test('goes back to the kept route after sign-in', () {
      expect(go('/sign-in?from=/orders', const SignedIn(_owner)), '/orders');
      expect(
        go('/signed-out?from=/orders/3', const SignedIn(_owner)),
        '/orders/3',
      );
    });

    test('never follows a from that leaves the app', () {
      expect(
        go('/sign-in?from=//evil.com', const SignedIn(_owner)),
        V2Routes.home,
      );
      expect(
        go('/sign-in?from=https://x.y', const SignedIn(_owner)),
        V2Routes.home,
      );
    });

    test('tabs open', () {
      for (final t in V2Routes.tabs) {
        expect(go(t, const SignedIn(_owner)), isNull, reason: t);
      }
    });
  });

  group('on the way in', () {
    final justSignedIn = SignedIn(_owner.copyWith(outletChosen: false));

    test('a multi-outlet brand chooses an outlet first, keeping where they were going', () {
      expect(
        go('/sign-in?from=/orders', justSignedIn),
        '/choose-outlet?from=%2Forders',
      );
      expect(go('/home', justSignedIn), V2Routes.chooseOutlet);
      expect(go('/choose-outlet?from=/orders', justSignedIn), isNull);
    });

    test('once the outlet is chosen, the kept route opens', () {
      expect(
        go('/choose-outlet?from=/orders', const SignedIn(_owner)),
        '/orders',
      );
      expect(go('/choose-outlet', const SignedIn(_owner)), V2Routes.home);
    });

    test('a new terms version comes before the app, for the owner only', () {
      const terms = AccessState(
        addonStates: {},
        terms: TermsStatus(version: '2', mustAccept: true),
      );
      expect(
        go('/home', const SignedIn(_owner), access: terms),
        V2Routes.terms,
      );
      expect(go(V2Routes.terms, const SignedIn(_owner), access: terms), isNull);
      expect(go('/home', SignedIn(_agent), access: terms), isNull);
      // Accepted: the terms screen moves on.
      expect(go(V2Routes.terms, const SignedIn(_owner)), V2Routes.home);
    });

    test('after the PIN or the outlet, Getting ready comes before Home', () {
      String? via(String location, {bool ready = true}) => resolveRedirect(
        GuardInput(
          location: Uri.parse(location),
          session: const SignedIn(_owner),
          access: _allAddons,
          wayIn: WayIn(readyDue: ready),
        ),
      );
      expect(via('/choose-outlet?from=/orders'), '/getting-ready?from=%2Forders');
      expect(via('/set-pin'), V2Routes.gettingReady);
      expect(via('/getting-ready?from=/orders'), isNull);
      // Start working now: on to where they were going.
      expect(via('/getting-ready?from=/orders', ready: false), '/orders');
      expect(via('/getting-ready', ready: false), V2Routes.home);
    });
  });

  group('agents', () {
    test('choose their password before anything else', () {
      final s = SignedIn(
        BrandSession(
          token: 't',
          userId: 2,
          name: 'Usman',
          who: const Who(isOwner: false, mustChangePassword: true),
        ),
      );
      expect(go('/home', s), V2Routes.agentPassword);
      expect(go(V2Routes.agentPassword, s), isNull);
    });

    test('owner-only routes say Not in your role', () {
      expect(go('/menu/plan', SignedIn(_agent)), V2Routes.notInRole);
      expect(go('/menu/outlets/4', SignedIn(_agent)), V2Routes.notInRole);
      // A permission the role lacks: Not in your role too.
      expect(go('/menu/team/4', SignedIn(_agent)), V2Routes.notInRole);
      expect(go('/order/abc', SignedIn(_agent)), isNull);
      expect(go('/menu/plan', const SignedIn(_owner)), isNull);
    });
  });

  group('add-ons', () {
    test('a route behind an add-on that is off goes Home', () {
      const noInventory = AccessState(
        addonStates: {
          Addon.inventory: AddonState.off,
          Addon.team: AddonState.trial,
        },
      );
      expect(
        go('/stock', const SignedIn(_owner), access: noInventory),
        V2Routes.home,
      );
      expect(
        go('/menu/team', const SignedIn(_owner), access: noInventory),
        isNull,
      );
    });

    test('a lapsed Inventory still opens, read-only; other add-ons do not', () {
      const lapsed = AccessState(
        addonStates: {
          Addon.inventory: AddonState.lapsed,
          Addon.team: AddonState.lapsed,
        },
      );
      expect(go('/stock', const SignedIn(_owner), access: lapsed), isNull);
      expect(
        go('/stock/history', const SignedIn(_owner), access: lapsed),
        isNull,
      );
      expect(
        go('/menu/team', const SignedIn(_owner), access: lapsed),
        V2Routes.home,
      );
    });

    test('unknown add-ons do not redirect yet', () {
      expect(
        go('/stock', const SignedIn(_owner), access: const AccessState()),
        isNull,
      );
    });
  });

  group('billing', () {
    const removed = AccessState(
      addonStates: {},
      account: AccountStatus.removed,
    );

    test('a removed package leaves only My plan and profile', () {
      expect(
        go('/home', const SignedIn(_owner), access: removed),
        V2Routes.stateRemoved,
      );
      expect(go('/menu/plan', const SignedIn(_owner), access: removed), isNull);
      expect(
        go('/menu/profile', const SignedIn(_owner), access: removed),
        isNull,
      );
      expect(
        go(V2Routes.stateRemoved, const SignedIn(_owner), access: removed),
        isNull,
      );
    });

    test('an agent with a removed package gets the state screen', () {
      expect(
        go('/menu/plan', SignedIn(_agent), access: removed),
        V2Routes.stateRemoved,
      );
    });

    test('once paid, the state screen goes Home', () {
      expect(go(V2Routes.stateRemoved, const SignedIn(_owner)), V2Routes.home);
    });

    test('read-only does not move anyone (it is a banner)', () {
      const ro = AccessState(addonStates: {}, account: AccountStatus.readOnly);
      expect(go('/orders', const SignedIn(_owner), access: ro), isNull);
    });
  });

  group('maintenance', () {
    const m = AccessState(maintenance: true);

    test('is the only screen, signed in or not', () {
      expect(
        go('/home', const SignedIn(_owner), access: m),
        V2Routes.maintenance,
      );
      expect(
        go('/sign-in', const SignedOut(), access: m),
        V2Routes.maintenance,
      );
      expect(
        go(V2Routes.maintenance, const SignedIn(_owner), access: m),
        isNull,
      );
    });

    test('when it clears, the app starts again', () {
      expect(go(V2Routes.maintenance, const SignedIn(_owner)), V2Routes.launch);
    });
  });
}
