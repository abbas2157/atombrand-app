// Team & roles (11.1–11.6): the permission switches, who may change whom,
// the words on a member row, the add form's checks and the server's shapes.

import 'package:atombrand_app/l10n/app_localizations.dart';
import 'package:atombrand_app/v2/core/session/session.dart';
import 'package:atombrand_app/v2/features/team/data/team_models.dart';
import 'package:atombrand_app/v2/features/team/data/team_rules.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final l = lookupAppLocalizations(const Locale('en'));

TeamRole _role(int id, List<String> perms, {bool ready = true, String? name}) =>
    TeamRole(
      id: id,
      name: name ?? 'Role $id',
      readyMade: ready,
      permissions: perms,
    );

TeamMember _member({
  int id = 1,
  int? userId = 10,
  MemberStatus status = MemberStatus.active,
  DateTime? last,
  DateTime? off,
  int roleId = 1,
}) => TeamMember(
  id: id,
  userId: userId,
  name: 'Usman Ali',
  status: status,
  lastActiveAt: last,
  switchedOffAt: off,
  role: RoleRef(id: roleId, name: 'Order handler'),
);

const _manager = Who(
  isOwner: false,
  permissions: {
    'orders.view',
    'orders.status',
    'catalogue.view',
    'team.manage',
  },
  outletIds: [4],
);

