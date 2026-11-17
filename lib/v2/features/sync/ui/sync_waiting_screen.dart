import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/db/outbox_db.dart';
import '../../../core/db/sync_store.dart';
import '../../../core/net/network_status.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/sync_providers.dart';
import 'sync_parts.dart';

/// Waiting to send (10.2): what this phone saved and has not sent, in the
/// order it goes, each with Undo while it is still here. The photos that
/// go with them are counted under.
class SyncWaitingScreen extends ConsumerWidget {
  const SyncWaitingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rows = ref.watch(waitingRowsProvider);
    final online = ref.watch(onlineProvider).value ?? true;

    return SyncScaffold(
      title: l.syncWaitingTitle,
      child: switch (rows) {
        AsyncLoading() => const Center(child: AtomSpinner(size: 28)),
        AsyncError(:final error) => AtomErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(waitingRowsProvider),
        ),
        AsyncData(:final value) when value.isEmpty => SyncEmpty(
          title: l.syncWaitingNone,
          body: l.syncWaitingNoneBody,
        ),
        AsyncData(:final value) => ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            if (!online) ...[
              AtomNote(
                kind: AtomNoteKind.warning,
                compact: true,
                message: l.syncWaitingOrder,
              ),
              const SizedBox(height: 12),
            ],
            AtomSectionLabel(l.syncChangesCount(value.length), page: false),
            SyncCard(
              children: [
                for (final (i, row) in value.indexed)
                  _WaitingRow(row: row, place: i + 1),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
              child: Text(
                l.syncUndoNoteFull,
                style: AtomText.small.copyWith(color: AtomColors.faint),
              ),
            ),
            if (_withPhotos(value) case final photos when photos > 0) ...[
              const SizedBox(height: 14),
              AtomSectionLabel('${l.syncPhotos} · $photos', page: false),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: AtomDecor.card,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.syncPhotosLine(photos),
                        style: AtomText.secondary.copyWith(
                          color: AtomColors.text,
                        ),
                      ),
                    ),
                    AtomPill(label: l.syncPhotoWaiting),
                  ],
                ),
              ),
            ],
          ],
        ),
      },
    );
  }

  static int _withPhotos(List<OutboxEntry> rows) =>
      rows.fold(0, (n, r) => n + SyncStore.filesOf(r).length);
}

class _WaitingRow extends ConsumerWidget {
  const _WaitingRow({required this.row, required this.place});

  final OutboxEntry row;
  final int place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = ref.watch(entryTextProvider((row, l))).value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AtomColors.surface,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$place',
              style: AtomText.tag.copyWith(color: AtomColors.text),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text?.title ?? sayAction(l, row.action),
                  style: AtomText.listTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  [?text?.sub, if (row.tries > 0) l.syncStopNote].join(' · '),
                  style: AtomText.secondary,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AtomButton.small(
            label: l.syncUndo,
            onPressed: () async {
              final done = await ref
                  .read(syncStatusProvider.notifier)
                  .undo(row.id);
              if (!context.mounted) return;
              ref.invalidate(waitingRowsProvider);
              showAtomToast(
                context,
                kind: done ? AtomToastKind.ok : AtomToastKind.wait,
                message: done ? l.syncUndone : l.syncTooLate,
              );
            },
          ),
        ],
      ),
    );
  }
}

final waitingRowsProvider = FutureProvider.autoDispose<List<OutboxEntry>>((
  ref,
) {
  // Again after every run and every save: the list is the outbox now.
  ref.watch(syncStatusProvider.select((s) => (s.waiting, s.lastSyncAt)));
  return ref.watch(syncStoreProvider).waiting(limit: 500);
});
