import '../core/access/access.dart';

/// Every v2 route path, in one place, so features link to each other by
/// constant (`context.push(V2Routes.orderOf(uuid))`) and never by a typed
/// string.
///
/// The screens themselves are registered by each feature's own
/// `features/<feature>/<feature>_routes.dart`, which the router spreads in
/// (see `router.dart` and docs/v2-foundation.md). Board numbers are the
/// canvas's (https://claude.ai/artifact/RCVYzKTyubLWbff3ztFxkq).
///
/// Adding or renaming a constant here is a shared change: ask the lead.
abstract final class V2Routes {
  // ───────────────────────────────────────────── launch and way in (1–4)

  /// 1.1 / 1.2 Splash, while the stored session is read.
  static const launch = '/';

  /// 1.3 Welcome.
  static const welcome = '/welcome';

  /// 2.1 Sign in (2.2 problems are states of it).
  static const signIn = '/sign-in';

  /// 2.3 Apply to list your brand.
  static const apply = '/apply';

  /// 3.1 Fingerprint unlock, for a signed-out phone with a saved sign-in.
  static const quickSignIn = '/sign-in/fingerprint';

  /// 4.1–4.4 Forgot password → verify code → new password → done.
  static const forgot = '/forgot';
  static const forgotCode = '/forgot/code';
  static const forgotNew = '/forgot/new';
  static const forgotDone = '/forgot/done';

  /// 18.15 Signed out, back after sign-in.
  static const signedOut = '/signed-out';

  /// 2.4 Team member: choose your password.
  static const agentPassword = '/agent-password';

  /// 2.5 Set up PIN and fingerprint.
  static const setPin = '/set-pin';

  /// 2.6 Choose outlet.
  static const chooseOutlet = '/choose-outlet';

  /// 2.7 Getting ready for offline (sync feature).
  static const gettingReady = '/getting-ready';

  /// Partner terms to accept (way in).
  static const terms = '/terms';

  /// 15.8 Allow notifications (after sign-in).
  static const allowNotifications = '/allow-notifications';

  /// 16.7 First-time tour.
  static const tour = '/tour';

  // ───────────────────────────────────────────── app-wide states (13, 18)

  /// 18.16 Maintenance.
  static const maintenance = '/maintenance';

  /// 18.16 Update needed.
  static const updateRequired = '/update';

  /// 13.6 Package removed.
  static const stateRemoved = '/state/removed';

  /// No plan at all.
  static const stateNoPlan = '/state/no-plan';

  /// 13.3 Not in your role.
  static const notInRole = '/state/not-in-role';

  /// 13.5 Restricted by Atomshop.
  static const restricted = '/state/restricted';

  // ───────────────────────────────────────────── the four tabs

  /// 5.1–5.5 Home (owner, team member, offline, first day, basic).
  static const home = '/home';

  /// 6.1 Orders: cash orders. `?tab=atompay` opens 6.8 AtomPay orders.
  static const orders = '/orders';

  /// 7.1 Bulk deals. `?tab=sellers|website|deals`.
  static const bulk = '/bulk';

  /// 8.1 Products.
  static const products = '/products';

  /// The Products tab on one status tile (`ProductStatus`: `Published`,
  /// `Pending`, `Out of Stock`, `On hold`).
  static String productsWith({String? status}) =>
      _withQuery(products, {'status': status});

  /// The tab roots, in the bar's order (the ＋ between Orders and Bulk
  /// deals opens [quickActions], not a tab).
  static const tabs = [home, orders, bulk, products];

  // ───────────────────────────────────────────── home (5)

  /// 5.6 Quick actions (the ＋).
  static const quickActions = '/quick-actions';

  /// 5.7 Outlet switcher.
  static const outletSwitcher = '/switch-outlet';

  /// 5.8 Search.
  static const search = '/search';

  // ───────────────────────────────────────────── orders (6)

  /// 6.8 Orders: AtomPay orders (the Orders tab's second tab).
  static const atompayOrders = '$orders?tab=atompay';

