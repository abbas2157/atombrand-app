import 'package:flutter/foundation.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/api/api_client.dart';
import '../../../core/format/dates.dart';

/// Open, paused (new orders go to the main outlet, its staff can't sign
/// in) or closed (history only).
enum OutletStatus {
  open('open'),
  paused('paused'),
  closed('closed');

  const OutletStatus(this.key);

  final String key;

  String label(AppLocalizations l) => switch (this) {
    OutletStatus.open => l.outletsStatusOpen,
    OutletStatus.paused => l.outletsStatusPaused,
    OutletStatus.closed => l.outletsStatusClosed,
  };

  static OutletStatus parse(Object? raw) => switch (Json.str(raw)) {
    'paused' => OutletStatus.paused,
    'closed' => OutletStatus.closed,
    _ => OutletStatus.open,
  };
}

/// A city (`{id, title}`).
typedef City = ({int id, String title});

City? _city(Object? raw) {
  final j = Json.map(raw);
  final id = Json.integer(j['id']);
  if (id == null) return null;
  return (id: id, title: Json.str(j['title']) ?? '');
}

/// An outlet's figures for a period (`BrandOutletService::figures`), in
/// whole rupees. `bulkWon`/`bulkDeals` are null until bulk deals exist and
/// `units` without the Inventory add-on.
@immutable
class OutletFigures {
  const OutletFigures({
    this.sales = 0,
    this.orders = 0,
    this.delivered = 0,
    this.cancelled = 0,
    this.atompay = 0,
    this.avgOrder = 0,
    this.toConfirm = 0,
    this.payments = 0,
    this.bulkWon,
    this.bulkDeals,
    this.units,
    this.staff = 0,
    this.staffAll = 0,
  });

  final int sales;
  final int orders;
  final int delivered;
  final int cancelled;
  final int atompay;
  final int avgOrder;
  final int toConfirm;
  final int payments;
  final int? bulkWon;
  final int? bulkDeals;
  final int? units;

  /// Switched-on members limited to this outlet.
  final int staff;

  /// Switched-on members who work in every outlet.
  final int staffAll;

  static OutletFigures fromJson(Object? raw) {
    final j = Json.map(raw);
    return OutletFigures(
      sales: Json.integer(j['sales']) ?? 0,
      orders: Json.integer(j['orders']) ?? 0,
      delivered: Json.integer(j['delivered']) ?? 0,
      cancelled: Json.integer(j['cancelled']) ?? 0,
      atompay: Json.integer(j['atompay']) ?? 0,
      avgOrder: Json.integer(j['avg_order']) ?? 0,
      toConfirm: Json.integer(j['to_confirm']) ?? 0,
      payments: Json.integer(j['payments']) ?? 0,
      bulkWon: Json.integer(j['bulk_won']),
      bulkDeals: Json.integer(j['bulk_deals']),
      units: Json.integer(j['units']),
      staff: Json.integer(j['staff']) ?? 0,
      staffAll: Json.integer(j['staff_all']) ?? 0,
    );
  }
}

/// An outlet (`{id, name, is_main, status, phone, address, city, cities,
/// manager {id, name}, opened_on}` plus `figures`, and on the detail
/// `open_orders`).
@immutable
class BrandOutlet {
  const BrandOutlet({
    required this.id,
    required this.name,
    this.isMain = false,
    this.status = OutletStatus.open,
    this.phone,
    this.address,
    this.city,
    this.cities = const [],
    this.managerUserId,
    this.managerName,
    this.openedOn,
    this.figures,
    this.openOrders,
    this.runBy,
    this.staffNames,
  });

  final int id;
  final String name;
  final bool isMain;
  final OutletStatus status;
  final String? phone;
  final String? address;
  final City? city;

  /// The cities it serves (a city belongs to one outlet).
  final List<City> cities;

  /// Who runs it: the manager's user id (not their team member id).
  final int? managerUserId;
  final String? managerName;
  final DateTime? openedOn;
  final OutletFigures? figures;

  /// Orders not yet delivered (Pending, Confirming, Processing); detail only.
  final int? openOrders;

  /// Who runs it (`run_by`): the manager, or the owner when none is set.
  final String? runBy;

  /// The people who work here, those in every outlet included; detail only.
  final List<String>? staffNames;

  factory BrandOutlet.fromJson(Object? raw) {
    final j = Json.map(raw);
    final manager = Json.map(j['manager']);
    return BrandOutlet(
      id: Json.integer(j['id']) ?? 0,
      name: Json.str(j['name']) ?? '',
      isMain: Json.flag(j['is_main']),
      status: OutletStatus.parse(j['status']),
      phone: Json.str(j['phone']),
      address: Json.str(j['address']),
      city: _city(j['city']),
      cities: [for (final c in Json.list(j['cities'])) ?_city(c)],
      managerUserId: Json.integer(manager['id']),
      managerName: Json.str(manager['name']),
      openedOn: AtomDates.parse(j['opened_on']),
      figures: j['figures'] is Map
          ? OutletFigures.fromJson(j['figures'])
          : null,
      openOrders: Json.integer(j['open_orders']),
      runBy: Json.str(j['run_by']) ?? Json.str(manager['name']),
      staffNames: j['staff_names'] is List
          ? [for (final n in Json.list(j['staff_names'])) ?Json.str(n)]
          : null,
    );
  }
}

