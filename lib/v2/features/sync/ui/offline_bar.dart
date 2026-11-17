import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/net/network_status.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/sync_providers.dart';

/// `.offbar` on Home (11.1): the amber strip that says the phone is
/// working from its own copy, and how much is waiting to go.
///
/// It shows only for an account with the add-on, and only when there is
/// something to say — no signal, or saves that have not reached the
/// server. Online with nothing waiting, Home looks as it always did.
class OfflineBar extends ConsumerWidget {
  const OfflineBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    if (!ref.watch(accessProvider).has(Addon.offline)) {
      return const SizedBox.shrink();
    }

    final online = ref.watch(onlineProvider).value ?? true;
    final waiting = ref.watch(syncStatusProvider.select((s) => s.waiting));
    if (online && waiting == 0) return const SizedBox.shrink();

    final text = [
      if (!online) l.syncOffBar,
      if (waiting > 0) l.syncOffBarChanges(waiting),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: AtomPressable(
        onTap: () => context.push(V2Routes.sync),
        semanticLabel: '$text, ${l.syncOffBarDetails}',
        builder: (_, _) => Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AtomColors.amber.withValues(alpha: 0.16),
            borderRadius: AtomRadius.brControl,
            border: Border.all(color: AtomColors.amber.withValues(alpha: 0.42)),
          ),
          child: Row(
            children: [
              Icon(
                online ? LucideIcons.clock : LucideIcons.wifiOff,
                size: AtomIcon.inline,
                color: AtomColors.darkAmber,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: AtomText.secondary.copyWith(
                    color: AtomColors.darkAmber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l.syncOffBarDetails,
                style: AtomText.secondary.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
