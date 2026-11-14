import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../../../core/app_providers.dart';
import '../../../core/format/dates.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../sync/data/sync_providers.dart';
import 'home_logic.dart';
import 'home_models.dart';

/// Home's calls: `GET dashboard`, `GET notifications/count`, `GET search`,
/// the owner's `GET outlets` (switcher) and `GET billing` (banners), and
/// for the first day `GET settings` and `GET team`.
abstract interface class HomeRepository {
  Future<ApiResult<HomeDashboard>> dashboard();
  Future<ApiResult<int>> unreadCount();
  Future<ApiResult<SearchResults>> search(String q, {required Who who});
  Future<ApiResult<OutletList>> outlets();
  Future<ApiResult<BillingGlance>> billing();
  Future<ApiResult<bool>> paymentsChosen();
  Future<ApiResult<int>> teamCount();

  /// Counts from the phone's copy; null without one.
  Future<OfflineHome?> offlineHome();
}

class ApiHomeRepository implements HomeRepository {
  const ApiHomeRepository(this._api, [this._copy, this._store]);
  final ApiClient _api;

  /// The phone's copy (Offline add-on), read with no signal.
  final OfflineCopy? _copy;
  final SyncStoreReader? _store;

  @override
  Future<ApiResult<HomeDashboard>> dashboard() => _api.get(
    'dashboard',
    // Every period comes back in `home.periods`; this picks `home.sales`.
    query: {'period': 'month'},
    parse: (data) => HomeDashboard.fromJson(data, readAt: AtomDates.now()),
  );

  @override
  Future<ApiResult<int>> unreadCount() => _api.get(
    'notifications/count',
    parse: (data) => Json.integer(Json.map(data)['count']) ?? 0,
  );

  @override
  Future<ApiResult<SearchResults>> search(String q, {required Who who}) async {
    final copy = _copy;
    if (copy != null && !copy.isOnline()) {
      if (await _searchCopy(q, who) case final r?) return ApiOk(r);
    }
    final answer = await _api.get(
      'search',
      query: {'q': q},
      parse: SearchResults.fromJson,
    );
    if (answer case ApiErr(:final failure) when _noSignal(failure)) {
      if (await _searchCopy(q, who) case final r?) return ApiOk(r);
    }
    return answer;
  }

