import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_page.dart';
import '../../../core/api/api_result.dart';
import '../../../core/app_providers.dart';
import '../../../core/format/dates.dart';
import '../../../core/session/session_controller.dart';

/// What a notification is about, for the chips (15.1): Orders, AtomPay,
/// Bulk deals, Stock, Product reviews, and Atomshop's own (billing,
/// messages, help replies).
enum NoticeKind { orders, atompay, bulk, stock, products, account }

/// One notification (`GET notifications`).
@immutable
class Notice {
  const Notice({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    this.at,
    this.data = const {},
  });

  final int id;

  /// The server's type: `brand_new_order`, `brand_new_bulk_request`,
  /// `brand_product_reviewed`, `brand_billing`, `brand_admin_message`…
  final String type;
  final String title;
  final String body;
  final bool read;
  final DateTime? at;

  /// Where it leads: `screen` and its ids (`BrandNotificationService`).
  final Map<String, dynamic> data;

  /// A message written by Atomshop (16.3).
  bool get fromAtomshop =>
      type == 'admin_message' ||
      type == 'brand_admin_message' ||
      Json.str(data['from']) == 'atomshop';

  NoticeKind get kind => noticeKindOf(type);

  Notice markedRead() => Notice(
    id: id,
    type: type,
    title: title,
    body: body,
    read: true,
    at: at,
    data: data,
  );

  factory Notice.fromJson(Object? raw) {
    final j = Json.map(raw);
    return Notice(
      id: Json.integer(j['id']) ?? 0,
      type: Json.str(j['type']) ?? '',
      title: Json.str(j['title']) ?? '',
      body: Json.str(j['body']) ?? '',
      read: Json.flag(j['is_read']),
      at: AtomDates.parse(j['created_at']),
      // `screen` sits beside `data` in the brand's inbox rows.
      data: {...Json.map(j['data']), 'screen': ?Json.str(j['screen'])},
    );
  }
}

/// The chip a notification type belongs to (`BrandNotificationService`).
NoticeKind noticeKindOf(String type) => switch (type) {
  'brand_new_order' => NoticeKind.orders,
  'brand_atompay_assigned' => NoticeKind.atompay,
  'brand_new_bulk_request' ||
  'brand_quote_accepted' ||
  'brand_quote_declined' ||
  'brand_quote_change' ||
  'brand_sourcing_received' => NoticeKind.bulk,
  'brand_stock_low' || 'stock_low' => NoticeKind.stock,
  'brand_product_reviewed' => NoticeKind.products,
  _ => NoticeKind.account,
};

/// One switch on the notification settings (16.4): the server's types for
/// this person (by add-on and role).
@immutable
class NoticeSwitch {
  const NoticeSwitch({
    required this.type,
    required this.label,
    required this.group,
    required this.on,
    this.description,
  });

  final String type;
  final String label;
  final String group;
  final String? description;
  final bool on;
}

/// The notification settings.
@immutable
class NoticeSettings {
  const NoticeSettings({
    required this.switches,
    this.quietFrom,
    this.quietTo,
    this.hideAmounts = false,
    this.pushOn = true,
    this.hideAmountsKept = false,
    this.alwaysOn = const [],
    this.alwaysOnItems = const [],
  });

  final List<NoticeSwitch> switches;

  /// "22:00" and "08:00", or null for no quiet hours.
  final String? quietFrom;
  final String? quietTo;
  final bool hideAmounts;

  /// The server keeps "Hide amounts" for this person (`hide_amounts` in
  /// the answer); when it doesn't, Security leaves the switch out.
  final bool hideAmountsKept;

  /// False while the Live alerts add-on is off: nothing is pushed, the
  /// inbox still gets everything.
  final bool pushOn;

  /// What can't be switched off ("Messages from Atomshop", "Bills").
  final List<String> alwaysOn;

  /// The same, with a line on each (16.4 "Messages from Atomshop · News,
  /// help replies and account notices"); the plain names when the server
  /// sends no lines.
  final List<({String label, String? description})> alwaysOnItems;

  factory NoticeSettings.fromJson(Object? data) {
    final d = Json.map(data);
    final quiet = Json.map(d['quiet_hours']);
    return NoticeSettings(
      switches: [
        for (final t in Json.list(d['types']))
          NoticeSwitch(
            type: Json.str(Json.map(t)['type']) ?? '',
            label: Json.str(Json.map(t)['label']) ?? '',
            group: Json.str(Json.map(t)['group']) ?? '',
            description: Json.str(Json.map(t)['description']),
            on: Json.flag(Json.map(t)['enabled']),
          ),
      ],
      quietFrom: Json.str(quiet['from']),
      quietTo: Json.str(quiet['to']),
      hideAmounts: Json.flag(d['hide_amounts']),
      pushOn: d['push_on'] == null || Json.flag(d['push_on']),
      hideAmountsKept: d.containsKey('hide_amounts'),
      alwaysOn: [for (final a in Json.list(d['always_on'])) ?Json.str(a)],
      alwaysOnItems: d['always_on_items'] is List
          ? [
              for (final a in Json.list(d['always_on_items']))
                if (Json.str(Json.map(a)['label']) case final label?)
                  (
                    label: label,
                    description: Json.str(Json.map(a)['description']),
                  ),
            ]
          : [
              for (final a in Json.list(d['always_on']))
                if (Json.str(a) case final label?)
                  (label: label, description: null),
            ],
    );
  }
}

