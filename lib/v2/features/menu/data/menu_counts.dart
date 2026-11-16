import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../../../core/app_providers.dart';
import '../../../core/format/dates.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';

/// The numbers beside the menu's rows (12.1): what waits in Orders,
/// AtomPay, Bulk deals, Stock and Products, from `GET dashboard`
/// (`home.counts`, `home.hero`, `home.plan`). Each is null when the role
/// can't see it or the server didn't send it, and the row then shows none.
@immutable
class MenuCounts {
  const MenuCounts({
    this.ordersToConfirm,
    this.atompayToHandOver,
    this.requestsWaiting,
    this.outOfStock,
    this.productsToCheck,
    this.paidUntil,
  });

  final int? ordersToConfirm;
  final int? atompayToHandOver;

  /// Seller and website bulk requests waiting for a reply.
  final int? requestsWaiting;
  final int? outOfStock;

  /// Products in review or on hold.
  final int? productsToCheck;
  final DateTime? paidUntil;

  factory MenuCounts.fromJson(Object? data) {
    final home = Json.map(Json.map(data)['home']);
    final hero = Json.map(home['hero']);
    final counts = Json.map(home['counts']);
    final orders = Json.map(counts['orders']);
    final catalogue = counts['catalogue'] is Map
        ? Json.map(counts['catalogue'])
        : null;
    int? sum(Object? a, Object? b) {
      final x = Json.integer(a), y = Json.integer(b);
      return x == null && y == null ? null : (x ?? 0) + (y ?? 0);
    }

    return MenuCounts(
      ordersToConfirm: Json.integer(
        orders['to_confirm'] ?? hero['orders_to_confirm'],
      ),
      atompayToHandOver: Json.integer(
        orders['atompay_to_hand_over'] ?? hero['atompay_to_hand_over'],
      ),
      requestsWaiting: sum(
        hero['bulk_requests_waiting'],
        hero['seller_requests_waiting'],
      ),
      outOfStock: catalogue == null
          ? null
          : Json.integer(catalogue['out_of_stock']),
      productsToCheck: catalogue == null
          ? null
          : sum(catalogue['in_review'], catalogue['on_hold']),
      paidUntil: AtomDates.parse(Json.map(home['plan'])['paid_until']),
    );
  }
}

/// Who and where: the counts start again when either changes.
Object? _scope(Ref ref) => ref.watch(
  sessionProvider.select(
    (s) => s is SignedIn ? (s.session.userId, s.session.outletId) : null,
  ),
);

/// `GET dashboard`, read for the menu's numbers. A failure leaves every
/// number out rather than showing an error on a menu.
final menuCountsProvider = FutureProvider.autoDispose<MenuCounts?>((ref) async {
  _scope(ref);
  final r = await ref
      .read(apiClientProvider)
      .get('dashboard', query: {'period': 'month'}, parse: MenuCounts.fromJson);
  return switch (r) {
    ApiOk(:final value) => value,
    ApiErr() => null,
  };
});

/// People on the team (`GET team`), for "4 people". Null without the Team
/// add-on, without `team.manage`, or when the call fails.
final menuTeamSizeProvider = FutureProvider.autoDispose<int?>((ref) async {
  _scope(ref);
  final who = ref.read(sessionProvider.notifier).current?.who;
  if (who == null ||
      !who.can(BrandPermission.teamManage) ||
      !ref.read(accessProvider).has(Addon.team)) {
    return null;
  }
  final r = await ref
      .read(apiClientProvider)
      .get(
        'team',
        parse: (data) => Json.list(Json.map(data)['members']).length,
      );
  return switch (r) {
    ApiOk(:final value) => value,
    ApiErr() => null,
  };
});
