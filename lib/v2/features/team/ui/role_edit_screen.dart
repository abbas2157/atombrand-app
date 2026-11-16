import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/api/api_result.dart';
import '../../../core/session/session.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/team_models.dart';
import '../data/team_repository.dart';
import '../data/team_rules.dart';
import 'team_parts.dart';

/// A role (11.6): its name, description and a switch for each permission
/// in the server's `permission_groups` (their groups, order and words;
/// Inventory only with the add-on), with All per group. A "do" permission
/// brings its "see", as the server saves it.
///
/// [roleId] opens a role: the brand's own one to change, Copy or Delete
/// (refused by the server while anyone has it), or a ready-made one
/// read-only. Without it the screen makes a new role, filled from
/// [copyOf] when copying. Only the owner changes roles; anyone else sees
/// them read-only.
class RoleEditScreen extends ConsumerStatefulWidget {
  const RoleEditScreen({super.key, this.roleId, this.copyOf});

  final int? roleId;
  final TeamRole? copyOf;

  @override
  ConsumerState<RoleEditScreen> createState() => _RoleEditScreenState();
}

class _RoleEditScreenState extends ConsumerState<RoleEditScreen> {
  AppLocalizations get l => AppLocalizations.of(context);

  final _name = TextEditingController();
  final _description = TextEditingController();

  Set<String> _on = {};
  bool _ready = false;
  TeamRole? _role;
  Set<String> _before = {};

  /// Saving and deleting never overlap.
  _RoleBusy _busy = _RoleBusy.idle;
  bool get _saving => _busy == _RoleBusy.saving;
  bool get _deleting => _busy == _RoleBusy.deleting;
  String? _error;
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _start(TeamRoles all, TeamRole? role) {
    _ready = true;
    _role = role;
    final grantable = all.labels.keys.toSet();
    final from = role ?? widget.copyOf;
    if (from == null) return;
    _on = withNeeded(from.permissions.toSet()).intersection(grantable);
    _before = role == null ? {} : _on;
    _name.text = role != null
        ? role.name
        : copyName(l, from.name, all.roles.map((r) => r.name));
    _description.text = from.description ?? '';
  }

  bool get _dirty {
    final r = _role;
    if (r == null) {
      return _name.text.trim().isNotEmpty || _on.isNotEmpty;
    }
    return _name.text.trim() != r.name ||
        _description.text.trim() != (r.description ?? '') ||
        _before.length != _on.length ||
        !_before.containsAll(_on);
  }

  void _set(Set<String> on) => setState(() {
    _on = on;
    _error = null;
  });

