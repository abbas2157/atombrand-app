import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/format/dates.dart';
import '../../../core/lock/quick_sign_in.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../auth/data/auth_repository.dart';
import '../../notifications/data/notifications_repository.dart'
    show unreadNoticesProvider;
import '../../sync/data/sync_providers.dart' show syncStatusProvider;
import '../../settings/data/settings_repository.dart'
    show appVersion, myProfileProvider;
import '../data/menu_counts.dart';

/// Asks first (19.4), revokes the token while it still works, then signs
/// the phone out whatever the answer.
Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  // With a sign-in saved behind the fingerprint, the next one can be the
  // fingerprint (2.1 → 3.0).
  final quick = ref.read(quickSignInProvider).profile;
  final me = ref.read(sessionProvider.notifier).current?.userId;
  // "Your brand's data stays safe with Atomshop" isn't true of work that
  // hasn't reached Atomshop: say how much, and that it waits for them.
  final sync = ref.read(syncStatusProvider);
  final unsent = sync.waiting + sync.attention;
  final yes = await showAtomConfirm(
    context,
    title: l.signOutConfirmTitle,
    body: unsent > 0
        ? l.signOutUnsentBody(unsent)
        : quick != null && quick.userId == me
        ? l.auth3SignOutBodyQuick
        : l.signOutConfirmBody,
    confirmLabel: l.menuSignOut,
    destructive: true,
    sideBySide: true,
  );
  if (!yes) return;
  await ref.read(authRepositoryProvider).signOut();
  await ref.read(sessionProvider.notifier).signOut();
}

