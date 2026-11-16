// The team screens draw from the server's answers: the list with the owner
// first, the add form's roles and outlets, a member's page (actions only
// for who may change them), Roles and the role editor's All.

import 'package:atombrand_app/l10n/app_localizations.dart';
import 'package:atombrand_app/v2/core/access/access.dart';
import 'package:atombrand_app/v2/core/access/access_controller.dart';
import 'package:atombrand_app/v2/core/api/api_result.dart';
import 'package:atombrand_app/v2/core/net/network_status.dart';
import 'package:atombrand_app/v2/core/session/session.dart';
import 'package:atombrand_app/v2/core/session/session_controller.dart';
import 'package:atombrand_app/v2/design/design.dart';
import 'package:atombrand_app/v2/features/team/data/team_models.dart';
import 'package:atombrand_app/v2/features/team/data/team_repository.dart';
import 'package:atombrand_app/v2/features/team/ui/role_edit_screen.dart';
import 'package:atombrand_app/v2/features/team/ui/team_list_screen.dart';
import 'package:atombrand_app/v2/features/team/ui/team_member_form.dart';
import 'package:atombrand_app/v2/features/team/ui/team_member_screen.dart';
import 'package:atombrand_app/v2/features/team/ui/team_roles_screen.dart';
import 'package:atombrand_app/v2/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Session extends SessionController {
  _Session(this.session);
  final BrandSession session;
  @override
  SessionState build() => SignedIn(session);
}

class _Access extends AccessController {
  @override
  AccessState build() =>
      const AccessState(addonStates: {Addon.team: AddonState.active});
  @override
  Future<void> refreshIfStale() async {}
}

final _members = TeamList.fromJson({
  'scopes': ['all', 'outlets'],
  'members': [
    {
      'id': 1,
      'user_id': 11,
      'name': 'Usman Ali',
      'phone': '03112290774',
      'role': {'id': 2, 'name': 'Order handler'},
      'scope': 'outlets',
      'outlets': [
        {'id': 4, 'name': 'Head office'},
      ],
      'status': 'active',
    },
    {
      'id': 2,
      'user_id': 12,
      'name': 'Sara Malik',
      'phone': '03001112223',
      'role': {'id': 5, 'name': 'Marketing'},
      'scope': 'all',
      'status': 'waiting',
    },
    {
      'id': 3,
      'user_id': 13,
      'name': 'Naveed Akhtar',
      'role': {'id': 1, 'name': 'Outlet manager'},
      'scope': 'all',
      'status': 'off',
      'switched_off_at': '2026-10-12 10:00:00',
    },
  ],
});

final _roles = TeamRoles.fromJson({
  'roles': [
    {
      'id': 1,
      'name': 'Outlet manager',
      'ready_made': true,
      'description': 'Everything except outlets, settings and billing',
      'permissions': ['orders.view', 'orders.status', 'team.manage'],
    },
    {
      'id': 2,
      'name': 'Order handler',
      'ready_made': true,
      'permissions': ['orders.view', 'orders.status', 'orders.payment'],
    },
    {
      'id': 5,
      'name': 'Marketing',
      'ready_made': true,
      'permissions': ['catalogue.view', 'catalogue.edit', 'page.edit'],
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
      'orders.payment': 'Record payments',
      'orders.cancel': 'Cancel orders',
    },
    'Catalogue': {
      'catalogue.view': 'See products',
      'catalogue.edit': 'Add and edit products and prices',
      'page.edit': 'Edit the brand page',
    },
    'Team': {'team.manage': 'Add and change team members'},
  },
});

class _Repo implements TeamRepository {
  @override
  Future<ApiResult<TeamList>> members() async => ApiOk(_members);
  @override
  Future<ApiResult<TeamMember>> member(int id) async =>
      ApiOk(_members.members.firstWhere((m) => m.id == id));
  @override
  Future<ApiResult<TeamRoles>> roles() async => ApiOk(_roles);
  @override
  Future<ApiResult<MemberWithLogin>> add(MemberDraft draft) =>
      throw UnimplementedError();
  @override
  Future<ApiResult<TeamMember>> update(int id, MemberDraft draft) =>
      throw UnimplementedError();
  @override
  Future<ApiResult<TeamMember>> switchOff(int id) => throw UnimplementedError();
  @override
  Future<ApiResult<MemberWithLogin>> switchOn(int id) =>
      throw UnimplementedError();
  @override
  Future<ApiResult<MemberWithLogin>> reset(TeamMember member) =>
      throw UnimplementedError();
  @override
  Future<ApiResult<int>> signOutPhones(int id) => throw UnimplementedError();
  @override
  Future<ApiResult<int>> saveRole({
    int? id,
    required String name,
    String? description,
    required List<String> permissions,
  }) => throw UnimplementedError();
  @override
  Future<ApiResult<void>> deleteRole(int id) => throw UnimplementedError();
}

