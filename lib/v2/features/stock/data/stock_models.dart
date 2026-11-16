import 'package:flutter/foundation.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/access/access.dart';
import '../../../core/api/api_client.dart';
import '../../../core/format/dates.dart';

/// The brand stock API's shapes (`/api/brand-app/stock*`,
/// `App\Http\Controllers\Api\BrandApp\StockController`, docs/BRAND_APP.md
/// "Portal v2: Stock"). Every list carries [StockAccess].

/// How a product's units are numbered.
enum Tracking {
  imei('imei'),
  serial('serial'),
  auto('auto');

  const Tracking(this.key);
  final String key;

  /// "numbered by serial number".
  String label(AppLocalizations l) => switch (this) {
    imei => l.stockTrackingImei,
    serial => l.stockTrackingSerial,
    auto => l.stockTrackingAuto,
  };

  static Tracking fromKey(Object? key) => switch (Json.str(key)) {
    'imei' => imei,
    'auto' => auto,
    _ => serial,
  };
}

/// `access` on every stock answer.
@immutable
class StockAccess {
  const StockAccess({
    this.state = AddonState.active,
    this.readOnly = false,
    this.daysLeft,
    this.canChange = false,
    this.canManage = false,
  });

  final AddonState state;
  final bool readOnly;
  final int? daysLeft;
  final bool canChange;
  final bool canManage;

  bool get trial => state == AddonState.trial;

  /// Stock in, move and adjust may run.
  bool get changes => canChange && !readOnly;

  /// Warehouses may be added or edited.
  bool get manages => canManage && !readOnly;

  factory StockAccess.fromJson(Object? data) {
    final j = Json.map(data);
    return StockAccess(
      state: AddonState.fromKey(j['state'] ?? 'active'),
      readOnly: Json.flag(j['read_only']),
      daysLeft: Json.integer(j['days_left']),
      canChange: Json.flag(j['can_change']),
      canManage: Json.flag(j['can_manage']),
    );
  }
}

@immutable
class StockPerson {
  const StockPerson({required this.id, required this.name, this.phone});
  final int id;
  final String name;
  final String? phone;

  static StockPerson? fromJson(Object? data) {
    final j = Json.map(data);
    final id = Json.integer(j['id']);
    if (id == null) return null;
    return StockPerson(
      id: id,
      name: Json.str(j['name']) ?? '',
      phone: Json.str(j['phone']),
    );
  }
}

/// A warehouse row (list, form options, product detail, warehouses page).
@immutable
class StockWarehouse {
  const StockWarehouse({
    required this.id,
    required this.name,
    this.type = 'store',
    this.outletId,
    this.outlet,
    this.address,
    this.sellsOnline = false,
    this.isDefault = false,
    this.status = 'active',
    this.inCharge,
    this.units = 0,
    this.held = 0,
    this.onHand = 0,
    this.available = 0,
  });

  final int id;
  final String name;

  /// `factory`, `godown`, `store`.
  final String type;
  final int? outletId;
  final String? outlet;
  final String? address;
  final bool sellsOnline;
  final bool isDefault;

  /// `active` or `archived`.
  final String status;
  final StockPerson? inCharge;

  /// Units in stock (warehouses page).
  final int units;
  final int held;

  /// Product detail only.
  final int onHand;
  final int available;

  bool get archived => status == 'archived';

  factory StockWarehouse.fromJson(Object? data) {
    final j = Json.map(data);
    return StockWarehouse(
      id: Json.integer(j['id']) ?? 0,
      name: Json.str(j['name']) ?? '',
      type: Json.str(j['type']) ?? 'store',
      outletId: Json.integer(j['outlet_id'] ?? j['brand_outlet_id']),
      outlet: Json.str(j['outlet']),
      address: Json.str(j['address']),
      sellsOnline: Json.flag(j['sells_online']),
      isDefault: Json.flag(j['is_default']),
      status: Json.str(j['status']) ?? 'active',
      inCharge: StockPerson.fromJson(j['in_charge']),
      units: Json.integer(j['units']) ?? 0,
      held: Json.integer(j['held']) ?? 0,
      onHand: Json.integer(j['on_hand']) ?? 0,
      available: Json.integer(j['available']) ?? 0,
    );
  }
}

