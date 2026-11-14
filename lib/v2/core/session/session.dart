import 'package:flutter/foundation.dart';

import '../api/api_client.dart';

/// The brand permission keys (`BrandRole::PERMISSIONS` on the server).
///
/// The owner has every one (`["*"]` from the server). A team member has
/// what their role lists. Check with `who.can(BrandPermission.ordersView)`.
abstract final class BrandPermission {
  static const homeTotals = 'home.totals';

  static const ordersView = 'orders.view';
  static const ordersStatus = 'orders.status';
  static const ordersPayment = 'orders.payment';
  static const ordersCancel = 'orders.cancel';

  static const atompayView = 'atompay.view';

  static const bulkView = 'bulk.view';
  static const bulkQuote = 'bulk.quote';
  static const bulkDeal = 'bulk.deal';

  static const catalogueView = 'catalogue.view';
  static const catalogueEdit = 'catalogue.edit';
  static const pageEdit = 'page.edit';

  static const stockView = 'stock.view';
  static const stockChange = 'stock.change';
  static const stockManage = 'stock.manage';

  static const moneyReports = 'money.reports';
  static const moneyExport = 'money.export';

  static const teamManage = 'team.manage';

  static const all = [
    homeTotals,
    ordersView,
    ordersStatus,
    ordersPayment,
    ordersCancel,
    atompayView,
    bulkView,
    bulkQuote,
    bulkDeal,
    catalogueView,
    catalogueEdit,
    pageEdit,
    stockView,
    stockChange,
    stockManage,
    moneyReports,
    moneyExport,
    teamManage,
  ];
}

/// Who is signed in, from the login's (and `GET me`'s) `access` block:
/// `{is_owner, role, role_key, permissions, outlet_ids, must_change_password}`.
@immutable
class Who {
  const Who({
    required this.isOwner,
    this.roleKey,
    this.roleName,
    this.permissions = const {},
    this.outletIds,
    this.mustChangePassword = false,
  });

  const Who.owner() : this(isOwner: true, roleKey: 'owner', roleName: 'Owner');

  final bool isOwner;

  /// A team member's role key and name; `owner` / "Owner" for the owner.
  final String? roleKey;
  final String? roleName;

  /// Brand permission keys ([BrandPermission]). `*` means every one.
  final Set<String> permissions;

  /// The outlets a team member may work in; null is every outlet (the
  /// owner, and members of a single-outlet brand).
  final List<int>? outletIds;

  /// A team member who has not yet chosen their own password (2.4).
  final bool mustChangePassword;

  /// The owner can do everything; a team member only what the role lists.
  bool can(String permission) =>
      isOwner || permissions.contains('*') || permissions.contains(permission);

  /// True when [can] answers yes for any of [keys].
  bool canAny(Iterable<String> keys) => keys.any(can);

  /// Whether this person may work in [outletId].
  bool worksIn(int outletId) =>
      outletIds == null || outletIds!.contains(outletId);

  factory Who.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty || Json.flag(json['is_owner'])) {
      return Who(
        isOwner: true,
        roleKey: Json.str(json['role_key']) ?? 'owner',
        roleName: Json.str(json['role']) ?? 'Owner',
        permissions: const {'*'},
      );
    }
    final ids = json['outlet_ids'];
    return Who(
      isOwner: false,
      roleKey: Json.str(json['role_key']),
      roleName: Json.str(json['role']),
      permissions: {
        for (final p in Json.list(json['permissions'])) ?Json.str(p),
      },
      outletIds: ids is List ? [for (final id in ids) ?Json.integer(id)] : null,
      mustChangePassword: Json.flag(json['must_change_password']),
    );
  }

  Map<String, dynamic> toJson() => {
    'is_owner': isOwner,
    'role': roleName,
    'role_key': roleKey,
    'permissions': permissions.toList(),
    'outlet_ids': outletIds,
    'must_change_password': mustChangePassword,
  };

  Who copyWith({bool? mustChangePassword}) => Who(
    isOwner: isOwner,
    roleKey: roleKey,
    roleName: roleName,
    permissions: permissions,
    outletIds: outletIds,
    mustChangePassword: mustChangePassword ?? this.mustChangePassword,
  );
}

/// One of the brand's outlets (`GET outlets` → `outlets[]`).
@immutable
class Outlet {
  const Outlet({
    required this.id,
    required this.name,
    this.city,
    this.isMain = false,
    this.active = true,
  });

  final int id;
  final String name;
  final String? city;
  final bool isMain;
  final bool active;

