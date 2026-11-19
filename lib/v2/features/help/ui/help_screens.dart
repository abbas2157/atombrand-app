import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/dates.dart';
import '../../../core/session/session.dart' show BrandPermission;
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../../app/portal_links.dart';
import '../../../core/format/ids.dart' show whatsAppUri;
import '../../settings/data/settings_repository.dart' show appVersion;
import '../data/help_repository.dart';

/// What a failed load says: "no signal" offline, otherwise the plain
/// "Something went wrong" (never the server's raw text).
String? helpErrorText(AppLocalizations l, Object? error) =>
    error is ApiFailure &&
        (error.kind == ApiFailureKind.offline ||
            error.kind == ApiFailureKind.timeout)
    ? l.signInOffline
    : null;

// ── Topics ────────────────────────────────────────────────────────────────

/// A help topic: the server's category, its name and its tile (18.1).
typedef HelpTopic = ({String key, String name, IconData icon, AtomTone tone});

/// The topics in the board's order (18.1), then the server's other
/// categories (searchable, and as chips on 18.2). Topics follow the add-ons
/// and the role: Stock with Inventory, Team with Roles, Plan for the owner.
List<HelpTopic> helpTopics(
  AppLocalizations l, {
  required bool Function(Addon) has,
  required bool owner,
  bool extras = false,
}) => [
  (
    key: 'getting-started',
    name: l.dpDcTopicStart,
    icon: LucideIcons.arrowRight,
    tone: AtomTone.blue,
  ),
  (
    key: 'orders',
    name: l.noticesOrders,
    icon: LucideIcons.box,
    tone: AtomTone.blue,
  ),
  (
    key: 'atompay',
    name: l.helpTopicAtompay,
    icon: LucideIcons.creditCard,
    tone: AtomTone.green,
  ),
  (
    key: 'bulk',
    name: l.noticesBulk,
    icon: LucideIcons.funnel,
    tone: AtomTone.blue,
  ),
  (
    key: 'products',
    name: l.noticesProducts,
    icon: LucideIcons.tag,
    tone: AtomTone.amber,
  ),
  if (has(Addon.inventory))
    (
      key: 'stock',
      name: l.stockTitle,
      icon: LucideIcons.layoutGrid,
      tone: AtomTone.green,
    ),
  if (has(Addon.team))
    (
      key: 'team',
      name: l.noticesTeam,
      icon: LucideIcons.userMinus,
      tone: AtomTone.amber,
    ),
  if (owner)
    (
      key: 'plan',
      name: l.dpDcTopicPlan,
      icon: LucideIcons.star,
      tone: AtomTone.amber,
    ),
  (
    key: 'account',
    name: l.noticesAccount,
    icon: LucideIcons.shield,
    tone: _greyTile,
  ),
  if (extras) ...[
    if (has(Addon.alerts))
      (
        key: 'alerts',
        name: l.noticesTitle,
        icon: LucideIcons.bell,
        tone: AtomTone.blue,
      ),
    (
      key: 'payments',
      name: l.helpTopicPayments,
      icon: LucideIcons.banknote,
      tone: AtomTone.green,
    ),
    (
      key: 'brand-page',
      name: l.helpTopicBrandPage,
      icon: LucideIcons.globe,
      tone: AtomTone.green,
    ),
    (
      key: 'outlets',
      name: l.menuOutlets,
      icon: LucideIcons.store,
      tone: AtomTone.blue,
    ),
    (
      key: 'reports',
      name: l.dpDcTopicReports,
      icon: LucideIcons.chartColumn,
      tone: AtomTone.blue,
    ),
    (
      key: 'settings',
      name: l.settingsTitle,
      icon: LucideIcons.settings,
      tone: _greyTile,
    ),
    (
      key: 'general',
      name: l.dpDcTopicGeneral,
      icon: LucideIcons.circleHelp,
      tone: _greyTile,
    ),
  ],
];

const _greyTile = AtomTone(
  fg: AtomColors.muted,
  bg: AtomColors.surface,
  border: AtomColors.line,
);

/// Categories left out for this person: an add-on that is off, or the
/// owner's bills for an agent.
Set<String> _hiddenCategories({
  required bool Function(Addon) has,
  required bool owner,
}) => {
  if (!has(Addon.inventory)) 'stock',
  if (!has(Addon.team)) 'team',
  if (!has(Addon.alerts)) 'alerts',
  if (!owner) 'plan',
};

/// The answers this person may see, in the server's order (most read first).
List<HelpFaq> _allowed(WidgetRef ref, List<HelpFaq> all) {
  final access = ref.watch(accessProvider);
  final owner =
      ref.watch(sessionProvider.notifier).current?.who.isOwner ?? false;
  final hidden = _hiddenCategories(has: access.has, owner: owner);
  return [
    for (final f in all)
      if (!hidden.contains(f.category)) f,
  ];
}

// ── Answer text ───────────────────────────────────────────────────────────

/// An answer split the board's way (18.3): what comes before the numbered
/// steps, the steps, then what comes after (shown as a note).
({List<String> intro, List<String> steps, List<String> after}) parseAnswer(
  String answer,
) {
  final step = RegExp(r'^\s*\d+[.)]\s+');
  final intro = <String>[], steps = <String>[], after = <String>[];
  for (final raw in answer.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (step.hasMatch(line)) {
      steps.add(line.replaceFirst(step, ''));
    } else if (steps.isEmpty) {
      intro.add(line);
    } else {
      after.add(line);
    }
  }
  return (intro: intro, steps: steps, after: after);
}

/// Text with the server's `**bold**` shown bold (600, ink).
class HelpRichText extends StatelessWidget {
  const HelpRichText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final parts = text.split('**');
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (var i = 0; i < parts.length; i++)
            if (parts[i].isNotEmpty)
              TextSpan(
                text: parts[i],
                style: i.isOdd
                    ? TextStyle(
                        fontWeight: FontWeight.w600,
                        color: style.color == AtomColors.noteBlueText
                            ? null
                            : AtomColors.ink,
                      )
                    : null,
              ),
        ],
      ),
    );
  }
}

// ── 18.1 Help ─────────────────────────────────────────────────────────────

