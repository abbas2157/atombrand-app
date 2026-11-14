import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
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
/// package): who is signed in, Sell, Inventory, Catalogue, Business, the
/// account rows, then Log out. Each row shows only when its add-on is
/// on and the person may use it; the rest close up and nothing is shown
/// locked.
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
        ? l.menuOwner
        : (who.roleName ?? '');
    // Unread notifications, as the server counts them.
    final unread = ref.watch(unreadNoticesProvider);
    final picture = ref.watch(myProfileProvider).value?.pictureUrl;
    final workKnown = access.addons != null;

    // 12.1–12.3: Sell, Inventory, Catalogue, Business. A row the person
    // can't use is left out, never shown locked; an empty group goes.
    final groups = <(String, List<Widget>)>[
      (
        l.menuSell,
        [
          if (can(BrandPermission.ordersView))
            _MenuItem(
              icon: LucideIcons.box,
              label: l.tabOrders,
              onTap: () => context.go(V2Routes.orders),
            ),
          if (can(BrandPermission.atompayView))
            _MenuItem(
              icon: LucideIcons.creditCard,
              label: l.menuAtompay,
              onTap: () => context.go(V2Routes.atompayOrders),
            ),
          if (can(BrandPermission.bulkView))
            _MenuItem(
              icon: LucideIcons.funnel,
              label: l.tabBulk,
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
              trailing: '${session!.outlets.length}',
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
              label: l.dpDaMenuTeam,
              onTap: () => context.push(V2Routes.team),
            ),
          if (access.has(Addon.askAtom))
            _MenuItem(
              icon: LucideIcons.sparkles,
              // Ask Atom carries the AI mark, not a sparkle.
              mark: true,
              label: l.atomTitle,
              onTap: () => context.push(V2Routes.askAtom),
            ),
        ],
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
                                ?session?.brandName,
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
                  _GroupLabel(l.menuWork),
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
                AtomRowGroup(
                  children: [
                    if (owner)
                      _MenuItem(
                        icon: LucideIcons.creditCard,
                        tone: AtomTone.amber,
                        label: l.menuPlan,
                        onTap: () => context.push(V2Routes.plan),
                      ),
                    // Sync (11.2) is about this phone, not the account, so
                    // an agent working offline sees it too.
                    if (access.has(Addon.offline))
                      _MenuItem(
                        icon: LucideIcons.refreshCw,
                        tone: AtomTone.blue,
                        label: l.syncTitle,
                        badge: ref.watch(
                          syncStatusProvider.select(
                            (s) => s.waiting + s.attention,
                          ),
                        ),
                        onTap: () => context.push(V2Routes.sync),
                      ),
                    _MenuItem(
                      icon: LucideIcons.bell,
                      label: l.noticesTitle,
                      badge: unread,
                      onTap: () => context.push(V2Routes.notifications),
                    ),
                    _MenuItem(
                      icon: LucideIcons.settings,
                      tone: AtomTone.grey,
                      label: l.settingsTitle,
                      onTap: () => context.push(V2Routes.settings),
                    ),
                    if (!owner)
                      _MenuItem(
                        icon: LucideIcons.lock,
                        tone: AtomTone.grey,
                        label: l.menuMyPassword,
                        onTap: () =>
                            context.push(V2Routes.settingsStep('password')),
                      ),
                    _MenuItem(
                      icon: LucideIcons.circleQuestionMark,
                      tone: AtomTone.grey,
                      label: l.menuHelp,
                      onTap: () => context.push(V2Routes.help),
                    ),
                  ],
                ),
                const SizedBox(height: AtomSpace.s3),
                AtomRowGroup(
                  children: [
                    _MenuItem(
                      icon: LucideIcons.logIn,
                      tone: AtomTone.rose,
                      label: l.menuSignOut,
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

/// A group label in capitals ("WORK"), 14 above and 6 below.
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

/// A menu row: a 34 tile, the label, then an optional value or count. No
/// chevron, as on the board.
class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tone = AtomTone.blue,
    this.trailing,
    this.badge,
    this.danger = false,
    this.mark = false,
  });

  final IconData icon;

  /// The Ask Atom mark in place of [icon].
  final bool mark;
  final String label;
  final VoidCallback onTap;
  final AtomTone tone;
  final String? trailing;
  final int? badge;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final count = badge != null && badge! > 0 ? badge : null;
    return AtomPressable(
      onTap: onTap,
      scaleOnPress: false,
      focusRadius: BorderRadius.zero,
      semanticLabel: [label, ?trailing, if (count != null) '$count'].join(', '),
      builder: (context, pressed) => ExcludeSemantics(
        child: Container(
          color: pressed ? AtomColors.head : AtomColors.paper,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              if (mark)
                AtomAiMark(
                  size: AtomSize.menuTile,
                  radius: AtomRadius.brControl,
                  background: tone.bg,
                )
              else
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
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    trailing!,
                    textAlign: TextAlign.end,
                    style: AtomText.secondary.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (count != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    color: AtomColors.alertBadge,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: AtomText.small.copyWith(
                      color: Colors.white,
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
