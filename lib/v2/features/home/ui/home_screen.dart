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
import '../../../core/net/network_status.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../states/ui/state_screens.dart' show NoInternetBody;
import '../../sync/data/sync_providers.dart';
import '../../sync/ui/offline_bar.dart';
import '../data/home_logic.dart';
import '../data/home_models.dart';
import '../data/home_repository.dart';
import 'home_banners.dart';
import 'home_parts.dart';
import 'home_sections.dart';
import 'home_tablet.dart';

/// Which Home to draw.
enum HomeMode {
  /// The full Home: the owner's (5.1) or a team member's (5.2), with the
  /// add-ons that are off left out (5.5).
  full,

  /// No signal, from the phone's copy (5.3, Offline add-on).
  offline,

  /// A new brand's first steps (5.4).
  firstDay,
}

/// Home (5.1–5.5): one screen that reads the session, the role and the
/// add-ons. Every figure is the server's (`GET dashboard`), but for the
/// offline Home, which counts from the phone's copy.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sessionProvider);
    final session = ref.watch(sessionProvider.notifier).current;
    final owner = session?.who.isOwner ?? false;
    final dashboard = ref.watch(homeDashboardProvider);
    final home = dashboard.value;
    final access = ref.watch(accessProvider);
    final online = ref.watch(onlineProvider).value ?? true;
    final copy = ref.watch(offlineCopyProvider);

    final error = dashboard.hasValue ? null : dashboard.error;
    final offline =
        access.has(Addon.offline) &&
        copy != null &&
        (!online || (error != null && noSignal(error)));
    final mode = offline
        ? HomeMode.offline
        : home != null && isFirstDay(owner: owner, home: home)
        ? HomeMode.firstDay
        : HomeMode.full;

    final Widget body;
    if (mode == HomeMode.offline) {
      final figures = ref.watch(homeOfflineProvider).value;
      body = figures == null
          ? const Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: AtomLoadingRows(count: 3),
            )
          : HomeOfflineSections(figures: figures);
    } else if (home == null && error != null) {
      body = SizedBox(
        height: 360,
        child: noSignal(error)
            ? NoInternetBody(onRetry: () => refreshHome(ref))
            : AtomErrorState(onRetry: () => refreshHome(ref)),
      );
    } else if (home == null) {
      body = const Padding(
        padding: EdgeInsets.fromLTRB(16, 18, 16, 0),
        child: AtomLoadingCard(count: 4),
      );
    } else if (mode == HomeMode.firstDay) {
      body = HomeFirstSteps(
        steps: firstStepsFor(ref, home, AppLocalizations.of(context)),
      );
    } else {
      body = HomeFullSections(home: home);
    }

    // A wide tablet (TabletHome, 14.1): a white top bar and the dashboard
    // in two columns, the rail beside it (the shell's).
    if (atomTwoPane(context) && mode == HomeMode.full && home != null) {
      return HomeTablet(home: home);
    }

    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: RefreshIndicator(
        onRefresh: () => refreshHome(ref),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _Header(mode: mode, home: home, error: error),
            if (mode != HomeMode.offline)
              HomeBannerSlot(activity: home?.activity ?? const []),
            body,
          ],
        ),
      ),
    );
  }
}

/// The navy header: the brand (and outlet switcher), search, the bell
/// and the menu; the greeting; the Ask Atom bar; the hero.
class _Header extends ConsumerWidget {
  const _Header({required this.mode, required this.home, this.error});

  final HomeMode mode;
  final HomeDashboard? home;
  final Object? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    ref.watch(sessionProvider);
    final session = ref.watch(sessionProvider.notifier).current;
    final who = session?.who ?? const Who.owner();
    final access = ref.watch(accessProvider);
    final unread = ref.watch(homeUnreadProvider).value;
    final now = ref.watch(homeClockProvider)();
    final brand = session?.brandName ?? l.homeBrandPartner;
    final multi = session?.multiOutlet ?? false;
    final firstDay = mode == HomeMode.firstDay;

