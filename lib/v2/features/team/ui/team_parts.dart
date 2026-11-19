import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/ids.dart';
import '../../../core/net/network_status.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../states/ui/state_screens.dart' show NoInternetBody;
import '../data/team_models.dart';
import '../data/team_rules.dart';

/// Atombrand on Google Play: the link that goes with the WhatsApp message.
const teamAppLink =
    'https://play.google.com/store/apps/details?id=com.ecommerce.atombrand';

/// The signed-in session, or null.
BrandSession? watchSession(WidgetRef ref) =>
    switch (ref.watch(sessionProvider)) {
      SignedIn(:final session) => session,
      _ => null,
    };

/// Whether the phone has a network (true until known).
bool watchOnline(WidgetRef ref) => ref.watch(onlineProvider).value ?? true;

/// A list's or page's error: No internet, or the server's words with Try
/// again.
Widget teamFailure(Object e, VoidCallback retry) =>
    e is ApiFailure &&
        (e.kind == ApiFailureKind.offline || e.kind == ApiFailureKind.timeout)
    ? NoInternetBody(onRetry: retry)
    : AtomErrorState(
        message: e is ApiFailure ? e.message : null,
        onRetry: retry,
      );

/// The white bar at the bottom of a form (`.bottombar`).
class TeamBottomBar extends StatelessWidget {
  const TeamBottomBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: AtomColors.paper,
      border: Border(top: BorderSide(color: AtomColors.line)),
    ),
    padding: EdgeInsets.fromLTRB(
      AtomSpace.gutter,
      AtomSpace.s3,
      AtomSpace.gutter,
      math.max(
        AtomSpace.s3,
        MediaQuery.paddingOf(context).bottom + AtomSpace.s3,
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

/// A small grey line under a card (`.tiny`).
class TeamFoot extends StatelessWidget {
  const TeamFoot(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Text(text, style: AtomText.small.copyWith(color: AtomColors.faint)),
  );
}

/// A member's initials; grey for someone switched off.
class MemberInitials extends StatelessWidget {
  const MemberInitials({super.key, required this.member, this.size = 40});

  final TeamMember member;
  final double size;

  @override
  Widget build(BuildContext context) => AtomInitials(
    name: member.name,
    size: size,
    tone: member.isOff ? AtomTone.grey : null,
  );
}

/// The status pill: green Active, amber Waiting to sign in, grey
/// Switched off.
class MemberStatusPill extends StatelessWidget {
  const MemberStatusPill({super.key, required this.status});

  final MemberStatus status;

  @override
  Widget build(BuildContext context) => AtomPill(
    label: statusLabel(AppLocalizations.of(context), status),
    tone: switch (status) {
      MemberStatus.active => AtomTone.green,
      MemberStatus.waiting => AtomTone.amber,
      MemberStatus.off => AtomTone.grey,
    },
    // `.pill` at `height: 22px` in the rows of 11.1
    compact: true,
  );
}

/// The dot's colour for how recently someone was active.
Color seenColour(SeenTone t) => switch (t) {
  SeenTone.now => AtomColors.green,
  SeenTone.earlier => AtomColors.amber,
  SeenTone.never => AtomColors.chevron,
};

/// "● Active 10:42 am", 12px faint.
class SeenText extends StatelessWidget {
  const SeenText({super.key, required this.text, required this.tone});

  final String text;
  final SeenTone tone;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: seenColour(tone),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        TextSpan(text: text),
      ],
    ),
    style: AtomText.small.copyWith(color: AtomColors.faint),
  );
}