/// The menu behind the avatar (12.1 owner, 12.2 team member, 12.3 basic
/// package): who is signed in, then Sell · Inventory · Catalogue ·
/// Business · Account · Help, then Log out. Each row shows only when its
/// add-on is on and the person may use it; the rest close up and nothing
/// is shown locked. The numbers beside the rows are the server's; one that
/// isn't known is left out.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider.notifier).current;
    final access = ref.watch(accessProvider);
    final who = session?.who;
    final owner = who?.isOwner ?? false;
    bool can(String p) => who?.can(p) ?? false;
    final role = who == null
        ? ''
        : who.isOwner
        ? l.menuRoleOwner
        : (who.roleName ?? '');
    // The owner's line names the brand; a team member's, where they work.
    final where = owner
        ? session?.brandName
        : (session?.outletName ?? session?.brandName);
    // Unread notifications, as the server counts them.
    final unread = ref.watch(unreadNoticesProvider);
    final picture = ref.watch(myProfileProvider).value?.pictureUrl;
    final workKnown = access.addons != null;
    final counts = ref.watch(menuCountsProvider).value;
    final teamSize = ref.watch(menuTeamSizeProvider).value;
    final sync = ref.watch(syncStatusProvider);
    final unsent = sync.waiting + sync.attention;
    final openOutlets = session?.outlets.where((o) => o.active).length ?? 0;
    final paidUntil = counts?.paidUntil;
    final requests = counts?.requestsWaiting ?? 0;

    _Badge? red(int? n) => n == null || n <= 0
        ? null
        : _Badge(n > 99 ? '99+' : '$n', _BadgeKind.red);
    _Badge? amber(int? n, [String Function(int)? say]) => n == null || n <= 0
        ? null
        : _Badge(say == null ? '$n' : say(n), _BadgeKind.amber);

    final groups = <(String, List<Widget>)>[
      (
        l.menuSell,
        [
          if (can(BrandPermission.ordersView))
            _MenuItem(
              icon: LucideIcons.box,
              label: l.tabOrders,
              badge: red(counts?.ordersToConfirm),
              onTap: () => context.go(V2Routes.orders),
            ),
          if (can(BrandPermission.atompayView))
            _MenuItem(
              icon: LucideIcons.creditCard,
              label: l.menuAtompay,
              badge: amber(counts?.atompayToHandOver),
              onTap: () => context.go(V2Routes.atompayOrders),
            ),
          if (can(BrandPermission.bulkView))
            _MenuItem(
              icon: LucideIcons.funnel,
              label: l.tabBulk,
              badge: requests > 0
                  ? _Badge(l.menuBadgeNew(requests), _BadgeKind.blue)
                  : null,
              onTap: () => context.go(V2Routes.bulk),
            ),
        ],
      ),
      // Lapsed, Inventory still opens read-only (as in Atom Seller): no
      // Stock in until the bill is paid.
      if (access.canRead(Addon.inventory))
        (
          l.menuInventory,
          [
            if (can(BrandPermission.stockView))
              _MenuItem(
                icon: LucideIcons.layoutGrid,
                tone: AtomTone.green,
                label: l.menuStock,
                badge: amber(counts?.outOfStock, l.menuBadgeOut),
                onTap: () => context.push(V2Routes.stock),
              ),
            if (can(BrandPermission.stockChange) && access.has(Addon.inventory))
              _MenuItem(
                icon: LucideIcons.plus,
                tone: AtomTone.green,
                label: l.menuStockIn,
                onTap: () => context.push(V2Routes.stockIn()),
              ),
            if (can(BrandPermission.stockManage))
              _MenuItem(
                icon: LucideIcons.building,
                tone: AtomTone.green,
                label: l.menuWarehouses,
                onTap: () => context.push(V2Routes.warehouses),
              ),
            if (can(BrandPermission.stockView))
              _MenuItem(
                icon: LucideIcons.clock,
                tone: AtomTone.green,
                label: l.menuStockHistory,
                onTap: () => context.push(V2Routes.stockHistory),
              ),
          ],
        ),
      (
        l.menuCatalogue,
        [
          if (can(BrandPermission.catalogueView))
            _MenuItem(
              icon: LucideIcons.tag,
              tone: AtomTone.amber,
              label: l.tabProducts,
              badge: amber(counts?.productsToCheck),
              onTap: () => context.go(V2Routes.products),
            ),
          if (can(BrandPermission.pageEdit))
            _MenuItem(
              icon: LucideIcons.globe,
              tone: AtomTone.amber,
              label: l.menuBrandPage,
              onTap: () => context.push(V2Routes.brandPage),
            ),
        ],
      ),
      (
        l.menuBusiness,
        [
          if (owner && (session?.multiOutlet ?? false))
            _MenuItem(
              icon: LucideIcons.building,
              tone: AtomTone.grey,
              label: l.menuOutlets,
              trailing: openOutlets > 0 ? l.menuOutletsOpen(openOutlets) : null,
              onTap: () => context.push(V2Routes.outlets),
            ),
          if (can(BrandPermission.moneyReports))
            _MenuItem(
              icon: LucideIcons.chartColumn,
              tone: AtomTone.grey,
              label: l.menuReports,
              onTap: () => context.push(V2Routes.reports),
            ),
          if (can(BrandPermission.teamManage) && access.has(Addon.team))
            _MenuItem(
              icon: LucideIcons.users,
              tone: AtomTone.grey,
              label: l.menuTeamRoles,
              trailing: teamSize == null || teamSize <= 0
                  ? null
                  : l.menuPeople(teamSize),
              onTap: () => context.push(V2Routes.team),
            ),
        ],
      ),
    ];

    final account = <Widget>[
      if (owner)
        _MenuItem(
          icon: LucideIcons.creditCard,
          tone: AtomTone.amber,
          label: l.menuPlan,
          trailing: paidUntil == null
              ? null
              : l.menuPaidUntil(AtomDates.short(paidUntil)),
          onTap: () => context.push(V2Routes.plan),
        ),
      _MenuItem(
        icon: LucideIcons.bell,
        label: l.noticesTitle,
        badge: red(unread),
        onTap: () => context.push(V2Routes.notifications),
      ),
      // Sync (10.1) is about this phone, not the account, so a team
      // member working offline sees it too.
      if (access.has(Addon.offline))
        _MenuItem(
          icon: LucideIcons.refreshCw,
          tone: AtomTone.grey,
          label: l.syncTitle,
          badge: amber(unsent),
          trailing: unsent > 0 ? null : _syncedLine(l, sync.lastSyncAt),
          onTap: () => context.push(V2Routes.sync),
        ),
      if (owner)
        _MenuItem(
          icon: LucideIcons.settings,
          tone: AtomTone.grey,
          label: l.menuProfileSettings,
          onTap: () => context.push(V2Routes.settings),
        )
      else ...[
        _MenuItem(
          icon: LucideIcons.lock,
          tone: AtomTone.grey,
          label: l.menuMyPassword,
          onTap: () => context.push(V2Routes.settingsStep('password')),
        ),
        _MenuItem(
          icon: LucideIcons.settings,
          tone: AtomTone.grey,
          label: l.settingsTitle,
          onTap: () => context.push(V2Routes.settings),
        ),
      ],
    ];

    final help = <Widget>[
      if (access.has(Addon.askAtom))
        _MenuItem(
          icon: LucideIcons.sparkle,
          label: l.atomTitle,
          onTap: () => context.push(V2Routes.askAtom),
        ),
      _MenuItem(
        icon: LucideIcons.circleQuestionMark,
        tone: AtomTone.grey,
        label: l.menuHelpSupport,
        onTap: () => context.push(V2Routes.help),
      ),
    ];

    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AtomColors.paper,
              border: Border(bottom: BorderSide(color: AtomColors.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AtomFlowBar(leading: AtomFlowLeading.close),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                  child: Row(
                    children: [
                      Container(
                        width: AtomSize.menuAvatar,
                        height: AtomSize.menuAvatar,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AtomColors.primary,
                          shape: BoxShape.circle,
                        ),
                        clipBehavior: Clip.antiAlias,
                        // The photo when there is one; the initials (which
                        // stay inside the circle at any text size) under it.
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Center(
                              child: MediaQuery.withClampedTextScaling(
                                maxScaleFactor: 1.3,
                                child: Text(
                                  session?.initials ?? '',
                                  style: AtomText.heading.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            if (picture != null && picture.isNotEmpty)
                              AtomPhoto(
                                picture,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const SizedBox.shrink(),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                session?.name ?? '',
                                // `b` 18/600 on the board.
                                style: AtomText.heading.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              [
                                role,
                                ?where,
                              ].where((s) => s.isNotEmpty).join(' · '),
                              style: AtomText.secondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(
                bottom: AtomSpace.s6 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                if (!workKnown) ...[
                  _GroupLabel(l.menuSell),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AtomSpace.gutter),
                    child: AtomLoadingCard(count: 3),
                  ),
                ] else
                  for (final (name, rows) in groups)
                    if (rows.isNotEmpty) ...[
                      _GroupLabel(name),
                      AtomRowGroup(children: rows),
                    ],
                _GroupLabel(l.menuAccount),
                AtomRowGroup(children: account),
                _GroupLabel(l.menuGroupHelp),
                AtomRowGroup(children: help),
                const SizedBox(height: AtomSpace.s3),
                AtomRowGroup(
                  children: [
                    _MenuItem(
                      icon: LucideIcons.logOut,
                      tone: AtomTone.rose,
                      label: l.menuLogOut,
                      danger: true,
                      onTap: () => confirmSignOut(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Center(
                  child: Image.asset(
                    'assets/brand/atomshop_logo.png',
                    height: AtomSize.partnerLogo,
                    semanticLabel: l.dpDaLogoLabel,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l.menuVersion(appVersion),
                    textAlign: TextAlign.center,
                    style: AtomText.small.copyWith(color: AtomColors.faint),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Synced 9:42" today, "Synced 14 Nov" before; nothing before the first.
String? _syncedLine(AppLocalizations l, DateTime? at) {
  if (at == null) return null;
  final now = AtomDates.now();
  final today =
      at.year == now.year && at.month == now.month && at.day == now.day;
  return l.menuSyncedAt(
    today ? DateFormat('h:mm').format(at) : AtomDates.short(at),
  );
}

/// The look of a row's count: red for work waiting (`.n`), amber
/// (`.n.amber`) and blue (`.n.blue`).
enum _BadgeKind { red, amber, blue }

class _Badge {
  const _Badge(this.text, this.kind);
  final String text;
  final _BadgeKind kind;
}

/// A group label in capitals ("SELL"), 14 above and 6 below.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Text(text.toUpperCase(), style: AtomText.section),
    ),
  );
}

/// A menu row: a 34 tile, the label, then an optional value or count at
/// the right edge. No chevron, as on the board.
class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tone = AtomTone.blue,
    this.trailing,
    this.badge,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AtomTone tone;
  final String? trailing;
  final _Badge? badge;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final b = badge;
    final (bg, fg) = switch (b?.kind) {
      _BadgeKind.amber => (AtomColors.amberSoft, AtomColors.amberInk),
      _BadgeKind.blue => (AtomColors.primarySoft, AtomColors.primary),
      _ => (AtomColors.alertBadge, Colors.white),
    };
    return AtomPressable(
      onTap: onTap,
      scaleOnPress: false,
      focusRadius: BorderRadius.zero,
      semanticLabel: [label, ?trailing, ?b?.text].join(', '),
      builder: (context, pressed) => ExcludeSemantics(
        child: Container(
          color: pressed ? AtomColors.head : AtomColors.paper,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: AtomSize.menuTile,
                height: AtomSize.menuTile,
                decoration: BoxDecoration(
                  color: tone.bg,
                  borderRadius: AtomRadius.brControl,
                ),
                child: Icon(icon, size: 18, color: tone.fg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AtomText.listTitle.copyWith(
                    fontWeight: FontWeight.w500,
                    color: danger ? AtomColors.rose : AtomColors.ink,
                  ),
                ),
              ),
              // The value hugs the right edge (`margin-left: auto`); it may
              // take up to under half the row before it wraps.
              if (trailing != null) ...[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * .42,
                  ),
                  child: Text(
                    trailing!,
                    textAlign: TextAlign.end,
                    style: AtomText.secondary.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (b != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Text(
                    b.text,
                    style: AtomText.small.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