/// Notifications calls (atomshop `Api\BrandApp\NotificationsController`,
/// `AccountController`).
abstract interface class NotificationsRepository {
  /// `GET notifications`: newest first, 20 a page, and the unread count.
  Future<ApiResult<(List<Notice>, int unread)>> list();

  /// `GET notifications?page=`: an older page of the same list, and
  /// whether there are more after it.
  Future<ApiResult<(List<Notice>, bool more)>> page(int page);

  /// `POST notifications/{id}/read`.
  Future<ApiResult<void>> markRead(int id);

  /// `POST notifications/read-all`.
  Future<ApiResult<void>> markAllRead();

  /// `GET settings/notifications`.
  Future<ApiResult<NoticeSettings>> settings();

  /// `POST settings/notifications/toggle`: one switch.
  Future<ApiResult<NoticeSettings>> toggle(String type, bool enabled);

  /// `POST settings/notifications`: only what is given changes. A null
  /// [quiet] with [clearQuiet] turns quiet hours off.
  Future<ApiResult<NoticeSettings>> saveSettings({
    Map<String, bool>? switches,
    (String, String)? quiet,
    bool clearQuiet = false,
    bool? hideAmounts,
  });
}

class ApiNotificationsRepository implements NotificationsRepository {
  const ApiNotificationsRepository(this._api);
  final ApiClient _api;

  @override
  Future<ApiResult<(List<Notice>, int)>> list() => _api.get(
    'notifications',
    parse: (data) {
      final page = ApiPage.fromJson(data, Notice.fromJson);
      return (page.items, Json.integer(page.extra['unread_count']) ?? 0);
    },
  );

  @override
  Future<ApiResult<(List<Notice>, bool)>> page(int page) => _api.get(
    'notifications',
    query: {'page': page},
    parse: (data) {
      final p = ApiPage.fromJson(data, Notice.fromJson);
      return (p.items, p.hasMore);
    },
  );

  @override
  Future<ApiResult<void>> markRead(int id) =>
      _api.post('notifications/$id/read', parse: (_) {});

  @override
  Future<ApiResult<void>> markAllRead() =>
      _api.post('notifications/read-all', parse: (_) {});

  @override
  Future<ApiResult<NoticeSettings>> settings() =>
      _api.get('settings/notifications', parse: NoticeSettings.fromJson);

  @override
  Future<ApiResult<NoticeSettings>> toggle(String type, bool enabled) =>
      _api.post(
        'settings/notifications/toggle',
        body: {'type': type, 'enabled': enabled},
        parse: NoticeSettings.fromJson,
      );

  @override
  Future<ApiResult<NoticeSettings>> saveSettings({
    Map<String, bool>? switches,
    (String, String)? quiet,
    bool clearQuiet = false,
    bool? hideAmounts,
  }) => _api.post(
    'settings/notifications',
    body: {
      'preferences': ?switches,
      if (quiet != null) 'quiet_hours': {'from': quiet.$1, 'to': quiet.$2},
      if (quiet == null && clearQuiet) 'quiet_hours': null,
      'hide_amounts': ?hideAmounts,
    },
    parse: NoticeSettings.fromJson,
  );
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => ApiNotificationsRepository(ref.read(apiClientProvider)),
);

Object? _who(Ref ref) => ref.watch(
  sessionProvider.select(
    (s) => s is SignedIn ? (s.session.userId, s.session.outletId) : null,
  ),
);

final noticesProvider = FutureProvider.autoDispose<(List<Notice>, int)>((
  ref,
) async {
  _who(ref);
  return switch (await ref.read(notificationsRepositoryProvider).list()) {
    ApiOk(:final value) => value,
    ApiErr(:final failure) => throw failure,
  };
});

final noticeSettingsProvider = FutureProvider.autoDispose<NoticeSettings>((
  ref,
) async {
  _who(ref);
  return switch (await ref.read(notificationsRepositoryProvider).settings()) {
    ApiOk(:final value) => value,
    ApiErr(:final failure) => throw failure,
  };
});

/// Notices read on this phone since [noticesProvider] last loaded. The
/// list showed them read at once, but the bell's count is the server's
/// and stayed as it was until the next reload; everything that counts
/// unread notices takes these off.
///
/// A reload brings the server's own word, so the set empties then, but
/// for ones whose mark-read is still on its way: a reload that beat it to
/// the server would show them unread again.
final noticesReadHereProvider =
    NotifierProvider.autoDispose<NoticesReadHere, Set<int>>(
      NoticesReadHere.new,
    );

class NoticesReadHere extends Notifier<Set<int>> {
  final _sending = <int>{};

  @override
  Set<int> build() {
    ref.listen(noticesProvider, (_, next) {
      if (next.hasValue && !next.isLoading) {
        state = state.where(_sending.contains).toSet();
      }
    });
    return const {};
  }

  /// Shows [n] read and tells the server. Back to unread if it refuses.
  Future<void> markRead(Notice n) async {
    if (n.read || state.contains(n.id)) return;
    state = {...state, n.id};
    _sending.add(n.id);
    final r = await ref.read(notificationsRepositoryProvider).markRead(n.id);
    _sending.remove(n.id);
    if (!ref.mounted) return;
    if (r is ApiErr) state = {...state}..remove(n.id);
  }
}

/// The bell's number: the server's unread count, less what was read here
/// since. Null until the list has loaded.
final unreadNoticesProvider = Provider.autoDispose<int?>((ref) {
  final count = ref.watch(noticesProvider).value?.$2;
  if (count == null) return null;
  final here = ref.watch(noticesReadHereProvider).length;
  return count - here < 0 ? 0 : count - here;
});
