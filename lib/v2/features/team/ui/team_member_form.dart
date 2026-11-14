import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/ids.dart';
import '../../../core/session/session.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/team_models.dart';
import '../data/team_repository.dart';
import '../data/team_rules.dart';
import 'team_parts.dart';

/// Add team member (11.2), or change one ([member]; the mobile number is
/// their username and stays). Name, mobile, email (optional), a brand role
/// from the ready-made and own roles (Stock keeper only with Inventory:
/// the server's list), and where they work on a multi-outlet brand.
///
/// A team manager who isn't the owner sees only the roles they may give
/// and, when limited to outlets, only those outlets.
class TeamMemberForm extends ConsumerStatefulWidget {
  const TeamMemberForm({super.key, this.member});

  final TeamMember? member;

  @override
  ConsumerState<TeamMemberForm> createState() => _TeamMemberFormState();
}

class _TeamMemberFormState extends ConsumerState<TeamMemberForm> {
  AppLocalizations get l => AppLocalizations.of(context);

  late final _name = TextEditingController(text: widget.member?.name);
  late final _phone = TextEditingController(
    text: widget.member?.phone == null
        ? null
        : AtomIds.formatMobile(widget.member!.phone!),
  );
  late final _email = TextEditingController(text: widget.member?.email);
  late int? _roleId = widget.member?.role?.id;
  late String? _scope = widget.member?.scope;
  late Set<int> _outletIds = {...?widget.member?.outlets.map((o) => o.$1)};

  bool _saving = false;
  Map<String, String> _errors = const {};
  String? _error;

  bool get _isNew => widget.member == null;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _dirty {
    final m = widget.member;
    if (m == null) {
      return _name.text.trim().isNotEmpty ||
          _phone.text.trim().isNotEmpty ||
          _email.text.trim().isNotEmpty ||
          _roleId != null;
    }
    final before = {...m.outlets.map((o) => o.$1)};
    return _name.text.trim() != m.name ||
        _email.text.trim() != (m.email ?? '') ||
        _roleId != m.role?.id ||
        _scope != m.scope ||
        (_scope == 'outlets' &&
            (before.length != _outletIds.length ||
                !before.containsAll(_outletIds)));
  }

  void _changed([String? field]) => setState(() {
    if (field != null && _errors.containsKey(field)) {
      _errors = {..._errors}..remove(field);
    }
    _error = null;
  });

  static const _fields = {
    'name',
    'phone',
    'email',
    'brand_role_id',
    'scope',
    'outlet_ids',
  };

  void _refused(ApiFailure failure) {
    final l = AppLocalizations.of(context);
    final shown = {
      for (final e in failure.fieldErrors.entries)
        if (_fields.contains(e.key.split('.').first))
          e.key.split('.').first: e.value,
    };
    setState(() {
      _saving = false;
      _errors = shown;
      _error = shown.isEmpty ? sayFailure(l, failure) : null;
    });
  }

  Future<void> _save(MemberDraft draft) async {
    setState(() {
      _saving = true;
      _error = null;
      _errors = const {};
    });
    final repo = ref.read(teamRepositoryProvider);
    if (_isNew) {
      final r = await repo.add(draft);
      if (!mounted) return;
      switch (r) {
        case ApiOk(:final value):
          refreshTeam(ref);
          context.pushReplacement(V2Routes.teamAdded, extra: value);
        case ApiErr(:final failure):
          _refused(failure);
      }
    } else {
      final r = await repo.update(widget.member!.id, draft);
      if (!mounted) return;
      switch (r) {
        case ApiOk():
          refreshTeam(ref);
          showAtomToast(context, kind: AtomToastKind.ok, message: l.teamSaved);
          Navigator.of(context).pop();
        case ApiErr(:final failure):
          _refused(failure);
      }
    }
  }

  Future<void> _pickOutlets(List<Outlet> outlets) async {
    final picked = await showAtomMultiSelect<int>(
      context,
      title: l.teamPickOutlets,
      searchHint: l.teamSearchOutlets,
      selected: _outletIds,
      options: [
        for (final o in outlets) AtomOption(value: o.id, label: o.name),
      ],
    );
    if (picked == null || !mounted) return;
    _outletIds = picked;
    _changed('outlet_ids');
  }