/// What a warehouse type is called.
String warehouseTypeLabel(AppLocalizations l, String type) => switch (type) {
  'factory' => l.stockWhTypeFactory,
  'godown' => l.stockWhTypeGodown,
  _ => l.stockWhTypeStore,
};

/// One variant's balance in one warehouse.
typedef WarehouseBalance = ({int warehouseId, int onHand, int reserved});

@immutable
class StockVariant {
  const StockVariant({
    required this.id,
    required this.name,
    this.sku,
    this.price = 0,
    this.onHand = 0,
    this.held = 0,
    this.available = 0,
    this.state = 'in',
    this.byWarehouse = const [],
    this.onWebsite = false,
  });

  final int id;
  final String name;
  final String? sku;
  final int price;
  final int onHand;
  final int held;
  final int available;

  /// `in`, `low` or `out`.
  final String state;
  final List<WarehouseBalance> byWarehouse;
  final bool onWebsite;

  factory StockVariant.fromJson(Object? data) {
    final j = Json.map(data);
    return StockVariant(
      id: Json.integer(j['id']) ?? 0,
      name: Json.str(j['name']) ?? '',
      sku: Json.str(j['sku']),
      price: Json.integer(j['price']) ?? 0,
      onHand: Json.integer(j['on_hand']) ?? 0,
      held: Json.integer(j['held']) ?? 0,
      available: Json.integer(j['available']) ?? 0,
      state: Json.str(j['state']) ?? 'in',
      byWarehouse: [
        for (final b in Json.list(j['by_warehouse']))
          (
            warehouseId: Json.integer(Json.map(b)['warehouse_id']) ?? 0,
            onHand: Json.integer(Json.map(b)['on_hand']) ?? 0,
            reserved: Json.integer(Json.map(b)['reserved']) ?? 0,
          ),
      ],
      onWebsite: Json.flag(j['on_website']),
    );
  }
}

/// A stock product (`GET stock` `items[]`).
@immutable
class StockProduct {
  const StockProduct({
    required this.id,
    required this.title,
    this.category,
    this.tracking = Tracking.serial,
    this.autoPrefix,
    this.catalogueProductId,
    this.prNumber,
    this.websiteStatus,
    this.variants = const [],
  });

  final int id;
  final String title;
  final String? category;
  final Tracking tracking;
  final String? autoPrefix;
  final int? catalogueProductId;
  final String? prNumber;
  final String? websiteStatus;
  final List<StockVariant> variants;

  factory StockProduct.fromJson(Object? data) {
    final j = Json.map(data);
    return StockProduct(
      id: Json.integer(j['id']) ?? 0,
      title: Json.str(j['title']) ?? '',
      category: Json.str(j['category']),
      tracking: Tracking.fromKey(j['tracking']),
      autoPrefix: Json.str(j['auto_prefix']),
      catalogueProductId: Json.integer(j['catalogue_product_id']),
      prNumber: Json.str(j['pr_number']),
      websiteStatus: Json.str(j['website_status']),
      variants: [
        for (final v in Json.list(j['variants'])) StockVariant.fromJson(v),
      ],
    );
  }
}

/// `totals` on `GET stock`.
@immutable
class StockTotals {
  const StockTotals({
    this.units = 0,
    this.held = 0,
    this.live = 0,
    this.listed = 0,
    this.low = 0,
    this.out = 0,
    this.variants = 0,
    this.byOutlet = const [],
  });

  final int units;
  final int held;
  final int live;
  final int listed;
  final int low;
  final int out;
  final int variants;
  final List<({String name, int units})> byOutlet;

  /// What can be sold now.
  int get available => (units - held).clamp(0, units);

  factory StockTotals.fromJson(Object? data) {
    final j = Json.map(data);
    return StockTotals(
      units: Json.integer(j['units']) ?? 0,
      held: Json.integer(j['held']) ?? 0,
      live: Json.integer(j['live']) ?? 0,
      listed: Json.integer(j['listed']) ?? 0,
      low: Json.integer(j['low']) ?? 0,
      out: Json.integer(j['out']) ?? 0,
      variants: Json.integer(j['variants']) ?? 0,
      byOutlet: [
        for (final o in Json.list(j['by_outlet']))
          (
            name: Json.str(Json.map(o)['name']) ?? '',
            units: Json.integer(Json.map(o)['units']) ?? 0,
          ),
      ],
    );
  }
}

