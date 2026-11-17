import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/format/dates.dart';
import '../../../core/net/network_status.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/atom_brand.dart';
import '../../sync/data/sync_providers.dart';

/// Splash: 1.1 on a first launch, 1.2 (a smaller tile and the shop under
/// the name) once a stored session is known. Shown while the session and
/// this phone's lock are read; the router moves on by itself.
///
/// 1.2's offline parts (the "Offline" pill, changes waiting to sync, the
/// last sync and the days left) show for a returning person on a brand
/// with the Offline add-on while the phone has no signal.
class LaunchScreen extends ConsumerWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final session = switch (ref.watch(sessionProvider)) {
      SignedIn(:final session) => session,
      _ => null,
    };
    final returning = session != null;
    final shop = session == null
        ? null
        : [
            if (session.brandName != null) session.brandName!,
            session.who.isOwner
                ? (session.outletName ?? l.auth2MainShop)
                : session.outletName,
          ].whereType<String>().join(' · ');
    final bottom = MediaQuery.paddingOf(context).bottom;
    final online = ref.watch(onlineProvider).value ?? true;
    final sync = ref.watch(syncStatusProvider);
    final offlineCopy =
        returning &&
        !online &&
        (ref.watch(accessProvider).has(Addon.offline) ||
            sync.offlineUntil != null);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AtomColors.nav,
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AtomBrandTile(
                        size: returning
                            ? AtomSize.splashTileReturning
                            : AtomSize.splashTile,
                        shadow: true,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        l.appName,
                        textAlign: TextAlign.center,
                        style: AtomText.amount.copyWith(
                          fontSize: returning ? 24 : 28,
                          color: Colors.white,
                          letterSpacing: returning ? -0.4 : -0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        returning && shop!.isNotEmpty ? shop : l.auth2Tagline,
                        textAlign: TextAlign.center,
                        style: AtomText.body.copyWith(
                          fontSize: 15,
                          color: AtomColors.navText,
                        ),
                      ),
                      if (offlineCopy) ...[
                        const SizedBox(height: 22),
                        _OfflinePill(label: l.authSplashOffline),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (offlineCopy)
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 40 + bottom),
                child: _OfflineCard(status: sync),
              ),
            if (!returning)
              Padding(
                padding: EdgeInsets.only(bottom: 48 + bottom),
                child: Column(
                  children: [
                    const AtomStepsStripe(width: 96),
                    const SizedBox(height: 14),
                    _By(l: l),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "by **Atomshop.pk** · Pay in Steps".
class _By extends StatelessWidget {
  const _By({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    const brand = 'Atomshop.pk';
    final parts = l.auth2SplashBy('\u0000').split('\u0000');
    final base = AtomText.secondary.copyWith(color: AtomColors.navMuted);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: parts.first),
          const TextSpan(
            text: brand,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          if (parts.length > 1) TextSpan(text: parts[1]),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// `.dark .pill.off`: "Offline · your data is on this phone".
class _OfflinePill extends StatelessWidget {
  const _OfflinePill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 26),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0x29F7A928),
      borderRadius: AtomRadius.brPill,
      border: Border.all(color: const Color(0x4DF7A928)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AtomColors.amber,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: AtomText.small.copyWith(
              color: AtomColors.darkAmber,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

/// 1.2's card: changes waiting to sync, the last sync and the days left.
/// A part the phone doesn't know yet is left out.
class _OfflineCard extends StatelessWidget {
  const _OfflineCard({required this.status});
  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final last = status.lastSyncAt;
    final until = status.offlineUntil;
    final days = until == null
        ? null
        : until.difference(DateTime.now()).inHours <= 0
        ? 0
        : (until.difference(DateTime.now()).inHours / 24).ceil();
    final muted = AtomText.small.copyWith(color: AtomColors.navMuted);
    final foot = [
      if (last != null)
        Text(l.authSplashLastSynced(_when(l, last)), style: muted),
      if (days != null) Text(l.authSplashDaysLeft(days), style: muted),
    ];
    if (status.waiting == 0 && foot.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AtomColors.nav2,
        borderRadius: AtomRadius.brCard,
        border: Border.all(color: AtomColors.navLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (status.waiting > 0)
            Row(
              children: [
                const Icon(
                  LucideIcons.rotateCw,
                  size: 20,
                  color: AtomColors.darkAmber,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.authSplashWaiting(status.waiting),
                    style: AtomText.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          if (status.waiting > 0 && foot.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AtomColors.navLine),
            const SizedBox(height: 10),
          ],
          if (foot.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 4,
              children: foot,
            ),
        ],
      ),
    );
  }

  static String _when(AppLocalizations l, DateTime at) {
    final days = AtomDates.daysFrom(at, today: DateTime.now());
    if (days == 0) return l.authSplashToday(AtomDates.time(at));
    return '${AtomDates.short(at)}, ${AtomDates.time(at)}';
  }
}
