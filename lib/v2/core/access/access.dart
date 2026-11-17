import 'package:flutter/foundation.dart';

import '../api/api_client.dart';

/// The brand's paid add-ons, by their billing key (`billing/addons/{key}`).
/// An add-on that is off is left out of every screen, never shown locked.
enum Addon {
  /// Stock: warehouses, serials, stock in / move / adjust.
  inventory('inventory'),

  /// Roles management: team members and roles.
  team('team'),
  askAtom('ask_atom'),

  /// Live alerts (push). Off, notifications still reach the inbox.
  alerts('alerts'),

  /// Offline working (the phone's copy and outbox).
  offline('offline');

  const Addon(this.key);
  final String key;

  static Addon? fromKey(String? key) {
    for (final a in values) {
      if (a.key == key) return a;
    }
    return null;
  }
}

/// An add-on's state, from `GET billing` `addons[].state` (or `GET me`).
enum AddonState {
  off,

  /// A free trial.
  trial,
  active,

  /// The trial or paid period ended: visible, nothing may change.
  lapsed,

  /// Free until `legacy_until` (brands that had a login before billing).
  legacy;

  static AddonState fromKey(Object? key) => switch (key) {
    true || 1 || '1' => active,
    'trial' => trial,
    'active' || 'on' => active,
    'lapsed' => lapsed,
    'legacy' => legacy,
    _ => off,
  };

  /// The brand may use it (and its screens show).
  bool get usable => this == trial || this == active || this == legacy;

  /// Shown but read-only.
  bool get readOnly => this == lapsed;
}

/// The account's billing state, from `billing` `access.state` and from the
/// server's 403 flags.
enum AccountStatus {
  ok,

  /// A renewal bill is open.
  due,

  /// 1–7 days late: a banner.
  late,

  /// 8–15 days late: a stronger banner.
  overdue,

  /// More than 15 days late: writes refused (`billing_state: readonly`).
  readOnly,

  /// Atomshop paused changes (`restricted: true`); no Pay.
  restricted,

  /// The package was removed: only Plan & billing and profile.
  removed,

  /// No plan at all.
  noPlan;

  static AccountStatus fromAccessState(String? state) => switch (state) {
    'due' => due,
    'late' => late,
    'overdue' => overdue,
    'readonly' => readOnly,
    'removed' => removed,
    'none' => noPlan,
    _ => ok,
  };

  /// States that close the app down to a state screen.
  bool get blocksApp => this == removed || this == noPlan;

  /// States where writes are refused (recording payments still works).
  bool get blocksWrites => this == readOnly || this == restricted;
}

/// What the account has and what state it is in.
@immutable
class AccessState {
  const AccessState({
    this.addonStates,
    this.account = AccountStatus.ok,
    this.daysLate,
    this.due,
    this.message,
    this.maintenance = false,
    this.updateRequired = false,
    this.storeUrl,
    this.terms,
  });

  /// Each add-on's state. Null until known: screens leave add-on parts out
  /// until then rather than show and then hide them.
  final Map<Addon, AddonState>? addonStates;

  final AccountStatus account;
  final int? daysLate;

  /// Rupees owed, for the late-bill banner and the read-only screen.
  final int? due;

  /// The server's own words for a restriction or a block.
  final String? message;

  /// A 503: Maintenance is the only screen.
  final bool maintenance;

  /// This version is below the server's minimum: Update is the only screen.
  final bool updateRequired;

  /// Where Update sends the person; null uses the store page.
  final String? storeUrl;

  /// The partner terms; null until read, or when the server has none.
  final TermsStatus? terms;

  /// The add-ons that may be used now (trial, active or legacy).
  Set<Addon>? get addons => addonStates == null
      ? null
      : {
          for (final e in addonStates!.entries)
            if (e.value.usable) e.key,
        };

  /// The owner must accept a new version before using the app.
  bool get mustAcceptTerms => terms?.mustAccept ?? false;

  /// The add-on is on (trial, active or legacy).
  bool has(Addon addon) => addonStates?[addon]?.usable ?? false;

  /// The add-on's screens may open: on, or lapsed (shown read-only, the
  /// server refusing changes). Inventory works this way, as in Atom Seller.
  bool canRead(Addon addon) {
    final s = addonStates?[addon];
    return s != null && (s.usable || s.readOnly);
  }

  /// The add-on's state; [AddonState.off] while unknown.
  AddonState stateOf(Addon addon) => addonStates?[addon] ?? AddonState.off;