/// A unit held for a cash order or a bulk deal (`held[]`).
@immutable
class StockHold {
  const StockHold({
    required this.id,
    required this.forDeal,
    this.orderId,
    this.orderUuid,
    this.product,
    this.variant,
    this.qty = 1,
    this.warehouse,
    this.since,
  });

  final int id;

  /// Held for a bulk deal (else a cash order).
  final bool forDeal;
  final int? orderId;

  /// The cash order's uuid (`order_uuid`), to open it; null for a deal.
  final String? orderUuid;
  final String? product;
  final String? variant;
  final int qty;
  final String? warehouse;
  final DateTime? since;

  factory StockHold.fromJson(Object? data) {
    final j = Json.map(data);
    return StockHold(
      id: Json.integer(j['id']) ?? 0,
      forDeal: Json.str(j['for']) == 'bulk_deal',
      orderId: Json.integer(j['order_id']),
      orderUuid: Json.str(j['order_uuid']),
      product: Json.str(j['product']),
      variant: Json.str(j['variant']),
      qty: Json.integer(j['qty']) ?? 1,
      warehouse: Json.str(j['warehouse']),
      since: AtomDates.parse(j['since']),
    );
  }
}

/// `GET stock`: one page of products with the totals, warehouses and holds.
@immutable
class StockOverview {
  const StockOverview({
    this.items = const [],
    this.page = 1,
    this.lastPage = 1,
    this.total = 0,
    this.access = const StockAccess(),
    this.totals = const StockTotals(),
    this.warehouses = const [],
    this.held = const [],
    this.categories = const [],
    this.fromCopy = false,
  });

  final List<StockProduct> items;

  /// The "Category: All" filter's choices (`categories`): id and title.
  final List<({int id, String title})> categories;
  final int page;
  final int lastPage;
  final int total;
  final StockAccess access;
  final StockTotals totals;
  final List<StockWarehouse> warehouses;
  final List<StockHold> held;

  /// Read from the phone's copy (no signal).
  final bool fromCopy;

  bool get hasMore => page < lastPage;

  factory StockOverview.fromJson(Object? data, {bool fromCopy = false}) {
    final j = Json.map(data);
    final p = Json.map(j['pagination']);
    final page = Json.integer(p['current_page']) ?? 1;
    return StockOverview(
      items: [for (final i in Json.list(j['items'])) StockProduct.fromJson(i)],
      page: page,
      lastPage: Json.integer(p['last_page']) ?? page,
      total: Json.integer(p['total']) ?? 0,
      access: StockAccess.fromJson(j['access']),
      totals: StockTotals.fromJson(j['totals']),
      warehouses: [
        for (final w in Json.list(j['warehouses'])) StockWarehouse.fromJson(w),
      ],
      held: [for (final h in Json.list(j['held'])) StockHold.fromJson(h)],
      categories: [
        for (final c in Json.list(j['categories']))
          if (Json.integer(Json.map(c)['id']) case final id?)
            (id: id, title: Json.str(Json.map(c)['title']) ?? ''),
      ],
      fromCopy: fromCopy,
    );
  }
}

/// A unit on the product page.
@immutable
class StockUnit {
  const StockUnit({
    required this.id,
    required this.serial,
    this.variant,
    this.status = 'in_stock',
    this.warehouse,
    this.cameIn,
    this.deliveredOn,
    this.deliveredForDeal = false,
    this.deliveredForId,
  });

  final int id;
  final String serial;
  final String? variant;

  /// `in_stock`, `damaged`, `delivered` (and other removed states).
  final String status;
  final String? warehouse;
  final DateTime? cameIn;
  final DateTime? deliveredOn;
  final bool deliveredForDeal;
  final int? deliveredForId;

  bool get delivered => status == 'delivered';

  factory StockUnit.fromJson(Object? data) {
    final j = Json.map(data);
    final f = Json.map(j['delivered_for']);
    return StockUnit(
      id: Json.integer(j['id']) ?? 0,
      serial: Json.str(j['serial']) ?? '',
      variant: Json.str(j['variant']),
      status: Json.str(j['status']) ?? 'in_stock',
      warehouse: Json.str(j['warehouse']),
      cameIn: AtomDates.parse(j['came_in']),
      deliveredOn: AtomDates.parse(j['delivered_on']),
      deliveredForDeal: Json.str(f['type']) == 'bulk_deal',
      deliveredForId: Json.integer(f['id']),
    );
  }
}

