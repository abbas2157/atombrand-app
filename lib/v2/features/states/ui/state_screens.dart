import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/dates.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../auth/ui/sign_in_screen.dart' show atomshopSupportPhone;
import '../../menu/ui/menu_screen.dart' show confirmSignOut;
import '../../../core/update/update_policy.dart';
import '../../../core/update/updates_controller.dart';
import '../../sync/data/sync_providers.dart';

/// The whole-screen states from row 14 and 19: signed out, maintenance,
/// package removed or none, not in your role, not found, restricted, and
/// the "No internet" body (11.9).

void _openWhatsApp() => launchUrl(
  Uri.parse('https://wa.me/${atomshopSupportPhone.substring(1)}'),
  mode: LaunchMode.externalApplication,
);

/// A centred state body: an icon tile, a title, a paragraph, then extra.
class _Centred extends StatelessWidget {
  const _Centred({
    required this.icon,
    required this.title,
    required this.body,
    this.extra = const [],
  });

  final Widget icon;
  final String title;
  final String body;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AtomSize.formMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 12),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AtomText.successTitle,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: AtomText.body.copyWith(
                  fontSize: 15,
                  height: 1.5,
                  color: AtomColors.muted,
                ),
              ),
              for (final w in extra) ...[const SizedBox(height: 12), w],
            ],
          ),
        ),
      ),
    );
  }
}

Widget _iconTile(IconData icon, AtomTone tone, {double size = 72}) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(
    color: tone.bg,
    borderRadius: const BorderRadius.all(Radius.circular(20)),
  ),
  child: Icon(icon, size: size * 0.45, color: tone.fg),
);

/// Sign out, under the buttons of every full-page error: a page that
/// stands in front of the app (maintenance, too old, no package,
/// restricted, offline ended…) must never leave the person with no way to
/// hand the phone to someone else. The usual confirm, which says how much
/// unsent work waits on the phone.
class StateSignOut extends ConsumerWidget {
  const StateSignOut({super.key, this.dark = false});

  /// On a navy page.
  final bool dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return AtomButton(
      label: l.menuSignOut,
      kind: dark ? AtomButtonKind.ghostDark : AtomButtonKind.outline,
      compact: true,
      onPressed: () => confirmSignOut(context, ref),
    );
  }
}

/// Bottom buttons, above the safe area.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.children,
    this.bottom = AtomSpace.s5,
    this.horizontal = AtomSpace.gutter,
  });
  final List<Widget> children;

  /// Space under the last one, above the safe area (the boards' 30 or 34).
  final double bottom;
  final double horizontal;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      horizontal,
      AtomSpace.s4,
      horizontal,
      bottom + MediaQuery.paddingOf(context).bottom,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AtomSize.formMaxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              children[i],
            ],
          ],
        ),
      ),
    ),
  );
}

/// A page's column (content, then the buttons at the bottom) that fills
/// the screen, and scrolls as a whole when large text makes it taller.
class _FitOrScroll extends StatelessWidget {
  const _FitOrScroll({
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            crossAxisAlignment: crossAxisAlignment,
            children: children,
          ),
        ),
      ],
    );
  }
}