  /// The Orders tab with a filter: [atompay] opens AtomPay orders; [status]
  /// (an `OrderStage` key such as `Pending`) and [payment] (`unpaid`,
  /// `part`, `paid`) filter Cash orders (a Home task, a Home tile).
  static String ordersWith({
    bool atompay = false,
    String? status,
    String? payment,
  }) => _withQuery(orders, {
    'tab': atompay ? 'atompay' : null,
    'status': status,
    'payment': payment,
  });

  /// 6.2 Cash order.
  static const orderPattern = '/order/:uuid';
  static String orderOf(String uuid) => '/order/$uuid';

  /// 6.3 Mark as delivered.
  static String orderDeliverOf(String uuid) => '/order/$uuid/deliver';

  /// 6.4 Record a payment.
  static String orderPaymentOf(String uuid) => '/order/$uuid/payment';

  /// 6.5 Cancel this order.
  static String orderCancelOf(String uuid) => '/order/$uuid/cancel';

  /// 6.6 Move to another outlet.
  static String orderMoveOf(String uuid) => '/order/$uuid/move';

  /// 6.7 Receipt.
  static String orderReceiptOf(String uuid) => '/order/$uuid/receipt';

  // ───────────────────────────────────────────── AtomPay (6.8–6.10)

  /// 6.9 AtomPay order.
  static const atompayPattern = '/atompay/:uuid';
  static String atompayOf(String uuid) => '/atompay/$uuid';

  /// 6.10 Hand over the unit.
  static String atompayHandoverOf(String uuid) => '/atompay/$uuid/handover';

  // ───────────────────────────────────────────── bulk deals (7)

  /// 7.1 with a tab chosen: `sellers`, `website` or `deals`.
  static String bulkTab(String tab) => '$bulk?tab=$tab';

  /// 7.2 Seller request (sourcing).
  static const sellerRequestPattern = '/seller-request/:id';
  static String sellerRequestOf(int id) => '/seller-request/$id';

  /// 7.4 Send a quote, for a seller request.
  static String sellerRequestQuoteOf(int id) => '/seller-request/$id/quote';

  /// 7.3 Website bulk request.
  static const bulkRequestPattern = '/bulk-request/:id';
  static String bulkRequestOf(int id) => '/bulk-request/$id';

  /// 7.4 Send a quote.
  static String bulkQuoteOf(int id) => '/bulk-request/$id/quote';

  /// 7.5 Update status.
  static String bulkStatusOf(int id) => '/bulk-request/$id/status';

  /// 7.6 They said yes: make a deal.
  static String bulkWonOf(int id) => '/bulk-request/$id/deal';

  /// 7.7 Deal.
  static const dealPattern = '/deal/:id';
  static String dealOf(int id) => '/deal/$id';

  /// 7.8 Deliver units.
  static String dealDeliverOf(int id) => '/deal/$id/deliver';

  /// 7.9 Record payment: deal.
  static String dealPaymentOf(int id) => '/deal/$id/payment';

  // ───────────────────────────────────────────── catalogue (8)

  /// 8.2 Add product.
  static const productNew = '/product/new';

  /// 8.2 Edit product.
  static const productEditPattern = '/product/:id/edit';
  static String productEditOf(int id) => '/product/$id/edit';

  /// 8.3 Brand page.
  static const brandPage = '/brand-page';

  // ───────────────────────────────────────────── stock (9, Inventory add-on)

  /// 9.1 / 9.2 Stock.
  static const stock = '/stock';

  /// 9.3 Stock list. [show] filters (`all`, `low`, `out`…).
  static String stockList({String show = 'all'}) => '/stock/list?show=$show';

  /// 9.4 Product stock.
  static String productStockOf(int productId) => '/stock/product/$productId';

  /// 9.5 Stock in, optionally for a product or a scanned serial.
  static String stockIn({int? productId, String? serial}) => _withQuery(
    '/stock/in',
    {'product': productId?.toString(), 'serial': serial},
  );

  /// 9.6 Move stock.
  static const stockMove = '/stock/move';

