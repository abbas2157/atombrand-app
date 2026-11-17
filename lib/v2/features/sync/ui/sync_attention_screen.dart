import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/db/outbox_actions.dart';
import '../../../core/db/outbox_db.dart';
import '../../../core/format/money.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/sync_providers.dart';
import 'sync_parts.dart';

/// One change the server would not apply, with its answer (§6.1).
typedef AttentionItem = ({OutboxEntry entry, Map<String, dynamic> answer});

/// What needs the person, oldest first, each with the server's answer.
final attentionItemsProvider = FutureProvider.autoDispose<List<AttentionItem>>((
  ref,
) async {
  ref.watch(syncStatusProvider.select((s) => (s.attention, s.lastSyncAt)));
  final store = ref.watch(syncStoreProvider);
  return [
    for (final e in await store.needingAttention())
      (entry: e, answer: await store.answerOf(e.id) ?? const {}),
  ];
});

/// Needs attention (10.3): saved on this phone, refused by the server.
/// Nothing of these was applied. A change that met a newer record (`seen
/// _changed`) says what the server has now and opens the record; a serial
/// taken meanwhile opens the clash screen (10.4); the rest can be tried
/// again once their cause is gone (a bill paid, a permission given) or
/// discarded.
class SyncAttentionScreen extends ConsumerWidget {
  const SyncAttentionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final items = ref.watch(attentionItemsProvider);

    return SyncScaffold(
      title: l.syncAttentionTitle,
      child: switch (items) {
        AsyncLoading() => const Center(child: AtomSpinner(size: 28)),
        AsyncError(:final error) => AtomErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(attentionItemsProvider),
        ),
        AsyncData(:final value) when value.isEmpty => SyncEmpty(
          title: l.syncAttentionEmpty,
          body: l.syncAttentionEmptyBody,
        ),
        AsyncData(:final value) => ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
              child: Text(l.syncAttentionLead, style: AtomText.secondary),
            ),
            for (final item in value) ...[
              _AttentionCard(key: ValueKey(item.entry.id), item: item),
              const SizedBox(height: 10),
            ],
          ],
        ),
      },
    );
  }
}

class _AttentionCard extends ConsumerStatefulWidget {
  const _AttentionCard({super.key, required this.item});

  final AttentionItem item;

  @override
  ConsumerState<_AttentionCard> createState() => _AttentionCardState();
}

class _AttentionCardState extends ConsumerState<_AttentionCard> {
  bool _busy = false;

  OutboxEntry get row => widget.item.entry;
  Map<String, dynamic> get answer => widget.item.answer;
  String? get reason => row.reason ?? Json.str(answer['reason']);

  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l = AppLocalizations.of(context);
    final moved = await ref.read(syncStatusProvider.notifier).retry(row.id);
    if (!mounted) return;
    setState(() => _busy = false);
    ref.invalidate(attentionItemsProvider);
    showAtomToast(
      context,
      kind: moved ? AtomToastKind.ok : AtomToastKind.wait,
      message: moved ? l.syncRetried : l.syncRetryGone,
    );
  }

  Future<void> _discard() async {
    if (_busy) return;
    final l = AppLocalizations.of(context);
    final yes = await showAtomConfirm(
      context,
      title: l.syncDiscardTitle,
      body: l.syncDiscardBody,
      confirmLabel: l.syncDiscard,
      destructive: true,
      sideBySide: true,
    );
    if (!yes || !mounted || _busy) return;
    setState(() => _busy = true);
    await ref.read(syncStatusProvider.notifier).discard(row.id);
    if (!mounted) return;
    ref.invalidate(attentionItemsProvider);
  }

  /// Where "Check it" goes: the record the change was about.
  String? _record() {
    final d = entryData(row);
    final uuid = Json.str(d['order_uuid']);
    return switch (row.action.split('.').first) {
      'atompay' when uuid != null => V2Routes.atompayOf(uuid),
      'order' when uuid != null => V2Routes.orderOf(uuid),
      'deal' => switch (Json.integer(d['deal_id'])) {
        final id? => V2Routes.dealOf(id),
        null => null,
      },
      'bulk' => switch (Json.integer(d['request_id'])) {
        final id? => V2Routes.bulkRequestOf(id),
        null => null,
      },
      'stock' => V2Routes.stock,
      _ => null,
    };
  }

  /// What the server has now, for `seen_changed`.
  String? _serverNow(AppLocalizations l) {
    final s = Json.map(answer['server']);
    if (s.isEmpty) return null;
    final status = Json.str(s['status']) ?? Json.str(s['step']);
    if (status != null) {
      return l.syncAlreadyMoved(
        status == OrderSteps.verification ? l.syncEntryVerification : status,
      );
    }
    final paid = s['paid'];
    final n = paid is num ? paid : num.tryParse('$paid');
    if (n != null) {
      return l.syncPaidNow(formatRs(n.round()));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = ref.watch(entryTextProvider((row, l))).value;
    final message = row.message ?? Json.str(answer['message']);
    final clash = reason == SyncReasons.serialClash;
    final changed = reason == SyncReasons.seenChanged;
    final canRetry =
        !SyncReasons.noRetry.contains(reason) &&
        !SyncReasons.conflicts.contains(reason);
    final record = _record();
    final tone = changed
        ? AtomTone.rose
        : clash
        ? AtomTone.amber
        : AtomTone.grey;
    final icon = changed || clash
        ? LucideIcons.triangleAlert
        : actionIcon(row.action);

    return Container(
      padding: const EdgeInsets.all(AtomSpace.inset),
      decoration: AtomDecor.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AtomIconTile(icon: icon, tone: tone),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      syncReasonTitle(l, reason, row.action),
                      style: AtomText.listTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        text?.title ?? sayAction(l, row.action),
                        ?message,
                        if (changed) ?_serverNow(l),
                      ].join('. ').replaceAll('..', '.'),
                      style: AtomText.secondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              if (clash)
                AtomButton.small(
                  label: l.syncFix,
                  kind: AtomButtonKind.primary,
                  onPressed: _busy
                      ? null
                      : () => context.push(V2Routes.syncClashOf(row.id)),
                )
              else if (changed && record != null)
                AtomButton.small(
                  label: l.syncCheckIt,
                  kind: AtomButtonKind.primary,
                  onPressed: () => context.push(record),
                ),
              if (canRetry)
                AtomButton.small(
                  label: l.commonTryAgain,
                  onPressed: _busy ? null : _retry,
                ),
              AtomButton.small(
                label: l.syncDiscard,
                kind: AtomButtonKind.danger,
                onPressed: _busy ? null : _discard,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