/// Signed out (19.15). Any 401 lands here with the stack cleared, and the
/// screen the person was on is reopened after they sign in.
/// The name of the screen at [path], for 18.15's "After you sign in you go
/// back to …"; null when it has no name worth saying.
String? signedOutPlace(AppLocalizations l, String? path) {
  if (path == null) return null;
  bool under(String root) => path == root || path.startsWith('$root/');
  return switch (path) {
    V2Routes.home => l.tabHome,
    V2Routes.orders => l.tabOrders,
    V2Routes.bulk => l.tabBulk,
    V2Routes.products => l.tabProducts,
    V2Routes.search => l.statesPlaceSearch,
    _ when path.startsWith('/order/') => l.statesPlaceOrder,
    _ when path.startsWith('/atompay/') => l.statesPlaceAtompay,
    _ when path.startsWith('/deal/') => l.statesPlaceDeal,
    _
        when path.startsWith('/bulk-request/') ||
            path.startsWith('/seller-request/') =>
      l.statesPlaceBulkRequest,
    _ when path.startsWith('/product/') => l.statesPlaceProduct,
    _ when under(V2Routes.brandPage) => l.statesPlaceBrandPage,
    _ when under(V2Routes.stock) => l.statesPlaceStock,
    _ when under(V2Routes.team) => l.statesPlaceTeam,
    _ when under(V2Routes.outlets) => l.statesPlaceOutlets,
    _ when under(V2Routes.plan) => l.statesPlacePlan,
    _ when under(V2Routes.reports) => l.statesPlaceReports,
    _ when under(V2Routes.askAtom) => l.statesPlaceAskAtom,
    _ when under(V2Routes.sync) => l.statesPlaceSync,
    _ when under(V2Routes.help) => l.statesPlaceHelp,
    _ when under(V2Routes.settings) => l.statesPlaceSettings,
    _ when under(V2Routes.notifications) => l.statesPlaceNotifications,
    _ when under(V2Routes.menu) => l.statesPlaceMenu,
    _ => null,
  };
}

class SignedOutScreen extends ConsumerWidget {
  const SignedOutScreen({super.key, this.from});

  final String? from;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(sessionProvider);
    final expired = s is SignedOut && s.reason == SignOutReason.expired;
    final signIn = from == null
        ? V2Routes.signIn
        : Uri(
            path: V2Routes.signIn,
            queryParameters: {'from': from},
          ).toString();

    final path = from == null ? null : Uri.tryParse(from!)?.path;
    // The screen to come back to, named (18.15 "…go back to **Orders**").
    final place = signedOutPlace(l, path);
    // Changes saved offline wait in the outbox and go after sign-in.
    final waiting = ref.watch(syncStatusProvider.select((s) => s.waiting));

    return Scaffold(
      // `.scr.home`: the grey app background.
      backgroundColor: AtomColors.surface,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.paddingOf(context).top),
          // The logo, top left (`padding: 8px 16px 0`, 26 tall).
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Image.asset(
                'assets/brand/atomshop_logo.png',
                height: 26,
                semanticLabel: 'Atomshop.pk',
              ),
            ),
          ),
          Expanded(
            child: _Centred(
              icon: _iconTile(LucideIcons.lock, AtomTone.blue),
              title: expired ? l.signedOutTitle : l.signedOutChosenTitle,
              body: expired ? l.signedOutBody : l.signedOutChosenBody,
              extra: [
                if (waiting > 0) ...[
                  AtomNote(
                    kind: AtomNoteKind.warning,
                    iconless: true,
                    message: l.statesKeptOnPhone(waiting),
                    bold: [l.statesKeptOnPhoneBold(waiting)],
                  ),
                  const SizedBox(height: 12),
                ],
                if (from != null)
                  _BackTo(
                    text: place == null
                        ? l.signedOutReturn
                        : l.auth2SignedOutPlace(place),
                    bold: place,
                  ),
              ],
            ),
          ),
          _Actions(
            bottom: 30,
            children: [
              AtomButton(
                label: l.signedOutSignIn,
                onPressed: () => context.go(signIn),
              ),
              AtomButton(
                label: l.signedOutForgot,
                kind: AtomButtonKind.outline,
                onPressed: () => context.push(V2Routes.forgot),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "After you sign in you go back to **Collect**" (`.back-to`).
class _BackTo extends StatelessWidget {
  const _BackTo({required this.text, this.bold});
  final String text;
  final String? bold;

  @override
  Widget build(BuildContext context) {
    final at = bold == null ? -1 : text.lastIndexOf(bold!);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AtomColors.head,
        borderRadius: AtomRadius.brControl,
        border: Border.all(color: AtomColors.line),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.arrowRightToLine,
            size: 18,
            color: AtomColors.chevron,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AtomText.secondary.copyWith(color: AtomColors.text),
                children: at < 0
                    ? [TextSpan(text: text)]
                    : [
                        TextSpan(text: text.substring(0, at)),
                        TextSpan(
                          text: bold,
                          style: const TextStyle(
                            color: AtomColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: text.substring(at + bold!.length)),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The navy top of 19.16 (`.top`): the mark on a 72 tile, a 24 title and
/// the 15 line under it, painted under the status bar.
class _NavyTop extends StatelessWidget {
  const _NavyTop({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      color: AtomColors.nav,
      padding: EdgeInsets.fromLTRB(20, top + 24, 20, 28),
      child: Column(
        children: [
          const AtomBrandTile(size: 72),
          const SizedBox(height: 18),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AtomText.successTitle.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AtomText.body.copyWith(
              fontSize: 15,
              height: 1.5,
              color: AtomColors.navText,
            ),
          ),
        ],
      ),
    );
  }
}

/// 19.16's page: the navy top, the card of what still works, then the
/// buttons 30 above the bottom.
class _NavyTopPage extends StatelessWidget {
  const _NavyTopPage({
    required this.title,
    required this.body,
    required this.lines,
    required this.actions,
  });

  final String title;
  final String body;
  final List<AtomInfoLine> lines;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AtomColors.surface,
        body: _FitOrScroll(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _NavyTop(title: title, body: body),
                    Padding(
                      padding: const EdgeInsets.all(AtomSpace.gutter),
                      child: AtomInfoCard(lines: lines),
                    ),
                  ],
                ),
              ),
            ),
            _Actions(bottom: 30, children: actions),
          ],
        ),
      ),
    );
  }
}

