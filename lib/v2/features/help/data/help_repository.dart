import 'dart:convert';

import 'package:atombrand_app/v2/core/services/local_storage_methods.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../../../core/app_providers.dart';
import '../../../core/format/dates.dart';
import '../../../core/session/session_controller.dart';

/// Atomshop's own contacts (18.1).
abstract final class AtomshopContacts {
  static const whatsapp = '+92 333 1214955';
  static const phone = '+92 330 2277522';
  static const email = 'atomshoppk@gmail.com';
  static final privacy = Uri.parse('https://atomshop.pk/app-privacy-policy');
  static const terms = 'https://atomshop.pk/terms-and-conditions';
}

/// One message in a support conversation: Atomshop's or this person's.
@immutable
class SupportMessage {
  const SupportMessage({
    required this.fromAtomshop,
    required this.text,
    this.name,
    this.at,
  });

  final bool fromAtomshop;
  final String text;
  final String? name;
  final DateTime? at;

  factory SupportMessage.fromJson(Object? raw) {
    final j = Json.map(raw);
    return SupportMessage(
      fromAtomshop: Json.str(j['by']) == 'atomshop',
      text: Json.str(j['text']) ?? '',
      name: Json.str(j['name']),
      at: AtomDates.parse(j['at']),
    );
  }
}

/// A question this person sent to Atomshop (`GET support`),
/// from Ask Atom's handover, with the conversation since.
@immutable
class SupportRequest {
  const SupportRequest({
    required this.code,
    required this.subject,
    required this.question,
    required this.status,
    this.uuid = '',
    this.reply,
    this.repliedAt,
    this.createdAt,
    this.thread = const [],
    this.canReply = false,
    this.canClose = false,
    this.about,
  });

  final String uuid;
  final String code;
  final String subject;
  final String question;

  /// `open` (waiting for Atomshop), `answered` or `closed`.
  final String status;
  final String? reply;
  final DateTime? repliedAt;
  final DateTime? createdAt;

  /// Atomshop's answers and this person's replies after the question.
  final List<SupportMessage> thread;
  final bool canReply;
  final bool canClose;

  /// The record Ask Atom handed it over with ("ORDER-4815 (Processing)").
  final String? about;

  bool get closed => status == 'closed';

  /// Atomshop has the last word.
  bool get answered =>
      !closed && (thread.isNotEmpty ? thread.last.fromAtomshop : reply != null);

  /// The last message: Atomshop's or this person's.
  SupportMessage get last => thread.isNotEmpty
      ? thread.last
      : SupportMessage(fromAtomshop: false, text: question, at: createdAt);

  factory SupportRequest.fromJson(Object? raw) {
    final j = Json.map(raw);
    return SupportRequest(
      uuid: Json.str(j['uuid']) ?? '',
      code: Json.str(j['code']) ?? '',
      subject: Json.str(j['subject']) ?? '',
      question: Json.str(j['question']) ?? '',
      status: Json.str(j['status']) ?? 'open',
      reply: Json.str(j['reply']),
      repliedAt: AtomDates.parse(j['replied_at']),
      createdAt: AtomDates.parse(j['created_at']),
      thread: [
        for (final t in Json.list(j['thread'])) SupportMessage.fromJson(t),
      ],
      canReply: Json.flag(j['can_reply']),
      canClose: Json.flag(j['can_close']),
      about: Json.str(j['about']),
    );
  }
}

/// One help answer (`GET help/faqs`): Ask Atom's brand answers, in the
/// app's wording. [answer] keeps the server's `**bold**` and numbered steps.
@immutable
class HelpFaq {
  const HelpFaq({
    required this.id,
    required this.question,
    required this.category,
    required this.answer,
    this.links = const [],
  });

  final int id;
  final String question;

  /// The answer's pages, [label, url] (dashboard links).
  final List<(String, String)> links;

  /// `collections`, `orders`, `getting-started`…
  final String category;
  final String answer;

  factory HelpFaq.fromJson(Object? raw) {
    final j = Json.map(raw);
    return HelpFaq(
      id: Json.integer(j['id']) ?? 0,
      question: Json.str(j['question']) ?? '',
      category: Json.str(j['category']) ?? 'general',
      answer: Json.str(j['answer']) ?? '',
      links: [
        for (final l in Json.list(j['links']))
          if (l is List && l.length >= 2) ('${l[0]}', '${l[1]}'),
      ],
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'question': question,
    'category': category,
    'answer': answer,
    'links': [
      for (final (label, url) in links) [label, url],
    ],
  };
}

/// A block of a legal page: a paragraph or a list.
typedef LegalBlock = ({String? text, List<String> items});

/// A legal page as sections (privacy policy 18.4, terms 18.5).
@immutable
class LegalDoc {
  const LegalDoc({
    required this.sections,
    this.title,
    this.url,
    this.updatedAt,
    this.version,
    this.acceptedBy,
    this.acceptedAt,
    this.acceptedVersion,
  });

