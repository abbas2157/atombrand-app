import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_result.dart';
import '../app_providers.dart';
import '../session/session.dart';
import '../session/session_controller.dart';
import 'access.dart';
import 'addon_store.dart';
import 'app_update.dart';

/// Reads the account's add-ons, billing state and outlets.
abstract interface class AccessRepository {
  /// `GET me`: user, brand, access (role, permissions, outlet ids) and,
  /// when the server sends them, add-ons and billing state.
  Future<ApiResult<MeAnswer>> loadMe();

  /// `GET billing` (owner only).
  Future<ApiResult<PlanAccess>> loadPlan();

  /// `GET outlets` (owner only).
  Future<ApiResult<List<Outlet>>> loadOutlets();

  /// `GET terms`. A 404 means there are none to accept.
  Future<ApiResult<TermsStatus>> loadTerms();

  /// `POST terms/accept {version}` (owner only).
  Future<ApiResult<TermsStatus>> acceptTerms(String version);
}

class ApiAccessRepository implements AccessRepository {
  const ApiAccessRepository(this._ref);
  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);

  @override
  Future<ApiResult<MeAnswer>> loadMe() =>
      _api.get('me', parse: MeAnswer.fromJson);

  @override
  Future<ApiResult<PlanAccess>> loadPlan() =>
      _api.get('billing', parse: PlanAccess.fromJson);

  @override
  Future<ApiResult<List<Outlet>>> loadOutlets() => _api.get(
    'outlets',
    parse: (data) => [
      for (final o in Json.list(Json.map(data)['outlets'])) Outlet.fromJson(o),
    ],
  );

  @override
  Future<ApiResult<TermsStatus>> loadTerms() =>
      _api.get('terms', parse: TermsStatus.fromJson);

  @override
  Future<ApiResult<TermsStatus>> acceptTerms(String version) => _api.post(
    'terms/accept',
    body: {'version': version},
    parse: TermsStatus.fromJson,
  );
}

final accessRepositoryProvider = Provider<AccessRepository>(
  ApiAccessRepository.new,
);

final accessProvider = NotifierProvider<AccessController, AccessState>(
  AccessController.new,
);

/// Owns [AccessState]: loads add-ons when someone signs in, refreshes them
/// on open and resume, and takes the app-wide failures the API client
/// reports (read-only, restricted, removed, maintenance).
class AccessController extends Notifier<AccessState> {
  @override
  AccessState build() {
    // A new person (or none) starts from nothing known.
    ref.listen(sessionProvider, (previous, next) {
      final was = previous is SignedIn ? previous.session.userId : null;
      final now = next is SignedIn ? next.session.userId : null;
      if (was != now) {
        state = const AccessState();
        if (now == null) {
          AddonStore.clear();
        } else {
          _restore(now);
          refresh(firstSignIn: previous is SignedOut);
        }
      }
    });
    final s = ref.read(sessionProvider);
    if (s is SignedIn) {
      // The kept answer first, so a launch with no signal still knows the
      // account works offline; then the server's, which replaces it.
      Future.microtask(() => _restore(s.session.userId));
      Future.microtask(refresh);
    }
    Future.microtask(checkVersion);
    return const AccessState();
  }

  Future<void> _restore(int userId) async {
    final kept = await AddonStore.read(userId);
    if (kept == null || state.addonStates != null) return;
    state = state.copyWith(addonStates: () => kept);
  }

  void _keep(Map<Addon, AddonState> addons) {
    final s = ref.read(sessionProvider);
    if (s is SignedIn) AddonStore.write(s.session.userId, addons);
  }

  /// Asks the server for the lowest version it still serves (on open and
  /// resume). Not knowing changes nothing; only a "too old" answer blocks.
  Future<void> checkVersion() async {
    final update = await ref.read(appUpdateRepositoryProvider).check();
    if (update == null) return;
    state = state.copyWith(
      updateRequired: update.required,
      storeUrl: () => update.storeUrl,
    );
  }

  /// A resume within this long of the last reload asks nothing.
  static const resumeQuiet = Duration(minutes: 5);
  DateTime? _refreshedAt;

  /// App resume: [refresh], unless it ran less than [resumeQuiet] ago.
  Future<void> refreshIfStale() async {
    final at = _refreshedAt;
    if (at != null && DateTime.now().difference(at) < resumeQuiet) return;
    await refresh();
  }

