import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/team_models.dart';
import '../data/team_repository.dart';
import '../data/team_rules.dart';
import 'team_parts.dart';

/// Roles and permissions (11.5): the brand's own roles (Edit; Copy and
/// Delete on the role) and the ready-made ones, read-only with Copy, each
/// with what it covers and how many people have it. New role, and Compare
/// roles side by side. Making and changing roles is the owner's: a team
/// manager sees the roles only.
class TeamRolesScreen extends ConsumerWidget {
  const TeamRolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(teamRolesProvider);
    final members = ref.watch(teamListProvider).value?.members;
    final owner = watchSession(ref)?.who.isOwner ?? false;
    final online = watchOnline(ref);
    final canMake = owner && online;

    (int, int)? countOf(TeamRole r) {
      if (members == null) return null;
      final have = members.where((m) => m.role?.id == r.id);
      return (have.length, have.where((m) => m.isOff).length);
    }

    Widget row(TeamRole r, Set<String> grantable) {
      final n = countOf(r);
      final chips = roleChips(l, r.permissions, grantable: grantable);
      final sub = n == null
          ? roleSummary(r)
          : n.$2 == 0
          ? l.teamPeopleCount(n.$1)
          : n.$1 == n.$2
          ? l.teamPeopleAllOff(l.teamPeopleCount(n.$1))
          : l.teamPeopleSomeOff(l.teamPeopleCount(n.$1), n.$2);
      final Widget? trailing = !canMake
          ? null
          : r.readyMade
          ? AtomButton.small(
              label: l.teamCopy,
              onPressed: () => context.push(V2Routes.roleEdit(), extra: r),
            )
          : IgnorePointer(
              child: AtomButton.small(label: l.teamEdit, onPressed: () {}),
            );
      return AtomPressable(
        onTap: () => context.push(V2Routes.roleEdit(roleId: r.id)),
        scaleOnPress: false,
        focusRadius: BorderRadius.zero,
        semanticLabel: [r.name, sub, ...chips].join(', '),
        builder: (_, pressed) => Container(
          color: pressed ? AtomColors.head : AtomColors.paper,
          padding: const EdgeInsets.symmetric(
            horizontal: AtomSpace.inset,
            vertical: AtomSpace.s3,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: AtomIconTile(
                  icon: LucideIcons.user,
                  tone: r.readyMade ? AtomTone.grey : AtomTone.green,
                ),
              ),
              const SizedBox(width: AtomSpace.s3),
              Expanded(
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name, style: AtomText.listTitle),
                      if (sub.isNotEmpty) Text(sub, style: AtomText.secondary),
                      if (chips.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _Chips(chips),
                      ],
                    ],
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AtomSpace.s2),
                trailing,
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtomPageHeader(
            title: l.teamRoles,
            leading: AtomIconButton(
              icon: LucideIcons.chevronLeft,
              label: AppLocalizations.of(context).commonBack,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            actions: [
              if (data.value case final all? when all.roles.length > 1)
                AtomIconButton(
                  icon: LucideIcons.columns2,
                  label: l.teamCompare,
                  onTap: () => showRoleCompare(context, all),
                ),
              if (canMake)
                AtomButton.small(
                  label: l.teamNewRole,
                  kind: AtomButtonKind.primary,
                  onPressed: () => context.push(V2Routes.roleEdit()),
                ),
              const SizedBox(width: 4),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () {
                ref.invalidate(teamListProvider);
                return ref.refresh(teamRolesProvider.future);
              },
              child: AtomReadableWidth(
                maxWidth: 720,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AtomSpace.gutter,
                    AtomSpace.s3,
                    AtomSpace.gutter,
                    AtomSpace.s6,
                  ),
                  children: data.when(
                    skipLoadingOnRefresh: true,
                    loading: () => const [AtomLoadingRows()],
                    error: (e, _) => [
                      SizedBox(
                        height: 420,
                        child: teamFailure(
                          e,
                          () => ref.invalidate(teamRolesProvider),
                        ),
                      ),
                    ],
                    data: (all) {
                      final grantable = all.labels.keys.toSet();
                      final mine = all.own;
                      return [
                        if (!owner) ...[
                          AtomNote(
                            kind: AtomNoteKind.info,
                            message: l.teamOwnerOnlyRoles,
                          ),
                          const SizedBox(height: AtomSpace.s3),
                        ],
                        if (mine.isNotEmpty || canMake) ...[
                          AtomSectionLabel(l.teamYours, page: false),
                          if (mine.isEmpty)
                            AtomListCard(
                              children: [
                                AtomNavRow(
                                  icon: LucideIcons.plus,
                                  tone: AtomTone.blue,
                                  title: l.teamNewRole,
                                  subtitle: l.teamNoOwnRoles,
                                  onTap: () =>
                                      context.push(V2Routes.roleEdit()),
                                ),
                              ],
                            )
                          else
                            AtomListCard(
                              children: [
                                for (final r in mine) row(r, grantable),
                              ],
                            ),
                          const SizedBox(height: 14),
                        ],
                        AtomSectionLabel(l.teamReadyMade, page: false),
                        AtomListCard(
                          children: [
                            const _OwnerRoleRow(),
                            for (final r in all.readyMade) row(r, grantable),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TeamFoot(l.teamReadyNote),
                      ];
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The Owner, first among the ready-made roles: not a role anyone can be
/// given.
class _OwnerRoleRow extends StatelessWidget {
  const _OwnerRoleRow();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      label: '${l.teamOwnerRole}, ${l.teamOwnerRoleSum}',
      excludeSemantics: true,
      child: Container(
        color: AtomColors.paper,
        padding: const EdgeInsets.symmetric(
          horizontal: AtomSpace.inset,
          vertical: AtomSpace.s3,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AtomIconTile(icon: LucideIcons.shield, tone: AtomTone.blue),
            const SizedBox(width: AtomSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.teamOwnerRole, style: AtomText.listTitle),
                  Text(l.teamOwnerRoleSum, style: AtomText.secondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small blue chips (`.cp span`).
class _Chips extends StatelessWidget {
  const _Chips(this.chips);

  final List<String> chips;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    runSpacing: 4,
    children: [
      for (final c in chips)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AtomColors.primarySoft,
            borderRadius: AtomRadius.brTag,
          ),
          child: Text(
            c,
            style: AtomText.tag.copyWith(
              fontWeight: FontWeight.w600,
              color: AtomColors.primary,
            ),
          ),
        ),
    ],
  );
}

// ───────────────────────────────────────────── compare

/// Compare roles: two roles side by side, every permission the brand can
/// give with a tick under each role that has it.
Future<void> showRoleCompare(BuildContext context, TeamRoles roles) =>
    showAtomSheet<void>(
      context,
      expand: true,
      builder: (_) => _CompareSheet(roles: roles),
    );

class _CompareSheet extends StatefulWidget {
  const _CompareSheet({required this.roles});

  final TeamRoles roles;

  @override
  State<_CompareSheet> createState() => _CompareSheetState();
}

class _CompareSheetState extends State<_CompareSheet> {
  AppLocalizations get l => AppLocalizations.of(context);

  late TeamRole _a = widget.roles.roles.first;
  late TeamRole _b = widget.roles.roles[1];

  AtomSelectField<int> _pick(
    String label,
    TeamRole value,
    ValueChanged<TeamRole> set,
  ) => AtomSelectField<int>(
    label: label,
    value: value.id,
    valueLabel: value.name,
    sheetTitle: label,
    options: [
      for (final r in widget.roles.roles)
        AtomOption(
          value: r.id,
          label: r.name,
          subtitle: r.readyMade ? l.teamReadyMade : l.teamYours,
        ),
    ],
    onChanged: (id) => setState(() => set(widget.roles.byId(id) ?? value)),
  );

  Widget _mark(bool on, String role, String perm) => Semantics(
    label: '$role: ${on ? l.teamSemYes : l.teamSemNo}',
    excludeSemantics: true,
    child: SizedBox(
      width: 56,
      child: Icon(
        on ? LucideIcons.check : LucideIcons.minus,
        size: 18,
        color: on ? AtomColors.green : AtomColors.chevron,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = withNeeded(_a.permissions.toSet());
    final b = withNeeded(_b.permissions.toSet());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtomSheetHeader(title: l.teamCompare),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AtomSpace.gutter,
              0,
              AtomSpace.gutter,
              AtomSpace.gutter,
            ),
            children: [
              Text(l.teamCompareHint, style: AtomText.secondary),
              const SizedBox(height: AtomSpace.s3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _pick(l.teamFirstRole, _a, (r) => _a = r)),
                  const SizedBox(width: AtomSpace.s3),
                  Expanded(child: _pick(l.teamSecondRole, _b, (r) => _b = r)),
                ],
              ),
              const SizedBox(height: AtomSpace.s3),
              for (final g in widget.roles.groups) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 10, 2, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          g.name.toUpperCase(),
                          style: AtomText.section.copyWith(letterSpacing: 0.5),
                        ),
                      ),
                      SizedBox(
                        width: 56,
                        child: Text(
                          _a.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AtomText.small,
                        ),
                      ),
                      SizedBox(
                        width: 56,
                        child: Text(
                          _b.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AtomText.small,
                        ),
                      ),
                    ],
                  ),
                ),
                AtomListCard(
                  children: [
                    for (final (k, label) in g.permissions)
                      Container(
                        color: a.contains(k) != b.contains(k)
                            ? AtomColors.amberSoft
                            : AtomColors.paper,
                        constraints: const BoxConstraints(minHeight: 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AtomSpace.inset,
                          vertical: AtomSpace.s2,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: AtomText.body.copyWith(
                                  color: AtomColors.ink,
                                ),
                              ),
                            ),
                            _mark(a.contains(k), _a.name, label),
                            _mark(b.contains(k), _b.name, label),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