  /// 9.6 Move stock, starting from a unit ([serial]) or a product.
  static String moveStock({String? serial, int? productId}) => _withQuery(
    stockMove,
    {'serial': serial, 'product': productId?.toString()},
  );

  /// 9.7 Adjust stock.
  static const stockAdjust = '/stock/adjust';

  /// 9.7 Adjust stock: a unit going out ([serial]), or, with [found], a unit
  /// found and coming back in; optionally for a product.
  static String adjustStock({
    String? serial,
    int? productId,
    bool found = false,
  }) => _withQuery(stockAdjust, {
    'dir': found ? 'in' : null,
    'serial': serial,
    'product': productId?.toString(),
  });

  /// 9.8 Scan a serial.
  static const scanSerial = '/stock/scan';

  /// 9.9 Stock history.
  static const stockHistory = '/stock/history';

  /// 9.9 Stock history of one product.
  static String stockHistoryOf({int? productId}) =>
      _withQuery(stockHistory, {'product_id': productId?.toString()});

  /// 9.10 Warehouses.
  static const warehouses = '/stock/warehouses';

  // ───────────────────────────────────────────── menu (12) and its screens

  /// 12.1–12.3 Menu (from the avatar).
  static const menu = '/menu';

  // Team (11.1–11.6, owner / team.manage, Team add-on).
  static const team = '/menu/team';
  static const teamAdd = '/menu/team/add';

  /// 11.3 Team member added (the new member is the route's `extra`).
  static const teamAdded = '/menu/team/added';
  static String teamMemberOf(int id) => '/menu/team/$id';
  static const teamRoles = '/menu/team/roles';

  /// 11.6 A new role, or [roleId]'s.
  static String roleEdit({int? roleId}) =>
      '/menu/team/roles/edit${roleId == null ? '' : '?id=$roleId'}';

  // Outlets (11.7–11.9, owner).
  static const outlets = '/menu/outlets';
  static const outletAdd = '/menu/outlets/add';
  static String outletOf(int id) => '/menu/outlets/$id';

  // Account: plan & billing (12.6–12.8), reports (12.4–12.5), profile and
  // shop settings.
  static const plan = '/menu/plan';

  /// 12.7 Switch an add-on on.
  static String addonSwitchOf(Addon addon) => '/menu/plan/addon/${addon.key}';

  /// 12.8 I've paid. [bill] is the bill number, kept in the address so the
  /// screen finds its bill again after Android restarts the app behind the
  /// photo picker.
  static String paidOf({String? bill}) => bill == null
      ? '/menu/plan/paid'
      : '/menu/plan/paid?bill=${Uri.encodeQueryComponent(bill)}';
  static const reports = '/menu/reports';
  static String reportOf(String name) => '/menu/reports/$name';

  /// 16.1 Edit your profile.
  static const profile = '/menu/profile';

  /// 18.2 Shop settings (the brand's own settings, owner).
  static const shopSettings = '/menu/shop-settings';

  /// 18.12 Daily summary.
  static const dailySummary = '/menu/daily-summary';

  /// 18.10 Rate Brand Partner.
  static const rateApp = '/menu/rate';

  // Ask Atom (12.10–12.12, Ask Atom add-on).
  static const askAtom = '/menu/ask-atom';

  // Sync centre (10.x, Offline add-on).
  static const sync = '/menu/sync';
  static const syncWaiting = '/menu/sync/waiting';
  static const syncAttention = '/menu/sync/attention';
  static const syncClash = '/menu/sync/clash';

  /// 10.4 Fix a serial clash for one outbox action.
  static String syncClashOf(String actionId) =>
      _withQuery(syncClash, {'id': actionId});
  static const syncRunning = '/menu/sync/running';
  static const syncUpdate = '/menu/sync/update';
  static const syncPhones = '/menu/sync/phones';

  // Notifications (15.x).
  static const notifications = '/notifications';

  /// Notifications showing only Atomshop's messages.
  static const recommendations = '/notifications?only=atomshop';
  static const notificationSettings = '/notifications/settings';
  static const notificationMessage = '/notifications/message';

