import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/app_localizations.dart';
import '../core/access/access_controller.dart';
import '../core/session/session_controller.dart';
import '../design/design.dart';
import '../features/menu/data/menu_counts.dart';
import '../features/notifications/ui/allow_notifications_screen.dart';
import '../features/settings/data/settings_repository.dart'
    show myProfileProvider;
import '../widgets/widgets.dart';
import 'routes.dart';
import 'tab_sheets.dart';

/// The frame around the tabs: a tab bar on phones, a navy rail from 600dp
/// (14.1). Laid out as in Atom Seller.
///
/// The bar is Home, Business (a sheet: Orders, AtomPay orders, Bulk deals,
/// Products, Stock, Warehouses), ＋ (Quick actions, 5.6), Insights (a
/// sheet: Reports, Ask Atom), Account (the Menu, with the person's
/// initials). Rows the role can't use are left out; on a tablet the rail's
/// More opens the Menu too.
///
/// Each tab keeps its own stack (StatefulShellRoute). The bar shows only on
/// the tab roots; a screen opened inside a tab has the whole height.
///
/// Back (18.17): inside a tab, back pops that tab's stack (go_router does
/// that before this is asked). On another tab's root, back goes to Home.
/// On Home, back twice within two seconds closes the app.
class AtomShell extends ConsumerStatefulWidget {
  const AtomShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AtomShell> createState() => _AtomShellState();
}

/// The shell's branches, in the router's order.
const _home = 0, _orders = 1, _bulk = 2, _products = 3;

class _AtomShellState extends ConsumerState<AtomShell> {
  DateTime? _lastBack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _askForNotifications());
  }

  /// The notifications explainer (16.8): once per phone, the first time
  /// the person reaches the tabs. The first-time tour (17.7) is a way-in
  /// step before the tabs (guards).
  Future<void> _askForNotifications() async {
    final prompt = ref.read(notificationPromptProvider);
    if (!await prompt.shouldShow() || !mounted) return;
    context.push(V2Routes.allowNotifications);
  }

  void _go(int branch) {
    // Tapping the tab you're on goes back to its root.
    widget.navigationShell.goBranch(
      branch,
      initialLocation: branch == widget.navigationShell.currentIndex,
    );
  }

  /// Business: Orders, AtomPay orders, Bulk deals, Products, Stock,
  /// Warehouses (what this role works); one choice opens straight away.
  void _business() {
    final l = AppLocalizations.of(context);
    openTabChoices(
      context,
      ref,
      title: l.tabBusiness,
      subtitle: l.businessSub,
      build: (c, r) => businessChoices(
        c,
        r,
        openOrders: () => _go(_orders),
        openBulk: () => _go(_bulk),
        openProducts: () => _go(_products),
      ),
      watch: [menuCountsProvider],
    );
  }

  /// Insights: Reports and Ask Atom.
  void _insights() {
    final l = AppLocalizations.of(context);
    openTabChoices(
      context,
      ref,
      title: l.tabInsights,
      subtitle: l.insightsSub,
      build: insightsChoices,
    );
  }

  void _onBack() {
    if (widget.navigationShell.currentIndex != _home) {
      widget.navigationShell.goBranch(_home);
      return;
    }
    final now = DateTime.now();
    if (_lastBack != null &&
        now.difference(_lastBack!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _lastBack = now;
    showAtomToast(
      context,
      kind: AtomToastKind.wait,
      message: AppLocalizations.of(context).backAgainToClose,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    ref.watch(sessionProvider);
    ref.watch(accessProvider);
    final session = ref.read(sessionProvider.notifier).current;
    final wide = MediaQuery.sizeOf(context).width >= AtomSize.tabletBreakpoint;
    final atRoot = V2Routes.tabs.contains(GoRouterState.of(context).uri.path);
    final branch = widget.navigationShell.currentIndex;
    // A tab whose sheet would be empty for this role is left out.
    final hasBusiness = businessChoices(
      context,
      ref,
      openOrders: () {},
      openBulk: () {},
      openProducts: () {},
    ).isNotEmpty;
    final hasInsights = insightsChoices(context, ref).isNotEmpty;

    // (destination, what a tap does, the branches it is lit for)
    final tabs = <(AtomDestination, VoidCallback, Set<int>)>[
      (
        AtomDestination(icon: LucideIcons.house, label: l.tabHome),
        () => _go(_home),
        {_home},
      ),
      if (hasBusiness)
        (
          AtomDestination(icon: LucideIcons.shoppingBag, label: l.tabBusiness),
          _business,
          {_orders, _bulk, _products},
        ),
      if (hasInsights)
        (
          AtomDestination(icon: LucideIcons.chartLine, label: l.tabInsights),
          _insights,
          const <int>{},
        ),
      (
        AtomDestination(
          icon: LucideIcons.circleUserRound,
          label: l.tabAccount,
          initials: session?.initials,
          imageUrl: ref.watch(myProfileProvider).value?.pictureUrl,
        ),
        // The Menu: outlets, team, plan, settings, help.
        () => context.push(V2Routes.menu),
        const <int>{},
      ),
    ];
    final selected = tabs.indexWhere((t) => t.$3.contains(branch));
    final plusLabel = l.tabQuickActions;
    void plus() => context.push(V2Routes.quickActions);

    final Widget body;
    if (wide) {
      body = Row(
        children: [
          AtomRail(
            destinations: [for (final t in tabs) t.$1],
            selected: selected,
            onSelect: (i) => tabs[i].$2(),
            onPlus: plus,
            plusLabel: plusLabel,
            onMore: () => context.push(V2Routes.menu),
            moreLabel: l.dpAMore,
          ),
          Expanded(child: widget.navigationShell),
        ],
      );
    } else {
      body = Column(
        children: [
          Expanded(child: widget.navigationShell),
          if (atRoot)
            AtomTabBar(
              destinations: [for (final t in tabs) t.$1],
              selected: selected,
              onSelect: (i) => tabs[i].$2(),
              onPlus: plus,
              plusLabel: plusLabel,
            ),
        ],
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: AtomColors.surface,
        // The keyboard is handled by each screen (the Save bar rides above
        // it); the shell itself doesn't shrink.
        resizeToAvoidBottomInset: false,
        body: body,
      ),
    );
  }
}