const _owner = BrandSession(
  token: 't',
  userId: 1,
  name: 'Asad Raza',
  brandName: 'Zenvo',
  who: Who.owner(),
  outlets: [
    Outlet(id: 4, name: 'Head office', isMain: true),
    Outlet(id: 9, name: 'Karachi outlet'),
  ],
);

const _manager = BrandSession(
  token: 't',
  userId: 11,
  name: 'Usman Ali',
  who: Who(
    isOwner: false,
    roleKey: 'manager',
    permissions: {'orders.view', 'orders.status', 'team.manage'},
    outletIds: [4],
  ),
);

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  BrandSession session = _owner,
  double width = 390,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width * 3, 2400 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(() => _Session(session)),
        accessProvider.overrideWith(_Access.new),
        onlineProvider.overrideWith((ref) => Stream.value(true)),
        teamRepositoryProvider.overrideWithValue(_Repo()),
      ],
      child: MaterialApp(
        theme: AtomTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Team: the owner first, active members, then switched off on its chip',
    (tester) async {
      await _pump(tester, const TeamListScreen());
      expect(find.text('Asad Raza'), findsOneWidget);
      expect(find.text('Usman Ali'), findsOneWidget);
      expect(find.text('Order handler · Head office'), findsOneWidget);
      expect(find.text('Waiting to sign in'), findsWidgets);
      expect(find.text('Naveed Akhtar'), findsNothing);

      await tester.tap(find.text('Switched off'));
      await tester.pumpAndSettle();
      expect(find.text('Naveed Akhtar'), findsOneWidget);
      expect(find.text('Asad Raza'), findsNothing);
    },
  );

  testWidgets('Team: each row is its own node; Roles sits beside People', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, const TeamListScreen());
    expect(find.bySemanticsLabel(RegExp(r'^Asad Raza, Owner')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp(r'^Usman Ali, ')), findsWidgets);
    // not merged into one node (a tap at its middle hit the divider)
    expect(
      find.bySemanticsLabel(RegExp(r'Asad Raza.*Usman Ali')),
      findsNothing,
    );
    expect(find.bySemanticsLabel(RegExp(r'^Roles, 4$')), findsWidgets);
    handle.dispose();
  });

  testWidgets('Team list and Add stay inside 320dp at 200% text', (
    tester,
  ) async {
    await _pump(tester, const TeamListScreen(), width: 320, textScale: 2);
    expect(tester.takeException(), isNull);
    await _pump(tester, const TeamMemberForm(), width: 320, textScale: 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Add: every role for the owner, outlets for Only some outlets', (
    tester,
  ) async {
    await _pump(tester, const TeamMemberForm());
    expect(find.text('Outlet manager'), findsOneWidget);
    expect(find.text('Counter staff'), findsOneWidget);
    expect(find.text('Enter their name'), findsOneWidget);

    await tester.tap(find.text('Only some outlets'));
    await tester.pumpAndSettle();
    expect(find.text('Karachi outlet'), findsOneWidget);
  });

  testWidgets(
    'Add: a team manager gives only roles inside their own, in their outlets',
    (tester) async {
      await _pump(tester, const TeamMemberForm(), session: _manager);
      expect(
        find.text('Outlet manager'),
        findsNothing,
        reason: 'it manages the team',
      );
      expect(
        find.text('Marketing'),
        findsNothing,
        reason: 'outside their permissions',
      );
      expect(find.text('Counter staff'), findsOneWidget);
      expect(find.text('Every outlet'), findsNothing);
    },
  );

  testWidgets('A member page: Reset and Switch off for the owner', (
    tester,
  ) async {
    await _pump(tester, const TeamMemberScreen(id: 1));
    expect(find.text('Reset password'), findsOneWidget);
    expect(find.text('Switch off'), findsOneWidget);
  });

  testWidgets(
    'A member page: a team manager can’t change another team manager',
    (tester) async {
      await _pump(tester, const TeamMemberScreen(id: 3), session: _manager);
      expect(find.text('Switch on'), findsNothing);
      expect(
        find.text(
          'You can see this person, but only the owner can change them.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('Roles: yours and ready-made with people counts and Copy', (
    tester,
  ) async {
    await _pump(tester, const TeamRolesScreen());
    expect(find.text('Counter staff'), findsOneWidget);
    expect(find.text('1 person (switched off)'), findsOneWidget);
    expect(find.text('Copy'), findsNWidgets(3));
  });

  testWidgets('Role editor: All turns a group on, and a do brings its see', (
    tester,
  ) async {
    await _pump(tester, const RoleEditScreen());
    expect(find.text('Give the role a name'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Counter help');
    await tester.pumpAndSettle();
    expect(find.text('Turn on at least one permission'), findsOneWidget);

    await tester.tap(find.text('Record payments'));
    await tester.pumpAndSettle();
    expect(find.text('Save role'), findsOneWidget);
    final switches = tester
        .widgetList<AtomSwitch>(find.byType(AtomSwitch))
        .toList();
    // See orders came on with Record payments.
    expect(switches.where((s) => s.value).length, 2);
  });
}
