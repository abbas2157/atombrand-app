import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/ids.dart';
import '../../../core/format/money.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/bulk_logic.dart';
import '../data/bulk_models.dart';

/// Pieces the bulk screens share: status pills, the step bar, cards with
/// lines, the history rows, call and WhatsApp.

/// `.st` Delivered on the boards (#E6F4F6 / #0E6B7A): no token draws it.
const _teal = AtomTone(
  fg: Color(0xFF0E6B7A),
  bg: Color(0xFFE6F4F6),
  border: Color(0xFFE6F4F6),
);

AtomTone requestTone(RequestStatus s) => switch (s) {
  RequestStatus.fresh => AtomTone.blue,
  RequestStatus.contacted => AtomTone.purple,
  RequestStatus.quoted => AtomTone.amber,
  RequestStatus.won => AtomTone.green,
  RequestStatus.lost => AtomTone.rose,
};

String requestLabel(AppLocalizations l, RequestStatus s) => switch (s) {
  RequestStatus.fresh => l.bulkStatusNew,
  RequestStatus.contacted => l.bulkStatusContacted,
  RequestStatus.quoted => l.bulkStatusQuoted,
  RequestStatus.won => l.bulkStatusWon,
  RequestStatus.lost => l.bulkStatusLost,
};

AtomTone sourcingTone(SourcingState s) => switch (s) {
  SourcingState.fresh => AtomTone.blue,
  SourcingState.changeAsked || SourcingState.quoted => AtomTone.amber,
  SourcingState.declined || SourcingState.closed => AtomTone.rose,
  SourcingState.accepted => AtomTone.green,
};

AtomTone dealTone(DealStatus s) => switch (s) {
  DealStatus.open => AtomTone.blue,
  DealStatus.delivering => AtomTone.purple,
  DealStatus.delivered => _teal,
  DealStatus.paid => AtomTone.green,
  DealStatus.closed => AtomTone.grey,
  DealStatus.lost => AtomTone.rose,
};

/// A quote's state for its pill.
(String, AtomTone) quoteLook(AppLocalizations l, Quote q) => switch (q.status) {
  QuoteStatus.draft => (l.bulkQuoteDraft, AtomTone.grey),
  QuoteStatus.accepted => (l.bulkStatusAccepted, AtomTone.green),
  QuoteStatus.superseded => (l.bulkQuoteSuperseded, AtomTone.grey),
  QuoteStatus.expired => (l.bulkQuoteExpired, AtomTone.rose),
  QuoteStatus.sent when q.expired => (l.bulkQuoteExpired, AtomTone.rose),
  QuoteStatus.sent => (l.bulkQuoteSent, AtomTone.amber),
};

/// "Today 10:20", "Yesterday 4:10 pm", "12 Nov 4:10 pm".
String bulkWhen(AppLocalizations l, DateTime? at) {
  if (at == null) return '';
  final local = at.toLocal();
  final today = AtomDates.now();
  final days = DateTime(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime(local.year, local.month, local.day)).inDays;
  final time = AtomDates.time(local);
  return switch (days) {
    0 => l.bulkWhenToday(time),
    1 => l.bulkWhenYesterday(time),
    _ => '${AtomDates.shortOrYear(local)} $time',
  };
}

/// "25 min ago", "2 h ago", "yesterday", "6 Nov".
String bulkAgo(AppLocalizations l, DateTime? at) {
  if (at == null) return '';
  final now = AtomDates.now();
  final d = now.difference(at.toLocal());
  if (d.inMinutes < 1) return l.bulkAgoNow;
  if (d.inMinutes < 60) return l.bulkAgoMinutes(d.inMinutes);
  if (d.inHours < 24 && now.day == at.toLocal().day) {
    return l.bulkAgoHours(d.inHours);
  }
  if (d.inDays <= 1) return l.bulkAgoYesterday;
  return AtomDates.shortOrYear(at.toLocal());
}

Future<void> callPhone(String? phone) async {
  final d = AtomIds.digits(phone ?? '');
  if (d.isEmpty) return;
  await launchUrl(Uri(scheme: 'tel', path: d));
}

/// Opens WhatsApp: the server's own link when it sent one, else a chat
/// with [phone].
Future<bool> openWhatsApp({String? link, String? phone}) async {
  final uri = link != null
      ? Uri.tryParse(link)
      : (phone == null || AtomIds.digits(phone).isEmpty)
      ? null
      : whatsAppUri(phone);
  if (uri == null) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// A white card (`.card`).
class BulkCard extends StatelessWidget {
  const BulkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AtomSpace.inset),
    this.tone,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// A tinted card (the change asked, They said yes?).
  final AtomTone? tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: tone == null ? AtomColors.paper : tone!.bg.withValues(alpha: .5),
      borderRadius: AtomRadius.brCard,
      border: Border.all(color: tone?.border ?? AtomColors.line),
    ),
    child: child,
  );
}

