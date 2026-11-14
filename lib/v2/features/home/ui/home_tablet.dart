import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/format/dates.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../sync/data/sync_providers.dart';
import '../data/home_logic.dart';
import '../data/home_models.dart';
import '../data/home_repository.dart';
import 'home_banners.dart';
import 'home_parts.dart';
import 'home_screen.dart';
import 'home_sections.dart';

/// Home on a wide tablet (TabletHome, 14.1), as Atom Seller's 15.1: a
/// white top bar with the greeting, Ask Atom, when this phone last synced,
/// the outlet, the bell and the menu; then two columns. Left: the navy
/// hero and the money (sales, the chart, the pipeline, bulk deals,
/// outlets, the plan). Right: what needs doing and what just happened
/// (tasks, latest orders, top products, activity). The rail is the
/// shell's.
class HomeTablet extends ConsumerWidget {
  const HomeTablet({super.key, required this.home});

  final HomeDashboard home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    ref.watch(sessionProvider);
    final session = ref.watch(sessionProvider.notifier).current;
    final who = session?.who ?? const Who.owner();
    final access = ref.watch(accessProvider);
    final unread = ref.watch(homeUnreadProvider).value;
    final now = ref.watch(homeClockProvider)();
    final last = ref.watch(syncStatusProvider.select((s) => s.lastSyncAt));
    final top = MediaQuery.paddingOf(context).top;
    final multi = (session?.multiOutlet ?? false) && who.isOwner;

    final bar = AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        constraints: BoxConstraints(minHeight: 72 + top),
        padding: EdgeInsets.fromLTRB(28, top + 10, 20, 10),
        decoration: const BoxDecoration(
          color: AtomColors.paper,
          border: Border(bottom: BorderSide(color: AtomColors.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  who.isOwner
                      ? '${greetingFor(now, l)}, ${session?.firstName ?? ''}'
                      : l.homeSalam(session?.firstName ?? ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtomText.pageTitle,
                ),
              ),
            ),
            if (access.has(Addon.askAtom)) ...[
              const SizedBox(width: 12),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: AskAtomBar(
                    label: l.homeAskBar,
                    light: true,
                    onTap: () => context.push(V2Routes.askAtom),
                  ),
                ),
              ),
            ],
            if (access.has(Addon.offline) && last != null) ...[
              const SizedBox(width: 12),
              AtomPressable(
                onTap: () => context.push(V2Routes.sync),
                semanticLabel: l.homeSynced(AtomDates.time(last)),
                focusRadius: AtomRadius.brPill,
                builder: (_, _) => ExcludeSemantics(
                  child: AtomPill(
                    label: l.homeSynced(AtomDates.time(last)),
                    tone: AtomTone.green,
                    dot: true,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            if (multi)
              AtomIconButton(
                icon: LucideIcons.store,
                label: session?.outletName ?? l.homeAllOutlets,
                onTap: () => context.push(V2Routes.outletSwitcher),
              ),
            AtomIconButton(
              icon: LucideIcons.search,
              label: l.homeSearch,
              onTap: () => context.push(V2Routes.search),
            ),
            AtomIconButton(
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
              size: 38,
              semanticLabel: l.homeMenu,
              onTap: () => context.push(V2Routes.menu),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        children: [
          bar,
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => refreshHome(ref),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
                children: [
                  HomeBannerSlot(activity: home.activity),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 125,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: HomeHeroFor(
                                mode: HomeMode.full,
                                home: home,
                              ),
                            ),
                            HomeFullSections(
                              home: home,
                              column: HomeColumn.left,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 100,
                        child: HomeFullSections(
                          home: home,
                          column: HomeColumn.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
