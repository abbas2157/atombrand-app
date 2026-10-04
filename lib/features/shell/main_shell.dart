import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_icons.dart';

import '../../core/session.dart';

/// True while a tab shows its own bottom bar for unsaved work (Inventory's
/// save and bulk bars), so the nav hides and nothing is left by accident.
final shellNavHiddenProvider = NotifierProvider<ShellNavHidden, bool>(ShellNavHidden.new);

class ShellNavHidden extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool hidden) {
    if (state != hidden) state = hidden;
  }
}

/// Bottom tabs: Home · Orders · Bulk · Catalogue · More (§3.1).
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Refresh the Bulk badge whenever the app comes back to the foreground.
    _lifecycle = AppLifecycleListener(onResume: () => ref.read(sessionProvider.notifier).refreshBadge());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = ref.watch(signedInProvider)?.newBulkRequests ?? 0;
    final navHidden = ref.watch(shellNavHiddenProvider);
    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: navHidden
          ? null
          : NavigationBar(
              selectedIndex: widget.shell.currentIndex,
              onDestinationSelected: (i) => widget.shell.goBranch(i, initialLocation: i == widget.shell.currentIndex),
              destinations: [
                const NavigationDestination(
                  icon: Icon(AppIcons.home),
                  selectedIcon: Icon(AppIcons.homeFill),
                  label: 'Home',
                ),
                const NavigationDestination(
                  icon: Icon(AppIcons.orders),
                  selectedIcon: Icon(AppIcons.ordersFill),
                  label: 'Orders',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: badge > 0,
                    label: Text(badge > 99 ? '99+' : '$badge'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(AppIcons.bulk),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: badge > 0,
                    label: Text(badge > 99 ? '99+' : '$badge'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(AppIcons.bulkFill),
                  ),
                  label: 'Bulk',
                  tooltip: badge > 0 ? 'Bulk requests, $badge new' : 'Bulk requests',
                ),
                const NavigationDestination(
                  icon: Icon(AppIcons.catalogue),
                  selectedIcon: Icon(AppIcons.catalogueFill),
                  label: 'Catalogue',
                ),
                const NavigationDestination(icon: Icon(AppIcons.more), selectedIcon: Icon(AppIcons.moreFill), label: 'More'),
              ],
            ),
    );
  }
}
