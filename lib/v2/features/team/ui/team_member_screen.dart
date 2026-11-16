import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/ids.dart';
import '../../../core/format/money.dart';
import '../../../core/session/session.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/team_models.dart';
import '../data/team_repository.dart';
import '../data/team_rules.dart';
import 'team_member_form.dart';
import 'team_parts.dart';

enum _Act { reset, phones, off, on }

/// A team member (11.4): who they are and when they were last active,
/// their login and where they work, and Edit, Reset password, Switch off
/// and Switch on, each confirmed first. A team manager who isn't the owner
/// can't change themselves or another team manager: those actions are
/// left out.
///
/// Left out until the server gives them: orders handled and payments
/// recorded this month, and signing out their phones on its own.
class TeamMemberScreen extends ConsumerStatefulWidget {
  const TeamMemberScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<TeamMemberScreen> createState() => _TeamMemberScreenState();
}

class _TeamMemberScreenState extends ConsumerState<TeamMemberScreen> {
  AppLocalizations get l => AppLocalizations.of(context);

  _Act? _busy;

  Future<void> _run(TeamMember m, _Act act) async {
    final l = AppLocalizations.of(context);
    final ok = await switch (act) {
      _Act.reset => showAtomConfirm(
        context,
        title: l.teamResetTitle(m.firstName),
        body: l.teamResetBody,
        confirmLabel: l.teamResetButton,
      ),
      _Act.phones => showAtomConfirm(
        context,
        title: l.teamPhonesTitle(m.firstName),
        body: l.teamPhonesBody,
        confirmLabel: l.teamPhonesButton,
      ),
      _Act.off => showAtomConfirm(
        context,
        title: l.teamOffTitle(m.firstName),
        body: l.teamOffBody,
        confirmLabel: l.teamOffRow,
        destructive: true,
      ),
      _Act.on => showAtomConfirm(
        context,
        title: l.teamOnTitle(m.firstName),
        body: l.teamOnBody,
        confirmLabel: l.teamOnRow,
      ),
    };
    if (!ok || !mounted) return;
    setState(() => _busy = act);
    final repo = ref.read(teamRepositoryProvider);
    final ApiResult<Object> r = switch (act) {
      _Act.reset => await repo.reset(m),
      _Act.phones => await repo.signOutPhones(m.id),
      _Act.off => await repo.switchOff(m.id),
      _Act.on => await repo.switchOn(m.id),
    };
    if (!mounted) return;
    setState(() => _busy = null);
    switch (r) {
      case ApiOk(:final value):
        refreshTeam(ref);
        if (value is MemberWithLogin) {
          await showTeamLoginSheet(context, value);
        } else if (act == _Act.phones) {
          showAtomToast(
            context,
            kind: AtomToastKind.ok,
            message: value == 0
                ? l.teamPhonesNone
                : l.teamPhonesDone(m.firstName),
          );
        } else {
          showAtomToast(
            context,
            kind: AtomToastKind.ok,
            message: l.teamOffDone(m.firstName),
          );
        }
      case ApiErr(:final failure):
        showAtomToast(
          context,
          kind: AtomToastKind.bad,
          message: sayFailure(l, failure),
        );
    }
  }