/// A row in an actions card (`.more`): an icon, a title and what it does.
/// Red for Switch off.
class TeamActionRow extends StatelessWidget {
  const TeamActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool danger;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colour = danger ? AtomColors.rose : AtomColors.ink;
    return AtomPressable(
      onTap: loading ? null : onTap,
      scaleOnPress: false,
      focusRadius: BorderRadius.zero,
      semanticLabel: '$title, $subtitle',
      builder: (_, pressed) => Container(
        color: pressed ? AtomColors.head : AtomColors.paper,
        constraints: const BoxConstraints(minHeight: AtomSize.tapTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: AtomSpace.inset,
          vertical: AtomSpace.s3,
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              SizedBox(
                width: AtomIcon.row,
                child: loading
                    ? const AtomSpinner(size: 18)
                    : Icon(icon, size: AtomIcon.row, color: colour),
              ),
              const SizedBox(width: AtomSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AtomText.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colour,
                        height: 1.3,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AtomText.small.copyWith(
                        color: danger ? AtomColors.rose : AtomColors.muted,
                      ),
                    ),
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

/// A chip that turns on and off (`.chips button`).
class TeamToggleChip extends StatelessWidget {
  const TeamToggleChip({
    super.key,
    required this.label,
    required this.on,
    required this.onTap,
  });

  final String label;
  final bool on;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AtomPressable(
    onTap: onTap,
    toggled: on,
    focusRadius: AtomRadius.brPill,
    semanticLabel: label,
    builder: (_, _) => Container(
      constraints: const BoxConstraints(minHeight: AtomSize.small),
      padding: on
          ? const EdgeInsets.symmetric(horizontal: 13, vertical: 5)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: onTap == null
            ? AtomColors.surface
            : (on ? AtomColors.primarySoft : AtomColors.paper),
        borderRadius: AtomRadius.brPill,
        border: Border.all(
          color: on ? AtomColors.primary : AtomColors.line2,
          width: on ? 2 : 1,
        ),
      ),
      child: ExcludeSemantics(
        child: Text(
          label,
          style: AtomText.smallButton.copyWith(
            color: onTap == null
                ? AtomColors.disabledText
                : (on ? AtomColors.primary : AtomColors.text),
          ),
        ),
      ),
    ),
  );
}

/// A form: the bar, a scrolling body, and the button in the bottom bar
/// with any refusal above it. Guards unsaved changes. On [surface] the bar
/// is white with a line under it and the body grey (11.6).
class TeamFormFrame extends StatelessWidget {
  const TeamFormFrame({
    super.key,
    required this.title,
    required this.children,
    required this.button,
    required this.onSave,
    required this.saving,
    required this.dirty,
    this.subtitle,
    this.error,
    this.close = true,
    this.surface = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final String? button;
  final VoidCallback? onSave;
  final bool saving;
  final bool dirty;
  final String? error;
  final bool close;
  final bool surface;

  @override
  Widget build(BuildContext context) {
    final bar = AtomFlowBar(
      leading: close ? AtomFlowLeading.close : AtomFlowLeading.back,
      title: title,
      subtitle: subtitle,
    );
    return AtomUnsavedGuard(
      dirty: dirty && !saving,
      child: Scaffold(
        backgroundColor: surface ? AtomColors.surface : AtomColors.paper,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (surface)
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: AtomColors.paper,
                  border: Border(bottom: BorderSide(color: AtomColors.line)),
                ),
                child: bar,
              )
            else
              bar,
            Expanded(
              child: AtomReadableWidth(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AtomSpace.gutter,
                    AtomSpace.s3,
                    AtomSpace.gutter,
                    AtomSpace.gutter,
                  ),
                  children: children,
                ),
              ),
            ),
            if (button != null || error != null)
              TeamBottomBar(
                children: [
                  if (error != null) ...[
                    AtomNote(kind: AtomNoteKind.problem, message: error!),
                    const SizedBox(height: 10),
                  ],
                  if (button != null)
                    AtomButton(
                      label: button!,
                      saving: saving,
                      onPressed: onSave,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────── the temporary password

/// A 44-tall button on the navy password card.
class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.whatsapp = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool whatsapp;

  @override
  Widget build(BuildContext context) => AtomPressable(
    onTap: onTap,
    semanticLabel: label,
    builder: (_, pressed) => Container(
      constraints: const BoxConstraints(minHeight: AtomSize.heroButton),
      padding: const EdgeInsets.symmetric(
        horizontal: AtomSpace.s2,
        vertical: 6,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: whatsapp
            ? (pressed ? AtomColors.noteGreenText : AtomColors.whatsapp)
            : (pressed ? AtomColors.nav2 : Colors.transparent),
        borderRadius: AtomRadius.brControl,
        border: Border.all(
          color: whatsapp ? Colors.transparent : AtomColors.navLine,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AtomText.button.copyWith(
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The navy card with the username, the temporary password, Send on
/// WhatsApp and Copy (`.pw`). It lives only as long as what shows it.
class TeamLoginCard extends ConsumerWidget {
  const TeamLoginCard({super.key, required this.added});

  final MemberWithLogin added;

  Future<void> _copy(BuildContext context, String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      showAtomToast(context, kind: AtomToastKind.ok, message: message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final m = added.member;
    final login = added.login;
    final phone = login.whatsapp ?? m.phone;
    final username = login.username.isEmpty
        ? AtomIds.formatMobile(m.phone ?? '')
        : AtomIds.formatMobile(login.username);
    final brand = watchSession(ref)?.brandName ?? 'Brand Partner';
    final soft = AtomText.secondary.copyWith(
      color: AtomColors.navText,
      height: 1.45,
    );
    final copy = _CardButton(
      label: l.teamCopy,
      onTap: () => _copy(context, login.password, l.teamPasswordCopied),
    );
    final whatsapp = phone == null
        ? null
        : _CardButton(
            label: l.teamSendWhatsApp,
            icon: AtomBrandIcons.whatsapp,
            whatsapp: true,
            onTap: () => launchUrl(
              whatsAppUri(
                phone,
                text: [
                  l.teamWhatsAppMessage(
                    m.firstName,
                    brand,
                    username,
                    login.password,
                    teamAppLink,
                  ),
                  if (login.signInUrl case final web?) l.teamWhatsAppWeb(web),
                ].join('\n'),
              ),
              mode: LaunchMode.externalApplication,
            ),
          );
    final stacked =
        MediaQuery.textScalerOf(context).scale(10) >= 15 ||
        MediaQuery.sizeOf(context).width < 360;
    return Container(
      padding: const EdgeInsets.all(AtomSpace.gutter),
      decoration: BoxDecoration(
        color: AtomColors.nav,
        borderRadius: AtomRadius.brCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: AtomSpace.s2,
            children: [
              Text(l.teamLoginTitle, style: soft),
              Text(
                l.teamShownOnce,
                style: soft.copyWith(
                  color: AtomColors.darkAmber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(l.teamUsername, style: soft),
              const SizedBox(width: AtomSpace.s2),
              Expanded(
                child: Text(
                  username,
                  textAlign: TextAlign.center,
                  style: AtomText.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AtomButton.small(
                label: l.teamCopy,
                onPressed: () =>
                    _copy(context, AtomIds.digits(username), l.teamCopied),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: AtomSpace.s2),
            decoration: BoxDecoration(
              color: AtomColors.nav2,
              borderRadius: AtomRadius.brControl,
              border: Border.all(color: AtomColors.navLine),
            ),
            child: SelectableText(
              login.password,
              textAlign: TextAlign.center,
              style: AtomText.amount.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(l.teamPasswordHow(m.firstName), style: soft),
          const SizedBox(height: 10),
          if (whatsapp == null)
            copy
          else if (stacked) ...[
            whatsapp,
            const SizedBox(height: AtomSpace.s2),
            copy,
          ] else
            Row(
              children: [
                Expanded(flex: 13, child: whatsapp),
                const SizedBox(width: AtomSpace.s2),
                Expanded(flex: 10, child: copy),
              ],
            ),
        ],
      ),
    );
  }
}

/// Shows a new temporary password in a sheet (reset, switch on); it is
/// gone when the sheet closes.
Future<void> showTeamLoginSheet(BuildContext context, MemberWithLogin added) =>
    showAtomSheet<void>(
      context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AtomSpace.gutter,
          0,
          AtomSpace.gutter,
          AtomSpace.gutter,
        ),
        child: SingleChildScrollView(child: TeamLoginCard(added: added)),
      ),
    );