/// The periods `GET outlets?p=` takes.
enum OutletPeriod {
  month('month'),
  last('last'),
  year('year');

  const OutletPeriod(this.key);

  final String key;

  String label(AppLocalizations l) => switch (this) {
    OutletPeriod.month => l.outletsPeriodMonth,
    OutletPeriod.last => l.outletsPeriodLast,
    OutletPeriod.year => l.outletsPeriodYear,
  };
}

/// `GET outlets`: `{account_type, outlet_limit, used, period, outlets}`.
@immutable
class OutletList {
  const OutletList({
    required this.outlets,
    this.accountType,
    this.limit = 1,
    this.used = 1,
  });

  final List<BrandOutlet> outlets;

  /// `multi` or `single`.
  final String? accountType;
  final int limit;
  final int used;

  bool get multi => accountType == 'multi';

  /// Whether another outlet can be added now.
  bool get canAdd => multi && used < limit;

  factory OutletList.fromJson(Object? data) {
    final d = Json.map(data);
    return OutletList(
      outlets: [
        for (final o in Json.list(d['outlets'])) BrandOutlet.fromJson(o),
      ],
      accountType: Json.str(d['account_type']),
      limit: Json.integer(d['outlet_limit']) ?? 1,
      used: Json.integer(d['used']) ?? 1,
    );
  }
}

/// An outlet's details as typed (11.8: add, or change one).
@immutable
class OutletDraft {
  const OutletDraft({
    required this.name,
    required this.phone,
    required this.cityId,
    required this.address,
    required this.cityIds,
    this.openedOn,
    this.managerId,
    this.sendManager = false,
  });

  final String name;
  final String phone;
  final int cityId;
  final String address;
  final List<int> cityIds;

  /// Only for a new outlet.
  final DateTime? openedOn;

  /// A switched-on team member's id (not user id).
  final int? managerId;

  /// Send [managerId] even when it didn't change (a new outlet always).
  final bool sendManager;

  Map<String, dynamic> toBody() => {
    'name': name,
    'phone': phone,
    'city_id': cityId,
    'address': address,
    'city_ids': cityIds,
    if (openedOn != null) 'opened_on': AtomDates.api(openedOn!),
    if (sendManager && managerId != null) 'manager_id': managerId,
  };
}

/// One of an outlet's orders this month (`GET orders?outlet_id=`).
@immutable
class OutletOrder {
  const OutletOrder({
    required this.uuid,
    required this.id,
    required this.status,
    this.product,
    this.city,
  });

  final String uuid;
  final int id;
  final String status;
  final String? product;
  final String? city;

  factory OutletOrder.fromJson(Object? raw) {
    final j = Json.map(raw);
    return OutletOrder(
      uuid: Json.str(j['uuid']) ?? '',
      id: Json.integer(j['id']) ?? 0,
      status: Json.str(j['status']) ?? '',
      product: Json.str(Json.map(j['product'])['title']),
      city: Json.str(j['city']),
    );
  }
}

/// Someone who can run an outlet (`outlets/form-options` `managers[]`): a
/// switched-on team member.
typedef OutletManagerChoice = ({int id, String name, String? role});

/// `GET outlets/form-options?outlet_id=`: the add / edit form's choices.
@immutable
class OutletFormOptions {
  const OutletFormOptions({
    this.cities = const [],
    this.taken = const {},
    this.managers = const [],
    this.currentManagerId,
  });

  /// Every active city, A to Z.
  final List<City> cities;

  /// City id → the name of the other outlet that serves it.
  final Map<int, String> taken;
  final List<OutletManagerChoice> managers;

  /// The member running this outlet now (an edit), as a `managers` id.
  final int? currentManagerId;

  factory OutletFormOptions.fromJson(Object? data) {
    final j = Json.map(data);
    final cities = <City>[];
    final taken = <int, String>{};
    for (final c in Json.list(j['cities'])) {
      final m = Json.map(c);
      final id = Json.integer(m['id']);
      if (id == null) continue;
      cities.add((id: id, title: Json.str(m['title']) ?? ''));
      if (Json.str(Json.map(m['taken_by'])['name']) case final by?) {
        taken[id] = by;
      }
    }
    return OutletFormOptions(
      cities: cities,
      taken: taken,
      managers: [
        for (final r in Json.list(j['managers']))
          if (Json.integer(Json.map(r)['id']) case final id?)
            (
              id: id,
              name: Json.str(Json.map(r)['name']) ?? '',
              role: Json.str(Json.map(r)['role']),
            ),
      ],
      currentManagerId: Json.integer(j['current_manager_id']),
    );
  }
}