  void _edit(TeamMember m) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => TeamMemberForm(member: m)));

  Widget _head(TeamMember m, {required bool canEdit}) {
    final (seen, _) = seenLine(l, m);
    final pillTone = switch (m.status) {
      MemberStatus.active => AtomTone.green,
      MemberStatus.waiting => AtomTone.amber,
      MemberStatus.off => AtomTone.grey,
    };
    final off = m.switchedOffAt?.toLocal();
    final pill = switch (m.status) {
      MemberStatus.active =>
        '${statusLabel(l, m.status)} · ${seen.toLowerCase()}',
      MemberStatus.waiting => statusLabel(l, m.status),
      MemberStatus.off =>
        off == null
            ? statusLabel(l, m.status)
            : '${statusLabel(l, m.status)} ${AtomDates.short(off)}',
    };
    return Container(
      padding: const EdgeInsets.only(bottom: 14),
      decoration: const BoxDecoration(
        color: AtomColors.paper,
        border: Border(bottom: BorderSide(color: AtomColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtomFlowBar(
            trailing: [
              if (canEdit)
                AtomIconButton(
                  icon: LucideIcons.pencil,
                  label: l.teamEdit,
                  onTap: _busy != null ? null : () => _edit(m),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AtomSpace.gutter),
            child: Row(
              children: [
                MemberInitials(member: m, size: 52),
                const SizedBox(width: AtomSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(m.name, style: AtomText.pageTitle),
                      ),
                      Text(
                        [
                          if (m.phone != null) AtomIds.formatMobile(m.phone!),
                          m.role?.name ?? l.teamNoRole,
                        ].join(' · '),
                        style: AtomText.secondary,
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: AtomPill(label: pill, tone: pillTone, dot: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(teamMemberProvider(widget.id));
    final roles = ref.watch(teamRolesProvider).value;
    final session = watchSession(ref);
    final who = session?.who ?? const Who.owner();
    final online = watchOnline(ref);
    final m = data.value;

    Widget body;
    if (m != null) {
      final can = canChangeMember(
        m,
        who,
        myUserId: session?.userId ?? 0,
        roles: roles,
      );
      final last = m.lastActiveAt?.toLocal();
      final now = AtomDates.now();
      body = RefreshIndicator(
        onRefresh: () => ref.refresh(teamMemberProvider(widget.id).future),
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _head(m, canEdit: can && online),
            AtomReadableWidth(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AtomSpace.gutter,
                  AtomSpace.s3,
                  AtomSpace.gutter,
                  AtomSpace.s6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // This month's work (the board's two tiles).
                    if (!m.isOff) ...[
                      AtomKpiGrid(
                        kpis: [
                          AtomKpi(
                            label: l.teamKpiHandled(
                              DateFormat.MMM().format(now),
                            ),
                            value: '${m.ordersMonth}',
                            note: l.teamKpiHandledNote(
                              m.confirmedMonth,
                              m.deliveredMonth,
                            ),
                          ),
                          AtomKpi(
                            label: l.teamKpiPaid(DateFormat.MMM().format(now)),
                            value: formatRs(m.paidMonth),
                            note: l.teamKpiPaidNote(m.paymentsMonth),
                          ),
                        ],
                      ),
                      const SizedBox(height: AtomSpace.s3),
                    ],
                    AtomSectionLabel(l.teamLoginAndAccess, page: false),
                    AtomInfoCard(
                      lines: [
                        if (m.phone != null)
                          AtomInfoLine(
                            label: l.teamUsername,
                            value: AtomIds.formatMobile(m.phone!),
                          ),
                        AtomInfoLine(
                          label: l.teamWorksIn,
                          value: worksIn(l, m),
                        ),
                        AtomInfoLine(
                          label: l.teamLastActive,
                          value: last == null
                              ? '–'
                              : '${AtomDates.shortOrYear(last)} · ${AtomDates.time(last)}',
                        ),
                        AtomInfoLine(
                          label: l.teamPassword,
                          value: m.mustChangePassword
                              ? l.teamTemporary
                              : l.teamTheirOwn,
                        ),
                        if (m.email != null)
                          AtomInfoLine(label: l.teamEmail, value: m.email!),
                        if (m.createdAt != null)
                          AtomInfoLine(
                            label: l.teamAdded,
                            value: AtomDates.day(m.createdAt!.toLocal()),
                          ),
                      ],
                    ),
                    const SizedBox(height: AtomSpace.s3),
                    if (!can)
                      AtomNote(
                        kind: AtomNoteKind.info,
                        message: l.teamNotYoursToChange,
                      )
                    else ...[
                      AtomListCard(
                        children: [
                          if (!m.isOff) ...[
                            TeamActionRow(
                              icon: LucideIcons.lock,
                              title: l.teamResetRow,
                              subtitle: l.teamResetSub,
                              loading: _busy == _Act.reset,
                              onTap: _busy != null || !online
                                  ? null
                                  : () => _run(m, _Act.reset),
                            ),
                            TeamActionRow(
                              icon: LucideIcons.logOut,
                              title: l.teamPhonesRow,
                              subtitle: l.teamPhonesSub,
                              loading: _busy == _Act.phones,
                              onTap: _busy != null || !online
                                  ? null
                                  : () => _run(m, _Act.phones),
                            ),
                            TeamActionRow(
                              icon: LucideIcons.power,
                              title: l.teamOffRow,
                              subtitle: l.teamOffSub,
                              danger: true,
                              loading: _busy == _Act.off,
                              onTap: _busy != null || !online
                                  ? null
                                  : () => _run(m, _Act.off),
                            ),
                          ] else
                            TeamActionRow(
                              icon: LucideIcons.power,
                              title: l.teamOnRow,
                              subtitle: l.teamOnSub,
                              loading: _busy == _Act.on,
                              onTap: _busy != null || !online
                                  ? null
                                  : () => _run(m, _Act.on),
                            ),
                        ],
                      ),
                      const SizedBox(height: AtomSpace.s3),
                      TeamFoot(l.teamNeedInternetFoot),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else if (data.hasError) {
      final e = data.error;
      final gone = e is ApiFailure && e.kind == ApiFailureKind.notFound;
      body = Column(
        children: [
          const AtomFlowBar(),
          Expanded(
            child: gone
                ? AtomMessageState(
                    icon: LucideIcons.userX,
                    title: l.teamMemberGone,
                  )
                : teamFailure(
                    e!,
                    () => ref.invalidate(teamMemberProvider(widget.id)),
                  ),
          ),
        ],
      );
    } else {
      body = const Column(
        children: [
          AtomFlowBar(),
          Padding(
            padding: EdgeInsets.all(AtomSpace.gutter),
            child: AtomLoadingCard(),
          ),
        ],
      );
    }
    return Scaffold(backgroundColor: AtomColors.surface, body: body);
  }
}