  final String? title;
  final String? url;
  final DateTime? updatedAt;
  final List<({String title, List<LegalBlock> blocks})> sections;

  /// Terms only: the current version, and who accepted it when.
  final String? version;
  final String? acceptedBy;
  final DateTime? acceptedAt;
  final String? acceptedVersion;

  factory LegalDoc.fromJson(Object? raw) {
    final d = Json.map(raw);
    final accepted = Json.map(d['accepted']);
    return LegalDoc(
      title: Json.str(d['title']),
      url: Json.str(d['url']),
      updatedAt: AtomDates.parse(d['updated_at'] ?? d['published_at']),
      version: Json.str(d['version']),
      acceptedBy: Json.str(accepted['by']),
      acceptedAt: AtomDates.parse(accepted['at']),
      acceptedVersion: Json.str(accepted['version']),
      sections: [
        for (final raw in Json.list(d['sections']))
          (
            title: Json.str(Json.map(raw)['title']) ?? '',
            blocks: [
              for (final b in Json.list(Json.map(raw)['blocks']))
                if (Json.str(Json.map(b)['type']) == 'ul')
                  (
                    text: null,
                    items: [
                      for (final i in Json.list(Json.map(b)['items']))
                        ?Json.str(i),
                    ],
                  )
                else
                  (text: Json.str(Json.map(b)['text']) ?? '', items: const []),
            ],
          ),
      ],
    );
  }
}

abstract interface class HelpRepository {
  /// `GET support`: newest first.
  Future<ApiResult<List<SupportRequest>>> support();

  /// `POST support/{uuid}/reply`: writes back to Atomshop; the request
  /// opens again.
  Future<ApiResult<SupportRequest>> reply(String uuid, String message);

  /// `POST support/{uuid}/close`: the question is sorted.
  Future<ApiResult<SupportRequest>> close(String uuid);

  /// `GET help/faqs`, or those matching [query] (English or Roman Urdu).
  /// The full list is kept on the phone, so Help opens offline.
  Future<ApiResult<List<HelpFaq>>> faqs({String? query});

  /// `POST help/faqs/{id}/feedback`: "Did this help?".
  Future<ApiResult<void>> faqFeedback(int id, {required bool helpful});

  /// `GET legal/privacy`: the website's privacy policy.
  Future<ApiResult<LegalDoc>> privacy();

  /// `GET terms`: the partner terms Atomshop published.
  Future<ApiResult<LegalDoc>> terms();
}

class ApiHelpRepository implements HelpRepository {
  const ApiHelpRepository(this._api);
  final ApiClient _api;

  static const _faqsKey = 'v2_help_faqs';

  @override
  Future<ApiResult<List<SupportRequest>>> support() => _api.get(
    'support',
    parse: (data) => [
      for (final r in Json.list(Json.map(data)['requests']))
        SupportRequest.fromJson(r),
    ],
  );

  @override
  Future<ApiResult<SupportRequest>> reply(String uuid, String message) =>
      _api.post(
        'support/$uuid/reply',
        body: {'message': message},
        parse: SupportRequest.fromJson,
      );

  @override
  Future<ApiResult<SupportRequest>> close(String uuid) =>
      _api.post('support/$uuid/close', parse: SupportRequest.fromJson);

  @override
  Future<ApiResult<List<HelpFaq>>> faqs({String? query}) async {
    final q = query?.trim() ?? '';
    final r = await _api.get(
      'help/faqs',
      query: {'q': ?(q.isEmpty ? null : q)},
      parse: (data) => [
        for (final f in Json.list(Json.map(data)['faqs'])) HelpFaq.fromJson(f),
      ],
    );
    // The brand FAQs call is being added on the server: until then, no
    // answers rather than an error (Help still offers WhatsApp).
    if (r case ApiErr(:final failure)
        when failure.kind == ApiFailureKind.notFound) {
      return const ApiOk(<HelpFaq>[]);
    }
    if (q.isNotEmpty) return r;
    switch (r) {
      case ApiOk(:final value):
        await LocalStorageMethods.instance.writeData(
          _faqsKey,
          jsonEncode([for (final f in value) f.toJson()]),
        );
        return r;
      case ApiErr():
        final saved = await LocalStorageMethods.instance.readData(_faqsKey);
        if (saved == null) return r;
        try {
          return ApiOk([
            for (final f in jsonDecode(saved) as List) HelpFaq.fromJson(f),
          ]);
        } on FormatException {
          return r;
        }
    }
  }