    final Widget brandButton;
    if (who.isOwner) {
      brandButton = BrandHeaderButton(
        title: brand,
        subtitle:
            session?.outletName ??
            (multi ? l.homeAllOutlets : l.homeBrandPartner),
        logo: session?.brandLogo,
        onTap: multi && !firstDay
            ? () => context.push(V2Routes.outletSwitcher)
            : null,
      );
    } else {
      final role = who.roleName ?? '';
      // 5.2: the outlet over "Zenvo Appliances · Order handler". A member
      // who works in every outlet of a brand with several sees All outlets.
      final outlet =
          agentOutletName(session) ?? (multi ? l.homeAllOutlets : null);
      brandButton = BrandHeaderButton(
        title: outlet ?? brand,
        subtitle: [
          if (outlet != null) brand,
          if (role.isNotEmpty) role,
        ].join(' · '),
        logo: session?.brandLogo,
      );
    }

    return AtomNavyHeader(
      top: Row(
        children: [
          Expanded(child: brandButton),
          const SizedBox(width: 6),
          if (!firstDay) ...[
            AtomNavyIconButton(
              icon: LucideIcons.search,
              label: l.homeSearch,
              onTap: () => context.push(V2Routes.search),
            ),
            const SizedBox(width: 6),
          ],
          AtomNavyIconButton(
            icon: LucideIcons.bell,
            label: l.homeNotifications,
            count: unread == null || unread == 0 ? null : unread,
            onTap: () async {
              await context.push(V2Routes.notifications);
              ref.invalidate(homeUnreadProvider);
            },
          ),
          const SizedBox(width: 6),
          AtomAvatar(
            initials: session?.initials ?? '',
            semanticLabel: l.homeMenu,
            onTap: () => context.push(V2Routes.menu),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mode == HomeMode.offline)
            const OfflineBar()
          else if (!firstDay)
            _Greeting(
              text: who.isOwner
                  ? '${greetingFor(now, l)}, ${session?.firstName ?? ''}'
                  : l.homeSalam(session?.firstName ?? ''),
            ),
          // The Ask Atom bar is on the owner's Home (5.1), not 5.2.
          if (mode == HomeMode.full && who.isOwner && access.has(Addon.askAtom))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AskAtomBar(
                label: l.homeAskBar,
                onTap: () => context.push(V2Routes.askAtom),
              ),
            ),
          if (mode == HomeMode.offline) const SizedBox(height: 12),
          HomeHeroFor(mode: mode, home: home, error: error),
        ],
      ),
    );
  }
}

/// The navy hero for [mode] (5.1–5.4): on the phone inside the header, on
/// the tablet at the top of the left column (TabletHome).
class HomeHeroFor extends ConsumerWidget {
  const HomeHeroFor({super.key, required this.mode, this.home, this.error});

  final HomeMode mode;
  final HomeDashboard? home;
  final Object? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sessionProvider);
    final who =
        ref.watch(sessionProvider.notifier).current?.who ?? const Who.owner();
    return switch (mode) {
      HomeMode.offline => const _OfflineHero(),
      HomeMode.firstDay => _FirstDayHero(home: home!),
      HomeMode.full when home == null => _HeroPlaceholder(
        waiting: error == null,
      ),
      HomeMode.full when who.isOwner => _OwnerHero(home: home!),
      HomeMode.full => _AgentHero(home: home!),
    };
  }
}

