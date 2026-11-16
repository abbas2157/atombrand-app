import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/portal_links.dart';
import '../../../app/routes.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/dates.dart';
import '../../../core/net/network_status.dart';
import '../../../core/prefs/atom_language.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/ask_atom_questions.dart';
import '../data/ask_atom_repository.dart';

/// `**bold**` and new lines, the only formatting Atom sends.
Widget atomText(String text, {TextStyle? style}) {
  final base = style ?? AtomText.body;
  final parts = text.split('**');
  return Text.rich(
    TextSpan(
      style: base,
      children: [
        for (var i = 0; i < parts.length; i++)
          TextSpan(
            text: parts[i],
            style: i.isOdd
                ? base.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AtomColors.ink,
                  )
                : null,
          ),
      ],
    ),
  );
}

/// One of Atom's links: the app's own screen when it has one (a portal
/// link such as `/brand-portal/orders/…`), else the browser.
void _openLink(BuildContext context, String url) {
  final route = appRouteForPortalUrl(url);
  if (route == null) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } else if (V2Routes.tabs.contains(Uri.parse(route).path)) {
    context.go(route);
  } else {
    context.push(route);
  }
}

/// A row's own button (12.12): the order or bulk request it is about, else
/// its portal link.
void _openRowAction(BuildContext context, AtomRowAction a) {
  if (a.orderUuid case final uuid?) {
    context.push(V2Routes.orderOf(uuid));
  } else if (a.bulkRequestId case final id?) {
    context.push(
      a.fromSeller ? V2Routes.sellerRequestOf(id) : V2Routes.bulkRequestOf(id),
    );
  } else if (a.url case final url?) {
    _openLink(context, url);
  }
}

/// A line of the chat: the person's question, Atom's answer, or a
/// hand-over note.
sealed class _Line {
  const _Line();
}

final class _Mine extends _Line {
  const _Mine(this.text);
  final String text;
}

final class _Atom extends _Line {
  const _Atom(this.answer);
  final AtomAnswer answer;
}

final class _Sent extends _Line {
  const _Sent(this.code, this.whatsapp);
  final String code;
  final String? whatsapp;
}

/// Ask Atom (12.10–12.12, Ask Atom add-on): a greeting, what Atom noticed,
/// brand questions that fit (orders to confirm, quotes running out, low
/// stock, sales this month, seller requests) and recent ones, then a chat.
/// Atom answers from the brand's own records; a change happens only after
/// Confirm; "Talk to Atomshop" hands the question to support. Needs
/// internet: offline, the box and Send are off.
class AskAtomScreen extends ConsumerStatefulWidget {
  const AskAtomScreen({super.key, this.question, this.error});

  /// A question to ask straight away ("Why?" on a refusal elsewhere).
  final String? question;

  /// The refusal the app just showed, sent as `error`.
  final String? error;

  @override
  ConsumerState<AskAtomScreen> createState() => _AskAtomScreenState();
}

