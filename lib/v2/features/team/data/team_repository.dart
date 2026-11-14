import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../../../core/app_providers.dart';
import '../../../core/session/session_controller.dart';
import 'team_models.dart';

/// Team & roles calls (atomshop `Api\BrandApp\TeamController`). Members
/// need `team.manage` and the Team add-on; role changes are the owner's.
abstract interface class TeamRepository {
  /// `GET team?status=all`.
  Future<ApiResult<TeamList>> members();

  /// `GET team/{id}`.
  Future<ApiResult<TeamMember>> member(int id);

  /// `POST team`: answers with the temporary password, once.
  Future<ApiResult<MemberWithLogin>> add(MemberDraft draft);

  /// `POST team/{id}`: the same fields without the phone.
  Future<ApiResult<TeamMember>> update(int id, MemberDraft draft);

  /// `POST team/{id}/switch` `status=off`: signed out everywhere.
  Future<ApiResult<TeamMember>> switchOff(int id);

  /// `POST team/{id}/switch` `status=on`: with a new temporary password.
  Future<ApiResult<MemberWithLogin>> switchOn(int id);

  /// `POST team/{id}/reset`: a new temporary password, signed out
  /// everywhere. The answer has no member: [member] is passed through.
  Future<ApiResult<MemberWithLogin>> reset(TeamMember member);

  /// `GET team/roles`.
  Future<ApiResult<TeamRoles>> roles();

  /// `POST team/roles` (new or a copy) or `POST team/roles/{id}` (owner).
  Future<ApiResult<int>> saveRole({
    int? id,
    required String name,
    String? description,
    required List<String> permissions,
  });

  /// `POST team/roles/{id}/delete`: refused while anyone has the role.
  Future<ApiResult<void>> deleteRole(int id);
}

class ApiTeamRepository implements TeamRepository {
  const ApiTeamRepository(this._api);

  final ApiClient _api;

  static TeamMember _member(Object? d) =>
      TeamMember.fromJson(Json.map(d)['member']);

  static MemberWithLogin _withLogin(Object? d) =>
      (member: _member(d), login: TeamLogin.fromJson(Json.map(d)['login']));

  @override
  Future<ApiResult<TeamList>> members() =>
      _api.get('team', query: {'status': 'all'}, parse: TeamList.fromJson);

  @override
  Future<ApiResult<TeamMember>> member(int id) =>
      _api.get('team/$id', parse: _member);

  @override
  Future<ApiResult<MemberWithLogin>> add(MemberDraft draft) =>
      _api.post('team', body: draft.toBody(), parse: _withLogin);

  @override
  Future<ApiResult<TeamMember>> update(int id, MemberDraft draft) => _api.post(
    'team/$id',
    body: draft.toBody()..remove('phone'),
    parse: _member,
  );

  @override
  Future<ApiResult<TeamMember>> switchOff(int id) =>
      _api.post('team/$id/switch', body: {'status': 'off'}, parse: _member);

  @override
  Future<ApiResult<MemberWithLogin>> switchOn(int id) =>
      _api.post('team/$id/switch', body: {'status': 'on'}, parse: _withLogin);

  @override
  Future<ApiResult<MemberWithLogin>> reset(TeamMember member) => _api.post(
    'team/${member.id}/reset',
    parse: (d) =>
        (member: member, login: TeamLogin.fromJson(Json.map(d)['login'])),
  );

  @override
  Future<ApiResult<TeamRoles>> roles() =>
      _api.get('team/roles', parse: TeamRoles.fromJson);

  @override
  Future<ApiResult<int>> saveRole({
    int? id,
    required String name,
    String? description,
    required List<String> permissions,
  }) => _api.post(
    id == null ? 'team/roles' : 'team/roles/$id',
    body: {
      'name': name,
      'description': (description == null || description.trim().isEmpty)
          ? null
          : description.trim(),
      'permissions': permissions,
    },
    parse: (d) => Json.integer(Json.map(Json.map(d)['role'])['id']) ?? id ?? 0,
  );

  @override
  Future<ApiResult<void>> deleteRole(int id) =>
      _api.post('team/roles/$id/delete', parse: (_) {});
}

final teamRepositoryProvider = Provider<TeamRepository>(
  (ref) => ApiTeamRepository(ref.read(apiClientProvider)),
);

/// Who and which outlet the answers belong to: a new sign-in or outlet
/// reads them again.
Object? _brandKey(Ref ref) => ref.watch(
  sessionProvider.select(
    (s) => s is SignedIn ? (s.session.userId, s.session.outletId) : null,
  ),
);

T _value<T>(ApiResult<T> r) => switch (r) {
  ApiOk(:final value) => value,
  ApiErr(:final failure) => throw failure,
};

/// `GET team`.
final teamListProvider = FutureProvider.autoDispose<TeamList>((ref) async {
  _brandKey(ref);
  return _value(await ref.read(teamRepositoryProvider).members());
});

/// `GET team/{id}`.
final teamMemberProvider = FutureProvider.autoDispose.family<TeamMember, int>((
  ref,
  id,
) async {
  _brandKey(ref);
  return _value(await ref.read(teamRepositoryProvider).member(id));
});

/// `GET team/roles`.
final teamRolesProvider = FutureProvider.autoDispose<TeamRoles>((ref) async {
  _brandKey(ref);
  return _value(await ref.read(teamRepositoryProvider).roles());
});

/// Reads the team again after a change (the list, the pages and the
/// roles' people counts).
void refreshTeam(WidgetRef ref) => ref
  ..invalidate(teamListProvider)
  ..invalidate(teamMemberProvider);