  factory Outlet.fromJson(Object? data) {
    final j = Json.map(data);
    final city = j['city'];
    return Outlet(
      id: Json.integer(j['id']) ?? 0,
      name: Json.str(j['name']) ?? '',
      city: city is Map
          ? Json.str(city['title'] ?? city['name'])
          : Json.str(city),
      isMain: Json.flag(j['is_main'] ?? j['main']),
      // `status` is `open`, `paused` or `closed` (`POST outlets/{id}/status`).
      active: j['status'] == null || j['status'] == 'open',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    'is_main': isMain,
    'status': active ? 'open' : 'paused',
  };

  @override
  bool operator ==(Object other) => other is Outlet && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A signed-in session on this phone.
@immutable
class BrandSession {
  const BrandSession({
    required this.token,
    required this.userId,
    required this.name,
    required this.who,
    this.email,
    this.phone,
    this.uuid,
    this.brandId,
    this.brandName,
    this.brandLogo,
    this.brandSlug,
    this.outletId,
    this.outletName,
    this.outlets = const [],
    this.outletChosen = true,
  });

  final String token;
  final int userId;
  final String name;
  final String? email;

  /// A team member's mobile number, their sign-in name.
  final String? phone;
  final String? uuid;
  final int? brandId;

  /// The brand's title ("Zenvo Appliances").
  final String? brandName;
  final String? brandLogo;
  final String? brandSlug;
  final Who who;

  /// The outlet chosen (sent as `X-Outlet`). Null is every outlet / the
  /// brand as a whole.
  final int? outletId;
  final String? outletName;

  /// The outlets this person can switch between, as last read
  /// (`GET outlets` for the owner). Empty until read, and for a
  /// single-outlet brand.
  final List<Outlet> outlets;

  /// False for a person who has just signed in on a multi-outlet brand and
  /// not yet been through "Choose outlet" (2.6).
  final bool outletChosen;

  /// More than one outlet to choose from: the outlet switcher shows.
  bool get multiOutlet => outlets.length > 1;

  /// Reads the `data` of `POST auth/login`:
  /// `{token, user, brand, access}`.
  factory BrandSession.fromLogin(Map<String, dynamic> data) {
    final user = Json.map(data['user']);
    final brand = Json.map(data['brand']);
    final who = Who.fromJson(Json.map(data['access']));
    return BrandSession(
      token: Json.str(data['token']) ?? '',
      userId: Json.integer(user['id']) ?? 0,
      name: Json.str(user['name']) ?? '',
      email: Json.str(user['email']),
      phone: Json.str(user['phone']),
      uuid: Json.str(user['uuid']),
      brandId: Json.integer(brand['id']),
      brandName: Json.str(brand['title']),
      brandLogo: Json.str(brand['logo']),
      brandSlug: Json.str(brand['slug']),
      who: who,
      outlets: [for (final o in Json.list(data['outlets'])) Outlet.fromJson(o)],
      // Decided once the outlets are known (SessionController.setOutlets).
      outletChosen: true,
    );
  }

  factory BrandSession.fromJson(Map<String, dynamic> json) => BrandSession(
    token: Json.str(json['token']) ?? '',
    userId: Json.integer(json['user_id']) ?? 0,
    name: Json.str(json['name']) ?? '',
    email: Json.str(json['email']),
    phone: Json.str(json['phone']),
    uuid: Json.str(json['uuid']),
    brandId: Json.integer(json['brand_id']),
    brandName: Json.str(json['brand_name']),
    brandLogo: Json.str(json['brand_logo']),
    brandSlug: Json.str(json['brand_slug']),
    outletId: Json.integer(json['outlet_id']),
    outletName: Json.str(json['outlet_name']),
    outlets: [for (final o in Json.list(json['outlets'])) Outlet.fromJson(o)],
    who: Who.fromJson(Json.map(json['who'])),
    outletChosen:
        json['outlet_chosen'] == null || Json.flag(json['outlet_chosen']),
  );

  Map<String, dynamic> toJson() => {
    'token': token,
    'user_id': userId,
    'name': name,
    'email': email,
    'phone': phone,
    'uuid': uuid,
    'brand_id': brandId,
    'brand_name': brandName,
    'brand_logo': brandLogo,
    'brand_slug': brandSlug,
    'outlet_id': outletId,
    'outlet_name': outletName,
    'outlets': [for (final o in outlets) o.toJson()],
    'outlet_chosen': outletChosen,
    'who': who.toJson(),
  };

  BrandSession copyWith({
    Who? who,
    String? name,
    String? Function()? brandName,
    String? Function()? brandLogo,
    int? Function()? outletId,
    String? Function()? outletName,
    List<Outlet>? outlets,
    bool? outletChosen,
  }) => BrandSession(
    token: token,
    userId: userId,
    name: name ?? this.name,
    email: email,
    phone: phone,
    uuid: uuid,
    brandId: brandId,
    brandName: brandName != null ? brandName() : this.brandName,
    brandLogo: brandLogo != null ? brandLogo() : this.brandLogo,
    brandSlug: brandSlug,
    who: who ?? this.who,
    outletId: outletId != null ? outletId() : this.outletId,
    outletName: outletName != null ? outletName() : this.outletName,
    outlets: outlets ?? this.outlets,
    outletChosen: outletChosen ?? this.outletChosen,
  );

  /// First name, for "Good morning, Asad".
  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  /// Two letters for the avatar.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}