  Future<SearchResults?> _searchCopy(String q, Who who) async {
    final copy = _copy;
    final store = _store;
    if (copy == null || store == null) return null;
    try {
      Future<List<Map<String, dynamic>>> t(String table) =>
          store(table, copy.shopId);
      return searchCopy(
        q,
        who: who,
        orders: await t('orders'),
        atompay: await t('atompay_orders'),
        products: await t('products'),
        requests: await t('bulk_requests'),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ApiResult<OutletList>> outlets() =>
      _api.get('outlets', query: {'p': 'month'}, parse: OutletList.fromJson);

  @override
  Future<ApiResult<BillingGlance>> billing() =>
      _api.get('billing', parse: BillingGlance.fromJson);

  @override
  Future<ApiResult<bool>> paymentsChosen() =>
      _api.get('settings', parse: paymentsChosenFrom);

  @override
  Future<ApiResult<int>> teamCount() => _api.get(
    'team',
    parse: (data) => Json.list(Json.map(data)['members']).length,
  );

  @override
  Future<OfflineHome?> offlineHome() async {
    final copy = _copy;
    final store = _store;
    if (copy == null || store == null) return null;
    try {
      Future<List<Map<String, dynamic>>> t(String table) =>
          store(table, copy.shopId);
      return offlineHomeFrom(
        orders: await t('orders'),
        atompay: await t('atompay_orders'),
        payments: await t('order_payments'),
        requests: await t('bulk_requests'),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Reads a table of the copy: `(table, shopId) → rows`.
typedef SyncStoreReader = Future<List<Map<String, dynamic>>> Function(
  String table,
  int shopId,
);

/// A failure that means "no signal", not "the server said no".
bool noSignal(Object? error) => error is ApiFailure && _noSignal(error);

bool _noSignal(ApiFailure f) =>
    f.kind == ApiFailureKind.offline || f.kind == ApiFailureKind.timeout;

// ───────────────────────────────────────────── providers

/// The time Home reads (greeting, banners); tests set it.
final homeClockProvider = Provider<DateTime Function()>((ref) => AtomDates.now);

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final copy = ref.watch(offlineCopyProvider);
  return ApiHomeRepository(
    ref.read(apiClientProvider),
    copy,
    copy == null
        ? null
        : (table, shopId) =>
              ref.read(syncStoreProvider).rows(table, shopId: shopId),
  );
});

/// Who and where: every Home read starts again when either changes.
Object? _scope(Ref ref) => ref.watch(
  sessionProvider.select(
    (s) => s is SignedIn ? (s.session.userId, s.session.outletId) : null,
  ),
);

T _unwrap<T>(ApiResult<T> r) => switch (r) {
  ApiOk(:final value) => value,
  ApiErr(:final failure) => throw failure,
};

final homeDashboardProvider = FutureProvider<HomeDashboard>((ref) async {
  _scope(ref);
  return _unwrap(await ref.read(homeRepositoryProvider).dashboard());
});

/// The bell's number (`GET notifications/count`).
final homeUnreadProvider = FutureProvider<int>((ref) async {
  _scope(ref);
  return _unwrap(await ref.read(homeRepositoryProvider).unreadCount());
});

/// The outlet switcher's list (owner).
final homeOutletsProvider = FutureProvider.autoDispose<OutletList>((ref) async {
  _scope(ref);
  return _unwrap(await ref.read(homeRepositoryProvider).outlets());
});

/// What the banners need from billing. Null for a team member, who can't
/// read billing, and when the call fails: the access state's own banners
/// still show.
final homeBillingProvider = FutureProvider<BillingGlance?>((ref) async {
  _scope(ref);
  final owner = ref.read(sessionProvider.notifier).current?.who.isOwner;
  if (owner != true) return null;
  return switch (await ref.read(homeRepositoryProvider).billing()) {
    ApiOk(:final value) => value,
    ApiErr() => null,
  };
});

/// The first-day steps the server knows about: payments chosen and team
/// members added. Unknown answers count as not done.
final homeFirstStepsProvider =
    FutureProvider.autoDispose<({bool payments, int team})>((ref) async {
      _scope(ref);
      final repo = ref.read(homeRepositoryProvider);
      final teamOn = ref.read(accessProvider).has(Addon.team);
      final payments = await repo.paymentsChosen();
      final team = teamOn ? await repo.teamCount() : const ApiOk(0);
      return (
        payments: payments is ApiOk<bool> && payments.value,
        team: team is ApiOk<int> ? team.value : 0,
      );
    });

/// Home from the phone's copy, with no signal (5.3).
final homeOfflineProvider = FutureProvider.autoDispose<OfflineHome?>((
  ref,
) async {
  _scope(ref);
  ref.watch(syncStatusProvider.select((s) => s.lastSyncAt));
  ref.watch(syncStatusProvider.select((s) => s.waiting));
  return ref.watch(homeRepositoryProvider).offlineHome();
});

/// Banners hidden with ✕ this session.
final hiddenBannersProvider = NotifierProvider<HiddenBanners, Set<String>>(
  HiddenBanners.new,
);

class HiddenBanners extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    _scope(ref);
    return const {};
  }

  void hide(String key) => state = {...state, key};
}

/// Reads every part of Home again (pull to refresh).
Future<void> refreshHome(WidgetRef ref) async {
  ref
    ..invalidate(homeDashboardProvider)
    ..invalidate(homeUnreadProvider)
    ..invalidate(homeBillingProvider)
    ..invalidate(homeFirstStepsProvider)
    ..invalidate(homeOfflineProvider);
  // The add-ons and billing state too, unless they were read just now.
  ref.read(accessProvider.notifier).refreshIfStale();
  try {
    await ref.read(homeDashboardProvider.future);
  } catch (_) {
    // The screen shows the failure itself.
  }
}