class _AskAtomScreenState extends ConsumerState<AskAtomScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _lines = <_Line>[];
  AtomContext? _context;
  List<AtomRecent> _recent = const [];
  final _speech = SpeechToText();
  bool _listening = false;
  bool _busy = false;
  String? _error;
  final _rated = <int>{};
  final _settled = <String>{};

  /// What has gone to Atomshop already: a second tap must not open a
  /// second support request for the same thing.
  final _handed = <String>{};

  @override
  void initState() {
    super.initState();
    _loadContext();
    _loadRecent();
    if (widget.question case final q? when q.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ask(q, error: widget.error),
      );
    }
  }

  @override
  void dispose() {
    if (_listening) _speech.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _lang => ref.read(atomLanguageProvider);

  List<AtomTurn> get _history => [
    for (final l in _lines)
      switch (l) {
        _Mine(:final text) => (mine: true, text: text),
        _Atom(:final answer) => (
          mine: false,
          text: answer.problem ?? answer.text ?? '',
        ),
        _Sent() => (mine: false, text: ''),
      },
  ].where((t) => t.text.isNotEmpty).toList();

  Future<void> _loadContext() async {
    final r = await ref.read(askAtomRepositoryProvider).context(lang: _lang);
    if (!mounted) return;
    if (r case ApiOk(:final value)) setState(() => _context = value);
  }

  Future<void> _loadRecent() async {
    final r = await ref.read(askAtomRepositoryProvider).recent();
    if (!mounted) return;
    if (r case ApiOk(:final value)) setState(() => _recent = value);
  }

  /// The mic (12.10): the phone's speech recogniser writes into the box;
  /// the person reads it and taps Send. Asked for the microphone only now;
  /// a "no" or a phone without a recogniser says so and the box still
  /// works.
  Future<void> _mic() async {
    final l = AppLocalizations.of(context);
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    var ready = false;
    try {
      ready = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == SpeechToText.doneStatus ||
              status == SpeechToText.notListeningStatus) {
            setState(() => _listening = false);
          }
        },
        onError: (SpeechRecognitionError e) {
          if (!mounted) return;
          setState(() => _listening = false);
          if (e.errorMsg == 'error_permission' ||
              e.errorMsg == 'error_insufficient_permissions') {
            showAtomToast(
              context,
              kind: AtomToastKind.bad,
              message: l.askAtomMicDenied,
            );
          }
        },
      );
    } catch (_) {
      ready = false;
    }
    if (!mounted) return;
    if (!ready) {
      final allowed = await _speech.hasPermission.catchError((_) => false);
      if (!mounted) return;
      showAtomToast(
        context,
        kind: AtomToastKind.bad,
        message: allowed ? l.askAtomMicUnavailable : l.askAtomMicDenied,
      );
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (r) {
        if (!mounted) return;
        _input.value = TextEditingValue(
          text: r.recognizedWords,
          selection: TextSelection.collapsed(offset: r.recognizedWords.length),
        );
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  void _toEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  });

  Future<void> _ask(String question, {String? shown, String? error}) async {
    final q = question.trim();
    if (q.isEmpty || _busy) return;
    if (_listening) {
      _speech.stop();
      _listening = false;
    }
    final l = AppLocalizations.of(context);
    final history = _history;
    setState(() {
      _lines.add(_Mine(shown ?? q));
      _busy = true;
      _error = null;
      _input.clear();
    });
    final asked = shown ?? q;
    _recent = [
      (question: asked, at: AtomDates.now()),
      for (final r in _recent)
        if (r.question != asked) r,
    ];
    _toEnd();
    final r = await ref
        .read(askAtomRepositoryProvider)
        .ask(q, lang: _lang, history: history, error: error);
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (r) {
        case ApiOk(:final value):
          _lines.add(_Atom(value));
        case ApiErr(:final failure):
          _error = sayFailure(l, failure);
      }
    });
    _toEnd();
  }

  /// One request at a time: ask, confirm and hand-over answer into the
  /// same thread and share [_busy].
  Future<void> _confirm(String token) async {
    if (_busy || _settled.contains(token)) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
      _settled.add(token);
    });
    final r = await ref
        .read(askAtomRepositoryProvider)
        .confirm(token, lang: _lang);
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (r) {
        case ApiOk(:final value):
          _lines.add(_Atom(value));
        case ApiErr(:final failure):
          _settled.remove(token);
          _error = sayFailure(l, failure);
      }
    });
    _toEnd();
  }

  Future<void> _handover({AtomAnswer? notice}) async {
    final l = AppLocalizations.of(context);
    final last = notice != null
        ? (notice.notice ?? notice.problem ?? notice.text)
        : _lines.whereType<_Mine>().lastOrNull?.text;
    // Nothing asked yet: Atomshop's support requests.
    if (last == null) {
      context.push(V2Routes.support);
      return;
    }
    if (_busy) return;
    if (_handed.contains(last)) return _toEnd();
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await ref
        .read(askAtomRepositoryProvider)
        .handover(
          last,
          lang: _lang,
          keys: notice != null
              ? [?notice.key]
              : [for (final a in _lines.whereType<_Atom>()) ?a.answer.key],
          history: _history,
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (r) {
        case ApiOk(:final value):
          _handed.add(last);
          _lines.add(_Sent(value.code, value.whatsapp));
        case ApiErr(:final failure):
          _error = sayFailure(l, failure);
      }
    });
    _toEnd();
  }

  Future<void> _rate(AtomAnswer a, bool helpful) async {
    if (a.id == null) return;
    setState(() => _rated.add(a.id!));
    await ref.read(askAtomRepositoryProvider).feedback(a.id!, helpful);
  }

  String _hello() {
    final name = ref.read(sessionProvider.notifier).current?.firstName ?? '';
    final l = AppLocalizations.of(context);
    final hour = AtomDates.now().hour;
    final part = hour < 12
        ? l.askAtomMorning
        : hour < 17
        ? l.askAtomAfternoon
        : l.askAtomEvening;
    return name.isEmpty ? l.askAtomHello(part) : l.askAtomHelloName(part, name);
  }

  String _when(DateTime? at) {
    if (at == null) return '';
    final days = AtomDates.daysFrom(at, today: AtomDates.now());
    if (days == 0) return AtomDates.time(at);
    if (days == -1) return AppLocalizations.of(context).dateYesterday;
    return AtomDates.short(at);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final online = ref.watch(onlineProvider).value ?? true;
    final ctx = _context;
    final who = ref.watch(
      sessionProvider.select((s) => s is SignedIn ? s.session.who : null),
    );
    // The server's questions, in the answer language; the brand's own
    // until they come (or when it sends none).
    final questions = (ctx?.questions.isNotEmpty ?? false)
        ? ctx!.questions
        : [
            for (final q in brandQuestionsFor(
              AppLocalizations.of(context),
              who,
              ref.watch(accessProvider),
            ))
              (q, q),
          ];
    final lastAtom = _lines.lastIndexWhere((x) => x is _Atom);
    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(online: online, onHandover: _busy ? null : _handover),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                if (_lines.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 12),
                    child: Semantics(
                      header: true,
                      child: Text(
                        _hello(),
                        style: AtomText.pageTitle.copyWith(letterSpacing: -.2),
                      ),
                    ),
                  ),
                  if (ctx?.notices.isNotEmpty ?? false) ...[
                    AtomSectionLabel(l.askAtomNoticed, page: false),
                    for (final n in ctx!.notices) ...[
                      _NoticeCard(
                        answer: n,
                        onHandover: () => _handover(notice: n),
                        onAsk: online && n.ask != null
                            ? () => _ask(n.ask!)
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                  if (questions.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    AtomSectionLabel(l.askAtomAsk, page: false),
                    Wrap(
                      spacing: 6,
                      runSpacing: 0,
                      children: [
                        for (final (shown, sent) in questions)
                          _QuestionChip(
                            label: shown,
                            onTap: online
                                ? () => _ask(sent, shown: shown)
                                : null,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_recent.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    AtomSectionLabel(l.askAtomRecent, page: false),
                    _RecentCard(
                      recent: _recent.take(3).toList(),
                      when: _when,
                      onTap: online ? _ask : null,
                    ),
                  ],
                ],
                for (final (i, line) in _lines.indexed) ...[
                  switch (line) {
                    _Mine(:final text) => _MineBubble(text: text),
                    _Atom(:final answer) => _AtomBubble(
                      answer: answer,
                      settled:
                          answer.confirmToken != null &&
                          _settled.contains(answer.confirmToken),
                      onConfirm: _confirm,
                      onDismiss: (t) => setState(() => _settled.add(t)),
                      onAsk: (q) => _ask(q),
                      onHandover: _handover,
                      rated: answer.id != null && _rated.contains(answer.id),
                      onRate: (h) => _rate(answer, h),
                      showLanguageNote: i == lastAtom,
                    ),
                    _Sent(:final code, :final whatsapp) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AtomNote(
                          kind: AtomNoteKind.success,
                          message: l.askAtomSentTo(code),
                        ),
                        if (whatsapp != null) ...[
                          const SizedBox(height: 8),
                          AtomButton(
                            label: l.askAtomWhatsAppUrgent,
                            kind: AtomButtonKind.whatsapp,
                            small: true,
                            onPressed: () => launchUrl(
                              Uri.parse(whatsapp),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                        ],
                      ],
                    ),
                  },
                  const SizedBox(height: 12),
                ],
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(child: AtomSpinner()),
                  ),
                if (_error != null)
                  AtomNote(kind: AtomNoteKind.problem, message: _error!),
              ],
            ),
          ),
          _InputBar(
            controller: _input,
            online: online,
            busy: _busy,
            onSend: _ask,
            listening: _listening,
            onMic: _mic,
          ),
        ],
      ),
    );
  }
}