/// "Good morning, Asad" and, with the Offline add-on, when this phone last
/// synced.
class _Greeting extends ConsumerWidget {
  const _Greeting({required this.text});
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final offline = ref.watch(accessProvider).has(Addon.offline);
    final last = ref.watch(syncStatusProvider.select((s) => s.lastSyncAt));
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                text,
                style: AtomText.pageTitle.copyWith(
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          if (offline && last != null)
            AtomPressable(
              onTap: () => context.push(V2Routes.sync),
              semanticLabel: l.homeSynced(AtomDates.time(last)),
              focusRadius: AtomRadius.brPill,
              builder: (_, _) => ExcludeSemantics(
                child: Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AtomColors.darkGreenFill,
                    borderRadius: AtomRadius.brPill,
                    border: Border.all(color: AtomColors.darkGreenLine),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AtomColors.darkGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l.homeSynced(AtomDates.time(last)),
                        style: AtomText.small.copyWith(
                          color: AtomColors.darkGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder({required this.waiting});
  final bool waiting;

  @override
  Widget build(BuildContext context) => Container(
    height: 190,
    decoration: BoxDecoration(
      color: AtomColors.nav2,
      borderRadius: const BorderRadius.all(Radius.circular(AtomRadius.sheet)),
      border: Border.all(color: AtomColors.navLine),
    ),
    alignment: Alignment.center,
    child: waiting
        ? const AtomSpinner(color: Colors.white, track: AtomColors.navLine)
        : const Icon(
            LucideIcons.wifiOff,
            color: AtomColors.darkAmber,
            size: 28,
          ),
  );
}

/// The owner's hero (5.1): "9 things need you today", three count tiles
/// and the two buttons. A count the role can't see is left out.
class _OwnerHero extends ConsumerWidget {
  const _OwnerHero({required this.home});
  final HomeDashboard home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final h = home.hero;
    final now = ref.watch(homeClockProvider)();
    final read = home.readAt;
    final tiles = <Widget>[
      if (h.ordersToConfirm case final n?)
        HeroCountTile(
          count: n,
          label: l.homeOrdersToConfirm,
          dot: AtomColors.amber,
          onTap: () => context.go(V2Routes.orders),
        ),
      if (h.atompayToHandOver case final n?)
        HeroCountTile(
          count: n,
          label: l.homeUnitsToHandOver,
          dot: AtomColors.toastLink,
          onTap: () => context.go(V2Routes.atompayOrders),
        ),
      if (h.requestsWaiting case final n?)
        HeroCountTile(
          count: n,
          label: l.homeRequestsToQuote,
          dot: AtomColors.darkGreen,
          onTap: () => context.go(
            V2Routes.bulkTab(
              (h.sellerWaiting ?? 0) > (h.bulkWaiting ?? 0)
                  ? 'sellers'
                  : 'website',
            ),
          ),
        ),
    ];
    final large = homeLargeText(context);
    final buttons = <Widget>[
      if (h.ordersToConfirm != null)
        HeroButton(
          label: l.homeConfirmOrders,
          light: true,
          icon: LucideIcons.check,
          onTap: () => context.go(V2Routes.orders),
        ),
      if (h.requestsWaiting != null)
        HeroButton(
          label: l.homeReplyToBulk,
          badge: h.requestsWaiting,
          onTap: () => context.go(V2Routes.bulk),
        ),
    ];
    return HomeHeroCard(
      label: '${l.homeToday} · ${DateFormat('EEE, d MMM').format(now)}',
      labelEnd: read == null ? null : l.homeUpdated(AtomDates.time(read)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 14),
            child: Text(
              l.homeThingsNeedYou(h.total),
              style: AtomText.pageTitle.copyWith(
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (tiles.isNotEmpty)
            large
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < tiles.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        tiles[i],
                      ],
                    ],
                  )
                : IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < tiles.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(child: tiles[i]),
                        ],
                      ],
                    ),
                  ),
          if (buttons.isNotEmpty) ...[
            const SizedBox(height: 14),
            large || buttons.length == 1
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < buttons.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        buttons[i],
                      ],
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: buttons[0]),
                      const SizedBox(width: 8),
                      Expanded(child: buttons[1]),
                    ],
                  ),
          ],
        ],
      ),
    );
  }
}