  @override
  Future<ApiResult<void>> faqFeedback(int id, {required bool helpful}) =>
      _api.post(
        'help/faqs/$id/feedback',
        body: {'helpful': helpful},
        parse: (_) {},
      );

  /// Kept on the phone too, so it opens offline (18.4).
  @override
  Future<ApiResult<LegalDoc>> privacy() async {
    const key = 'v2_help_privacy';
    final r = await _api.get<Object?>('legal/privacy', parse: (data) => data);
    switch (r) {
      case ApiOk(:final value):
        await LocalStorageMethods.instance.writeData(key, jsonEncode(value));
        return ApiOk(LegalDoc.fromJson(value));
      case ApiErr(:final failure):
        final saved = await LocalStorageMethods.instance.readData(key);
        if (saved == null && failure.kind == ApiFailureKind.notFound) {
          return ApiOk(
            onTheSite('Privacy policy', AtomshopContacts.privacy.toString()),
          );
        }
        if (saved == null) return ApiErr(failure);
        try {
          return ApiOk(LegalDoc.fromJson(jsonDecode(saved)));
        } on FormatException {
          return ApiErr(failure);
        }
    }
  }

  @override
  Future<ApiResult<LegalDoc>> terms() async {
    final r = await _api.get('terms', parse: LegalDoc.fromJson);
    if (r case ApiErr(:final failure)
        when failure.kind == ApiFailureKind.notFound) {
      return ApiOk(onTheSite('Terms & conditions', AtomshopContacts.terms));
    }
    return r;
  }
}

/// A document the server doesn't serve to the app yet: one line pointing
/// to its page on atomshop.pk.
LegalDoc onTheSite(String title, String url) => LegalDoc(
  title: title,
  url: url,
  sections: [
    (
      title: title,
      blocks: [
        (
          text:
              'The full text is on atomshop.pk. Tap Open on the site to read '
              'it.',
          items: const <String>[],
        ),
      ],
    ),
  ],
);

final helpRepositoryProvider = Provider<HelpRepository>(
  (ref) => ApiHelpRepository(ref.read(apiClientProvider)),
);

final supportRequestsProvider =
    FutureProvider.autoDispose<List<SupportRequest>>((ref) async {
      ref.watch(
        sessionProvider.select(
          (s) => s is SignedIn ? (s.session.userId, s.session.outletId) : null,
        ),
      );
      return switch (await ref.read(helpRepositoryProvider).support()) {
        ApiOk(:final value) => value,
        ApiErr(:final failure) => throw failure,
      };
    });

Future<T> _value<T>(Future<ApiResult<T>> call) async => switch (await call) {
  ApiOk(:final value) => value,
  ApiErr(:final failure) => throw failure,
};

/// Every help answer (18.1, 18.2).
final helpFaqsProvider = FutureProvider.autoDispose<List<HelpFaq>>(
  (ref) => _value(ref.read(helpRepositoryProvider).faqs()),
);

/// The answers matching a search (18.2).
final helpSearchProvider = FutureProvider.autoDispose
    .family<List<HelpFaq>, String>(
      (ref, q) => _value(ref.read(helpRepositoryProvider).faqs(query: q)),
    );

final privacyProvider = FutureProvider.autoDispose<LegalDoc>(
  (ref) => _value(ref.read(helpRepositoryProvider).privacy()),
);

final termsDocProvider = FutureProvider.autoDispose<LegalDoc>(
  (ref) => _value(ref.read(helpRepositoryProvider).terms()),
);

/// The first-time tour (17.7): once per phone.
abstract interface class TourMemory {
  Future<bool> shouldShow();
  Future<void> markShown();
}

class PhoneTourMemory implements TourMemory {
  const PhoneTourMemory();
  static const _key = 'v2_tour_shown';

  @override
  Future<bool> shouldShow() async =>
      await LocalStorageMethods.instance.readData(_key) != '1';

  @override
  Future<void> markShown() => LocalStorageMethods.instance.writeData(_key, '1');
}

final tourMemoryProvider = Provider<TourMemory>(
  (ref) => const PhoneTourMemory(),
);