  Widget? _fieldError(String key) => _errors[key] == null
      ? null
      : Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(_errors[key]!, style: AtomText.fieldError),
        );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: AtomText.fieldLabel),
  );

  Widget _frame(Widget body) => Scaffold(
    backgroundColor: AtomColors.paper,
    body: Column(
      children: [
        AtomFlowBar(
          leading: AtomFlowLeading.close,
          title: _isNew ? l.teamAddMember : l.teamEditMember,
        ),
        Expanded(child: body),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final session = watchSession(ref);
    final who = session?.who ?? const Who.owner();
    final online = watchOnline(ref);
    final rolesData = ref.watch(teamRolesProvider);
    final teamData = ref.watch(teamListProvider);

    if (rolesData.hasError && !rolesData.hasValue) {
      return _frame(
        teamFailure(rolesData.error!, () => ref.invalidate(teamRolesProvider)),
      );
    }
    final roles = rolesData.value;
    if (roles == null) {
      return _frame(const Center(child: AtomSpinner(size: 28)));
    }

    final pickable = grantableRoles(roles.roles, who);
    // A member's current role stays on the list even if it couldn't be
    // given now, so changing their name doesn't drop it.
    final current = roles.byId(widget.member?.role?.id);
    final roleList = [
      ...pickable,
      if (current != null && !pickable.contains(current)) current,
    ];
    final scopes = scopesFor(teamData.value?.scopes ?? const ['all'], who);
    final multi = scopes.contains('outlets');
    final scope = scopes.contains(_scope)
        ? _scope
        : (scopes.length == 1 ? scopes.first : null);
    final outlets = [
      for (final o in session?.outlets ?? const <Outlet>[])
        if (who.worksIn(o.id)) o,
    ];

    final blocker = memberFormBlocker(
      l,
      name: _name.text,
      mobile: _isNew ? _phone.text : null,
      email: _email.text,
      roleId: roleList.any((r) => r.id == _roleId) ? _roleId : null,
      scope: scope,
      outletIds: _outletIds,
    );
    final String button;
    VoidCallback? onSave;
    if (!online) {
      button = l.teamNeedsInternet;
    } else if (blocker != null) {
      button = blocker;
    } else if (!_isNew && !_dirty) {
      button = l.teamNoChanges;
    } else {
      button = _isNew ? l.teamAddMember : l.teamSave;
      final m = widget.member;
      onSave = () => _save(
        MemberDraft(
          name: _name.text.trim(),
          phone: _isNew ? AtomIds.normaliseMobile(_phone.text) : null,
          email: _email.text.trim(),
          cnic: m?.cnic,
          roleId: _roleId!,
          scope: scope!,
          outletIds: [
            for (final o in outlets)
              if (_outletIds.contains(o.id)) o.id,
          ],
        ),
      );
    }

    final typedMobile = AtomIds.digits(_phone.text).length >= 11;
    final name = AtomTextField(
      label: l.teamFullName,
      controller: _name,
      error:
          _errors['name'] ??
          (_name.text.trim().isNotEmpty ? nameProblem(l, _name.text) : null),
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.name],
      onChanged: (_) => _changed('name'),
    );
    final phone = AtomTextField(
      label: l.teamMobile,
      controller: _phone,
      enabled: _isNew,
      placeholder: '03xx xxxx xxx',
      keyboardType: TextInputType.phone,
      inputFormatters: [MobileInputFormatter()],
      error:
          _errors['phone'] ??
          (_isNew && typedMobile ? mobileProblem(l, _phone.text) : null),
      textInputAction: TextInputAction.next,
      onChanged: (_) => _changed('phone'),
    );
    final email = AtomTextField(
      label: l.teamEmailOptional,
      controller: _email,
      placeholder: 'name@example.pk',
      keyboardType: TextInputType.emailAddress,
      error: _errors['email'] ?? emailProblem(l, _email.text),
      onChanged: (_) => _changed('email'),
    );
    final wide =
        MediaQuery.sizeOf(context).width >= 420 &&
        MediaQuery.textScalerOf(context).scale(10) < 13;

    return TeamFormFrame(
      title: _isNew ? l.teamAddMember : l.teamEditMember,
      dirty: _dirty,
      saving: _saving,
      button: button,
      onSave: onSave,
      error: _error,
      children: [
        name,
        const SizedBox(height: AtomSpace.s3),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: phone),
              const SizedBox(width: AtomSpace.s3),
              Expanded(child: email),
            ],
          )
        else ...[
          phone,
          const SizedBox(height: AtomSpace.s3),
          email,
        ],
        const SizedBox(height: 6),
        Text(
          _isNew ? l.teamMobileHint : l.teamMobileFixed,
          style: AtomText.secondary.copyWith(color: AtomColors.faint),
        ),
        const SizedBox(height: AtomSpace.s4),
        _label(l.teamRole),
        for (final r in roleList) ...[
          _RoleOption(
            role: r,
            selected: r.id == _roleId,
            onTap: () {
              _roleId = r.id;
              _changed('brand_role_id');
            },
          ),
          const SizedBox(height: 6),
        ],
        ?_fieldError('brand_role_id'),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AtomTextLink(
            label: l.teamRolesAndPermissions,
            onTap: () => context.push(V2Routes.teamRoles),
          ),
        ),
        if (multi) ...[
          const SizedBox(height: AtomSpace.s3),
          _label(l.teamWorksIn),
          if (scopes.length > 1)
            AtomSegmented<String>(
              segments: [
                for (final s in scopes)
                  AtomSegment(
                    s,
                    s == 'all' ? l.teamEveryOutlet : l.teamSomeOutlets,
                  ),
              ],
              selected: scope ?? '',
              onChanged: (s) {
                _scope = s;
                _changed('scope');
              },
            ),
          if (scope != null) ...[
            const SizedBox(height: 5),
            Text(
              scope == 'all' ? l.teamEveryOutletHint : l.teamSomeOutletsHint,
              style: AtomText.secondary.copyWith(color: AtomColors.faint),
            ),
          ],
          ?_fieldError('scope'),
          if (scope == 'outlets') ...[
            const SizedBox(height: AtomSpace.s3),
            Wrap(
              spacing: AtomSpace.s2,
              runSpacing: AtomSpace.s2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final o in outlets.take(outlets.length > 8 ? 6 : 8))
                  TeamToggleChip(
                    label: o.name,
                    on: _outletIds.contains(o.id),
                    onTap: () {
                      _outletIds = _outletIds.contains(o.id)
                          ? ({..._outletIds}..remove(o.id))
                          : {..._outletIds, o.id};
                      _changed('outlet_ids');
                    },
                  ),
                if (outlets.length > 8)
                  AtomButton.small(
                    label: l.teamAllOutlets,
                    icon: LucideIcons.search,
                    onPressed: () => _pickOutlets(outlets),
                  ),
              ],
            ),
            ?_fieldError('outlet_ids'),
          ],
        ],
      ],
    );
  }
}

/// A role to pick (`.roles button`): a radio, its name and what it covers.
class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final TeamRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sum = roleSummary(role);
    return AtomPressable(
      onTap: onTap,
      selected: selected,
      scaleOnPress: false,
      semanticLabel: [role.name, if (sum.isNotEmpty) sum].join(', '),
      builder: (_, pressed) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 11 : 12,
          vertical: selected ? 7 : 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AtomColors.primarySoft
              : (pressed ? AtomColors.head : AtomColors.paper),
          borderRadius: AtomRadius.brControl,
          border: Border.all(
            color: selected ? AtomColors.primary : AtomColors.line2,
            width: selected ? 2 : 1,
          ),
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              AtomRadio(on: selected),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.name,
                      style: AtomText.body.copyWith(
                        color: AtomColors.ink,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    if (sum.isNotEmpty) Text(sum, style: AtomText.small),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