  Future<void> _save(TeamRoles all) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = _RoleBusy.saving;
      _error = null;
      _nameError = null;
    });
    final r = await ref
        .read(teamRepositoryProvider)
        .saveRole(
          id: _role?.id,
          name: _name.text.trim(),
          description: _description.text,
          permissions: orderedPermissions(_on, all.groups),
        );
    if (!mounted) return;
    switch (r) {
      case ApiOk():
        ref.invalidate(teamRolesProvider);
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: l.teamRoleSaved,
        );
        Navigator.of(context).pop();
      case ApiErr(:final failure):
        setState(() {
          _busy = _RoleBusy.idle;
          _nameError = failure.fieldErrors['name'];
          _error = _nameError == null ? sayFailure(l, failure) : null;
        });
    }
  }

  Future<void> _delete(TeamRole role) async {
    final l = AppLocalizations.of(context);
    final ok = await showAtomConfirm(
      context,
      title: l.teamDeleteRoleTitle(role.name),
      body: l.teamDeleteRoleBody,
      confirmLabel: l.teamDeleteRole,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() {
      _busy = _RoleBusy.deleting;
      _error = null;
    });
    final r = await ref.read(teamRepositoryProvider).deleteRole(role.id);
    if (!mounted) return;
    switch (r) {
      case ApiOk():
        ref.invalidate(teamRolesProvider);
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: l.teamRoleDeleted,
        );
        Navigator.of(context).pop();
      case ApiErr(:final failure):
        setState(() {
          _busy = _RoleBusy.idle;
          _error = sayFailure(l, failure);
        });
    }
  }

  /// A white group (`.grp`): its name in capitals with All, then its rows.
  Widget _group(
    String title,
    List<Widget> rows, {
    VoidCallback? onAll,
    bool allOn = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: AtomDecor.card,
      foregroundDecoration: AtomDecor.cardOutline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              14,
              onAll == null ? 10 : 2,
              4,
              onAll == null ? 4 : 0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title.toUpperCase(),
                      style: AtomText.section.copyWith(letterSpacing: 0.5),
                    ),
                  ),
                ),
                if (onAll != null)
                  TextButton(
                    onPressed: onAll,
                    child: Text(
                      l.teamAll,
                      semanticsLabel:
                          '${l.teamAll} $title${allOn ? ', on' : ''}',
                      style: AtomText.smallButton.copyWith(
                        color: AtomColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ...rows,
        ],
      ),
    ),
  );

  Widget _permRow(String key, String label, {required bool editable}) {
    final on = _on.contains(key);
    final sub = key == BrandPermission.homeTotals ? l.teamHomeTotalsSub : null;
    return AtomPressable(
      onTap: editable ? () => _set(flipPermission(_on, key)) : null,
      toggled: on,
      scaleOnPress: false,
      focusRadius: BorderRadius.zero,
      semanticLabel: [label, ?sub].join(', '),
      builder: (_, pressed) => Container(
        color: pressed ? AtomColors.head : AtomColors.paper,
        constraints: const BoxConstraints(minHeight: AtomSize.tapTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: AtomSpace.inset,
          vertical: AtomSpace.s2,
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AtomText.body.copyWith(color: AtomColors.ink),
                    ),
                    if (sub != null) Text(sub, style: AtomText.small),
                  ],
                ),
              ),
              const SizedBox(width: AtomSpace.s3),
              IgnorePointer(
                child: SizedBox(
                  width: AtomSize.switchWidth,
                  height: AtomSize.switchHeight,
                  child: OverflowBox(
                    maxWidth: AtomSize.tapTarget,
                    maxHeight: AtomSize.tapTarget,
                    child: AtomSwitch(
                      value: on,
                      onChanged: editable ? (_) {} : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _readOnly(TeamRoles all, TeamRole role, {required bool owner}) {
    final has = withNeeded(role.permissions.toSet());
    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AtomColors.paper,
              border: Border(bottom: BorderSide(color: AtomColors.line)),
            ),
            child: AtomFlowBar(title: l.teamRoleTitle(role.name)),
          ),
          Expanded(
            child: AtomReadableWidth(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AtomSpace.gutter,
                  AtomSpace.s3,
                  AtomSpace.gutter,
                  AtomSpace.s6,
                ),
                children: [
                  AtomNote(
                    kind: AtomNoteKind.info,
                    message: role.readyMade
                        ? l.teamReadyNote
                        : l.teamOwnerOnlyRoles,
                  ),
                  if (role.description case final d?) ...[
                    const SizedBox(height: AtomSpace.s3),
                    Text(d, style: AtomText.body),
                  ],
                  const SizedBox(height: AtomSpace.s3),
                  for (final g in all.groups)
                    _group(g.name, [
                      for (final (k, label) in g.permissions)
                        if (has.contains(k) || role.readyMade)
                          _readRow(
                            label,
                            has.contains(k),
                            sub: k == BrandPermission.homeTotals
                                ? l.teamHomeTotalsSub
                                : null,
                          ),
                    ]),
                  if (owner && role.readyMade && watchOnline(ref)) ...[
                    const SizedBox(height: AtomSpace.s2),
                    AtomButton(
                      label: '${l.teamCopy} ${role.name}',
                      icon: LucideIcons.copy,
                      onPressed: () => context.pushReplacement(
                        V2Routes.roleEdit(),
                        extra: role,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readRow(String label, bool on, {String? sub}) => Semantics(
    label: [label, ?sub, on ? l.teamSemOn : l.teamSemOff].join(', '),
    excludeSemantics: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AtomSpace.inset,
        vertical: AtomSpace.s2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AtomText.body.copyWith(
                    color: on ? AtomColors.ink : AtomColors.faint,
                  ),
                ),
                if (sub != null) Text(sub, style: AtomText.small),
              ],
            ),
          ),
          const SizedBox(width: AtomSpace.s3),
          Icon(
            on ? LucideIcons.check : LucideIcons.minus,
            size: 18,
            color: on ? AtomColors.green : AtomColors.chevron,
          ),
        ],
      ),
    ),
  );

  Widget _plain(Widget body) => Scaffold(
    body: Column(
      children: [
        const AtomFlowBar(),
        Expanded(child: body),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(teamRolesProvider);
    final owner = watchSession(ref)?.who.isOwner ?? false;
    final online = watchOnline(ref);
    final id = widget.roleId;

    final all = data.value;
    if (all == null) {
      return _plain(
        data.hasError
            ? teamFailure(data.error!, () => ref.invalidate(teamRolesProvider))
            : const Center(child: AtomSpinner(size: 28)),
      );
    }
    if (!_ready) {
      final role = all.byId(id);
      if (id != null && role == null) {
        return _plain(
          AtomMessageState(icon: LucideIcons.shield, title: l.teamRoleGone),
        );
      }
      _start(all, role);
    }

    final role = _role;
    if (role != null && (role.readyMade || !owner)) {
      return _readOnly(all, role, owner: owner);
    }
    if (role == null && !owner) {
      return _plain(
        AtomMessageState(icon: LucideIcons.shield, title: l.teamOwnerOnlyRoles),
      );
    }

    final noGroups = all.groups.isEmpty;
    final String button;
    VoidCallback? onSave;
    if (!online) {
      button = l.teamNeedsInternet;
    } else if (noGroups) {
      button = l.teamSaveRole;
    } else if (_name.text.trim().isEmpty) {
      button = l.teamNeedRoleName;
    } else if (_on.isEmpty) {
      button = l.teamNeedPermission;
    } else if (role != null && !_dirty) {
      button = l.teamNoChanges;
    } else {
      button = l.teamSaveRole;
      onSave = _deleting ? null : () => _save(all);
    }

    return TeamFormFrame(
      title: role == null ? l.teamNewRole : l.teamRoleTitle(role.name),
      close: false,
      surface: true,
      dirty: _dirty && !_deleting,
      saving: _saving,
      button: button,
      onSave: onSave,
      error: _error,
      children: [
        AtomTextField(
          label: l.teamRoleName,
          controller: _name,
          error: _nameError,
          inputFormatters: [LengthLimitingTextInputFormatter(40)],
          onChanged: (_) => setState(() {
            _nameError = null;
            _error = null;
          }),
        ),
        const SizedBox(height: AtomSpace.s3),
        AtomTextField(
          label: l.teamDescription,
          controller: _description,
          placeholder: l.teamDescriptionHint,
          inputFormatters: [LengthLimitingTextInputFormatter(200)],
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: AtomSpace.s3),
        if (noGroups) ...[
          AtomNote(kind: AtomNoteKind.problem, message: l.teamNoGroups),
          const SizedBox(height: AtomSpace.s2),
          AtomButton(
            label: AppLocalizations.of(context).commonTryAgain,
            kind: AtomButtonKind.outline,
            small: true,
            onPressed: () => ref.invalidate(teamRolesProvider),
          ),
        ],
        for (final g in all.groups)
          if (g.permissions.isNotEmpty)
            _group(
              g.name,
              [
                for (final (k, label) in g.permissions)
                  _permRow(k, label, editable: true),
              ],
              allOn: g.keys.every(_on.contains),
              onAll: () => _set(toggleGroup(_on, g.keys)),
            ),
        if (role != null && online) ...[
          const SizedBox(height: AtomSpace.s2),
          AtomButtonPair(
            first: AtomButton(
              label: l.teamCopy,
              kind: AtomButtonKind.outline,
              icon: LucideIcons.copy,
              onPressed: _saving || _deleting
                  ? null
                  : () => context.pushReplacement(
                      V2Routes.roleEdit(),
                      extra: role,
                    ),
            ),
            second: AtomButton(
              label: l.teamDelete,
              kind: AtomButtonKind.danger,
              icon: LucideIcons.trash2,
              saving: _deleting,
              onPressed: _saving ? null : () => _delete(role),
            ),
          ),
        ],
      ],
    );
  }
}

enum _RoleBusy { idle, saving, deleting }
