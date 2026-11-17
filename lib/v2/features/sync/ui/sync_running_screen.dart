import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/sync_engine.dart';
import '../data/sync_providers.dart';
import 'sync_parts.dart';

/// Sending… (10.5): the run as it goes. The big figure is what has been
/// applied out of what was waiting; under it, a step per kind of change,
/// then the photos and the download of others' changes.
///
/// Opened from Sync now. A run that ends with nothing left shows "All
/// sent"; one that stops (no signal) says it carries on later.
class SyncRunningScreen extends ConsumerStatefulWidget {
  const SyncRunningScreen({super.key});

  @override
  ConsumerState<SyncRunningScreen> createState() => _SyncRunningScreenState();
}

class _SyncRunningScreenState extends ConsumerState<SyncRunningScreen> {
  /// The last figures a sending phase showed: kept so the steps don't drop
  /// back to zero while the download runs.
  SyncProgress? _sending;

  @override
  void initState() {
    super.initState();
    // Opened with nothing going (a deep link, or the run ended already):
    // start one, the controller refuses a second.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!ref.read(syncStatusProvider).running) {
        ref.read(syncStatusProvider.notifier).syncNow();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final status = ref.watch(syncStatusProvider);
    final p = status.progress;
    if (p.phase == SyncPhase.sending) _sending = p;
    final s = _sending ?? p;
    final total = s.toSend;
    final pct = total == 0
        ? (p.phase == SyncPhase.done ? 100 : 0)
        : (s.sent * 100 / total).round();
    final phaseIndex = switch (p.phase) {
      SyncPhase.idle || SyncPhase.checking || SyncPhase.sending => 0,
      SyncPhase.photos => 1,
      SyncPhase.downloading => 2,
      SyncPhase.done || SyncPhase.failed => 3,
    };

    SyncStepRow group(SyncGroup g, String label) {
      final to = s.toSendBy[g] ?? 0;
      final sent = s.sentBy[g] ?? 0;
      final sending = p.phase == SyncPhase.sending && sent < to;
      return SyncStepRow(
        state: to == 0 || sent >= to || phaseIndex > 0
            ? SyncStepState.done
            : sending
            ? SyncStepState.running
            : SyncStepState.waiting,
        label: label,
        trailing: to == 0
            ? l.syncStepNothing
            : sending
            ? l.syncStepSending(sent + 1, to)
            : l.syncStepSent(sent),
        trailingColor: to == 0
            ? AtomColors.faint
            : sending
            ? AtomColors.primary
            : AtomColors.green,
      );
    }

    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              bottom: 24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              AtomNavyHeader(
                top: Row(
                  children: [
                    AtomNavyIconButton(
                      icon: LucideIcons.chevronLeft,
                      label: l.commonBack,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          l.syncTitle,
                          style: AtomText.heading.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.syncSendingTitle,
                            style: AtomText.secondary.copyWith(
                              color: AtomColors.navText,
                            ),
                          ),
                        ),
                        Text(
                          '$pct%',
                          style: AtomText.secondary.copyWith(
                            color: AtomColors.navText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.syncSentOf(s.sent, total),
                      style: AtomText.amount.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: AtomRadius.brPill,
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        minHeight: 8,
                        backgroundColor: AtomColors.navLine,
                        valueColor: const AlwaysStoppedAnimation(
                          AtomColors.darkGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l.syncKeepWorking,
                      style: AtomText.small.copyWith(
                        color: AtomColors.navMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SyncCard(
                      children: [
                        group(SyncGroup.ordersAndPayments, l.syncStepOrders),
                        group(SyncGroup.bulk, l.syncStepBulk),
                        group(SyncGroup.stock, l.syncStepStock),
                        SyncStepRow(
                          state: phaseIndex > 1
                              ? SyncStepState.done
                              : phaseIndex == 1
                              ? SyncStepState.running
                              : SyncStepState.waiting,
                          label: l.syncPhotos,
                          trailing: phaseIndex > 1
                              ? l.syncStepDone
                              : status.photos > 0
                              ? l.syncStepWaiting(status.photos)
                              : l.syncStepNext,
                        ),
                        SyncStepRow(
                          state: phaseIndex > 2
                              ? SyncStepState.done
                              : phaseIndex == 2
                              ? SyncStepState.running
                              : SyncStepState.waiting,
                          label: l.syncStepDown,
                          trailing: phaseIndex > 2
                              ? l.syncStepDone
                              : l.syncStepNext,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (p.phase == SyncPhase.done) ...[
                      AtomNote(
                        kind: status.attention > 0
                            ? AtomNoteKind.warning
                            : AtomNoteKind.success,
                        message: status.attention > 0
                            ? l.syncSomeAttention(status.attention)
                            : l.syncAllDone,
                      ),
                      if (status.attention > 0) ...[
                        const SizedBox(height: 10),
                        AtomButton(
                          label: l.syncAttentionTitle,
                          kind: AtomButtonKind.outline,
                          compact: true,
                          onPressed: () =>
                              context.pushReplacement(V2Routes.syncAttention),
                        ),
                      ],
                    ] else if (p.phase == SyncPhase.failed)
                      AtomNote(
                        kind: AtomNoteKind.warning,
                        message: status.message ?? l.syncFailed,
                      ),
                    const SizedBox(height: 10),
                    Text(
                      l.syncSignalNote,
                      style: AtomText.small.copyWith(color: AtomColors.faint),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const AtomNavyStatusStrip(),
        ],
      ),
    );
  }
}
