import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/db/copy_key.dart';
import '../../../core/format/dates.dart';
import '../../../core/net/network_status.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/sync_engine.dart';
import '../data/sync_providers.dart';
import 'sync_parts.dart';
import 'sync_phones_screen.dart' show phonesProvider;

/// Sync (10.1, Offline add-on): where this phone stands with the server.
///
/// The navy state card says online or offline, when it last synced, how
/// long this phone may keep working without the server, and Sync now.
/// Under it: what needs the person, what is waiting, the photos going with
/// it; then the phones signed in and what the copy holds.
///
/// "Messages held" (receipts and WhatsApp messages sent once the change
/// is) is on the board but not here: the brand server sends no such
/// messages from the outbox yet, and an always-zero row would read as
/// "none held" rather than "not built".
class SyncCentreScreen extends ConsumerWidget {
  const SyncCentreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final status = ref.watch(syncStatusProvider);
    final online = ref.watch(onlineProvider).value ?? true;
    final phones = ref.watch(phonesProvider);

    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(phonesProvider);
              ref.invalidate(copyCountsProvider);
              await ref.read(syncStatusProvider.notifier).refresh();
            },
            child: ListView(
              padding: EdgeInsets.only(
                bottom: 24 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                _Head(status: status, online: online),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (status.check?.readOnly ?? false) ...[
                        AtomNote(
                          kind: AtomNoteKind.warning,
                          message: l.syncReadOnly,
                        ),
                        const SizedBox(height: 12),
                      ],
                      SyncCard(
                        children: [
                          _Row(
                            icon: LucideIcons.triangleAlert,
                            tone: AtomTone.rose,
                            title: l.syncAttentionTitle,
                            sub: l.syncAttentionSub,
                            count: '${status.attention}',
                            countColor: status.attention > 0
                                ? AtomColors.rose
                                : AtomColors.faint,
                            onTap: () => context.push(V2Routes.syncAttention),
                          ),
                          _Row(
                            icon: LucideIcons.clock,
                            tone: AtomTone.amber,
                            title: l.syncWaitingTitle,
                            sub: l.syncWaitingSub,
                            count: '${status.waiting}',
                            onTap: () => context.push(V2Routes.syncWaiting),
                          ),
                          _Row(
                            icon: LucideIcons.image,
                            tone: AtomTone.grey,
                            title: l.syncPhotos,
                            sub: status.photos > 0
                                ? l.syncPhotosWaiting(status.photos)
                                : l.syncPhotosNone,
                            count: '${status.photos}',
                            onTap: () => context.push(V2Routes.syncWaiting),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SyncCard(
                        children: [
                          _Row(
                            icon: LucideIcons.smartphone,
                            tone: AtomTone.grey,
                            title: l.syncPhones,
                            sub: switch (phones) {
                              AsyncData(:final value) => syncPhonesLine(
                                l,
                                value.mine.where((d) => d.signedIn).length,
                                [
                                  for (final t in value.team)
                                    ...t.devices.where((d) => d.signedIn),
                                ].length,
                              ),
                              _ => l.syncPhonesLoading,
                            },
                            onTap: () => context.push(V2Routes.syncPhones),
                          ),
                          const _CopyRow(),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 12, 2, 0),
                        child: Text(
                          l.syncFootnote,
                          style: AtomText.small.copyWith(
                            color: AtomColors.faint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const AtomNavyStatusStrip(),
        ],
      ),
    );
  }
}

/// The navy top and the state card (`.state`).
class _Head extends ConsumerWidget {
  const _Head({required this.status, required this.online});

  final SyncStatus status;
  final bool online;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final running = status.running;
    final dot = online ? AtomColors.darkGreen : AtomColors.darkAmber;
    final last = status.lastSyncAt;
    final title = !online
        ? l.syncOffline
        : last == null
        ? l.syncNeverSynced
        : l.syncOnline(AtomDates.time(last));
    final sub = !online && status.waiting > 0
        ? l.syncLastSyncWaiting(
            last == null ? '—' : _when(l, last),
            status.waiting,
          )
        : status.attention > 0
        ? (status.waiting > 0
              ? '${l.syncSomeWaiting(status.waiting)} '
                    '${l.syncSomeAttention(status.attention)}'
              : l.syncAllSentExcept(status.attention))
        : status.waiting > 0
        ? l.syncSomeWaiting(status.waiting)
        : status.loaded
        ? l.syncAllSent
        : '';

    return AtomNavyHeader(
      bottom: 16,
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
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AtomColors.nav2,
          borderRadius: BorderRadius.circular(AtomRadius.sheet),
          border: Border.all(color: AtomColors.navLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: AtomText.heading.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                sub,
                style: AtomText.secondary.copyWith(color: AtomColors.navText),
              ),
            ],
            if (status.offlineUntil case final until?) ...[
              const SizedBox(height: 8),
              _UntilLine(until: until, paidUntil: status.check?.paidUntil),
            ],
            const SizedBox(height: 10),
            _WindowBar(until: status.offlineUntil),
            if (running) ...[
              const SizedBox(height: 12),
              AtomButton(
                label: l.syncSentOf(
                  status.progress.sent,
                  status.progress.toSend,
                ),
                kind: AtomButtonKind.light,
                compact: true,
                onPressed: () => context.push(V2Routes.syncRunning),
              ),
            ] else if (online) ...[
              const SizedBox(height: 12),
              AtomButton(
                label: l.syncNow,
                kind: AtomButtonKind.light,
                compact: true,
                onPressed: () {
                  ref.read(syncStatusProvider.notifier).syncNow();
                  context.push(V2Routes.syncRunning);
                },
              ),
            ],
            if (status.stop case final stop? when !running) ...[
              const SizedBox(height: 10),
              Text(
                _say(l, stop, status.message),
                style: AtomText.secondary.copyWith(
                  color: AtomColors.darkAmber,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (stop == SyncStop.updateNeeded) ...[
                const SizedBox(height: 10),
                AtomButton(
                  label: Theme.of(context).platform == TargetPlatform.iOS
                      ? l.updateButtonIos
                      : l.syncUpdateOnPlay,
                  kind: AtomButtonKind.light,
                  compact: true,
                  onPressed: () => context.push(V2Routes.syncUpdate),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  static String _when(AppLocalizations l, DateTime d) {
    final days = AtomDates.daysFrom(d, today: AtomDates.now());
    return days == 0
        ? l.syncWhenToday(AtomDates.time(d))
        : '${AtomDates.short(d)}, ${AtomDates.time(d)}';
  }

  String _say(AppLocalizations l, SyncStop stop, String? message) =>
      switch (stop) {
        SyncStop.offline => l.syncOffline,
        SyncStop.updateNeeded => l.syncUpdateTitle,
        SyncStop.offlineEnded => l.syncEndedTitle,
        SyncStop.wiped || SyncStop.notAllowed => message ?? l.syncFailed,
        SyncStop.failed => message ?? l.syncFailed,
      };
}

/// "Works offline until 30 Nov", and why that day when it is the plan's.
class _UntilLine extends StatelessWidget {
  const _UntilLine({required this.until, this.paidUntil});

  final DateTime until;
  final DateTime? paidUntil;

  @override
  Widget build(BuildContext context) {
    final byPlan =
        paidUntil != null && AtomDates.daysFrom(until, today: paidUntil!) == 0;
    final l = AppLocalizations.of(context);
    final style = AtomText.secondary.copyWith(color: AtomColors.navText);
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              style: style,
              children: [
                TextSpan(text: l.syncWorksUntilLead),
                const TextSpan(text: ' '),
                TextSpan(
                  text: AtomDates.short(until),
                  style: style.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (byPlan) Text(l.syncUntilWhy, style: style),
      ],
    );
  }
}

/// How much of the offline window is used up (`.prog` on the card).
class _WindowBar extends StatelessWidget {
  const _WindowBar({required this.until});

  final DateTime? until;

  @override
  Widget build(BuildContext context) {
    final u = until;
    final left = u == null
        ? 0.0
        : (u.difference(DateTime.now()).inHours / (30 * 24)).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: AtomRadius.brPill,
      child: LinearProgressIndicator(
        value: u == null ? 0 : 1 - left,
        minHeight: 6,
        backgroundColor: AtomColors.navLine,
        valueColor: const AlwaysStoppedAnimation(AtomColors.darkGreen),
      ),
    );
  }
}

/// One row of the Sync centre list (`.grp`).
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.tone,
    required this.title,
    required this.sub,
    required this.onTap,
    this.count,
    this.countColor,
  });

  final IconData icon;
  final AtomTone tone;
  final String title;
  final String sub;
  final String? count;
  final Color? countColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AtomPressable(
      onTap: onTap,
      semanticLabel: count == null ? title : '$title, $count',
      scaleOnPress: false,
      focusRadius: BorderRadius.zero,
      builder: (_, pressed) => Container(
        color: pressed ? AtomColors.head : AtomColors.paper,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: const BoxConstraints(minHeight: AtomSize.tapTarget),
        child: Row(
          children: [
            AtomIconTile(icon: icon, tone: tone),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AtomText.listTitle),
                  const SizedBox(height: 2),
                  Text(sub, style: AtomText.secondary),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (count != null)
              Text(
                count!,
                style: AtomText.money.copyWith(
                  fontSize: 16,
                  color: countColor ?? AtomColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              const Icon(
                LucideIcons.chevronRight,
                size: AtomIcon.inline,
                color: AtomColors.chevron,
              ),
          ],
        ),
      ),
    );
  }
}

/// "On this phone": what the copy holds, counted from the phone.
class _CopyRow extends ConsumerWidget {
  const _CopyRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final counts = ref.watch(copyCountsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const AtomIconTile(icon: LucideIcons.database, tone: AtomTone.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.syncOnThisPhone, style: AtomText.listTitle),
                const SizedBox(height: 2),
                Text(switch (counts) {
                  AsyncData(value: null) => l.syncCopyLocked,
                  AsyncData(:final value?) when value.isEmpty =>
                    l.syncCopyNothing,
                  AsyncData(:final value?) => [
                    for (final c in value) _copyPart(l, c),
                    l.syncEncrypted,
                  ].join(' · '),
                  _ => '…',
                }, style: AtomText.secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Counts behind "312 orders · 46 products · 341 units · 14 bulk requests ·
/// 186 MB": null while the copy is shut behind the PIN, empty when it holds
/// nothing.
typedef CopyCount = ({String kind, int n});

final copyCountsProvider = FutureProvider.autoDispose<List<CopyCount>?>((
  ref,
) async {
  if (!ref.watch(copyOpenProvider)) return null;
  ref.watch(syncStatusProvider.select((s) => s.lastSyncAt));
  final shopId = ref.watch(syncShopIdProvider) ?? 0;
  final store = ref.watch(syncStoreProvider);
  CopyCount? part(String kind, int n) => n == 0 ? null : (kind: kind, n: n);
  try {
    final orders =
        await store.count('orders', shopId: shopId) +
        await store.count('atompay_orders', shopId: shopId);
    final parts = [
      ?part('orders', orders),
      ?part('products', await store.count('products', shopId: shopId)),
      ?part('units', await store.count('stock_units', shopId: shopId)),
      ?part('bulk', await store.count('bulk_requests', shopId: shopId)),
    ];
    if (parts.isEmpty) return const [];
    try {
      final bytes = await (await CopyKey.file()).length();
      parts.add((kind: 'mb', n: (bytes / (1024 * 1024)).ceil()));
    } catch (_) {}
    return parts;
  } catch (_) {
    return null;
  }
});

String _copyPart(AppLocalizations l, CopyCount c) => switch (c.kind) {
  'orders' => l.syncCopyOrders(c.n),
  'products' => l.syncCopyProducts(c.n),
  'units' => l.syncCopyUnits(c.n),
  'bulk' => l.syncCopyBulk(c.n),
  _ => l.syncCopyMb(c.n),
};