/// `.ahead`: ‹, Atom's avatar, its name and status, Talk to Atomshop, and
/// the stripe.
class _Header extends StatelessWidget {
  const _Header({required this.online, required this.onHandover});
  final bool online;
  final VoidCallback? onHandover;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final status = Text(
      online ? l.askAtomStatus : l.askAtomStatusOffline,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.fade,
      style: AtomText.small.copyWith(color: AtomColors.navMuted),
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: AtomColors.nav,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    AtomIconButton(
                      icon: LucideIcons.chevronLeft,
                      label: l.commonBack,
                      color: Colors.white,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 2),
                    const AtomAiMark(size: AtomSize.atomAvatar),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              l.askAtomName,
                              style: AtomText.input.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          status,
                        ],
                      ),
                    ),
                    AtomIconButton(
                      icon: LucideIcons.headphones,
                      label: l.helpTalk,
                      color: Colors.white,
                      onTap: onHandover,
                    ),
                  ],
                ),
              ),
            ),
            const AtomStepsStripe(width: double.infinity),
          ],
        ),
      ),
    );
  }
}

/// `.nc`: something Atom noticed, with what to do about it.
class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.answer,
    required this.onHandover,
    required this.onAsk,
  });

  final AtomAnswer answer;
  final VoidCallback onHandover;

  /// "Show them": asks the notice's question in the chat; null offline.
  final VoidCallback? onAsk;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = answer;
    final tone = a.kind == 'problem' ? AtomTone.rose : AtomTone.amber;
    final quote = a.key == 'insight_quote_ending';
    // An insight comes as one text, "**2 orders waiting** · …\n…": its
    // first line is the title, the rest the line under it.
    final text = a.text ?? '';
    final cut = a.problem == null ? text.indexOf('\n') : -1;
    final title =
        a.notice ??
        a.problem ??
        (cut > 0 ? text.substring(0, cut) : text).replaceAll('**', '');
    final body = a.problem != null
        ? (a.reason ?? a.text)
        : cut > 0
        ? text.substring(cut + 1).trim()
        : a.reason;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AtomDecor.card,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tone.bg,
              borderRadius: AtomRadius.brControl,
            ),
            child: Icon(
              a.kind == 'problem'
                  ? LucideIcons.triangleAlert
                  : quote
                  ? LucideIcons.funnel
                  : LucideIcons.clock,
              size: 16,
              color: tone.fg,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                atomText(
                  title,
                  style: AtomText.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AtomColors.ink,
                    height: 1.3,
                  ),
                ),
                if (body != null && body.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  atomText(body, style: AtomText.secondary),
                ],
                if (a.ask != null || a.actions.isNotEmpty || a.handover) ...[
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (a.ask != null)
                        AtomButton.small(
                          label: a.askLabel ?? l.askAtomShowThem,
                          kind: AtomButtonKind.primary,
                          onPressed: onAsk,
                        ),
                      for (final (name, url) in a.actions)
                        AtomButton.small(
                          label: name,
                          onPressed: () => quote && a.bulkRequestId != null
                              ? _openRowAction(
                                  context,
                                  AtomRowAction(
                                    label: name,
                                    bulkRequestId: a.bulkRequestId,
                                    fromSeller: a.fromSeller,
                                  ),
                                )
                              : _openLink(context, url),
                        ),
                      if (a.handover)
                        AtomButton.small(
                          label: l.askAtomAskAtomshop,
                          onPressed: onHandover,
                        ),
                    ],
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

