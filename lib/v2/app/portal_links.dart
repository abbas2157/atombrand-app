import 'routes.dart';

/// The app screen for a Brand Partner Portal link (`/brand-portal/...`),
/// so a link in a help answer, a notification or an Ask Atom reply opens
/// the screen here instead of the browser. Null when there is none.
String? appRouteForPortalUrl(String url) {
  final path = Uri.tryParse(url)?.path ?? '';
  bool has(String p) => path.contains('/brand-portal/$p');
  if (has('atompay')) return V2Routes.atompayOrders;
  if (has('order')) return V2Routes.orders;
  if (has('bulk') || has('deal') || has('sourcing')) return V2Routes.bulk;
  if (has('product') || has('catalogue')) return V2Routes.products;
  if (has('page')) return V2Routes.brandPage;
  if (has('stock') || has('inventory') || has('warehouse')) {
    return V2Routes.stock;
  }
  if (has('team')) return V2Routes.team;
  if (has('outlet')) return V2Routes.outlets;
  if (has('report')) return V2Routes.reports;
  if (has('billing') || has('plan')) return V2Routes.plan;
  if (has('setting')) return V2Routes.settings;
  if (has('notification')) return V2Routes.notifications;
  if (path.endsWith('/brand-portal') || has('dashboard')) return V2Routes.home;
  return null;
}