/// A card title (`.ch`).
class BulkCardTitle extends StatelessWidget {
  const BulkCardTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 4),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              text,
              style: AtomText.listTitle.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        if (trailing != null) Flexible(child: trailing!),
      ],
    ),
  );
}

/// A card of label · value lines with a title.
class BulkLinesCard extends StatelessWidget {
  const BulkLinesCard({
    super.key,
    required this.title,
    required this.lines,
    this.footer,
    this.trailing,
  });

  final String title;
  final List<Widget> lines;
  final Widget? footer;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => BulkCard(
    padding: const EdgeInsets.fromLTRB(AtomSpace.inset, 10, AtomSpace.inset, 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BulkCardTitle(title, trailing: trailing),
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AtomColors.line),
          lines[i],
        ],
        ?footer,
      ],
    ),
  );
}

/// A line whose label has a second, small line (deliveries, payments).
class BulkTwoLine extends StatelessWidget {
  const BulkTwoLine({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.extra,
    this.valueColor,
  });

  final String title;
  final String? subtitle;
  final Widget? extra;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AtomText.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AtomColors.ink,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(subtitle!, style: AtomText.small),
              if (extra != null) ...[const SizedBox(height: 4), extra!],
            ],
          ),
        ),
        const SizedBox(width: 12),
        // At the right edge: a bare Flexible text sat mid-row.
        Flexible(
          child: Align(
            heightFactor: 1,
            alignment: AlignmentDirectional.topEnd,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AtomText.money.copyWith(
                fontSize: 14,
                color: valueColor ?? AtomColors.ink,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// The step bar under a detail header (`.stp`).
class BulkSteps extends StatelessWidget {
  const BulkSteps({
    super.key,
    required this.labels,
    required this.reached,
    this.lostAt,
  });

  final List<String> labels;

  /// How many steps are done.
  final int reached;

  /// The step drawn red (a lost request, a declined quote).
  final int? lostAt;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).bulkStepOf(
        reached,
        labels.length,
        labels[(reached - 1).clamp(0, labels.length - 1)],
      ),
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: i < reached
                            ? (i == lostAt
                                  ? AtomColors.rose
                                  : AtomColors.primary)
                            : AtomColors.line,
                        borderRadius: AtomRadius.brPill,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      style: AtomText.small.copyWith(
                        fontSize: 11,
                        fontWeight: i < reached ? FontWeight.w600 : null,
                        color: i < reached
                            ? (i == lostAt ? AtomColors.rose : AtomColors.ink)
                            : AtomColors.faint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One history row (`.ev2`): when on the left, what on the right.
class BulkHistoryRow extends StatelessWidget {
  const BulkHistoryRow({super.key, required this.when, required this.what});

  final String when;
  final InlineSpan what;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 92, child: Text(when, style: AtomText.small)),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(what, style: AtomText.body.copyWith(height: 1.35)),
        ),
      ],
    ),
  );
}

/// The blue rosette after a verified seller's name.
class VerifiedMark extends StatelessWidget {
  const VerifiedMark({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).bulkVerifiedSeller,
    child: Icon(LucideIcons.badgeCheck, size: size, color: AtomColors.primary),
  );
}

/// A small soft tag (`.sbadge`, "Not in your catalogue").
class BulkTag extends StatelessWidget {
  const BulkTag(this.label, {super.key, this.tone = AtomTone.blue});

  final String label;
  final AtomTone tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: tone.bg, borderRadius: AtomRadius.brTag),
    child: Text(label, style: AtomText.tag.copyWith(color: tone.fg)),
  );
}

/// The "needed by" chip on a seller request (calm, amber, red).
class NeedByChip extends StatelessWidget {
  const NeedByChip({super.key, required this.text, required this.urgency});

  final String text;
  final int urgency;

  @override
  Widget build(BuildContext context) {
    final tone = switch (urgency) {
      2 => AtomTone.rose,
      1 => AtomTone.amber,
      _ => null,
    };
    final colour = tone?.fg ?? AtomColors.muted;
    // One line, always (`.st` is nowrap): on a narrow phone it shrinks a
    // little rather than breaking "· 5 days" onto a second line.
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.calendar, size: 13, color: colour),
        const SizedBox(width: 4),
        Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: AtomText.small.copyWith(
            color: colour,
            fontWeight: tone == null ? FontWeight.w600 : FontWeight.w700,
          ),
        ),
      ],
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: tone == null
          ? row
          : Container(
              constraints: const BoxConstraints(minHeight: 24),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tone.bg,
                borderRadius: AtomRadius.brPill,
              ),
              child: row,
            ),
    );
  }
}