/// Maintenance (19.16): a 503. The only root while it lasts; Back closes
/// the app. Without the Offline add-on nothing can be done meanwhile, so
/// the board's offline rows and its "sent when back" note are left out.
class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return _NavyTopPage(
      title: l.maintenanceTitle,
      body: l.dpDbMaintenanceBody,
      lines: [
        AtomInfoLine(
          label: l.maintenanceData,
          value: l.maintenanceDataSafe,
          valueColor: AtomColors.green,
        ),
        AtomInfoLine(
          label: l.maintenanceCustomers,
          value: l.maintenanceCustomersOk,
          valueColor: AtomColors.green,
        ),
        AtomInfoLine(
          label: l.maintenanceUsing,
          value: l.maintenanceUsingWait,
          valueColor: AtomColors.amberInk,
        ),
      ],
      actions: [
        AtomButton(
          label: l.commonTryAgain,
          kind: AtomButtonKind.outline,
          onPressed: () {
            ref.read(accessProvider.notifier)
              ..clearMaintenance()
              ..refresh();
          },
        ),
        const StateSignOut(),
      ],
    );
  }
}

/// Update required (19.16, update variant): this version is below the
/// server's minimum. The only root while it lasts; Update opens the store.
class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final update = ref.watch(updatesProvider);
    final sync = ref.watch(syncStatusProvider);
    final unsent = sync.waiting + sync.attention;
    final pulled = update.level == UpdateLevel.blocked;
    final ios =
        update.installed?.platform == 'ios' ||
        (update.installed == null &&
            Theme.of(context).platform == TargetPlatform.iOS);
    final version = update.policy?.latestVersion;
    return _NavyTopPage(
      title: pulled ? l.updatePulledTitle : l.dpDbUpdateTitle,
      body: pulled ? l.updatePulledBody : l.dpDbUpdateBody,
      lines: [
        // Unsent offline work survives the update (same app, same files)
        // and goes up after it: say so, so nobody reinstalls to "fix" it.
        if (unsent > 0)
          AtomInfoLine(
            label: l.updateWaitingLabel,
            value: l.updateWaitingValue(unsent),
            valueColor: AtomColors.green,
          )
        else
          AtomInfoLine(
            label: l.maintenanceData,
            value: l.maintenanceDataSafe,
            valueColor: AtomColors.green,
          ),
        if (version != null)
          AtomInfoLine(label: l.updateNewVersion, value: version)
        else
          AtomInfoLine(
            label: l.maintenanceUsing,
            value: l.dpDbUpdateUsing,
            valueColor: AtomColors.amberInk,
          ),
      ],
      actions: [
        AtomButton(
          label: ios ? l.updateButtonIos : l.dpDbUpdateButton,
          // Android: Google Play's own update, in the app; the store page
          // when Play can't (installed outside Play). iPhone: the App Store.
          onPressed: () => ref.read(updatesProvider.notifier).updateNow(),
        ),
        AtomButton(
          label: l.commonTryAgain,
          kind: AtomButtonKind.outline,
          onPressed: () async {
            await ref.read(updatesProvider.notifier).check(force: true);
            await ref.read(accessProvider.notifier).checkVersion();
          },
        ),
        const StateSignOut(),
      ],
    );
  }
}