  /// Reloads `me` (role, permissions, add-ons), the owner's billing state
  /// and outlets. Called on sign-in, app resume and after a payment.
  Future<void> refresh({bool firstSignIn = false}) async {
    final session = ref.read(sessionProvider);
    if (session is! SignedIn) return;
    _refreshedAt = DateTime.now();
    final repo = ref.read(accessRepositoryProvider);
    final sessions = ref.read(sessionProvider.notifier);
    final owner = session.session.who.isOwner;

    if (owner) await _loadTerms(repo);

    // 1. Who this is now, and what `me` says the account has.
    final me = await repo.loadMe();
    if (me case ApiOk(:final value)) {
      await sessions.refreshFromMe(value.raw);
      if (value.addonStates case final addons?) {
        _keep(addons);
        state = state.copyWith(addonStates: () => addons);
      }
      state = _fromMe(value, state);
    }

    // 2. The owner's outlets, for the switcher and the way in (2.6).
    if (owner) {
      if (await repo.loadOutlets() case ApiOk(:final value)) {
        await sessions.setOutlets(value, askToChoose: firstSignIn);
      }
    }

    // 3. The owner's billing: add-on states and the access state.
    if (!owner) {
      // A team member can't read billing; with nothing from `me` the
      // server's own 403 `feature_off` hides what is off.
      if (state.addonStates == null) {
        state = state.copyWith(addonStates: () => _assumedForMembers);
      }
      return;
    }
    switch (await repo.loadPlan()) {
      case ApiOk(:final value):
        final meHadAddons =
            me is ApiOk<MeAnswer> && me.value.addonStates != null;
        if (!meHadAddons) _keep(value.addonStates);
        state = state.copyWith(
          addonStates: meHadAddons ? null : () => value.addonStates,
          account: value.paused
              ? AccountStatus.restricted
              : (state.account == AccountStatus.restricted
                    ? AccountStatus.restricted
                    : value.account),
          daysLate: () => value.daysLate,
          due: () => value.due,
          message: () => value.message ?? state.message,
          maintenance: false,
        );
      case ApiErr(:final failure):
        if (failure.kind == ApiFailureKind.server &&
            state.addonStates == null) {
          // Unknown add-ons are treated as off.
          state = state.copyWith(addonStates: () => const {});
        }
    }
  }

  /// What `me` adds: a billing state and a restriction, when it sends one.
  AccessState _fromMe(MeAnswer me, AccessState next) {
    var out = next;
    if (me.account case final account?) {
      out = out.copyWith(
        account: account,
        daysLate: () => me.daysLate,
        due: () => me.due,
      );
    }
    switch (me.restricted) {
      case true:
        out = out.copyWith(
          account: AccountStatus.restricted,
          message: () => me.reason ?? out.message,
        );
      case false when out.account == AccountStatus.restricted:
        out = out.copyWith(
          account: me.account ?? AccountStatus.ok,
          message: () => null,
        );
      case false || null:
        break;
    }
    return out;
  }

  Future<void> _loadTerms(AccessRepository repo) async {
    switch (await repo.loadTerms()) {
      case ApiOk(:final value):
        state = state.copyWith(terms: () => value);
      case ApiErr(:final failure):
        // No terms call on the server: nothing to accept.
        if (failure.kind == ApiFailureKind.notFound) {
          state = state.copyWith(terms: () => TermsStatus.none);
        }
    }
  }

  /// The owner accepted [version]. Null on success; the failure otherwise.
  Future<ApiFailure?> acceptTerms(String version) async {
    final result = await ref
        .read(accessRepositoryProvider)
        .acceptTerms(version);
    switch (result) {
      case ApiOk(:final value):
        state = state.copyWith(terms: () => value);
        return null;
      case ApiErr(:final failure):
        return failure;
    }
  }

  /// Called by the API client for failures that change the whole app.
  void onFailure(ApiFailure failure) {
    final body = failure.body ?? const {};
    switch (failure.kind) {
      case ApiFailureKind.readOnly:
        state = state.copyWith(
          account: AccountStatus.readOnly,
          daysLate: () => Json.integer(body['days_late']),
          due: () => Json.integer(body['due']),
          message: () => failure.message,
        );
      case ApiFailureKind.restricted:
        state = state.copyWith(
          account: AccountStatus.restricted,
          message: () => Json.str(body['reason']) ?? failure.message,
        );
      case ApiFailureKind.packageRemoved:
        state = state.copyWith(
          account: AccountStatus.removed,
          message: () => failure.message,
        );
      case ApiFailureKind.noPlan:
        state = state.copyWith(
          account: AccountStatus.noPlan,
          message: () => failure.message,
        );
      case ApiFailureKind.maintenance:
        state = state.copyWith(maintenance: true);
      case ApiFailureKind.featureOff:
        // The server says an add-on is off: hide it at once.
        final addon = Addon.fromKey(Json.str(body['feature']));
        final states = state.addonStates;
        if (addon != null && states != null) {
          state = state.copyWith(
            addonStates: () => {...states, addon: AddonState.off},
          );
        }
      default:
        break;
    }
  }

  /// Try again on the Maintenance screen.
  void clearMaintenance() => state = state.copyWith(maintenance: false);
}

/// What a team member gets while the server can't tell them: the add-ons
/// the server gates itself (a 403 `feature_off` still hides them), not the
/// owner-only or phone-wide ones.
const _assumedForMembers = {
  Addon.inventory: AddonState.active,
  Addon.askAtom: AddonState.active,
  Addon.alerts: AddonState.active,
};