void main() {
  group('permissions', () {
    test('a "do" brings its "see"', () {
      expect(withNeeded({'orders.payment', 'money.export'}), {
        'orders.payment',
        'orders.view',
        'money.export',
        'money.reports',
      });
    });

    test(
      'turning a do on turns its see on; turning the see off turns the do off',
      () {
        var on = flipPermission({}, 'bulk.quote');
        expect(on, {'bulk.quote', 'bulk.view'});
        on = flipPermission(on, 'bulk.view');
        expect(on, isEmpty);
      },
    );

    test('turning a do off keeps its see', () {
      expect(
        flipPermission({'orders.view', 'orders.status'}, 'orders.status'),
        {'orders.view'},
      );
    });

    test('All turns a whole group on, then off', () {
      const keys = [
        'orders.view',
        'orders.status',
        'orders.payment',
        'orders.cancel',
      ];
      var on = toggleGroup({'home.totals', 'orders.view'}, keys);
      expect(on, {'home.totals', ...keys});
      on = toggleGroup(on, keys);
      expect(on, {'home.totals'});
    });

    test('saved in the menu order, only what the brand can give', () {
      const groups = [
        PermissionGroup(
          name: 'Home',
          permissions: [('home.totals', 'See business totals')],
        ),
        PermissionGroup(
          name: 'Orders',
          permissions: [
            ('orders.view', 'See orders'),
            ('orders.status', 'Confirm'),
          ],
        ),
      ];
      expect(
        orderedPermissions({
          'orders.status',
          'stock.view',
          'home.totals',
          'orders.view',
        }, groups),
        ['home.totals', 'orders.view', 'orders.status'],
      );
    });

    test(
      'role chips keep the server order and drop what the brand can’t give',
      () {
        // "Orders" is working orders (orders.status), as the board words it.
        expect(
          roleChips(l, ['stock.view', 'orders.status', 'orders.payment']),
          ['Orders', 'Payments', 'See stock'],
        );
        expect(
          roleChips(
            l,
            ['stock.view', 'orders.status'],
            grantable: {'orders.status'},
          ),
          ['Orders'],
        );
      },
    );

    test('a copy gets a free name within 40 letters', () {
      expect(
        copyName(l, 'Order handler', ['Order handler']),
        'Order handler copy',
      );
      expect(
        copyName(l, 'Order handler', ['order handler copy']),
        'Order handler copy 2',
      );
      final long = 'A' * 40;
      expect(copyName(l, long, const []).length, 40);
    });
  });

  group('who may do what', () {
    final roles = [
      _role(1, ['orders.view', 'orders.status']),
      _role(2, ['orders.view', 'orders.payment']),
      _role(3, ['orders.view', 'team.manage']),
    ];

    test('the owner may give any role', () {
      expect(grantableRoles(roles, const Who.owner()), roles);
    });

    test('a team manager gives only roles inside their own permissions, never Team', () {
      expect(grantableRoles(roles, _manager).map((r) => r.id), [1]);
    });

    test('a team manager can’t change themselves or another team manager', () {
      final all = TeamRoles(roles: roles);
      expect(
        canChangeMember(_member(roleId: 1), _manager, myUserId: 99, roles: all),
        isTrue,
      );
      expect(
        canChangeMember(_member(roleId: 3), _manager, myUserId: 99, roles: all),
        isFalse,
      );
      expect(
        canChangeMember(
          _member(userId: 99),
          _manager,
          myUserId: 99,
          roles: all,
        ),
        isFalse,
      );
      expect(
        canChangeMember(_member(roleId: 3), const Who.owner(), myUserId: 1),
        isTrue,
      );
    });

    test('until the roles are known a team manager can’t change anyone', () {
      expect(canChangeMember(_member(), _manager, myUserId: 99), isFalse);
    });

    test('a member limited to outlets can’t give Every outlet', () {
      expect(scopesFor(['all', 'outlets'], _manager), ['outlets']);
      expect(scopesFor(['all', 'outlets'], const Who.owner()), [
        'all',
        'outlets',
      ]);
    });
  });

  group('member row words', () {
    final now = DateTime(2026, 11, 14, 11);

    test('works in', () {
      expect(worksIn(l, _member()), 'Every outlet');
      expect(
        worksIn(
          l,
          const TeamMember(
            id: 1,
            name: 'H',
            scope: 'outlets',
            outlets: [(4, 'Head office'), (9, 'Karachi outlet')],
          ),
        ),
        'Head office, Karachi outlet',
      );
    });

    test('last active', () {
      expect(
        seenLine(
          l,
          _member(last: now.subtract(const Duration(minutes: 2))),
          now: now,
        ).$1,
        'Active now',
      );
      final today = seenLine(
        l,
        _member(last: DateTime(2026, 11, 14, 9, 15)),
        now: now,
      );
      expect(today.$1, 'Active 9:15 am');
      expect(today.$2, SeenTone.now);
      final yesterday = seenLine(
        l,
        _member(last: DateTime(2026, 11, 13, 18)),
        now: now,
      );
      expect(yesterday, ('Last active yesterday', SeenTone.earlier));
      expect(
        seenLine(l, _member(last: DateTime(2026, 11, 3)), now: now).$1,
        'Last active 3 Nov',
      );
    });

    test('waiting and switched off', () {
      expect(seenLine(l, _member(status: MemberStatus.waiting), now: now), (
        'Temporary: not signed in yet',
        SeenTone.never,
      ));
      expect(
        seenLine(
          l,
          _member(status: MemberStatus.off, off: DateTime(2026, 10, 12)),
          now: now,
        ).$1,
        "Switched off 12 Oct · can't sign in",
      );
      expect(statusLabel(l, MemberStatus.waiting), 'Waiting to sign in');
    });

    test('active today leaves out the switched off', () {
      final members = [
        _member(last: DateTime(2026, 11, 14, 8)),
        _member(last: DateTime(2026, 11, 13, 8)),
        _member(status: MemberStatus.off, last: DateTime(2026, 11, 14, 8)),
      ];
      expect(activeToday(members, now: now), 1);
    });
  });

  group('the add form', () {
    test('name: letters and spaces only', () {
      expect(nameProblem(l, 'Usman Ali'), isNull);
      expect(nameProblem(l, ''), isNotNull);
      expect(nameProblem(l, 'Usman 2'), isNotNull);
    });

    test('mobile and email', () {
      expect(mobileProblem(l, '0311 2290 774'), isNull);
      expect(mobileProblem(l, '0421234567'), isNotNull);
      expect(emailProblem(l, ''), isNull);
      expect(emailProblem(l, 'name@zenvo.pk'), isNull);
      expect(emailProblem(l, 'name@'), isNotNull);
    });

    test('the button says what is missing, in order', () {
      String? b({
        String name = 'Usman Ali',
        String? mobile = '03112290774',
        String email = '',
        int? role = 1,
        String? scope = 'outlets',
        Set<int> outlets = const {4},
      }) => memberFormBlocker(
        l,
        name: name,
        mobile: mobile,
        email: email,
        roleId: role,
        scope: scope,
        outletIds: outlets,
      );
      expect(b(), isNull);
      expect(b(name: ''), 'Enter their name');
      expect(b(mobile: ''), 'Enter their mobile number');
      expect(b(mobile: '0300'), 'Check the mobile number');
      expect(
        b(mobile: null),
        isNull,
        reason: 'a member being changed keeps their mobile',
      );
      expect(b(email: 'x@'), 'Check the email');
      expect(b(role: null), 'Choose a role');
      expect(b(scope: null), 'Choose where they work');
      expect(b(outlets: const {}), 'Pick at least one outlet');
      expect(b(scope: 'all', outlets: const {}), isNull);
    });

    test('the body sends outlets only for Only some outlets', () {
      const draft = MemberDraft(
        name: 'U',
        roleId: 2,
        scope: 'all',
        phone: '03112290774',
        outletIds: [4],
      );
      expect(draft.toBody(), {
        'name': 'U',
        'phone': '03112290774',
        'email': null,
        'brand_role_id': 2,
        'scope': 'all',
        'outlet_ids': const <int>[],
      });
    });
  });

  group('server shapes', () {
    test('a member', () {
      final m = TeamMember.fromJson({
        'id': 5,
        'user_id': '77',
        'name': 'Hira Shah',
        'phone': '03001234567',
        'role': {'id': 3, 'name': 'Stock keeper', 'key': 'stock'},
        'scope': 'outlets',
        'outlets': [
          {'id': 4, 'name': 'Head office'},
        ],
        'status': 'waiting',
        'must_change_password': 1,
        'last_active_at': null,
        'created_at': '2026-07-12 10:00:00',
      });
      expect(m.userId, 77);
      expect(m.role?.name, 'Stock keeper');
      expect(m.outlets, [(4, 'Head office')]);
      expect(m.status, MemberStatus.waiting);
      expect(m.mustChangePassword, isTrue);
      expect(m.createdAt, isNotNull);
    });

    test('roles and permission groups keep the server order', () {
      final r = TeamRoles.fromJson({
        'roles': [
          {
            'id': 1,
            'name': 'Outlet manager',
            'ready_made': true,
            'permissions': ['orders.view'],
          },
          {
            'id': 9,
            'name': 'Counter staff',
            'ready_made': false,
            'permissions': ['orders.view'],
          },
        ],
        'permission_groups': {
          'Home': {'home.totals': 'See business totals'},
          'Orders': {
            'orders.view': 'See orders',
            'orders.status': 'Confirm and change status',
          },
        },
      });
      expect(r.readyMade.single.id, 1);
      expect(r.own.single.name, 'Counter staff');
      expect(r.groups.map((g) => g.name), ['Home', 'Orders']);
      expect(r.groups[1].keys, ['orders.view', 'orders.status']);
      expect(r.labels['orders.status'], 'Confirm and change status');
    });

    test('a login', () {
      final l = TeamLogin.fromJson({
        'username': '03112290774',
        'temporary_password': 'KM7Q-4XNP',
        'whatsapp': '923112290774',
      });
      expect(l.password, 'KM7Q-4XNP');
      expect(l.whatsapp, '923112290774');
    });
  });

  test('role summary falls back to its groups', () {
    expect(
      roleSummary(
        const TeamRole(
          id: 1,
          name: 'X',
          summary: [
            ('Orders', ['See orders']),
            ('AtomPay', ['See']),
          ],
        ),
      ),
      'Orders, atompay',
    );
    expect(
      roleSummary(
        const TeamRole(id: 1, name: 'X', description: 'Walk-in help'),
      ),
      'Walk-in help',
    );
    expect(BrandPermission.all, contains('team.manage'));
  });
}