/// A team member's hero (5.2): their outlet's counts as lines, and
/// "Confirm orders".
class _AgentHero extends ConsumerWidget {
  const _AgentHero({required this.home});
  final HomeDashboard home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider.notifier).current;
    final h = home.hero;
    final lines = <Widget>[
      if (h.ordersToConfirm case final n?)
        HeroCountLine(
          count: n,
          label: l.homeOrdersToConfirmLine(n),
          onTap: () => context.go(V2Routes.orders),
        ),
      if (h.atompayToHandOver case final n?)
        HeroCountLine(
          count: n,
          label: l.homeUnitsToHandOverLine(n),
          onTap: () => context.go(V2Routes.atompayOrders),
        ),
      if (h.requestsWaiting case final n?)
        HeroCountLine(
          count: n,
          label: l.homeRequestsLine(n),
          onTap: () => context.go(V2Routes.bulk),
        ),
    ];
    // 5.2: one light "Confirm orders" under the lines (`.acts`, 1fr).
    return HomeHeroCard(
      label: l.homeDashboard,
      labelEnd:
          agentOutletName(session) ??
          ((session?.multiOutlet ?? false) ? l.homeAllOutlets : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          ...lines,
          if (h.ordersToConfirm != null) ...[
            const SizedBox(height: 12),
            HeroButton(
              label: l.homeConfirmOrders,
              light: true,
              icon: LucideIcons.check,
              onTap: () => context.go(V2Routes.orders),
            ),
          ],
        ],
      ),
    );
  }
}

/// The outlet a team member works in, for 5.2's header and hero: the one
/// chosen, else their only outlet (`who.outletIds`), else the brand's only
/// one. Null when they work across several and chose All outlets.
String? agentOutletName(BrandSession? session) {
  if (session == null) return null;
  if (session.outletName case final name? when name.isNotEmpty) return name;
  final ids = session.who.outletIds;
  final mine = [
    for (final o in session.outlets)
      if (ids == null || ids.contains(o.id)) o,
  ];
  return mine.length == 1 ? mine.first.name : null;
}

/// The offline hero (5.3): the copy's counts, as of the last sync.
class _OfflineHero extends ConsumerWidget {
  const _OfflineHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final who =
        ref.watch(sessionProvider.notifier).current?.who ?? const Who.owner();
    final f = ref.watch(homeOfflineProvider).value ?? const OfflineHome();
    final last = ref.watch(syncStatusProvider.select((s) => s.lastSyncAt));
    return HomeHeroCard(
      label: l.homeDashboard,
      labelEnd: last == null ? null : l.homeAsOf(AtomDates.time(last)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          if (who.can(BrandPermission.ordersView))
            HeroCountLine(
              count: f.toConfirm,
              label: l.homeOrdersToConfirmLine(f.toConfirm),
              onTap: () => context.go(V2Routes.orders),
            ),
          if (who.can(BrandPermission.atompayView))
            HeroCountLine(
              count: f.toHandOver,
              label: l.homeUnitsToHandOverLine(f.toHandOver),
              onTap: () => context.go(V2Routes.atompayOrders),
            ),
          const SizedBox(height: 10),
          Text(
            l.homeOfflineLegend,
            style: AtomText.small.copyWith(color: AtomColors.navText),
          ),
        ],
      ),
    );
  }
}

/// The first-day hero (5.4): how many steps are done, and a bar.
class _FirstDayHero extends ConsumerWidget {
  const _FirstDayHero({required this.home});
  final HomeDashboard home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final steps = firstStepsFor(ref, home, AppLocalizations.of(context));
    final done = steps.where((s) => s.done).length;
    return HomeHeroCard(
      label: l.homeWelcome,
      labelEnd: l.homeDoneOf(done, steps.length),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 12),
            child: Text(
              l.homeLetsSell,
              style: AtomText.successTitle.copyWith(color: Colors.white),
            ),
          ),
          Semantics(
            label: l.homeDoneOf(done, steps.length),
            child: ClipRRect(
              borderRadius: AtomRadius.brPill,
              child: LinearProgressIndicator(
                value: steps.isEmpty ? 0 : done / steps.length,
                minHeight: 8,
                color: AtomColors.darkGreen,
                backgroundColor: AtomColors.heroBarRest,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