/// Package removed (14.6) and no package at all. Only My plan, billing and
/// the profile open; Back can't get past it.
class NoPackageScreen extends ConsumerWidget {
  const NoPackageScreen({super.key, required this.removed});

  final bool removed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider.notifier).current;
    final owner = session?.who.isOwner ?? false;
    final business = session?.brandName ?? l.appName;
    final top = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AtomColors.nav,
        body: _FitOrScroll(
          children: [
            SizedBox(height: top),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const AtomBrandTile(
                        size: AtomSize.stateTile,
                        shadow: true,
                      ),
                      const SizedBox(height: 14),
                      Semantics(
                        header: true,
                        child: Text(
                          removed ? l.removedTitle : l.noPlanTitle,
                          textAlign: TextAlign.center,
                          style: AtomText.successTitle.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        removed ? l.removedBody(business) : l.noPlanBody,
                        textAlign: TextAlign.center,
                        style: AtomText.body.copyWith(
                          fontSize: 15,
                          height: 1.5,
                          color: AtomColors.navText,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AtomInfoCard(
                        onDark: true,
                        lines: [
                          AtomInfoLine(
                            onDark: true,
                            label: l.removedOpenNow,
                            value: l.removedOpenNowValue,
                          ),
                          AtomInfoLine(
                            onDark: true,
                            label: l.removedAfterPaying,
                            value: l.removedAfterPayingValue,
                          ),
                        ],
                      ),
                      if (!owner) ...[
                        const SizedBox(height: 14),
                        AtomNote(
                          kind: AtomNoteKind.info,
                          message: l.removedAgentNote,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                AtomSpace.s4,
                20,
                34 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (owner) ...[
                    AtomButton(
                      label: l.removedSeePackages,
                      kind: AtomButtonKind.light,
                      onPressed: () => context.push(V2Routes.plan),
                    ),
                    const SizedBox(height: 10),
                  ],
                  AtomButton(
                    label: l.removedTalk,
                    kind: AtomButtonKind.ghostDark,
                    onPressed: _openWhatsApp,
                  ),
                  const SizedBox(height: 10),
                  const StateSignOut(dark: true),
                  const SizedBox(height: 16),
                  const Center(child: AtomStepsStripe()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What an agent tried that the role doesn't open (14.3's three cases).
enum NotInRoleTried {
  order('order'),
  stock('stock'),
  discount('discount');

  const NotInRoleTried(this.key);
  final String key;

  static NotInRoleTried? fromKey(String? key) {
    for (final t in values) {
      if (t.key == key) return t;
    }
    return null;
  }
}

/// "You can": what a role's rights cover, in words, the way 13.3 reads
/// ("Orders, payments, AtomPay; see products and stock"): what it may
/// change first, then what it may only see.
String roleCanSummary(AppLocalizations l, Set<String> permissions) {
  if (permissions.contains('*')) return l.statesCanEverything;
  bool has(String p) => permissions.contains(p);
  bool any(String prefix) => permissions.any((p) => p.startsWith(prefix));
  final edit = <String>[
    if (any('orders.')) l.dpDbCanOrders,
    if (has('orders.payment')) l.statesCanPayments,
    if (any('atompay.')) l.statesCanAtompay,
    if (any('bulk.')) l.dpDbCanLeads,
    if (has('catalogue.edit') || has('page.edit')) l.dpDbCanCustomers,
    if (has('stock.change') || has('stock.manage')) l.dpDbCanStock,
    if (any('money.')) l.dpDbCanReports,
    if (has('team.manage')) l.statesCanTeam,
  ];
  final see = <String>[
    if (has('catalogue.view') && !edit.contains(l.dpDbCanCustomers))
      l.dpDbCanCustomers,
    if (has('stock.view') && !edit.contains(l.dpDbCanStock)) l.dpDbCanStock,
  ];
  String and(List<String> parts) => parts.length == 1
      ? parts.first
      : l.dpDbCanList(
          parts.sublist(0, parts.length - 1).join(', '),
          parts.last,
        );
  final text = [
    if (edit.isNotEmpty) edit.join(', '),
    if (see.isNotEmpty) l.statesCanSee(and(see)),
  ].join('; ');
  if (text.isEmpty) return '';
  return text[0].toUpperCase() + text.substring(1);
}

/// Shows "Not in your role" (13.3) as a sheet over the current screen:
/// what any 403 on an action shows. [failure] is the refusal, sent to Ask
/// Atom with "Ask Atom why".
Future<void> showNotInRoleSheet(
  BuildContext context, {
  NotInRoleTried? tried,
  ApiFailure? failure,
}) {
  return showAtomSheet<void>(
    context,
    builder: (sheet) => _NotInRoleSheet(
      tried: tried,
      failure: failure,
      onClose: () => Navigator.of(sheet).pop(),
    ),
  );
}

/// 13.3 in place of a screen's content, when loading it was refused with a
/// 403 (a role changed meanwhile, or a shared link): the same words, role
/// and "You can" as the sheet, and Ask Atom why. `AtomErrorState(error:)`
/// shows it for any 403 ([registerRoleRefusal]).
class NotInRoleBody extends StatelessWidget {
  const NotInRoleBody({super.key, this.failure});

  final ApiFailure? failure;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: _NotInRoleSheet(tried: null, failure: failure, onClose: null),
      ),
    ),
  );
}

/// Makes every `AtomErrorState(error: failure)` show [NotInRoleBody] for a
/// 403. Called once, when the router reads [stateRoutes].
void registerRoleRefusal() {
  AtomErrorState.roleRefusal = (_, failure) => NotInRoleBody(failure: failure);
}

/// "Ask Atom why": Ask Atom with the refusal, so it explains it.
void _askAtomWhy(BuildContext context, ApiFailure? failure) {
  final l = AppLocalizations.of(context);
  final error = failure?.message;
  GoRouter.of(context).push(
    Uri(
      path: V2Routes.askAtom,
      queryParameters: {
        'q': l.statesAskWhyQuestion,
        if (error != null && error.isNotEmpty) 'error': error,
      },
    ).toString(),
  );
}

/// 14.3's sheet: the grey person tile, what isn't in the role, the role and
/// what it can do, then OK and Ask Atom why.
class _NotInRoleSheet extends ConsumerWidget {
  const _NotInRoleSheet({
    required this.tried,
    required this.onClose,
    this.failure,
  });

  final NotInRoleTried? tried;

  /// OK; null in place of a screen's content (no OK, nothing to close).
  final VoidCallback? onClose;
  final ApiFailure? failure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final who = ref.watch(sessionProvider.notifier).current?.who;
    final atom =
        ref.watch(accessProvider).addons?.contains(Addon.askAtom) ?? false;
    final (title, body) = switch (tried) {
      NotInRoleTried.order => (l.dpDbRoleOrderTitle, l.dpDbRoleOrderBody),
      NotInRoleTried.stock => (l.dpDbRoleStockTitle, l.dpDbRoleStockBody),
      NotInRoleTried.discount => (
        l.dpDbRoleDiscountTitle,
        l.dpDbRoleDiscountBody,
      ),
      null => (l.notInRoleTitle, l.notInRoleBody),
    };
    final can = who == null ? '' : roleCanSummary(l, who.permissions);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ExcludeSemantics(
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AtomColors.surface,
                  borderRadius: AtomRadius.brCard,
                ),
                child: const Icon(
                  LucideIcons.user,
                  size: 24,
                  color: AtomColors.muted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Semantics(header: true, child: Text(title, style: AtomText.heading)),
          const SizedBox(height: AtomSpace.s1),
          Text(body, style: AtomText.secondary.copyWith(height: 1.45)),
          if (who?.roleName != null || can.isNotEmpty) ...[
            const SizedBox(height: 14),
            AtomInfoCard(
              lines: [
                if (who?.roleName != null)
                  AtomInfoLine(
                    label: l.notInRoleYourRole,
                    value: who!.roleName!,
                  ),
                if (can.isNotEmpty)
                  AtomInfoLine(label: l.dpDbRoleYouCan, value: can),
              ],
            ),
          ],
          if (onClose != null) ...[
            const SizedBox(height: 14),
            AtomButtonPair(
              first: AtomButton(
                label: l.commonOk,
                kind: AtomButtonKind.outline,
                onPressed: onClose,
              ),
              second: atom
                  ? AtomButton(
                      label: l.dpDbRoleAskAtom,
                      onPressed: () {
                        final router = GoRouter.of(context);
                        final why = Uri(
                          path: V2Routes.askAtom,
                          queryParameters: {
                            'q': l.statesAskWhyQuestion,
                            if (failure?.message case final m?
                                when m.isNotEmpty)
                              'error': m,
                          },
                        ).toString();
                        onClose!();
                        router.push(why);
                      },
                    )
                  : null,
              secondFlex: 13,
              firstFlex: 10,
            ),
          ] else if (atom) ...[
            const SizedBox(height: 14),
            AtomButton(
              label: l.dpDbRoleAskAtom,
              kind: AtomButtonKind.outline,
              onPressed: () => _askAtomWhy(context, failure),
            ),
          ],
        ],
      ),
    );
  }
}

/// Not in your role (14.3), for a route the role doesn't open (a shared
/// link, or a role changed meanwhile). Normally the button isn't shown at
/// all. Drawn as the board: the sheet over a dimmed screen. `?tried=order`
/// (or stock, discount) says what was tried.
class NotInRoleScreen extends StatelessWidget {
  const NotInRoleScreen({super.key, this.tried});

  final NotInRoleTried? tried;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final asked =
        tried ??
        NotInRoleTried.fromKey(
          GoRouterState.of(context).uri.queryParameters['tried'],
        );
    void close() => context.go(V2Routes.home);
    // Android back closes the sheet, as tapping outside does.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) close();
      },
      child: _notInRoleScaffold(context, l, asked, close),
    );
  }

  Widget _notInRoleScaffold(
    BuildContext context,
    AppLocalizations l,
    NotInRoleTried? asked,
    VoidCallback close,
  ) {
    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Stack(
        children: [
          // `.ghost`: the screen it was opened over.
          Container(
            height: 330,
            decoration: const BoxDecoration(
              color: AtomColors.paper,
              border: Border(bottom: BorderSide(color: AtomColors.line)),
            ),
          ),
          Positioned.fill(
            child: Semantics(
              button: true,
              label: l.commonClose,
              child: GestureDetector(
                onTap: close,
                child: const ColoredBox(color: AtomColors.scrim),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.sizeOf(context).height -
                    MediaQuery.paddingOf(context).top,
              ),
              decoration: const BoxDecoration(
                color: AtomColors.paper,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AtomRadius.sheet),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AtomColors.line2,
                          borderRadius: AtomRadius.brPill,
                        ),
                      ),
                      _NotInRoleSheet(tried: asked, onClose: close),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// An unknown, deleted or out-of-scope route.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AtomFlowBar(
            leading: AtomFlowLeading.close,
            onLeading: () => context.go(V2Routes.home),
          ),
          Expanded(
            child: _Centred(
              icon: _iconTile(LucideIcons.searchX, AtomTone.grey),
              title: l.notFoundTitle,
              body: l.notFoundBody,
            ),
          ),
          _Actions(
            children: [
              AtomButton(
                label: l.notFoundHome,
                onPressed: () => context.go(V2Routes.home),
              ),
              const StateSignOut(),
            ],
          ),
        ],
      ),
    );
  }
}

