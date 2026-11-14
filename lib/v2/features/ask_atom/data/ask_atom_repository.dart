import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../../../core/app_providers.dart';

/// One of Atom's answers (`POST ask-atom`, docs/BRAND_APP.md "Portal v2:
/// Ask Atom"): `{kind, key, problem, reason, text, steps[], rows[[label,
/// value]], actions[[label, url]], confirm: {token, label}|null, handover,
/// related[], source, lang, id}`.
@immutable
class AtomAnswer {
  const AtomAnswer({
    required this.kind,
    this.key,
    this.problem,
    this.reason,
    this.text,
    this.steps = const [],
    this.rows = const [],
    this.actions = const [],
    this.related = const [],
    this.confirmToken,
    this.confirmLabel,
    this.handover = false,
    this.id,
    this.notice,
    this.langLabel,
  });

  /// problem, info, numbers, confirm or ask.
  final String kind;
  final String? key;
  final String? problem;
  final String? reason;
  final String? text;
  final List<String> steps;
  final List<(String, String)> rows;

  /// Portal links: label → url. The app opens its own screen for the ones
  /// it has (`appRouteForPortalUrl`).
  final List<(String, String)> actions;
  final List<String> related;

  /// A change Atom makes only after Confirm (`POST ask-atom/confirm`).
  final String? confirmToken;
  final String? confirmLabel;

  /// Atom can't settle it: offer the hand-over to Atomshop support.
  final bool handover;

  /// For 👍/👎 (`POST ask-atom/feedback`); null when the answer wasn't
  /// logged.
  final int? id;

  /// On a notice card (`ask-atom/context` → `notices`): its title.
  final String? notice;
  final String? langLabel;

  static List<(String, String)> _pairs(Object? v) => [
    for (final p in Json.list(v))
      if (Json.list(p).length >= 2)
        (Json.str(Json.list(p)[0]) ?? '', Json.str(Json.list(p)[1]) ?? ''),
  ];

  factory AtomAnswer.fromJson(Object? raw) {
    final j = Json.map(raw);
    final confirm = Json.map(j['confirm']);
    return AtomAnswer(
      kind: Json.str(j['kind']) ?? 'info',
      key: Json.str(j['key']),
      problem: Json.str(j['problem']),
      reason: Json.str(j['reason']),
      text: Json.str(j['text']),
      steps: [for (final s in Json.list(j['steps'])) ?Json.str(s)],
      rows: _pairs(j['rows']),
      actions: _pairs(j['actions']),
      related: [for (final r in Json.list(j['related'])) ?Json.str(r)],
      confirmToken: Json.str(confirm['token']),
      confirmLabel: Json.str(confirm['label']),
      handover: Json.flag(j['handover']),
      id: Json.integer(j['id']),
      notice: Json.str(j['notice']),
      langLabel: Json.str(Json.map(j['lang'])['label']),
    );
  }
}

/// What Atom noticed and the questions that fit (`GET ask-atom/context`):
/// `{notices[], questions[] (shown), prompts[] (sent), lang}`.
@immutable
class AtomContext {
  const AtomContext({this.notices = const [], this.questions = const []});

  final List<AtomAnswer> notices;

  /// (shown, sent): the chip in the answer language, and the prompt sent
  /// when it is tapped.
  final List<(String, String)> questions;

  factory AtomContext.fromJson(Object? data) {
    final d = Json.map(data);
    final shown = [
      for (final q in Json.list(d['questions'])) Json.str(q) ?? '',
    ];
    final prompts = [
      for (final q in Json.list(d['prompts'])) Json.str(q) ?? '',
    ];
    return AtomContext(
      notices: [
        for (final n in Json.list(d['notices'])) AtomAnswer.fromJson(n),
      ],
      questions: [
        for (var i = 0; i < shown.length; i++)
          if (shown[i].isNotEmpty)
            (
              shown[i],
              i < prompts.length && prompts[i].isNotEmpty
                  ? prompts[i]
                  : shown[i],
            ),
      ],
    );
  }
}

/// A support request made by the hand-over: its code and a WhatsApp link
/// with the message written.
typedef AtomHandover = ({String code, String? whatsapp});

/// A turn of the chat, for `history`.
typedef AtomTurn = ({bool mine, String text});

/// The portal screen the app's Ask Atom stands for: the brand dashboard,
/// so the context answers with brand-wide notices and questions.
const atomScreen = 'brand.dashboard';

abstract interface class AskAtomRepository {
  Future<ApiResult<AtomContext>> context({required String lang});

  Future<ApiResult<AtomAnswer>> ask(
    String question, {
    required String lang,
    List<AtomTurn> history = const [],
    String? error,
  });

  Future<ApiResult<AtomAnswer>> confirm(String token, {required String lang});

  Future<ApiResult<void>> feedback(int id, bool helpful);

  Future<ApiResult<AtomHandover>> handover(
    String question, {
    required String lang,
    List<String> keys = const [],
    List<AtomTurn> history = const [],
  });
}

class ApiAskAtomRepository implements AskAtomRepository {
  const ApiAskAtomRepository(this._api);
  final ApiClient _api;

  /// The server keeps at most 12 turns.
  static List<Map<String, String>> history(List<AtomTurn> turns) => [
    for (final t
        in turns.length > 12 ? turns.sublist(turns.length - 12) : turns)
      {'role': t.mine ? 'user' : 'bot', 'text': t.text},
  ];

  @override
  Future<ApiResult<AtomContext>> context({required String lang}) => _api.get(
    'ask-atom/context',
    query: {'lang': lang, 'screen': atomScreen},
    parse: AtomContext.fromJson,
  );

  @override
  Future<ApiResult<AtomAnswer>> ask(
    String question, {
    required String lang,
    List<AtomTurn> history = const [],
    String? error,
  }) => _api.post(
    'ask-atom',
    body: {
      // The server takes at most 600 characters.
      'question': question.length > 600 ? question.substring(0, 600) : question,
      'lang': lang,
      'screen': atomScreen,
      'history': ApiAskAtomRepository.history(history),
      'error': ?error,
    },
    parse: AtomAnswer.fromJson,
  );

  @override
  Future<ApiResult<AtomAnswer>> confirm(String token, {required String lang}) =>
      _api.post(
        'ask-atom/confirm',
        body: {'token': token, 'lang': lang, 'screen': atomScreen},
        parse: AtomAnswer.fromJson,
      );

  @override
  Future<ApiResult<void>> feedback(int id, bool helpful) => _api.post(
    'ask-atom/feedback',
    body: {'id': id, 'helpful': helpful},
    parse: (_) {},
  );

  @override
  Future<ApiResult<AtomHandover>> handover(
    String question, {
    required String lang,
    List<String> keys = const [],
    List<AtomTurn> history = const [],
  }) => _api.post(
    'ask-atom/handover',
    body: {
      'question': question.length > 1000
          ? question.substring(0, 1000)
          : question,
      'lang': lang,
      'screen': atomScreen,
      'keys': keys.take(10).toList(),
      'history': ApiAskAtomRepository.history(history),
    },
    parse: (data) {
      final d = Json.map(data);
      return (
        code: Json.str(d['code']) ?? '',
        whatsapp: Json.str(d['whatsapp']),
      );
    },
  );
}

final askAtomRepositoryProvider = Provider<AskAtomRepository>(
  (ref) => ApiAskAtomRepository(ref.read(apiClientProvider)),
);