/// `.qs button`: a question to tap.
class _QuestionChip extends StatelessWidget {
  const _QuestionChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AtomPressable(
    onTap: onTap,
    semanticLabel: label,
    builder: (context, pressed) => Container(
      constraints: const BoxConstraints(minHeight: 34),
      margin: const EdgeInsets.symmetric(vertical: 7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: pressed ? AtomColors.primaryLine : AtomColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AtomColors.primaryLine),
      ),
      child: Text(
        label,
        style: AtomText.smallButton.copyWith(color: AtomColors.noteBlueText),
      ),
    ),
  );
}

/// `.rec`: the last questions asked on this phone.
class _RecentCard extends StatelessWidget {
  const _RecentCard({
    required this.recent,
    required this.when,
    required this.onTap,
  });

  final List<AtomRecent> recent;
  final String Function(DateTime? at) when;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: AtomDecor.card,
    foregroundDecoration: AtomDecor.cardOutline,
    child: Column(
      children: [
        for (final (i, r) in recent.indexed) ...[
          if (i > 0) const Divider(height: 1, color: AtomColors.line),
          AtomPressable(
            onTap: onTap == null ? null : () => onTap!(r.question),
            scaleOnPress: false,
            focusRadius: BorderRadius.zero,
            semanticLabel: '${r.question}, ${when(r.at)}',
            builder: (context, pressed) => Container(
              color: pressed ? AtomColors.head : AtomColors.paper,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.history,
                    size: 16,
                    color: AtomColors.chevron,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r.question,
                      style: AtomText.body.copyWith(color: AtomColors.text),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    when(r.at),
                    style: AtomText.small.copyWith(color: AtomColors.faint),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

/// `.me`: the person's question, on the right.
class _MineBubble extends StatelessWidget {
  const _MineBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * .8,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          color: AtomColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AtomRadius.card),
            topRight: Radius.circular(AtomRadius.card),
            bottomLeft: Radius.circular(AtomRadius.card),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(text, style: AtomText.body.copyWith(color: Colors.white)),
      ),
    ),
  );
}

/// `.bot`: Atom's avatar and its answer in a bubble, laid out by kind.
class _AtomBubble extends StatelessWidget {
  const _AtomBubble({
    required this.answer,
    required this.settled,
    required this.onConfirm,
    required this.onDismiss,
    required this.onAsk,
    required this.onHandover,
    required this.rated,
    required this.onRate,
    required this.showLanguageNote,
  });

  final AtomAnswer answer;

  /// Its change was confirmed or put off.
  final bool settled;
  final ValueChanged<String> onConfirm;
  final ValueChanged<String> onDismiss;
  final ValueChanged<String> onAsk;
  final VoidCallback onHandover;
  final bool rated;
  final ValueChanged<bool> onRate;
  final bool showLanguageNote;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = answer;
    final text = AtomText.body.copyWith(color: AtomColors.text, height: 1.5);
    Widget label(String t) => Text(t.toUpperCase(), style: AtomText.section);
    final parts = <Widget>[
      if (a.problem != null)
        atomText(
          a.problem!,
          style: text.copyWith(
            color: AtomColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      if (a.reason != null) ...[
        label(l.stockWhy),
        atomText(a.reason!, style: text),
      ],
      if (a.text != null && a.confirmToken == null)
        atomText(a.text!, style: text),
      if (a.rows.isNotEmpty) _MiniTable(rows: a.rows, actions: a.rowActions),
      if (a.steps.isNotEmpty) ...[
        if (a.kind == 'problem') label(l.askAtomHowFix),
        for (final (i, s) in a.steps.indexed)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 20, child: Text('${i + 1}.', style: text)),
              Expanded(child: atomText(s, style: text)),
            ],
          ),
      ],
      if (a.confirmToken != null)
        _ConfirmBox(
          text: a.text,
          label: a.confirmLabel ?? l.askAtomConfirm,
          settled: settled,
          onConfirm: () => onConfirm(a.confirmToken!),
          onDismiss: () => onDismiss(a.confirmToken!),
        ),
      if (a.actions.isNotEmpty || a.handover)
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (name, url) in a.actions)
              AtomButton.small(
                label: name,
                onPressed: () => _openLink(context, url),
              ),
            if (a.handover)
              AtomButton.small(
                label: l.askAtomAskAtomshop,
                onPressed: onHandover,
              ),
          ],
        ),
      if (a.related.isNotEmpty)
        Wrap(
          spacing: 6,
          runSpacing: 0,
          children: [
            for (final r in a.related)
              _QuestionChip(label: r, onTap: () => onAsk(r)),
          ],
        ),
      if (a.id != null)
        Row(
          children: [
            Text(
              rated ? l.askAtomThanks : l.askAtomHelpfulQ,
              style: AtomText.small.copyWith(color: AtomColors.faint),
            ),
            if (!rated) ...[
              const SizedBox(width: 4),
              _RateButton(
                icon: LucideIcons.thumbsUp,
                label: l.askAtomHelpful,
                onTap: () => onRate(true),
              ),
              _RateButton(
                icon: LucideIcons.thumbsDown,
                label: l.askAtomNotHelpful,
                onTap: () => onRate(false),
              ),
            ],
          ],
        ),
      if (showLanguageNote)
        Text(
          l.askAtomLanguageNote,
          style: AtomText.small.copyWith(color: AtomColors.faint),
        ),
    ];
    return FractionallySizedBox(
      widthFactor: .92,
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const AtomAiMark(size: AtomSize.atomAvatarSmall),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AtomColors.paper,
                border: Border.all(color: AtomColors.line),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AtomRadius.card),
                  topRight: Radius.circular(AtomRadius.card),
                  bottomRight: Radius.circular(AtomRadius.card),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (i, p) in parts.indexed) ...[
                    if (i > 0) const SizedBox(height: 8),
                    p,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.mt`: the rows of an answer (a name and its figure).
class _MiniTable extends StatelessWidget {
  const _MiniTable({required this.rows, this.actions = const []});
  final List<(String, String)> rows;

  /// Each row's own button (Confirm on an order), or null.
  final List<AtomRowAction?> actions;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: AtomRadius.brControl,
      border: Border.all(color: AtomColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, (name, value)) in rows.indexed) ...[
          if (i > 0) const Divider(height: 1, color: AtomColors.line),
          if (i < actions.length && actions[i] != null)
            _ActionRow(name: name, value: value, action: actions[i]!)
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: value.length > 18
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AtomText.secondary.copyWith(
                            color: AtomColors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(value, style: AtomText.small),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: AtomText.secondary.copyWith(
                              color: AtomColors.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          value,
                          textAlign: TextAlign.end,
                          style: AtomText.secondary.copyWith(
                            color: AtomColors.ink,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
            ),
        ],
      ],
    ),
  );
}

/// `.mt div` with its own button: the row, its amount and a small primary
/// button (Confirm opens the order to confirm it). Narrow screens or large
/// text put the amount and button under the name.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.name,
    required this.value,
    required this.action,
  });

  final String name;
  final String value;
  final AtomRowAction action;

  @override
  Widget build(BuildContext context) {
    final nameText = Text(
      name,
      style: AtomText.secondary.copyWith(color: AtomColors.text),
    );
    final amount = Text(
      value,
      style: AtomText.secondary.copyWith(
        color: AtomColors.ink,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    // `.mini.pri` at the board's `height: 28px; padding: 0 8px`, so the
    // row's name keeps its room.
    final button = AtomPressable(
      onTap: () => _openRowAction(context, action),
      semanticLabel: '${action.label}, $name',
      builder: (context, pressed) => Container(
        constraints: const BoxConstraints(minHeight: 28),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: pressed ? AtomColors.primaryPressed : AtomColors.primary,
          borderRadius: AtomRadius.brControl,
        ),
        child: Text(
          action.label,
          style: AtomText.smallButton.copyWith(color: Colors.white),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: LayoutBuilder(
        builder: (context, box) {
          final roomy =
              box.maxWidth >= 260 &&
              MediaQuery.textScalerOf(context).scale(1) <= 1.3;
          if (roomy) {
            return Row(
              children: [
                Expanded(child: nameText),
                const SizedBox(width: 8),
                amount,
                const SizedBox(width: 8),
                button,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              nameText,
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [amount, button],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// `.confirm`: a change Atom will make only after Confirm.
class _ConfirmBox extends StatelessWidget {
  const _ConfirmBox({
    required this.text,
    required this.label,
    required this.settled,
    required this.onConfirm,
    required this.onDismiss,
  });

  final String? text;
  final String label;
  final bool settled;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final style = AtomText.secondary.copyWith(
      color: AtomColors.confirmText,
      height: 1.45,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AtomColors.amberSoft,
        borderRadius: AtomRadius.brControl,
        border: Border.all(color: AtomColors.amberLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (text != null) atomText(text!, style: style),
          if (!settled) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                AtomButton.small(
                  label: label,
                  kind: AtomButtonKind.primary,
                  onPressed: onConfirm,
                ),
                AtomButton.small(label: l.notifNotNow, onPressed: onDismiss),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// `.fb button`: 👍 or 👎, 28 square.
class _RateButton extends StatelessWidget {
  const _RateButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AtomPressable(
    onTap: onTap,
    semanticLabel: label,
    // 32 x 36 around the 28 square: `.fb`'s 4px gap between the two.
    builder: (context, pressed) => SizedBox(
      width: 32,
      height: 36,
      child: Center(
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: pressed ? AtomColors.surface : AtomColors.paper,
            borderRadius: AtomRadius.brControl,
            border: Border.all(color: AtomColors.line),
          ),
          child: Icon(icon, size: 14, color: AtomColors.muted),
        ),
      ),
    ),
  );
}

/// `.inbar`: the round input and Send. Atom needs internet.
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.online,
    required this.busy,
    required this.onSend,
    required this.listening,
    required this.onMic,
  });

  final TextEditingController controller;
  final bool online;
  final bool busy;
  final ValueChanged<String> onSend;
  final bool listening;
  final VoidCallback onMic;

  static const _round = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(24)),
    borderSide: BorderSide(color: AtomColors.line2),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final can = online && !busy;
    return Container(
      decoration: const BoxDecoration(
        color: AtomColors.paper,
        border: Border(top: BorderSide(color: AtomColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AtomSize.atomInput),
              child: TextField(
                controller: controller,
                enabled: online,
                minLines: 1,
                maxLines: 4,
                maxLength: 600,
                buildCounter: (
                  _, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => null,
                textInputAction: TextInputAction.send,
                onSubmitted: can ? onSend : null,
                style: AtomText.input,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: !online
                      ? l.askAtomHintOffline
                      : listening
                      ? l.askAtomListening
                      : l.askAtomHint,
                  hintStyle: AtomText.input.copyWith(
                    color: AtomColors.placeholder,
                  ),
                  filled: true,
                  fillColor: online ? AtomColors.paper : AtomColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  border: _round,
                  enabledBorder: _round,
                  disabledBorder: _round,
                  focusedBorder: _round.copyWith(
                    borderSide: const BorderSide(color: AtomColors.primary),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AtomPressable(
            onTap: online ? onMic : null,
            semanticLabel: listening ? l.askAtomMicStop : l.askAtomMic,
            builder: (context, pressed) => Container(
              width: AtomSize.atomInput,
              height: AtomSize.atomInput,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: !online
                    ? AtomColors.disabledFill
                    : listening
                    ? AtomColors.primarySoft
                    : pressed
                    ? AtomColors.line
                    : AtomColors.surface,
                border: listening
                    ? Border.all(color: AtomColors.primary, width: 1.5)
                    : null,
              ),
              child: Icon(
                listening ? LucideIcons.square : LucideIcons.mic,
                size: 20,
                color: !online
                    ? AtomColors.disabledText
                    : listening
                    ? AtomColors.primary
                    : AtomColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AtomPressable(
            onTap: can ? () => onSend(controller.text) : null,
            semanticLabel: l.askAtomSend,
            builder: (context, pressed) => Container(
              width: AtomSize.atomInput,
              height: AtomSize.atomInput,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: !can
                    ? AtomColors.disabledFill
                    : pressed
                    ? AtomColors.primaryPressed
                    : AtomColors.primary,
              ),
              child: Icon(
                LucideIcons.arrowRight,
                size: 20,
                color: can ? Colors.white : AtomColors.disabledText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