  AccessState copyWith({
    Map<Addon, AddonState>? Function()? addonStates,
    AccountStatus? account,
    int? Function()? daysLate,
    int? Function()? due,
    String? Function()? message,
    bool? maintenance,
    bool? updateRequired,
    String? Function()? storeUrl,
    TermsStatus? Function()? terms,
  }) => AccessState(
    addonStates: addonStates != null ? addonStates() : this.addonStates,
    account: account ?? this.account,
    daysLate: daysLate != null ? daysLate() : this.daysLate,
    due: due != null ? due() : this.due,
    message: message != null ? message() : this.message,
    maintenance: maintenance ?? this.maintenance,
    updateRequired: updateRequired ?? this.updateRequired,
    storeUrl: storeUrl != null ? storeUrl() : this.storeUrl,
    terms: terms != null ? terms() : this.terms,
  );
}

/// Reads add-on states from either shape the server uses:
/// a map `{inventory: "trial", team: true, …}` or a list
/// `[{key: "team", state: "trial"}, …]` (`GET billing`).
Map<Addon, AddonState> addonStatesFromJson(Object? raw) {
  final out = <Addon, AddonState>{};
  if (raw is Map) {
    for (final e in raw.entries) {
      final addon = Addon.fromKey('${e.key}');
      if (addon == null) continue;
      final v = e.value;
      out[addon] = v is Map
          ? AddonState.fromKey(v['state'] ?? v['status'] ?? v['on'])
          : AddonState.fromKey(v);
    }
  } else if (raw is List) {
    for (final item in raw) {
      final m = Json.map(item);
      final addon = Addon.fromKey(Json.str(m['key']));
      if (addon == null) continue;
      out[addon] = AddonState.fromKey(m['state'] ?? m['status'] ?? m['on']);
    }
  }
  return out;
}

/// `GET me` read for the access controller: add-ons and billing state when
/// the server includes them (`addons`, `billing`), plus any restriction.
@immutable
class MeAnswer {
  const MeAnswer({
    this.addonStates,
    this.account,
    this.daysLate,
    this.due,
    this.restricted,
    this.reason,
    this.raw = const {},
  });

  /// Null when `me` doesn't carry add-ons.
  final Map<Addon, AddonState>? addonStates;
  final AccountStatus? account;
  final int? daysLate;
  final int? due;
  final bool? restricted;
  final String? reason;

  /// The whole `data`, for the session (`user`, `brand`, `access`).
  final Map<String, dynamic> raw;

  factory MeAnswer.fromJson(Object? data) {
    final d = Json.map(data);
    final billing = Json.map(d['billing']);
    final access = billing['access'] is Map
        ? Json.map(billing['access'])
        : billing;
    final addons = d['addons'] ?? billing['addons'];
    final restricted = d['restricted'] ?? access['paused'];
    return MeAnswer(
      addonStates: addons == null ? null : addonStatesFromJson(addons),
      account: Json.str(access['state']) == null
          ? null
          : AccountStatus.fromAccessState(Json.str(access['state'])),
      daysLate: Json.integer(access['days_late']),
      due: Json.integer(access['due']),
      restricted: restricted == null ? null : Json.flag(restricted),
      reason: Json.str(d['restricted_reason'] ?? access['message']),
      raw: d,
    );
  }
}

/// `GET billing` read for the app: add-on states and the access state.
@immutable
class PlanAccess {
  const PlanAccess({
    required this.addonStates,
    required this.account,
    this.daysLate,
    this.due,
    this.paused = false,
    this.message,
  });

  final Map<Addon, AddonState> addonStates;
  final AccountStatus account;
  final int? daysLate;
  final int? due;
  final bool paused;
  final String? message;

  factory PlanAccess.fromJson(Object? data) {
    final d = Json.map(data);
    final access = Json.map(d['access']);
    return PlanAccess(
      addonStates: addonStatesFromJson(d['addons']),
      account: AccountStatus.fromAccessState(Json.str(access['state'])),
      daysLate: Json.integer(access['days_late']),
      due: Json.integer(access['due']),
      paused: Json.flag(access['paused']),
      message: Json.str(access['message']),
    );
  }
}

/// `GET terms`: the current version and whether the owner still has to
/// accept it. Team members only read the terms.
@immutable
class TermsStatus {
  const TermsStatus({
    required this.version,
    required this.mustAccept,
    this.acceptedBy,
    this.acceptedAt,
    this.url,
  });

  final String? version;
  final bool mustAccept;
  final String? acceptedBy;
  final DateTime? acceptedAt;

  /// Where the full text is.
  final String? url;

  /// No terms to accept: what a server without the terms call means.
  static const none = TermsStatus(version: null, mustAccept: false);

  factory TermsStatus.fromJson(Object? data) {
    final d = Json.map(data);
    final accepted = Json.map(d['accepted']);
    return TermsStatus(
      version: Json.str(d['version']),
      mustAccept: Json.flag(d['must_accept']),
      acceptedBy: Json.str(accepted['by']),
      acceptedAt: DateTime.tryParse(Json.str(accepted['at']) ?? ''),
      url: Json.str(d['url']),
    );
  }
}