/// "Needed by Fri 7 Nov · 3 days", and how urgent.
({String text, int urgency})? needByText(
  AppLocalizations l,
  DateTime? neededBy, {
  String? lead,
}) {
  if (neededBy == null) return null;
  final n = needByOf(neededBy, today: AtomDates.now());
  final day = AtomDates.weekday(neededBy);
  final by = lead ?? l.bulkNeededBy;
  final text = n.days < 0 || n.days <= 7
      ? l.bulkNeedBySoon(by, day, daysLeftText(l, n.days))
      : l.bulkNeedByDate(by, AtomDates.short(neededBy));
  return (text: text, urgency: n.urgency);
}

/// Call and WhatsApp side by side (`.contact`).
class ContactButtons extends StatelessWidget {
  const ContactButtons({
    super.key,
    required this.phone,
    this.whatsapp,
    this.extra,
  });

  final String? phone;
  final String? whatsapp;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final has = AtomIds.digits(phone ?? '').isNotEmpty;
    if (!has && extra == null) return const SizedBox.shrink();
    return Row(
      children: [
        if (has) ...[
          Expanded(
            child: AtomButton(
              label: l.bulkCall,
              icon: LucideIcons.phone,
              kind: AtomButtonKind.outline,
              small: true,
              onPressed: () => callPhone(phone),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AtomButton(
              label: l.bulkWhatsApp,
              icon: AtomBrandIcons.whatsapp,
              kind: AtomButtonKind.whatsapp,
              small: true,
              onPressed: () => openWhatsApp(link: whatsapp, phone: phone),
            ),
          ),
        ],
        if (extra != null) ...[
          if (has) const SizedBox(width: 8),
          Expanded(child: extra!),
        ],
      ],
    );
  }
}

/// The white bar pinned to the bottom (`.bottombar`).
class BulkBottomBar extends StatelessWidget {
  const BulkBottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: AtomColors.paper,
      border: Border(top: BorderSide(color: AtomColors.line)),
    ),
    padding: EdgeInsets.fromLTRB(
      AtomSpace.gutter,
      12,
      AtomSpace.gutter,
      12 + MediaQuery.paddingOf(context).bottom,
    ),
    child: child,
  );
}

/// What is open beside the Bulk deals list on a wide tablet (TabletOrders'
/// list-and-detail, 14.x): a seller's or website request, or a deal.
typedef BulkPick = ({BulkPickKind kind, int id});

enum BulkPickKind { sellerRequest, websiteRequest, deal }

/// Above the Bulk deals list on a wide tablet: which row is open beside it
/// and how a row picks itself. Rows then pick instead of opening a page.
class BulkPicker extends InheritedWidget {
  const BulkPicker({
    super.key,
    required this.picked,
    required this.onPick,
    required super.child,
  });

  final BulkPick? picked;
  final ValueChanged<BulkPick> onPick;

  static BulkPicker? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BulkPicker>();

  @override
  bool updateShouldNotify(BulkPicker old) => old.picked != picked;
}

/// Around a request or deal shown beside the list (not as its own page):
/// its bar has no back arrow.
class BulkBeside extends InheritedWidget {
  const BulkBeside({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BulkBeside>() != null;

  @override
  bool updateShouldNotify(BulkBeside old) => false;
}

/// A detail screen's white top: the bar with an eyebrow and status, the
/// title, a line under it and whatever follows (steps, buttons).
class BulkDetailHeader extends StatelessWidget {
  const BulkDetailHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.status,
    this.children = const [],
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? status;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AtomColors.paper,
        border: Border(bottom: BorderSide(color: AtomColors.line)),
      ),
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtomFlowBar(
            leading: BulkBeside.of(context)
                ? AtomFlowLeading.none
                : AtomFlowLeading.back,
            // `.bar` with `.eyebrow`: beside the status, wrapping to a
            // second line rather than being cut short.
            middle: Text(
              eyebrow.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AtomText.tag.copyWith(
                fontSize: 12,
                letterSpacing: .8,
                color: AtomColors.primary,
              ),
            ),
            trailing: [
              if (status != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  // At large text the pill shrinks rather than push the
                  // bar past the edge.
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * .45,
                    ),
                    child: FittedBox(fit: BoxFit.scaleDown, child: status),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AtomSpace.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: AtomText.pageTitle),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: AtomText.secondary),
                ],
                for (final c in children) ...[const SizedBox(height: 12), c],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `Rs 52,300` or "Free" for a zero delivery charge.
String deliveryText(AppLocalizations l, int charge) =>
    charge <= 0 ? l.bulkFree : formatRs(charge);

/// The screen-wide loading / error frame for a detail screen.
class BulkLoadFrame extends StatelessWidget {
  const BulkLoadFrame({
    super.key,
    required this.title,
    required this.error,
    required this.onRetry,
  });