/// A ledger row (`stock/history`, `recent[]`).
@immutable
class StockMove {
  const StockMove({
    required this.id,
    required this.type,
    this.date,
    this.at,
    this.label,
    this.qty = 0,
    this.product,
    this.variant,
    this.serial,
    this.warehouse,
    this.why,
    this.by,
    this.refType,
    this.refId,
  });

  final int id;

  /// `stock_in`, `opening_stock`, `purchase_in`, `sale_out`,
  /// `transfer_out`, `transfer_in`, `adjust_in`, `adjust_out`.
  final String type;
  final DateTime? date;
  final DateTime? at;
  final String? label;
  final int qty;
  final String? product;
  final String? variant;
  final String? serial;
  final String? warehouse;
  final String? why;
  final String? by;
  final String? refType;
  final int? refId;

  factory StockMove.fromJson(Object? data) {
    final j = Json.map(data);
    final ref = Json.map(j['ref']);
    return StockMove(
      id: Json.integer(j['id']) ?? 0,
      type: Json.str(j['type']) ?? '',
      date: AtomDates.parse(j['date']),
      at: AtomDates.parse(j['at']),
      label: Json.str(j['label']),
      qty: Json.integer(j['qty']) ?? 0,
      product: Json.str(j['product']),
      variant: Json.str(j['variant']),
      serial: Json.str(j['serial']),
      warehouse: Json.str(j['warehouse']),
      why: Json.str(j['why']),
      by: Json.str(j['by']),
      refType: Json.str(ref['type']),
      refId: Json.integer(ref['id']),
    );
  }
}

/// `GET stock/products/{id}`.
@immutable
class ProductStock {
  const ProductStock({
    required this.id,
    required this.title,
    this.tracking = Tracking.serial,
    this.autoPrefix,
    this.catalogueProductId,
    this.prNumber,
    this.category,
    this.websiteStatus,
    this.canChangeTracking = false,
    this.access = const StockAccess(),
    this.variants = const [],
    this.warehouses = const [],
    this.units = const [],
    this.recent = const [],
    this.delivered90 = 0,
  });

  final int id;
  final String title;
  final Tracking tracking;
  final String? autoPrefix;
  final int? catalogueProductId;
  final String? prNumber;
  final String? category;
  final String? websiteStatus;
  final bool canChangeTracking;
  final StockAccess access;
  final List<StockVariant> variants;
  final List<StockWarehouse> warehouses;
  final List<StockUnit> units;
  final List<StockMove> recent;
  final int delivered90;

  factory ProductStock.fromJson(Object? data) {
    final j = Json.map(data);
    final p = Json.map(j['product']);
    return ProductStock(
      id: Json.integer(p['id']) ?? 0,
      title: Json.str(p['title']) ?? '',
      tracking: Tracking.fromKey(p['tracking']),
      autoPrefix: Json.str(p['auto_prefix']),
      catalogueProductId: Json.integer(p['catalogue_product_id']),
      prNumber: Json.str(p['pr_number']),
      category: Json.str(p['category']),
      websiteStatus: Json.str(p['website_status']),
      canChangeTracking: Json.flag(p['can_change_tracking']),
      access: StockAccess.fromJson(j['access']),
      variants: [
        for (final v in Json.list(j['variants'])) StockVariant.fromJson(v),
      ],
      warehouses: [
        for (final w in Json.list(j['warehouses'])) StockWarehouse.fromJson(w),
      ],
      units: [for (final u in Json.list(j['units'])) StockUnit.fromJson(u)],
      recent: [for (final m in Json.list(j['recent'])) StockMove.fromJson(m)],
      delivered90: Json.integer(j['delivered_90_days']) ?? 0,
    );
  }
}

/// A variant to stock in, adjust or move (`form-options` `variants[]`).
@immutable
class VariantOption {
  const VariantOption({
    required this.id,
    required this.productId,
    required this.product,
    required this.variant,
    this.sku,
    this.tracking = Tracking.serial,
    this.autoPrefix,
    this.nextAutoNumber,
  });

  final int id;
  final int productId;
  final String product;
  final String variant;
  final String? sku;
  final Tracking tracking;
  final String? autoPrefix;
  final String? nextAutoNumber;

  /// "Zenvo 55" 4K Smart TV · Black".
  String get title => variantTitle(product, variant);