/// Restricted by Atomshop (14.5): Atomshop paused changes on the account
/// (`restricted: true` on a refused write, with Atomshop's `reason`). Opened
/// from the Home banner. No Pay button: this isn't about a bill. The
/// board's "Since 2 Nov" is left out: the server doesn't keep the date.
class RestrictedScreen extends ConsumerWidget {
  const RestrictedScreen({super.key, this.reason});

  /// Atomshop's words; defaults to the one the server last sent.
  final String? reason;

  static const _phoneShown = '+92 330 2277522';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final said = reason ?? ref.watch(accessProvider.select((a) => a.message));
    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: _FitOrScroll(
        children: [
          AtomFlowBar(
            leading: AtomFlowLeading.close,
            onLeading: () =>
                context.canPop() ? context.pop() : context.go(V2Routes.home),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AtomSpace.gutter,
                ),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AtomColors.paper,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AtomRadius.sheet),
                  ),
                  border: Border.all(color: AtomColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AtomSpace.gutter),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AtomColors.line),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/brand/atomshop_logo.png',
                            height: 30,
                            semanticLabel: 'Atomshop.pk',
                          ),
                          const SizedBox(height: 10),
                          Semantics(
                            header: true,
                            child: Text(
                              l.restrictedTitle,
                              style: AtomText.pageTitle.copyWith(height: 1.2),
                            ),
                          ),
                          if (said != null && said.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AtomColors.head,
                                borderRadius: AtomRadius.brControl,
                                border: Border.all(color: AtomColors.line),
                              ),
                              child: Text(
                                '"$said"',
                                style: AtomText.body.copyWith(
                                  color: AtomColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 2,
                      ),
                      child: Column(
                        children: [
                          AtomInfoLine(
                            label: l.restrictedPayments,
                            value: l.restrictedWorks,
                            valueColor: AtomColors.green,
                          ),
                          const Divider(height: 1, color: AtomColors.line),
                          AtomInfoLine(
                            label: l.restrictedCloseDeals,
                            value: l.restrictedWorks,
                            valueColor: AtomColors.green,
                          ),
                          const Divider(height: 1, color: AtomColors.line),
                          AtomInfoLine(
                            label: l.restrictedNewThings,
                            value: l.restrictedPaused,
                            valueColor: AtomColors.amberInk,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _Actions(
            bottom: 30,
            children: [
              AtomButton(
                label: l.restrictedWhatsApp,
                kind: AtomButtonKind.whatsapp,
                icon: AtomBrandIcons.whatsapp,
                onPressed: _openWhatsApp,
              ),
              AtomButton(
                label: l.restrictedCall(_phoneShown),
                kind: AtomButtonKind.outline,
                onPressed: () =>
                    launchUrl(Uri.parse('tel:$atomshopSupportPhone')),
              ),
              Text(
                l.restrictedNote,
                textAlign: TextAlign.center,
                style: AtomText.small.copyWith(color: AtomColors.faint),
              ),
              const StateSignOut(),
            ],
          ),
        ],
      ),
    );
  }
}