  final String title;
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final e = error;
    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        children: [
          AtomFlowBar(
            title: title,
            leading: BulkBeside.of(context)
                ? AtomFlowLeading.none
                : AtomFlowLeading.back,
          ),
          Expanded(
            child: switch (e) {
              null => const SingleChildScrollView(
                padding: EdgeInsets.all(AtomSpace.gutter),
                child: AtomLoadingCard(count: 4),
              ),
              ApiFailure(kind: ApiFailureKind.notFound) => AtomMessageState(
                icon: LucideIcons.searchX,
                title: l.notFoundTitle,
                body: l.bulkNotFoundBody,
              ),
              ApiFailure(
                kind: ApiFailureKind.notInRole || ApiFailureKind.ownerOnly,
              ) =>
                AtomMessageState(
                  icon: LucideIcons.lock,
                  title: l.notInRoleTitle,
                  body: l.notInRoleBody,
                ),
              ApiFailure(
                kind: ApiFailureKind.offline || ApiFailureKind.timeout,
              ) =>
                AtomErrorState(onRetry: onRetry, message: sayFailure(l, e)),
              // Anything else: the board's copy, never the server's words.
              ApiFailure() => AtomMessageState(
                icon: LucideIcons.circleAlert,
                tone: AtomTone.rose,
                art: false,
                title: l.bulkLoadErrorTitle,
                body: switch (e.body?['ref']) {
                  final String ref when ref.isNotEmpty =>
                    '${l.bulkLoadErrorBody}\n'
                        '${l.dpDbErrorRef(ref, bulkWhen(l, AtomDates.now()))}',
                  _ => l.bulkLoadErrorBody,
                },
                actionLabel: l.commonTryAgain,
                onAction: onRetry,
              ),
              _ => AtomErrorState(onRetry: onRetry),
            },
          ),
        ],
      ),
    );
  }
}

/// A green / rose note whose sentence carries links (`.note` with `<a>`:
/// "Quote Q-1042 rev 2 is ready. Open WhatsApp · Download PDF").
class BulkLinkNote extends StatelessWidget {
  const BulkLinkNote({
    super.key,
    required this.kind,
    required this.lead,
    this.text,
    this.links = const [],
    this.icon,
    this.boldLead = true,
  });

  final AtomNoteKind kind;
  final bool boldLead;

  /// The bold start.
  final String lead;
  final String? text;
  final List<(String, VoidCallback)> links;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border, Color fg, IconData glyph) = switch (kind) {
      AtomNoteKind.info => (
        AtomColors.primarySoft,
        AtomColors.primaryLine,
        AtomColors.noteBlueText,
        LucideIcons.info,
      ),
      AtomNoteKind.success => (
        AtomColors.greenSoft,
        AtomColors.greenLine,
        AtomColors.noteGreenText,
        LucideIcons.check,
      ),
      AtomNoteKind.warning => (
        AtomColors.amberSoft,
        AtomColors.amberLine,
        AtomColors.amberInk,
        LucideIcons.circleAlert,
      ),
      AtomNoteKind.problem => (
        AtomColors.roseSoft,
        AtomColors.roseLine,
        AtomColors.noteRoseText,
        LucideIcons.circleAlert,
      ),
    };
    final style = AtomText.body.copyWith(color: fg);
    final linkStyle = style.copyWith(
      color: AtomColors.primary,
      fontWeight: FontWeight.w600,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AtomRadius.brControl,
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon ?? glyph, size: 18, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: lead,
                        style: boldLead
                            ? const TextStyle(fontWeight: FontWeight.w700)
                            : null,
                      ),
                      if (text != null) TextSpan(text: ' $text'),
                      if (links.isNotEmpty) const TextSpan(text: ' '),
                    ],
                  ),
                  style: style,
                ),
                for (final (i, (label, onTap)) in links.indexed) ...[
                  if (i > 0) Text(' · ', style: style),
                  Semantics(
                    button: true,
                    child: InkWell(
                      onTap: onTap,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 24),
                        child: Text(label, style: linkStyle),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