  factory VariantOption.fromJson(Object? data) {
    final j = Json.map(data);
    return VariantOption(
      id: Json.integer(j['id']) ?? 0,
      productId: Json.integer(j['product_id']) ?? 0,
      product: Json.str(j['product']) ?? '',
      variant: Json.str(j['variant']) ?? '',
      sku: Json.str(j['sku']),
      tracking: Tracking.fromKey(j['tracking']),
      autoPrefix: Json.str(j['auto_prefix']),
      nextAutoNumber: Json.str(j['next_auto_number']),
    );
  }
}

/// A unit in stock (`form-options` `in_stock_units[]`).
@immutable
class UnitOption {
  const UnitOption({
    required this.id,
    required this.serial,
    this.variantId,
    this.product,
    this.variant,
    this.warehouseId,
    this.warehouse,
  });

  /// Null for a unit stocked in on this phone and not sent yet.
  final int? id;
  final String serial;
  final int? variantId;
  final String? product;
  final String? variant;
  final int? warehouseId;
  final String? warehouse;

  String get title => variantTitle(product ?? '', variant ?? '');

  factory UnitOption.fromJson(Object? data) {
    final j = Json.map(data);
    return UnitOption(
      id: Json.integer(j['id']),
      serial: Json.str(j['serial']) ?? '',
      variantId: Json.integer(j['variant_id']),
      product: Json.str(j['product']),
      variant: Json.str(j['variant']),
      warehouseId: Json.integer(j['warehouse_id']),
      warehouse: Json.str(j['warehouse']),
    );
  }
}

/// What a unit is held for (`held_for` on `GET stock/units`, and `held[]`):
/// a cash order (with its `order_uuid`, to open it) or a bulk deal.
@immutable
class UnitHold {
  const UnitHold({required this.forType, this.orderId, this.orderUuid});

  /// `order` or `bulk_deal`.
  final String forType;
  final int? orderId;

  /// The cash order's uuid; null for a bulk deal.
  final String? orderUuid;

  static UnitHold? fromJson(Object? data) {
    if (data is! Map) return null;
    final j = Json.map(data);
    return UnitHold(
      forType: Json.str(j['for']) ?? 'order',
      orderId: Json.integer(j['order_id']),
      orderUuid: Json.str(j['order_uuid']),
    );
  }
}

/// One unit from `GET stock/units?serial=`.
@immutable
class SerialUnit {
  const SerialUnit({
    required this.id,
    required this.serial,
    required this.status,
    this.serial2,
    this.productId,
    this.product,
    this.variantId,
    this.variant,
    this.warehouseId,
    this.warehouse,
    this.cameIn,
    this.heldFor,
    this.deliveredOn,
    this.deliveredForType,
    this.deliveredForId,
  });

  final int id;
  final String serial;
  final String? serial2;

  /// `in_stock`, `delivered`, `damaged`...
  final String status;

  /// The stock product (for Product stock, 9.4).
  final int? productId;
  final String? product;
  final int? variantId;
  final String? variant;
  final int? warehouseId;
  final String? warehouse;
  final DateTime? cameIn;
  final UnitHold? heldFor;
  final DateTime? deliveredOn;
  final String? deliveredForType;
  final int? deliveredForId;

  factory SerialUnit.fromJson(Object? data) {
    final j = Json.map(data);
    final dfor = Json.map(j['delivered_for']);
    return SerialUnit(
      id: Json.integer(j['id']) ?? 0,
      serial: Json.str(j['serial']) ?? '',
      serial2: Json.str(j['serial_2']),
      status: Json.str(j['status']) ?? '',
      productId: Json.integer(j['product_id']),
      product: Json.str(j['product']),
      variantId: Json.integer(j['variant_id']),
      variant: Json.str(j['variant']),
      warehouseId: Json.integer(j['warehouse_id']),
      warehouse: Json.str(j['warehouse']),
      cameIn: AtomDates.parse(j['came_in']),
      heldFor: UnitHold.fromJson(j['held_for']),
      deliveredOn: AtomDates.parse(j['delivered_on']),
      deliveredForType: Json.str(dfor['type']),
      deliveredForId: Json.integer(dfor['id']),
    );
  }

  /// [number] is this unit's serial or its second one (IMEI 2).
  bool matches(String number) {
    final key = number.trim().toUpperCase();
    return serial.toUpperCase() == key || serial2?.toUpperCase() == key;
  }
}