  // Help (17.x).
  static const help = '/menu/help';
  static const faqs = '/menu/help/faqs';

  /// 17.3 One answer; the answer is the route's `extra`.
  static const faqAnswer = '/menu/help/faqs/answer';
  static const support = '/menu/help/support';
  static const supportThread = '/menu/help/support/thread';
  static const ecosystem = '/menu/help/ecosystem';
  static const privacy = '/menu/help/privacy';

  /// 17.5 The terms to read (not the way-in accept screen).
  static const termsRead = '/menu/help/terms';

  // Settings (18.x).
  static const settings = '/menu/settings';

  /// [step] is `password`, `language`, `devices`, `feedback`, `data`,
  /// `close-account`, `security`, `pin`, `permissions` or `storage`.
  static String settingsStep(String step) => '/menu/settings/$step';

  // ───────────────────────────────────────────── rules

  /// [path] with the [query] values that are set, encoded; no `?` when
  /// none are.
  static String _withQuery(String path, Map<String, String?> query) {
    final set = {
      for (final e in query.entries)
        if (e.value case final v? when v.isNotEmpty) e.key: v,
    };
    return set.isEmpty
        ? path
        : Uri(path: path, queryParameters: set).toString();
  }

  /// Routes that need no session.
  static bool isPublic(String path) =>
      path == welcome ||
      path == signIn ||
      path == apply ||
      path == quickSignIn ||
      path == signedOut ||
      path == forgot ||
      path.startsWith('$forgot/');

  /// The steps on the way in after signing in. Once nothing is left to do,
  /// being on one of them moves the person on.
  static const wayIn = {
    launch,
    agentPassword,
    setPin,
    chooseOutlet,
    terms,
    tour,
    gettingReady,
  };

  /// While the package is removed (or there is none), only these open.
  static const openWithoutPackage = [plan, profile];
}

/// Who may open a route, beyond being signed in.
class RouteRule {
  const RouteRule(
    this.prefix, {
    this.ownerOnly = false,
    this.addon,
    this.readWhenLapsed = false,
    this.anyOf = const [],
  });

  final String prefix;

  /// Team members never see Plan & billing, Outlets or Shop settings.
  final bool ownerOnly;

  /// The add-on the route needs. When it is off, the route goes Home.
  final Addon? addon;

  /// A lapsed [addon] still opens its screens, read-only (the bill went
  /// unpaid: the brand can still see its stock, not change it).
  final bool readWhenLapsed;

  /// A team member needs at least one of these permissions
  /// (`BrandPermission`); empty means anyone signed in.
  final List<String> anyOf;

  bool matches(String path) => path == prefix || path.startsWith('$prefix/');
}

/// Route rules, most specific first. The server refuses on its own too;
/// these keep the person from landing on a screen that can only say no.
const routeRules = [
  RouteRule('/menu/plan', ownerOnly: true),
  RouteRule('/menu/outlets', ownerOnly: true),
  RouteRule('/menu/shop-settings', ownerOnly: true),
  RouteRule('/menu/settings/close-account', ownerOnly: true),
  RouteRule('/menu/team', addon: Addon.team, anyOf: ['team.manage']),
  RouteRule('/menu/reports', anyOf: ['money.reports']),
  RouteRule('/menu/ask-atom', addon: Addon.askAtom),
  RouteRule('/menu/sync', addon: Addon.offline),
  RouteRule(
    '/stock',
    addon: Addon.inventory,
    readWhenLapsed: true,
    anyOf: ['stock.view'],
  ),
  RouteRule('/atompay', anyOf: ['atompay.view']),
  RouteRule('/order', anyOf: ['orders.view']),
  RouteRule('/seller-request', anyOf: ['bulk.view']),
  RouteRule('/bulk-request', anyOf: ['bulk.view']),
  RouteRule('/deal', anyOf: ['bulk.view']),
  RouteRule('/product', anyOf: ['catalogue.view']),
  RouteRule('/brand-page', anyOf: ['page.edit']),
];