/// That didn't save (14.7): a save the server refused with an error. Says
/// nothing changed and what was typed is kept, shows the server's
/// reference, and offers Try again and (with the add-on) Ask Atom why. The
/// server's technical message is never shown.
class SaveErrorScreen extends ConsumerWidget {
  const SaveErrorScreen({
    super.key,
    required this.what,
    required this.onRetry,
    this.failure,
    this.at,
  });

  /// What didn't save, as it reads in "couldn't save the {what}"
  /// ("hand-over", "payment").
  final String what;
  final VoidCallback onRetry;
  final ApiFailure? failure;

  /// When it failed; defaults to now.
  final DateTime? at;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final atom =
        ref.watch(accessProvider).addons?.contains(Addon.askAtom) ?? false;
    final ref0 = failure?.body?['ref'];
    final when = at ?? AtomDates.now();
    final whenText =
        '${AtomDates.short(when)}, ${DateFormat('H:mm').format(when)}';
    return Scaffold(
      backgroundColor: AtomColors.paper,
      body: _FitOrScroll(
        children: [
          const AtomFlowBar(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 60),
                child: Column(
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: AtomSize.stateTile,
                        height: AtomSize.stateTile,
                        decoration: const BoxDecoration(
                          color: AtomColors.roseSoft,
                          borderRadius: BorderRadius.all(
                            Radius.circular(AtomRadius.sheet),
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.circleAlert,
                          size: 36,
                          color: AtomColors.rose,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Semantics(
                      header: true,
                      child: Text(
                        l.dpDbErrorTitle,
                        textAlign: TextAlign.center,
                        style: AtomText.successTitle.copyWith(height: 1.2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l.dpDbErrorBody(what),
                      textAlign: TextAlign.center,
                      style: AtomText.body.copyWith(
                        fontSize: 15,
                        height: 1.5,
                        color: AtomColors.muted,
                      ),
                    ),
                    if (ref0 is String && ref0.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AtomColors.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l.dpDbErrorRef(ref0, whenText),
                          style: AtomText.small.copyWith(
                            color: AtomColors.faint,
                            fontFamily: 'monospace',
                            fontFamilyFallback: const ['Consolas', 'Menlo'],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _Actions(
            bottom: 34,
            horizontal: 20,
            children: [
              AtomButton(
                label: l.commonTryAgain,
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
              ),
              if (atom)
                AtomButton(
                  label: l.dpDbRoleAskAtom,
                  kind: AtomButtonKind.outline,
                  onPressed: () => context.push(V2Routes.askAtom),
                ),
              if (ref0 is String && ref0.isNotEmpty)
                Text(
                  l.dpDbErrorRefNote,
                  textAlign: TextAlign.center,
                  style: AtomText.small.copyWith(color: AtomColors.faint),
                ),
              const StateSignOut(),
            ],
          ),
        ],
      ),
    );
  }
}

/// Opens [SaveErrorScreen] over the current screen, which keeps what was
/// typed underneath. Try again closes it and calls [onRetry].
Future<void> showSaveError(
  BuildContext context, {
  required String what,
  required VoidCallback onRetry,
  ApiFailure? failure,
}) {
  // A 403 isn't an error to try again: it is 13.3's sheet.
  if (failure != null &&
      (failure.kind == ApiFailureKind.notInRole ||
          failure.kind == ApiFailureKind.ownerOnly)) {
    return showNotInRoleSheet(context, failure: failure);
  }
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          SaveErrorScreen(what: what, onRetry: onRetry, failure: failure),
    ),
  );
}

/// No internet (11.9), for sellers without the Offline add-on. A body to
/// put in place of a screen's content; the screen keeps what was typed.
class NoInternetBody extends StatelessWidget {
  const NoInternetBody({super.key, required this.onRetry, this.kept});

  final VoidCallback onRetry;

  /// What the person was typing, kept on screen ("Rs 8,400 · Bilal Ahmed").
  final String? kept;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // The board's column: 14 between the tile, title, words and note.
    const gap = SizedBox(height: 14);
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AtomSize.formMaxWidth,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AtomColors.surface,
                        borderRadius: BorderRadius.all(
                          Radius.circular(AtomRadius.sheet),
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.wifiOff,
                        size: 36,
                        color: AtomColors.muted,
                      ),
                    ),
                    gap,
                    Semantics(
                      header: true,
                      child: Text(
                        l.noInternetTitle,
                        textAlign: TextAlign.center,
                        style: AtomText.successTitle,
                      ),
                    ),
                    gap,
                    Text(
                      l.noInternetBody,
                      textAlign: TextAlign.center,
                      style: AtomText.body.copyWith(
                        fontSize: 15,
                        height: 1.5,
                        color: AtomColors.muted,
                      ),
                    ),
                    if (kept != null) ...[
                      gap,
                      AtomNote(
                        kind: AtomNoteKind.info,
                        icon: LucideIcons.check,
                        message: l.dpETNoInternetKept(kept!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            34 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AtomSize.formMaxWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AtomButton(label: l.commonTryAgain, onPressed: onRetry),
                  const SizedBox(height: 12),
                  Text(
                    l.noInternetAuto,
                    textAlign: TextAlign.center,
                    style: AtomText.small.copyWith(color: AtomColors.faint),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