/// `GET stock/units?serial=`: `exact` is false when only partial matches
/// came back.
@immutable
class SerialUnits {
  const SerialUnits({this.exact = false, this.units = const []});
  final bool exact;
  final List<SerialUnit> units;

  factory SerialUnits.fromJson(Object? data) {
    final j = Json.map(data);
    return SerialUnits(
      exact: Json.flag(j['exact']),
      units: [for (final u in Json.list(j['units'])) SerialUnit.fromJson(u)],
    );
  }
}

/// `GET stock/form-options`.
@immutable
class StockFormOptions {
  const StockFormOptions({
    this.access = const StockAccess(),
    this.variants = const [],
    this.warehouses = const [],
    this.allWarehouses = const [],
    this.inStockUnits = const [],
    this.outReasons = const [
      'Damaged',
      'Lost or stolen',
      'Recount',
      'Used as a demo',
      'Other',
    ],
    this.inReasons = const ['Recount', 'Found', 'Other'],
    this.maxStockIn = 200,
  });

  final StockAccess access;
  final List<VariantOption> variants;

  /// In this person's outlets: where stock comes in, and moves from.
  final List<StockWarehouse> warehouses;

  /// Every warehouse of the brand: where stock may move to.
  final List<StockWarehouse> allWarehouses;
  final List<UnitOption> inStockUnits;
  final List<String> outReasons;
  final List<String> inReasons;
  final int maxStockIn;

  factory StockFormOptions.fromJson(Object? data) {
    final j = Json.map(data);
    List<String> strings(Object? v) => [
      for (final s in Json.list(v)) ?Json.str(s),
    ];
    final out = strings(j['adjust_out_reasons']);
    final inn = strings(j['adjust_in_reasons']);
    return StockFormOptions(
      access: StockAccess.fromJson(j['access']),
      variants: [
        for (final v in Json.list(j['variants'])) VariantOption.fromJson(v),
      ],
      // Archived warehouses take no stock: never offered in a picker.
      warehouses: [
        for (final w in Json.list(j['warehouses']))
          if (StockWarehouse.fromJson(w) case final x when !x.archived) x,
      ],
      allWarehouses: [
        for (final w in Json.list(j['all_warehouses']))
          if (StockWarehouse.fromJson(w) case final x when !x.archived) x,
      ],
      inStockUnits: [
        for (final u in Json.list(j['in_stock_units'])) UnitOption.fromJson(u),
      ],
      outReasons: out.isEmpty ? const StockFormOptions().outReasons : out,
      inReasons: inn.isEmpty ? const StockFormOptions().inReasons : inn,
      maxStockIn: Json.integer(j['max_stock_in']) ?? 200,
    );
  }
}

/// `GET stock/warehouses`: the warehouses page.
@immutable
class WarehouseBook {
  const WarehouseBook({
    this.access = const StockAccess(),
    this.outlets = const [],
    this.inChargeChoices = const [],
    this.warehouses = const [],
  });

  final StockAccess access;
  final List<({int id, String name, bool isMain})> outlets;
  final List<({int id, String name, bool isOwner})> inChargeChoices;
  final List<StockWarehouse> warehouses;

  factory WarehouseBook.fromJson(Object? data) {
    final j = Json.map(data);
    return WarehouseBook(
      access: StockAccess.fromJson(j['access']),
      outlets: [
        for (final o in Json.list(j['outlets']))
          (
            id: Json.integer(Json.map(o)['id']) ?? 0,
            name: Json.str(Json.map(o)['name']) ?? '',
            isMain: Json.flag(Json.map(o)['is_main']),
          ),
      ],
      inChargeChoices: [
        for (final c in Json.list(j['in_charge_choices']))
          (
            id: Json.integer(Json.map(c)['id']) ?? 0,
            name: Json.str(Json.map(c)['name']) ?? '',
            isOwner: Json.flag(Json.map(c)['is_owner']),
          ),
      ],
      warehouses: [
        for (final w in Json.list(j['warehouses'])) StockWarehouse.fromJson(w),
      ],
    );
  }
}

/// "Zenvo AC · White"; a lone "Standard" variant adds nothing.
String variantTitle(String product, String variant) =>
    variant.isEmpty || variant == 'Standard' || variant == 'Default'
    ? product
    : '$product · $variant';
