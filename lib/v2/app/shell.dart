import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/app_localizations.dart';
import '../core/session/session_controller.dart';
import '../design/design.dart';
import '../features/notifications/ui/allow_notifications_screen.dart';
import '../widgets/widgets.dart';
import 'routes.dart';

/// The frame around the four tabs: a tab bar on phones, a navy rail from
/// 600dp (14.1).
///
/// The bar is Home · Orders · ＋ · Bulk deals · Products. The ＋ opens
/// Quick actions (5.6); the avatar on Home's header opens the Menu (12.1),
/// and on a tablet the rail's More does.
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
    final wide = MediaQuery.sizeOf(context).width >= AtomSize.tabletBreakpoint;
    final atRoot = V2Routes.tabs.contains(GoRouterState.of(context).uri.path);
    final branch = widget.navigationShell.currentIndex;

    // (destination, its branch)
    final tabs = <(AtomDestination, int)>[
      (AtomDestination(icon: LucideIcons.house, label: l.tabHome), _home),
      (
        AtomDestination(icon: LucideIcons.fileText, label: l.tabOrders),
        _orders,
      ),
      (AtomDestination(icon: LucideIcons.funnel, label: l.tabBulk), _bulk),
      (AtomDestination(icon: LucideIcons.tag, label: l.tabProducts), _products),
    ];
    final selected = tabs.indexWhere((t) => t.$2 == branch);
    final plusLabel = l.tabQuickActions;
    void plus() => context.push(V2Routes.quickActions);

    final Widget body;
    if (wide) {
      body = Row(
        children: [
          AtomRail(
            destinations: [for (final t in tabs) t.$1],
            selected: selected,
            onSelect: (i) => _go(tabs[i].$2),
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
              onSelect: (i) => _go(tabs[i].$2),
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