/// Help (18.1): search, Ask Atom, topics, popular answers, Atomshop's
/// contacts and your support requests, then About.
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final access = ref.watch(accessProvider);
    final owner =
        ref.watch(sessionProvider.notifier).current?.who.isOwner ?? false;
    final topics = helpTopics(l, has: access.has, owner: owner);
    final faqs = ref.watch(helpFaqsProvider);
    final allowed = _allowed(ref, faqs.value ?? const []);
    final support = ref.watch(supportRequestsProvider).value;
    final answered = support?.where((r) => r.answered).length ?? 0;
    final waiting = support?.where((r) => !r.closed && !r.answered).length ?? 0;
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle.light,
                child: Container(
                  color: AtomColors.nav,
                  padding: EdgeInsets.fromLTRB(16, top, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _NavyBack(onTap: () => Navigator.of(context).maybePop()),
                      const SizedBox(height: 6),
                      Semantics(
                        header: true,
                        child: Text(
                          l.helpTitle,
                          style: AtomText.pageTitle.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AtomPressable(
                        onTap: () => context.push(V2Routes.faqs, extra: true),
                        semanticLabel: l.helpSearch,
                        builder: (_, _) => Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: AtomRadius.brPill,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.search,
                                size: 18,
                                color: AtomColors.faint,
                              ),
                              const SizedBox(width: 10),
                              // One line in the 48 pill, as on the board; the
                              // examples end in "…" on a narrow phone.
                              Expanded(
                                child: Text(
                                  l.helpSearch,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AtomText.body.copyWith(
                                    fontSize: 15,
                                    color: AtomColors.faint,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const _FullStripe(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (access.has(Addon.askAtom)) ...[
                      _AskAtomCard(onTap: () => context.push(V2Routes.askAtom)),
                      const SizedBox(height: 16),
                    ],
                    AtomSectionLabel(l.helpTopics, page: false),
                    _TopicGrid(
                      topics: topics,
                      counts: {
                        for (final t in topics)
                          t.key: allowed
                              .where((f) => f.category == t.key)
                              .length,
                      },
                      loaded: faqs.hasValue,
                    ),
                    const SizedBox(height: 16),
                    AtomSectionLabel(l.helpPopular, page: false),
                    AtomListCard(
                      children: [
                        if (faqs.isLoading && !faqs.hasValue)
                          const Padding(
                            padding: EdgeInsets.all(14),
                            child: Center(child: AtomSpinner()),
                          ),
                        for (final f in allowed.take(3))
                          _Row2(
                            title: f.question,
                            sub: _topicName(l, f.category, topics: topics),
                            onTap: () =>
                                context.push(V2Routes.faqAnswer, extra: f),
                          ),
                        _Row2(
                          title: l.helpAllFaqs,
                          link: true,
                          onTap: () => context.push(V2Routes.faqs),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AtomSectionLabel(l.helpTalk, page: false),
                    AtomListCard(
                      children: [
                        _Row2(
                          icon: LucideIcons.messageCircle,
                          tone: AtomTone.blue,
                          title: l.supportTitle,
                          sub: answered + waiting == 0
                              ? l.supportSub
                              : l.dpDcSupportCounts(answered, waiting),
                          onTap: () => context.push(V2Routes.support),
                        ),
                        _Row2(
                          icon: AtomBrandIcons.whatsapp,
                          tone: const AtomTone(
                            fg: AtomColors.whatsapp,
                            bg: AtomColors.greenSoft,
                            border: AtomColors.greenLine,
                          ),
                          title: 'WhatsApp',
                          sub: AtomshopContacts.whatsapp,
                          onTap: () => launchUrl(
                            whatsAppUri(AtomshopContacts.whatsapp),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                        _Row2(
                          icon: LucideIcons.phone,
                          tone: _greyTile,
                          title: l.helpCall,
                          sub: AtomshopContacts.phone,
                          onTap: () => launchUrl(
                            Uri(
                              scheme: 'tel',
                              path: AtomshopContacts.phone.replaceAll(' ', ''),
                            ),
                          ),
                        ),
                        _Row2(
                          icon: LucideIcons.mail,
                          tone: _greyTile,
                          title: l.helpEmail,
                          sub: AtomshopContacts.email,
                          onTap: () => launchUrl(
                            Uri(scheme: 'mailto', path: AtomshopContacts.email),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AtomSectionLabel(l.settingsAbout, page: false),
                    AtomListCard(
                      children: [
                        _Row2(
                          title: l.ecosystemTitle,
                          sub: l.dpDcEcosystemSub,
                          onTap: () => context.push(V2Routes.ecosystem),
                        ),
                        _Row2(
                          title: l.privacyTitle,
                          onTap: () => context.push(V2Routes.privacy),
                        ),
                        _Row2(
                          title: l.termsTitle,
                          onTap: () => context.push(V2Routes.termsRead),
                        ),
                        _Row2(
                          title: l.helpVersion,
                          sub: access.updateRequired
                              ? l.dpDcVersionOld(appVersion)
                              : l.dpDcVersionOk(appVersion),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // The header scrolls away; the status bar keeps its navy so the
          // page never shows under the clock.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: top,
            child: const AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: ColoredBox(color: AtomColors.nav),
            ),
          ),
        ],
      ),
    );
  }
}

String _topicName(
  AppLocalizations l,
  String key, {
  required List<HelpTopic> topics,
}) =>
    topics.where((t) => t.key == key).firstOrNull?.name ??
    helpTopics(
      l,
      has: (_) => true,
      owner: true,
      extras: true,
    ).where((t) => t.key == key).firstOrNull?.name ??
    key;

/// ‹ on navy, 44 square, lined up with the page's edge.
class _NavyBack extends StatelessWidget {
  const _NavyBack({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Transform.translate(
        offset: const Offset(-8, 0),
        child: AtomIconButton(
          icon: LucideIcons.chevronLeft,
          label: AppLocalizations.of(context).commonBack,
          color: Colors.white,
          onTap: onTap,
        ),
      ),
    ),
  );
}

/// The logo colours across the full width (`.steps`).
class _FullStripe extends StatelessWidget {
  const _FullStripe();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => AtomStepsStripe(width: c.maxWidth),
  );
}

/// The Atomshop mark in a white circle (`Ask Atom first`, the thread).
class _RoundLogo extends StatelessWidget {
  const _RoundLogo({required this.size, required this.logo});
  final double size;
  final double logo;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: AtomColors.line),
    ),
    child: Image.asset(
      'assets/brand/eco_atomshop.png',
      width: logo,
      height: logo,
    ),
  );
}

class _AskAtomCard extends StatelessWidget {
  const _AskAtomCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AtomPressable(
      onTap: onTap,
      semanticLabel: '${l.atomTitle}. ${l.dpDcAskAtomFastest}',
      builder: (_, pressed) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AtomColors.primarySoft,
          borderRadius: AtomRadius.brCard,
          border: Border.all(color: AtomColors.primaryLine),
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              const AtomAiMark(size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.atomTitle, style: AtomText.listTitle),
                    Text(
                      l.dpDcAskAtomFastest,
                      style: AtomText.secondary.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AtomColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicGrid extends StatelessWidget {
  const _TopicGrid({
    required this.topics,
    required this.counts,
    required this.loaded,
  });

  final List<HelpTopic> topics;
  final Map<String, int> counts;
  final bool loaded;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // `.topics` is a 3-column grid: tiles side by side are the same
    // height (a two-line name doesn't make its tile taller than the rest).
    Widget tile(HelpTopic t) => AtomPressable(
      onTap: () => context.push(V2Routes.faqs, extra: t.key),
      semanticLabel: loaded
          ? '${t.name}, ${l.dpDcAnswers(counts[t.key] ?? 0)}'
          : t.name,
      builder: (_, pressed) => Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: BoxDecoration(
          color: pressed ? AtomColors.primarySoft : AtomColors.paper,
          borderRadius: AtomRadius.brCard,
          border: Border.all(
            color: pressed ? AtomColors.primaryLine : AtomColors.line,
          ),
        ),
        child: ExcludeSemantics(
          child: Column(
            children: [
              AtomIconTile(icon: t.icon, tone: t.tone, size: 36),
              const SizedBox(height: 6),
              Text(
                t.name,
                textAlign: TextAlign.center,
                style: AtomText.smallButton.copyWith(color: AtomColors.ink),
              ),
              if (loaded)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l.dpDcAnswers(counts[t.key] ?? 0),
                    textAlign: TextAlign.center,
                    style: AtomText.small.copyWith(
                      color: AtomColors.faint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return Column(
      children: [
        for (var i = 0; i < topics.length; i += 3) ...[
          if (i > 0) const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = i; j < i + 3; j++) ...[
                  if (j > i) const SizedBox(width: 8),
                  Expanded(
                    child: j < topics.length
                        ? tile(topics[j])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// `.row2`: a plain row, an optional icon tile, no chevron.
class _Row2 extends StatelessWidget {
  const _Row2({
    required this.title,
    this.sub,
    this.icon,
    this.tone = AtomTone.blue,
    this.onTap,
    this.link = false,
  });

  final String title;
  final String? sub;
  final IconData? icon;
  final AtomTone tone;
  final VoidCallback? onTap;

  /// "All FAQs": blue and centred.
  final bool link;

  @override
  Widget build(BuildContext context) {
    return AtomPressable(
      onTap: onTap,
      scaleOnPress: false,
      focusRadius: BorderRadius.zero,
      semanticLabel: [title, ?sub].join(', '),
      builder: (_, pressed) => Container(
        color: pressed ? AtomColors.head : AtomColors.paper,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: ExcludeSemantics(
          child: link
              ? Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AtomText.listTitle.copyWith(color: AtomColors.primary),
                )
              : Row(
                  children: [
                    if (icon != null) ...[
                      AtomIconTile(icon: icon!, tone: tone),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AtomText.listTitle),
                          if (sub != null)
                            Text(
                              sub!,
                              style: AtomText.secondary.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
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

// ── 18.2 FAQs ─────────────────────────────────────────────────────────────

/// A topic chip (`.chips button`): a pill, 36 tall.
class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.label,
    required this.on,
    required this.onTap,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AtomPressable(
    onTap: onTap,
    selected: on,
    semanticLabel: label,
    focusRadius: AtomRadius.brPill,
    builder: (context, pressed) => Container(
      constraints: const BoxConstraints(minHeight: AtomSize.small),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on
            ? AtomColors.primarySoft
            : pressed
            ? AtomColors.surface
            : AtomColors.paper,
        borderRadius: AtomRadius.brPill,
        border: Border.all(
          color: on ? AtomColors.primary : AtomColors.line2,
          width: on ? 2 : 1,
        ),
      ),
      child: Text(
        label,
        style: AtomText.smallButton.copyWith(
          color: on ? AtomColors.primary : AtomColors.text,
        ),
      ),
    ),
  );
}

/// The search box in a header (`.input`, 46 tall).
class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.hint,
    required this.label,
    required this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final String label;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: AtomSize.sheetSearch),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AtomColors.paper,
        borderRadius: AtomRadius.brControl,
        border: Border.all(color: AtomColors.line2),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.search, size: 18, color: AtomColors.faint),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: AtomText.input.copyWith(color: AtomColors.ink),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                // 46 with the border: 10 + a 24 line + 10 + 2.
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                hintText: hint,
                hintStyle: AtomText.input.copyWith(
                  color: AtomColors.placeholder,
                ),
                semanticCounterText: label,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// FAQs (18.2): search in English or Roman Urdu, topic chips, and each
/// answer opened in place, with Read more and Ask Atom.
class FaqScreen extends ConsumerStatefulWidget {
  const FaqScreen({super.key, this.topic, this.search = false});

  /// The topic to show first (the server's category).
  final String? topic;

  /// Opened from Help's search box: the keyboard comes up.
  final bool search;

  @override
  ConsumerState<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends ConsumerState<FaqScreen> {
  late String? _topic = widget.topic;
  int? _open;
  // The board opens the first answer of a topic; tapping takes over.
  bool _autoOpen = true;
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _typed(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final access = ref.watch(accessProvider);
    final owner =
        ref.watch(sessionProvider.notifier).current?.who.isOwner ?? false;
    final askAtom = access.has(Addon.askAtom);
    final searching = _query.isNotEmpty;
    final data = searching
        ? ref.watch(helpSearchProvider(_query))
        : ref.watch(helpFaqsProvider);
    final all = _allowed(ref, data.value ?? const []);
    final topics = [
      for (final t in helpTopics(
        l,
        has: access.has,
        owner: owner,
        extras: true,
      ))
        if (all.any((f) => f.category == t.key) || searching) t,
    ];
    // The board's chip order (Orders, AtomPay, Bulk deals, Products …
    // Account), then the topics the board's add-ons bring.
    const first = [
      'orders',
      'atompay',
      'bulk',
      'products',
      'stock',
      'team',
      'plan',
      'getting-started',
      'account',
    ];
    topics.sort((a, b) {
      final ia = first.indexOf(a.key), ib = first.indexOf(b.key);
      return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
    });
    final topic = _topic != null && topics.any((t) => t.key == _topic)
        ? _topic
        : topics.firstOrNull?.key;
    final shown = searching
        ? all
        : [
            for (final f in all)
              if (f.category == topic) f,
          ];
    final open =
        _open ?? (_autoOpen && !searching ? shown.firstOrNull?.id : null);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: Container(
              decoration: const BoxDecoration(
                color: AtomColors.paper,
                border: Border(bottom: BorderSide(color: AtomColors.line)),
              ),
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, right: 8),
                      child: Row(
                        children: [
                          AtomIconButton(
                            icon: LucideIcons.chevronLeft,
                            label: l.commonBack,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(
                                l.faqsTitle,
                                style: AtomText.pageTitle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _SearchBox(
                      controller: _search,
                      autofocus: widget.search,
                      hint: l.dpDcFaqSearchHint,
                      label: l.dpDcFaqSearchLabel,
                      onChanged: _typed,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (!searching && topics.length > 1)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        for (final t in topics) ...[
                          if (t != topics.first) const SizedBox(width: 8),
                          _TopicChip(
                            label: t.name,
                            on: t.key == topic,
                            onTap: () => setState(() {
                              _topic = t.key;
                              _open = null;
                              _autoOpen = true;
                            }),
                          ),
                        ],
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: data.isLoading && !data.hasValue
                      ? const AtomLoadingRows()
                      : data.hasError && !data.hasValue
                      ? AtomErrorState(
                          message: helpErrorText(l, data.error),
                          onRetry: () => searching
                              ? ref.invalidate(helpSearchProvider(_query))
                              : ref.invalidate(helpFaqsProvider),
                        )
                      : shown.isEmpty
                      ? AtomMessageState(
                          icon: LucideIcons.circleHelp,
                          title: searching ? l.faqsNone : l.helpFaqsEmpty,
                          body: searching ? null : l.helpFaqsEmptySub,
                          actionLabel: l.supportWhatsApp,
                          onAction: () => launchUrl(
                            whatsAppUri(AtomshopContacts.whatsapp),
                            mode: LaunchMode.externalApplication,
                          ),
                        )
                      : AtomListCard(
                          children: [
                            for (final f in shown)
                              _FaqItem(
                                faq: f,
                                open: open == f.id,
                                askAtom: askAtom,
                                onTap: () => setState(() {
                                  _autoOpen = false;
                                  _open = open == f.id ? null : f.id;
                                }),
                              ),
                          ],
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                  child: Text(
                    l.dpDcFaqFoot,
                    style: AtomText.small.copyWith(color: AtomColors.faint),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({
    required this.faq,
    required this.open,
    required this.askAtom,
    required this.onTap,
  });

  final HelpFaq faq;
  final bool open;
  final bool askAtom;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = parseAnswer(faq.answer);
    final body = AtomText.body.copyWith(height: 1.55);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          expanded: open,
          child: AtomPressable(
            onTap: onTap,
            scaleOnPress: false,
            focusRadius: BorderRadius.zero,
            semanticLabel: faq.question,
            builder: (_, pressed) => Container(
              color: pressed ? AtomColors.head : AtomColors.paper,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Expanded(
                    child: ExcludeSemantics(
                      child: Text(faq.question, style: AtomText.listTitle),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: AtomMotion.knob,
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 18,
                      color: open ? AtomColors.primary : AtomColors.chevron,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (open)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final p in a.intro) ...[
                  HelpRichText(p, style: body),
                  const SizedBox(height: 6),
                ],
                for (var i = 0; i < a.steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 18,
                          child: Text('${i + 1}.', style: body),
                        ),
                        Expanded(child: HelpRichText(a.steps[i], style: body)),
                      ],
                    ),
                  ),
                for (final p in a.after) ...[
                  const SizedBox(height: 2),
                  HelpRichText(p, style: AtomText.secondary),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    IntrinsicWidth(
                      child: AtomButton.small(
                        label: l.dpDcReadMore,
                        onPressed: () =>
                            context.push(V2Routes.faqAnswer, extra: faq),
                      ),
                    ),
                    if (askAtom)
                      IntrinsicWidth(
                        child: AtomButton.small(
                          label: l.atomTitle,
                          onPressed: () => context.push(V2Routes.askAtom),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── 18.3 One answer ───────────────────────────────────────────────────────

/// One answer (18.3): the question, numbered steps, a note, and "Did this
/// help?" (kept with Ask Atom's answer feedback).
class FaqAnswerScreen extends ConsumerStatefulWidget {
  const FaqAnswerScreen({super.key, required this.faq});
  final HelpFaq? faq;

  @override
  ConsumerState<FaqAnswerScreen> createState() => _FaqAnswerScreenState();
}

class _FaqAnswerScreenState extends ConsumerState<FaqAnswerScreen> {
  bool? _helped;

  Future<void> _say(bool helpful) async {
    final f = widget.faq;
    if (f == null || _helped == helpful) return;
    final before = _helped;
    setState(() => _helped = helpful);
    final r = await ref
        .read(helpRepositoryProvider)
        .faqFeedback(f.id, helpful: helpful);
    if (!mounted) return;
    if (r case ApiErr(:final failure)) {
      // Not counted: the buttons go back to what the server has, so the
      // seller can try again rather than see a thank-you for nothing.
      // Only if no later tap has changed it since.
      if (_helped == helpful) setState(() => _helped = before);
      showAtomToast(
        context,
        kind: AtomToastKind.bad,
        message: sayFailure(AppLocalizations.of(context), failure),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = widget.faq;
    final access = ref.watch(accessProvider);
    final owner =
        ref.watch(sessionProvider.notifier).current?.who.isOwner ?? false;
    if (f == null) {
      return Scaffold(
        backgroundColor: AtomColors.paper,
        body: Column(
          children: [
            const AtomFlowBar(),
            Expanded(
              child: AtomMessageState(
                icon: LucideIcons.circleHelp,
                title: l.dpDcFaqOpenFromList,
              ),
            ),
          ],
        ),
      );
    }
    final a = parseAnswer(f.answer);
    final tryRoute = f.links
        .map((x) => appRouteForPortalUrl(x.$2))
        .whereType<String>()
        .firstOrNull;
    final text = AtomText.body.copyWith(fontSize: 15, height: 1.5);
    final topic = _topicName(
      l,
      f.category,
      topics: helpTopics(l, has: access.has, owner: owner, extras: true),
    );
    return Scaffold(
      backgroundColor: AtomColors.paper,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: Padding(
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
              child: SizedBox(
                height: 52,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      AtomIconButton(
                        icon: LucideIcons.chevronLeft,
                        label: l.commonBack,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          topic,
                          style: AtomText.small.copyWith(
                            color: AtomColors.faint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Semantics(
                  header: true,
                  child: Text(f.question, style: AtomText.pageTitle),
                ),
                for (final p in a.intro) ...[
                  const SizedBox(height: 14),
                  HelpRichText(p, style: text),
                ],
                for (var i = 0; i < a.steps.length; i++) ...[
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AtomColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: AtomText.smallButton.copyWith(
                            color: AtomColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: HelpRichText(a.steps[i], style: text),
                        ),
                      ),
                    ],
                  ),
                ],
                if (a.after.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _BlueNote(text: a.after.join(' ')),
                ],
                // "Try it now" (18.3): the first of the answer's pages that
                // the app has a screen for.
                if (tryRoute != null) ...[
                  const SizedBox(height: 14),
                  AtomButton(
                    label: l.emuP4TryItNow,
                    kind: AtomButtonKind.outline,
                    compact: true,
                    onPressed: () => V2Routes.tabs.contains(tryRoute)
                        ? context.go(tryRoute)
                        : context.push(tryRoute),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(l.dpDcDidThisHelp, style: AtomText.body),
                    _VoteChip(
                      label: l.commonYes,
                      on: _helped == true,
                      onTap: () => _say(true),
                    ),
                    _VoteChip(
                      label: l.commonNo,
                      on: _helped == false,
                      onTap: () => _say(false),
                    ),
                  ],
                ),
                if (_helped == false && access.has(Addon.askAtom)) ...[
                  const SizedBox(height: 14),
                  _Button46(
                    label: l.dpDcAskAtomCase,
                    primary: true,
                    onTap: () => context.push(V2Routes.askAtom),
                  ),
                ],
                if (_helped == true) ...[
                  const SizedBox(height: 10),
                  Text(l.dpDcThanks, style: AtomText.secondary),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `.note.blue`, with the server's bold.
class _BlueNote extends StatelessWidget {
  const _BlueNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AtomColors.primarySoft,
      borderRadius: AtomRadius.brControl,
      border: Border.all(color: AtomColors.primaryLine),
    ),
    child: HelpRichText(
      text,
      style: AtomText.body.copyWith(color: AtomColors.noteBlueText),
    ),
  );
}

/// `.fb button`: a 40-tall pill.
class _VoteChip extends StatelessWidget {
  const _VoteChip({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AtomPressable(
    onTap: onTap,
    selected: on,
    semanticLabel: label,
    focusRadius: AtomRadius.brPill,
    builder: (_, pressed) => Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: on ? AtomColors.primarySoft : AtomColors.paper,
        borderRadius: AtomRadius.brPill,
        border: Border.all(color: on ? AtomColors.primary : AtomColors.line2),
      ),
      child: Text(
        label,
        style: AtomText.body.copyWith(
          fontWeight: FontWeight.w600,
          color: on ? AtomColors.primary : AtomColors.ink,
        ),
      ),
    ),
  );
}

/// A 46-tall full-width button, 15/600 (18.3 "Ask Atom about your case").
class _Button46 extends StatelessWidget {
  const _Button46({
    required this.label,
    required this.onTap,
    this.primary = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) => AtomPressable(
    onTap: onTap,
    semanticLabel: label,
    builder: (_, pressed) => Container(
      constraints: const BoxConstraints(minHeight: 46),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: primary
            ? (pressed ? AtomColors.primaryPressed : AtomColors.primary)
            : (pressed ? AtomColors.surface : AtomColors.paper),
        borderRadius: AtomRadius.brControl,
        border: Border.all(
          color: primary ? Colors.transparent : AtomColors.line2,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AtomText.listTitle.copyWith(
          color: primary ? Colors.white : AtomColors.ink,
        ),
      ),
    ),
  );
}

// ── 17.2 Support requests ─────────────────────────────────────────────────

String _supportWhen(AppLocalizations l, SupportRequest r) {
  final at = r.last.at ?? r.repliedAt ?? r.createdAt;
  String when(DateTime d, {bool since = false}) {
    final today = AtomDates.daysFrom(d, today: AtomDates.now()) == 0;
    if (!today) return AtomDates.short(d);
    return since ? AtomDates.time(d) : l.dpDcTodayAt(AtomDates.time(d));
  }

  if (r.closed) {
    return at == null ? l.dpDcClosed : '${l.dpDcClosed} · ${when(at)}';
  }
  if (r.answered) {
    return at == null
        ? l.supportAnswered
        : '${l.supportAnswered} · ${when(at)}';
  }
  return at == null
      ? l.dpDcWaitingAtomshop
      : '${l.dpDcWaitingAtomshop} · ${l.dpDcSince(when(at, since: true))}';
}

({String label, AtomTone tone}) _supportState(
  AppLocalizations l,
  SupportRequest r,
) => r.closed
    ? (label: l.dpDcClosed, tone: AtomTone.grey)
    : r.answered
    ? (label: l.supportAnswered, tone: AtomTone.green)
    : (label: l.supportWaiting, tone: AtomTone.amber);

/// Your support requests (17.2): questions Ask Atom handed to Atomshop,
/// open and closed, with the last word in each.
class SupportListScreen extends ConsumerStatefulWidget {
  const SupportListScreen({super.key});

  @override
  ConsumerState<SupportListScreen> createState() => _SupportListScreenState();
}

class _SupportListScreenState extends ConsumerState<SupportListScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(supportRequestsProvider);
    final list = data.value ?? const <SupportRequest>[];
    final open = [
      for (final r in list)
        if (!r.closed) r,
    ];
    final closed = [
      for (final r in list)
        if (r.closed) r,
    ];
    final shown = _tab == 0 ? open : closed;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final askAtom = ref.watch(accessProvider).has(Addon.askAtom);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtomPageHeader(
            title: l.dpDcHelpSupport,
            leading: AtomIconButton(
              icon: LucideIcons.chevronLeft,
              label: l.commonBack,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            tabs: [
              AtomHeaderTab(l.dpDcOpen, count: open.length),
              AtomHeaderTab(l.dpDcClosed, count: closed.length),
            ],
            selectedTab: _tab,
            onTab: (i) => setState(() => _tab = i),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(supportRequestsProvider.future),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (askAtom) ...[
                    AtomPressable(
                      onTap: () => context.push(V2Routes.askAtom),
                      semanticLabel:
                          '${l.dpDcAskAtomFirst}. ${l.dpDcAskAtomFirstSub}',
                      builder: (_, pressed) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: pressed ? AtomColors.head : AtomColors.paper,
                          borderRadius: AtomRadius.brCard,
                          border: Border.all(color: AtomColors.line),
                        ),
                        child: ExcludeSemantics(
                          child: Row(
                            children: [
                              const AtomAiMark(size: 40, ring: true),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.dpDcAskAtomFirst,
                                      style: AtomText.listTitle,
                                    ),
                                    Text(
                                      l.dpDcAskAtomFirstSub,
                                      style: AtomText.secondary.copyWith(
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (data.isLoading && !data.hasValue)
                    const AtomLoadingRows()
                  else if (data.hasError && !data.hasValue)
                    AtomErrorState(
                      message: helpErrorText(l, data.error),
                      onRetry: () => ref.invalidate(supportRequestsProvider),
                    )
                  else if (shown.isEmpty)
                    AtomMessageState(
                      icon: LucideIcons.messagesSquare,
                      title: _tab == 0 ? l.dpDcNoOpen : l.dpDcNoClosed,
                      body: l.supportEmptyBody,
                    )
                  else
                    AtomListCard(
                      children: [
                        for (final r in shown)
                          _SupportRow(
                            request: r,
                            onTap: () =>
                                context.push(V2Routes.supportThread, extra: r),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AtomColors.paper,
              border: Border(top: BorderSide(color: AtomColors.line)),
            ),
            padding: EdgeInsets.fromLTRB(16, 12, 16, 26 + bottom),
            child: AtomButton(
              label: l.dpDcWhatsAppAtomshop(
                // One line for the number: it never breaks inside.
                AtomshopContacts.whatsapp.replaceAll(' ', '\u00A0'),
              ),
              kind: AtomButtonKind.whatsapp,
              oneLine: true,
              icon: AtomBrandIcons.whatsapp,
              onPressed: () => launchUrl(
                whatsAppUri(AtomshopContacts.whatsapp),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportRow extends StatelessWidget {
  const _SupportRow({required this.request, required this.onTap});
  final SupportRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = request;
    final state = _supportState(l, r);
    final title = r.subject.isEmpty ? r.question : r.subject;
    final last = r.last;
    final lastLine = last.fromAtomshop
        ? l.dpDcLastAtomshop(last.text)
        : l.dpDcLastYou(last.text);
    final when = _supportWhen(l, r);
    return AtomPressable(
      onTap: onTap,
      scaleOnPress: false,
      focusRadius: BorderRadius.zero,
      semanticLabel: [title, lastLine, when, state.label].join(', '),
      builder: (_, pressed) => Container(
        color: pressed ? AtomColors.head : AtomColors.paper,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AtomIconTile(
                icon: LucideIcons.messageCircle,
                tone: r.closed ? _greyTile : state.tone,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AtomText.listTitle),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        lastLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AtomText.secondary,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        when,
                        style: AtomText.small.copyWith(color: AtomColors.faint),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _SmallPill(label: state.label, tone: state.tone),
            ],
          ),
        ),
      ),
    );
  }
}

/// A 22-tall status pill (17.2).
class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.label, required this.tone, this.height = 22});
  final String label;
  final AtomTone tone;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(minHeight: height),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: tone.bg,
      borderRadius: AtomRadius.brPill,
      border: Border.all(color: tone.border),
    ),
    child: Text(
      label,
      style: AtomText.small.copyWith(
        color: tone.fg,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

// ── 17.3 A support conversation ───────────────────────────────────────────

/// A support conversation (17.3): what you asked, Atomshop's answers and
/// your replies; reply here (it opens the request again) or close it.
class SupportThreadScreen extends ConsumerStatefulWidget {
  const SupportThreadScreen({super.key, required this.request});
  final SupportRequest? request;

  @override
  ConsumerState<SupportThreadScreen> createState() =>
      _SupportThreadScreenState();
}

class _SupportThreadScreenState extends ConsumerState<SupportThreadScreen> {
  late SupportRequest? _r = widget.request;
  final _reply = TextEditingController();

  /// A reply or "Yes, close it" on its way, one at a time: a second tap
  /// sent a second close, and a close could cross a reply still being sent.
  _ThreadBusy _busy = _ThreadBusy.idle;
  bool get _sending => _busy == _ThreadBusy.sending;
  bool get _closing => _busy == _ThreadBusy.closing;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final r = _r;
    final text = _reply.text.trim();
    if (r == null || text.isEmpty || _busy != _ThreadBusy.idle) return;
    setState(() => _busy = _ThreadBusy.sending);
    final res = await ref.read(helpRepositoryProvider).reply(r.uuid, text);
    if (!mounted) return;
    setState(() => _busy = _ThreadBusy.idle);
    switch (res) {
      case ApiOk(:final value):
        _reply.clear();
        setState(() => _r = value);
        ref.invalidate(supportRequestsProvider);
      case ApiErr(:final failure):
        showAtomToast(
          context,
          kind: AtomToastKind.bad,
          message: failure.kind == ApiFailureKind.notFound
              ? AppLocalizations.of(context).helpRepliesOff
              : sayFailure(AppLocalizations.of(context), failure),
        );
    }
  }

  Future<void> _close() async {
    final r = _r;
    if (r == null || _busy != _ThreadBusy.idle) return;
    final l = AppLocalizations.of(context);
    setState(() => _busy = _ThreadBusy.closing);
    final res = await ref.read(helpRepositoryProvider).close(r.uuid);
    if (!mounted) return;
    setState(() => _busy = _ThreadBusy.idle);
    switch (res) {
      case ApiOk():
        ref.invalidate(supportRequestsProvider);
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: l.dpDcClosedToast,
        );
        Navigator.of(context).maybePop();
      case ApiErr(:final failure):
        showAtomToast(
          context,
          kind: AtomToastKind.bad,
          message: sayFailure(l, failure),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = _r;
    final back = AtomIconButton(
      icon: LucideIcons.chevronLeft,
      label: l.commonBack,
      onTap: () => Navigator.of(context).maybePop(),
    );
    if (r == null) {
      return Scaffold(
        body: Column(
          children: [
            AtomPageHeader(title: l.dpDcHelpSupport, leading: back),
            Expanded(
              child: AtomMessageState(
                icon: LucideIcons.messagesSquare,
                title: l.supportOpenFromList,
              ),
            ),
          ],
        ),
      );
    }
    final state = _supportState(l, r);
    final title = r.subject.isEmpty ? r.code : r.subject;
    String who(String name, DateTime? at) =>
        at == null ? name : '$name · ${AtomDates.time(at)}';
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: Container(
              decoration: const BoxDecoration(
                color: AtomColors.paper,
                border: Border(bottom: BorderSide(color: AtomColors.line)),
              ),
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, right: 16),
                  child: Row(
                    children: [
                      back,
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AtomText.heading,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SmallPill(
                        label: state.label,
                        tone: state.tone,
                        height: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AtomColors.head,
                    borderRadius: AtomRadius.brControl,
                    border: Border.all(color: AtomColors.line),
                  ),
                  child: Text(
                    r.about == null
                        ? l.dpDcFromAskAtom
                        : l.dpDcFromAskAtomAbout(r.about!),
                    style: AtomText.secondary,
                  ),
                ),
                const SizedBox(height: 12),
                _Bubble(
                  who: who(l.supportYou, r.createdAt),
                  text: r.question,
                  mine: true,
                ),
                for (final m in r.thread) ...[
                  const SizedBox(height: 12),
                  _Bubble(
                    who: who(
                      m.fromAtomshop ? l.supportAtomshop : l.supportYou,
                      m.at,
                    ),
                    text: m.text,
                    mine: !m.fromAtomshop,
                  ),
                ],
                if (r.thread.isEmpty && r.reply != null) ...[
                  const SizedBox(height: 12),
                  _Bubble(
                    who: who(l.supportAtomshop, r.repliedAt),
                    text: r.reply!,
                    mine: false,
                  ),
                ],
                const SizedBox(height: 12),
                if (r.answered && r.canClose)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AtomColors.primarySoft,
                      borderRadius: AtomRadius.brControl,
                      border: Border.all(color: AtomColors.primaryLine),
                    ),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${l.dpDcSolved} ',
                          style: AtomText.secondary.copyWith(
                            color: AtomColors.noteBlueText,
                          ),
                        ),
                        Semantics(
                          button: true,
                          child: GestureDetector(
                            onTap: _closing ? null : _close,
                            child: Text(
                              l.dpDcYesClose,
                              style: AtomText.secondary.copyWith(
                                color: AtomColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          ' ${l.dpDcOrReply}',
                          style: AtomText.secondary.copyWith(
                            color: AtomColors.noteBlueText,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (!r.answered && !r.closed)
                  AtomNote(
                    kind: AtomNoteKind.info,
                    message: l.supportWaitingNote,
                  ),
              ],
            ),
          ),
          if (r.canReply)
            Container(
              decoration: const BoxDecoration(
                color: AtomColors.paper,
                border: Border(top: BorderSide(color: AtomColors.line)),
              ),
              padding: EdgeInsets.fromLTRB(12, 10, 12, 26 + bottom),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: AtomColors.paper,
                        borderRadius: AtomRadius.brPill,
                        border: Border.all(color: AtomColors.line2),
                      ),
                      child: TextField(
                        controller: _reply,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 2000,
                        onChanged: (_) => setState(() {}),
                        textCapitalization: TextCapitalization.sentences,
                        style: AtomText.input.copyWith(color: AtomColors.ink),
                        decoration: InputDecoration(
                          isDense: true,
                          counterText: '',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          hintText: l.dpDcReplyAtomshop,
                          hintStyle: AtomText.input.copyWith(
                            color: AtomColors.placeholder,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AtomPressable(
                    onTap: _reply.text.trim().isEmpty || _sending
                        ? null
                        : _send,
                    semanticLabel: l.dpDcSend,
                    builder: (_, pressed) => Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _reply.text.trim().isEmpty
                            ? AtomColors.disabledFill
                            : pressed
                            ? AtomColors.primaryPressed
                            : AtomColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _sending
                          ? const Center(
                              child: AtomSpinner(
                                size: 18,
                                color: Colors.white,
                                track: Colors.white38,
                              ),
                            )
                          : Icon(
                              LucideIcons.arrowRight,
                              size: 20,
                              color: _reply.text.trim().isEmpty
                                  ? AtomColors.disabledText
                                  : Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.who, required this.text, required this.mine});
  final String who;
  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final max = MediaQuery.sizeOf(context).width * (mine ? 0.78 : 0.82);
    final label = Text(
      who,
      style: AtomText.small.copyWith(color: AtomColors.faint),
    );
    if (mine) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          label,
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: max),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: AtomColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: Text(
                text,
                style: AtomText.body.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label,
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const _RoundLogo(size: 28, logo: 22),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: max - 36),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AtomColors.paper,
                  border: Border.all(color: AtomColors.line),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                child: Text(text, style: AtomText.body.copyWith(height: 1.5)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── 18.4 Privacy policy ───────────────────────────────────────────────────

/// A legal page's numbered sections, each opened in place (18.4, 18.5).
class LegalSections extends StatefulWidget {
  const LegalSections({super.key, required this.doc, this.openFirst});
  final LegalDoc doc;

  /// The section opened at first: the first whose title has this word
  /// (18.4 opens "Privacy & data security", as the board).
  final String? openFirst;

  @override
  State<LegalSections> createState() => _LegalSectionsState();
}

class _LegalSectionsState extends State<LegalSections> {
  int? _open;

  @override
  void initState() {
    super.initState();
    final word = widget.openFirst?.toLowerCase();
    if (word != null) {
      final i = widget.doc.sections.indexWhere(
        (s) => s.title.toLowerCase().contains(word),
      );
      if (i >= 0) _open = i;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = AtomText.body.copyWith(height: 1.6);
    final s = widget.doc.sections;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < s.length; i++)
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AtomColors.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  expanded: _open == i,
                  child: AtomPressable(
                    onTap: () => setState(() => _open = _open == i ? null : i),
                    scaleOnPress: false,
                    semanticLabel: '${i + 1}. ${s[i].title}',
                    builder: (_, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: ExcludeSemantics(
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AtomColors.surface,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                              ),
                              child: Text(
                                '${i + 1}',
                                style: AtomText.smallButton.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AtomColors.text,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                s[i].title,
                                style: AtomText.listTitle,
                              ),
                            ),
                            Icon(
                              _open == i
                                  ? LucideIcons.chevronUp
                                  : LucideIcons.chevronDown,
                              size: 18,
                              color: AtomColors.chevron,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_open == i)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(38, 0, 0, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final b in s[i].blocks)
                          if (b.text != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(b.text!, style: body),
                            )
                          else
                            for (final item in b.items)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('•  ', style: body),
                                    Expanded(child: Text(item, style: body)),
                                  ],
                                ),
                              ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A legal page's head (`.hd`): the title, a grey pill and a line.
class LegalHead extends StatelessWidget {
  const LegalHead({
    super.key,
    required this.title,
    required this.lead,
    this.pill,
  });

  final String title;
  final String lead;
  final String? pill;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AtomColors.line)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: AtomText.successTitle),
        ),
        if (pill != null) ...[
          const SizedBox(height: 8),
          HelpPill(label: pill!),
        ],
        const SizedBox(height: 8),
        Text(lead, style: AtomText.secondary.copyWith(height: 1.45)),
      ],
    ),
  );
}

/// The plain white bar with ‹ (`.bar`), and anything on the right.
class LegalBar extends StatelessWidget {
  const LegalBar({super.key, this.trailing});
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark,
    child: Padding(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              AtomIconButton(
                icon: LucideIcons.chevronLeft,
                label: AppLocalizations.of(context).commonBack,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: trailing,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// A grey (or [tone]) pill whose words wrap at large text (`.pill`).
class HelpPill extends StatelessWidget {
  const HelpPill({super.key, required this.label, this.tone = AtomTone.grey});
  final String label;
  final AtomTone tone;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 22),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: tone.bg,
      borderRadius: AtomRadius.brPill,
      border: Border.all(color: tone.border),
    ),
    child: Text(
      label,
      style: AtomText.small.copyWith(
        color: tone.fg,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// A small outline button at its own size, wherever it sits.
class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  // `.mini` in the bar: 36 tall at its own size, at the bar's end, not
  // stretched to the row's height.
  Widget build(BuildContext context) => Align(
    widthFactor: 1,
    heightFactor: 1,
    child: IntrinsicWidth(
      child: AtomButton.small(label: label, onPressed: onPressed),
    ),
  );
}

/// Privacy policy (18.4): the website's page, section by section.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(privacyProvider);
    final doc = data.value;
    return Scaffold(
      backgroundColor: AtomColors.paper,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LegalBar(
            trailing: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Mini(
                label: l.dpDcOpenOnSite,
                onPressed: () => launchUrl(
                  doc?.url == null
                      ? AtomshopContacts.privacy
                      : Uri.parse(doc!.url!),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                LegalHead(
                  title: l.privacyTitle,
                  pill: doc?.updatedAt == null
                      ? null
                      : l.dpDcLastUpdated(AtomDates.day(doc!.updatedAt!)),
                  lead: l.dpDcPrivacyLead,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: data.isLoading && !data.hasValue
                      ? const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: AtomLoadingRows(),
                        )
                      : data.hasError && !data.hasValue
                      ? AtomErrorState(
                          message: helpErrorText(l, data.error),
                          onRetry: () => ref.invalidate(privacyProvider),
                        )
                      : LegalSections(doc: doc!, openFirst: 'privacy'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    l.dpDcPrivacyFoot(AtomshopContacts.email),
                    style: AtomText.small.copyWith(color: AtomColors.faint),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 18.6 Our ecosystem ────────────────────────────────────────────────────

/// Atomshop's links (config/website.php `app.*`, `social.*`).
abstract final class _Links {
  static final atomshopAndroid = Uri.parse(
    'https://play.google.com/store/apps/details?id=com.ecommerce.atomshop',
  );
  static final atomshopIos = Uri.parse(
    'https://apps.apple.com/us/app/atomshop/id6744655747',
  );
  static final atompayAndroid = Uri.parse(
    'https://play.google.com/store/apps/details?id=com.ecommerce.atompay',
  );
  static final atomsellerAndroid = Uri.parse(
    'https://play.google.com/store/apps/details?id=com.ecommerce.atomseller',
  );
  static const brandPartnerAndroid =
      'https://play.google.com/store/apps/details?id=com.ecommerce.atombrand';
  static final site = Uri.parse('https://atomshop.pk');
  static final facebook = Uri.parse('https://www.facebook.com/atomshoppk');
  static final instagram = Uri.parse('https://www.instagram.com/atomshop.pk/');
  static final tiktok = Uri.parse('https://www.tiktok.com/@atomshop.pk');
}

/// Our ecosystem (18.6): how customers, you and brands fit together, and
/// each Atomshop app with its links.
class EcosystemScreen extends ConsumerWidget {
  const EcosystemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    // The brand has a public page on atomshop.pk once it has a slug.
    final session = ref.watch(sessionProvider.notifier).current;
    final shop =
        session?.brandSlug != null &&
        (session?.who.can(BrandPermission.pageEdit) ?? false);
    final top = MediaQuery.paddingOf(context).top;
    void open(Uri u) => launchUrl(u, mode: LaunchMode.externalApplication);
    void share(String text) => launchUrl(
      whatsAppUri('', text: text),
      mode: LaunchMode.externalApplication,
    );

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Container(
              color: AtomColors.nav,
              padding: EdgeInsets.fromLTRB(16, top, 16, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NavyBack(onTap: () => Navigator.of(context).maybePop()),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Image.asset(
                      'assets/brand/atomshop_logo.png',
                      height: 34,
                      semanticLabel: AppLocalizations.of(context)
                          .helpAtomshopLogo,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Semantics(
                    header: true,
                    child: Text(
                      l.dpDcEcoTitle,
                      style: AtomText.successTitle.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.dpDcEcoLead,
                    style: AtomText.body.copyWith(
                      color: AtomColors.navText,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const _FullStripe(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Semantics(
              label: l.dpDcEcoFlowLabel,
              child: ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AtomDecor.card,
                  child: Row(
                    children: [
                      _FlowStep(l.dpDcEcoCustomers, l.dpDcEcoCustomersSub),
                      const _FlowArrow(),
                      _FlowStep(l.dpDcEcoYou, l.dpDcEcoYouSub),
                      const _FlowArrow(back: true),
                      _FlowStep(l.dpDcEcoBrands, l.dpDcEcoBrandsSub),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AppCard(
                  you: true,
                  mark: const _Mark(asset: 'assets/brand/mark.png'),
                  name: 'Brand Partner',
                  pill: HelpPill(label: l.dpDcYouAreHere, tone: AtomTone.blue),
                  text: l.dpDcEcoSeller,
                  links: [
                    (
                      l.dpDcShareSeller,
                      () => share(
                        l.dpDcShareSellerText(_Links.brandPartnerAndroid),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _AppCard(
                  mark: const _Mark(asset: 'assets/brand/eco_atomshop.png'),
                  name: 'Atomshop',
                  text: l.dpDcEcoAtomshop,
                  links: [
                    ('Google Play', () => open(_Links.atomshopAndroid)),
                    ('App Store', () => open(_Links.atomshopIos)),
                  ],
                ),
                const SizedBox(height: 10),
                _AppCard(
                  mark: const _Mark(asset: 'assets/brand/eco_atompay.png'),
                  name: 'AtomPay',
                  text: l.dpDcEcoPay,
                  links: [('Google Play', () => open(_Links.atompayAndroid))],
                ),
                const SizedBox(height: 10),
                _AppCard(
                  mark: const _Mark(asset: 'assets/brand/eco_atomseller.png'),
                  name: 'Atom Seller',
                  text: l.dpDcEcoBrand,
                  links: [
                    ('Google Play', () => open(_Links.atomsellerAndroid)),
                  ],
                ),
                const SizedBox(height: 10),
                _AppCard(
                  mark: const _Mark(icon: LucideIcons.globe),
                  name: 'atomshop.pk',
                  text: shop ? l.dpDcEcoSiteShop : l.dpDcEcoSite,
                  links: [
                    (l.dpDcOpenSite, () => open(_Links.site)),
                    if (shop)
                      (
                        l.dpDcYourShopPage,
                        () => context.push(V2Routes.brandPage),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                AtomSectionLabel(l.dpDcFollow, page: false),
                Row(
                  children: [
                    for (final (i, s) in [
                      ('Facebook', _Links.facebook),
                      ('Instagram', _Links.instagram),
                      ('TikTok', _Links.tiktok),
                    ].indexed) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: AtomPressable(
                          onTap: () => open(s.$2),
                          semanticLabel: s.$1,
                          builder: (_, pressed) => Container(
                            constraints: const BoxConstraints(minHeight: 44),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: pressed
                                  ? AtomColors.head
                                  : AtomColors.paper,
                              borderRadius: AtomRadius.brControl,
                              border: Border.all(color: AtomColors.line),
                            ),
                            child: Text(
                              s.$1,
                              style: AtomText.smallButton.copyWith(
                                color: AtomColors.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep(this.name, this.sub);
  final String name;
  final String sub;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          name,
          textAlign: TextAlign.center,
          style: AtomText.smallButton.copyWith(color: AtomColors.ink),
        ),
        Text(
          sub,
          textAlign: TextAlign.center,
          style: AtomText.small.copyWith(color: AtomColors.muted, height: 1.3),
        ),
      ],
    ),
  );
}

class _FlowArrow extends StatelessWidget {
  const _FlowArrow({this.back = false});

  /// Pointing back at "You" (brands supply you), as the board's second arrow.
  final bool back;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Icon(
      back ? LucideIcons.arrowLeft : LucideIcons.arrowRight,
      size: 18,
      color: AtomColors.chevron,
    ),
  );
}

/// An app's mark on a white 52 tile with a hairline (`.app .mk`).
class _Mark extends StatelessWidget {
  const _Mark({this.asset, this.icon});
  final String? asset;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 52,
    alignment: Alignment.center,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AtomColors.line),
    ),
    child: asset != null
        ? Image.asset(asset!, width: 44, height: 44)
        : Icon(icon, size: 24, color: AtomColors.primary),
  );
}

class _AppCard extends StatelessWidget {
  const _AppCard({
    required this.mark,
    required this.name,
    required this.text,
    this.links = const [],
    this.pill,
    this.you = false,
  });

  final Widget mark;
  final String name;
  final String text;
  final List<(String, VoidCallback)> links;
  final Widget? pill;

  /// This app: a blue ring.
  final bool you;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(you ? 13 : 14),
    decoration: BoxDecoration(
      color: AtomColors.paper,
      borderRadius: AtomRadius.brCard,
      border: Border.all(
        color: you ? AtomColors.primary : AtomColors.line,
        width: you ? 2 : 1,
      ),
      boxShadow: you
          ? const [BoxShadow(color: AtomColors.primarySoft, spreadRadius: 3)]
          : null,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: mark),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    name,
                    style: AtomText.input.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AtomColors.ink,
                    ),
                  ),
                  ?pill,
                ],
              ),
              const SizedBox(height: 2),
              Text(text, style: AtomText.secondary.copyWith(height: 1.45)),
              const SizedBox(height: 8),
              if (links.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final (label, onTap) in links)
                      IntrinsicWidth(
                        child: AtomButton.small(label: label, onPressed: onTap),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

enum _ThreadBusy { idle, sending, closing }
