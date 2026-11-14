import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/db/outbox_actions.dart';
import '../../../core/db/outbox_db.dart';
import '../../../core/db/sync_store.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/sync_providers.dart';

/// What one outbox action is called, for Waiting to send and Needs
/// attention: the brand contract's keys (`SyncActionKeys`, §6.2). An action
/// this app does not know shows its key rather than nothing, so a person
/// can still say what is stuck.
String sayAction(AppLocalizations l, String action) => switch (action) {
  SyncActionKeys.orderStatus => l.syncActionOrderStatus,
  SyncActionKeys.orderCancel => l.syncActionOrderCancel,
  SyncActionKeys.orderPayment => l.syncActionOrderPayment,
  SyncActionKeys.atompayHandover => l.syncActionAtompayHandover,
  SyncActionKeys.dealDeliver => l.syncActionDealDeliver,
  SyncActionKeys.dealPayment => l.syncActionDealPayment,
  SyncActionKeys.bulkStatus => l.syncActionBulkStatus,
  SyncActionKeys.stockIn => l.syncActionStockIn,
  SyncActionKeys.stockAdjust => l.syncActionStockAdjust,
  SyncActionKeys.stockTransfer => l.syncActionStockTransfer,
  _ => action,
};

/// Why the server set a change aside (10.3), from its `reason` key.
String syncReasonTitle(AppLocalizations l, String? reason, String action) =>
    switch (reason) {
      'seen_changed' => switch (action.split('.').first) {
        'order' || 'atompay' => l.syncReasonOrderChanged,
        'deal' => l.syncReasonDealChanged,
        'bulk' => l.syncReasonRequestChanged,
        _ => l.syncReasonChanged,
      },
      'serial_clash' => l.syncReasonSerial,
      'not_found' => l.syncReasonNotFound,
      'not_allowed' => l.syncReasonNotAllowed,
      'read_only' => l.syncReasonReadOnly,
      'addon' => l.syncReasonAddon,
      'refused' => l.syncReasonRefused,
      'needs_internet' => l.syncNeedsInternet,
      'unknown_action' || 'bad_request' => l.syncReasonCantSend,
      _ => l.syncReasonNotApplied,
    };

/// "You and 2 team phones", "This phone and 1 more".
String syncPhonesLine(AppLocalizations l, int mine, int team) => team > 0
    ? l.syncPhonesTeam(team)
    : mine <= 1
    ? l.syncPhonesThis
    : l.syncPhonesMore(mine - 1);

/// The icon an action is shown with.
IconData actionIcon(String action) => switch (action) {
  SyncActionKeys.orderPayment ||
  SyncActionKeys.dealPayment => LucideIcons.banknote,
  SyncActionKeys.stockTransfer => LucideIcons.arrowLeftRight,
  _ => switch (action.split('.').first) {
    'order' || 'atompay' => LucideIcons.fileText,
    'deal' || 'bulk' => LucideIcons.handshake,
    'stock' => LucideIcons.package,
    _ => LucideIcons.clock,
  },
};

/// An outbox row's fields, read back.
Map<String, dynamic> entryData(OutboxEntry e) => _json(e.data);

/// What the person saw when they saved it.
Map<String, dynamic> entrySeen(OutboxEntry e) => _json(e.seen);

Map<String, dynamic> _json(String raw) {
  try {
    final v = jsonDecode(raw);
    return v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  } on FormatException {
    return <String, dynamic>{};
  }
}

/// How a waiting change reads on 10.2 and 10.3: "Payment Rs 214,999 ·
/// order #48190" over "9:02 · cash".
typedef EntryText = ({String title, String sub});

/// The words for one outbox row, with names looked up in the copy (the
/// order's number, the deal's, the product's title). The copy may be shut
/// behind the PIN: then the row still reads, with less detail.
final entryTextProvider = FutureProvider.autoDispose
    .family<EntryText, (OutboxEntry, AppLocalizations)>((ref, key) async {
      final (e, l) = key;
      final shopId = ref.watch(syncShopIdProvider) ?? 0;
      SyncStore? store;
      if (ref.watch(copyOpenProvider)) store = ref.watch(syncStoreProvider);
      return describeEntry(l, e, store: store, shopId: shopId);
    });

/// [entryTextProvider]'s work, with no Riverpod: tests call it directly.
Future<EntryText> describeEntry(
  AppLocalizations l,
  OutboxEntry e, {
  SyncStore? store,
  required int shopId,
}) async {
  final d = entryData(e);
  final time = AtomDates.time(e.at);

  Future<Map<String, dynamic>?> row(String table, Object? id) async {
    final n = id is int ? id : int.tryParse('$id');
    if (store == null || n == null) return null;
    try {
      return await store.row(table, n, shopId: shopId);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> order(Object? uuid) async {
    if (store == null || uuid == null) return null;
    try {
      for (final t in const ['orders', 'atompay_orders']) {
        for (final r in await store.rows(t, shopId: shopId)) {
          if ('${r['uuid']}' == '$uuid') return r;
        }
      }
    } catch (_) {}
    return null;
  }

  String orderName(Map<String, dynamic>? o) =>
      o?['id'] == null ? l.syncEntryOrder : l.syncEntryOrderNo('${o!['id']}');

  String rs(Object? v) {
    final n = v is num ? v : num.tryParse('$v');
    return n == null ? '' : formatRs(n.round());
  }

  String join(List<String?> parts) => [
    for (final p in parts)
      if (p != null && p.isNotEmpty) p,
  ].join(' · ');

  switch (e.action) {
    case SyncActionKeys.orderStatus:
      final o = await order(d['order_uuid']);
      final status = '${d['status'] ?? ''}';
      return (
        title: join([
          status == OrderSteps.verification ? l.syncEntryVerification : status,
          orderName(o),
        ]),
        sub: join([
          time,
          o?['product_title'] as String?,
          if (d['received_by'] != null)
            l.syncEntryReceivedBy('${d['received_by']}'),
          if (d['serial'] != null) '${d['serial']}',
        ]),
      );
    case SyncActionKeys.orderCancel:
      final o = await order(d['order_uuid']);
      return (
        title: join([l.syncEntryCancelled, orderName(o)]),
        sub: join([
          time,
          o?['product_title'] as String?,
          d['reason'] as String?,
        ]),
      );
    case SyncActionKeys.orderPayment:
      final o = await order(d['order_uuid']);
      return (
        title: join([l.syncEntryPayment(rs(d['amount'])), orderName(o)]),
        sub: join([
          time,
          d['method'] as String?,
          o?['product_title'] as String?,
        ]),
      );
    case SyncActionKeys.atompayHandover:
      final o = await order(d['order_uuid']);
      return (
        title: join([l.syncEntryHandedOver, l.syncEntryAtompay(orderName(o))]),
        sub: join([
          time,
          l.syncEntryReceivedBy('${d['received_by'] ?? ''}'),
          d['serial'] as String?,
        ]),
      );
    case SyncActionKeys.dealDeliver:
      final deal = await row('deals', d['deal_id']);
      var qty = 0;
      if (d['items'] case Map items) {
        for (final line in items.values) {
          if (line is Map) qty += int.tryParse('${line['qty']}') ?? 0;
        }
      }
      return (
        title: join([
          l.syncEntryDelivery,
          l.syncEntryDeal('${deal?['number'] ?? '#${d['deal_id']}'}'),
        ]),
        sub: join([
          time,
          l.syncUnits(qty),
          l.syncEntryReceivedBy('${d['received_by'] ?? ''}'),
        ]),
      );
    case SyncActionKeys.dealPayment:
      final deal = await row('deals', d['deal_id']);
      return (
        title: join([
          l.syncEntryPayment(rs(d['amount'])),
          l.syncEntryDeal('${deal?['number'] ?? '#${d['deal_id']}'}'),
        ]),
        sub: join([
          time,
          d['method'] as String?,
          deal?['buyer_name'] as String?,
        ]),
      );
    case SyncActionKeys.bulkStatus:
      final req = await row('bulk_requests', d['request_id']);
      return (
        title: join([
          '${d['status'] ?? ''}',
          req?['full_name'] as String? ??
              l.syncEntryRequest('${d['request_id']}'),
        ]),
        sub: join([time, d['reason'] as String?, d['comments'] as String?]),
      );
    case SyncActionKeys.stockIn:
      final variant = await row('stock_variants', d['variant_id']);
      final product = await row(
        'stock_products',
        variant?['seller_product_id'],
      );
      final wh = await row('warehouses', d['warehouse_id']);
      final serials = OfflineAction.serialsOf(e.action, d);
      return (
        title: join([
          l.syncEntryStockIn('${d['qty'] ?? serials.length}'),
          product?['title'] as String? ?? variant?['name'] as String?,
        ]),
        sub: join([
          time,
          wh?['name'] as String?,
          if (serials.isNotEmpty) l.syncEntrySerials(serials.length),
        ]),
      );
    case SyncActionKeys.stockAdjust:
      final out = d['direction'] == 'out';
      return (
        title: join([
          out ? l.syncEntryStockOut : l.syncEntryBackIn,
          d['serial'] as String? ??
              (d['unit_id'] == null
                  ? null
                  : l.syncEntryUnit('${d['unit_id']}')),
        ]),
        sub: join([time, d['reason'] as String?, d['note'] as String?]),
      );
    case SyncActionKeys.stockTransfer:
      final wh = await row('warehouses', d['to_warehouse_id']);
      final n =
          OfflineAction.serialsOf(e.action, d).length +
          ((d['unit_ids'] as List?)?.length ?? 0);
      return (
        title: join([
          l.syncEntryMoved(n),
          if (wh?['name'] != null) l.syncEntryTo('${wh!['name']}'),
        ]),
        sub: join([time, d['note'] as String?]),
      );
  }
  return (title: e.action, sub: time);
}

/// Nothing to show, said plainly.
class SyncEmpty extends StatelessWidget {
  const SyncEmpty({
    super.key,
    required this.title,
    required this.body,
    this.icon = LucideIcons.check,
    this.tone = AtomTone.green,
  });

  final String title;
  final String body;
  final IconData icon;
  final AtomTone tone;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AtomIconTile(icon: icon, tone: tone, size: AtomSize.emptyTile),
          const SizedBox(height: 14),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AtomText.heading,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AtomText.body.copyWith(color: AtomColors.muted),
          ),
        ],
      ),
    ),
  );
}

/// A card of rows with lines between them (`.card` with `.grp` rows).
class SyncCard extends StatelessWidget {
  const SyncCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: AtomDecor.card,
    foregroundDecoration: AtomDecor.cardOutline,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, c) in children.indexed) ...[
          if (i > 0) const Divider(height: 1, color: AtomColors.line),
          c,
        ],
      ],
    ),
  );
}

/// One step of a run (10.5, 10.10, 2.7): done, going, or waiting.
enum SyncStepState { done, running, waiting }

class SyncStepRow extends StatelessWidget {
  const SyncStepRow({
    super.key,
    required this.state,
    required this.label,
    this.trailing,
    this.trailingColor,
    this.dark = false,
  });

  final SyncStepState state;
  final String label;
  final String? trailing;
  final Color? trailingColor;

  /// On the navy screen of 2.7.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final mark = switch (state) {
      SyncStepState.done => Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: AtomColors.green,
          shape: BoxShape.circle,
        ),
        child: const Icon(LucideIcons.check, size: 13, color: Colors.white),
      ),
      SyncStepState.running => const SizedBox(
        width: 20,
        height: 20,
        child: Padding(
          padding: EdgeInsets.all(2),
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AtomColors.primary,
          ),
        ),
      ),
      SyncStepState.waiting => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: dark ? AtomColors.navLine : AtomColors.line2,
            width: 2,
          ),
        ),
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          mark,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AtomText.body.copyWith(
                fontWeight: FontWeight.w600,
                color: dark ? Colors.white : AtomColors.ink,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(
              trailing!,
              style: AtomText.small.copyWith(
                color:
                    trailingColor ??
                    (dark ? AtomColors.navMuted : AtomColors.faint),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A plain page bar over a list: the Sync screens' `.pagehead`.
class SyncScaffold extends StatelessWidget {
  const SyncScaffold({
    super.key,
    required this.title,
    required this.child,
    this.bottom,
  });

  final String title;
  final Widget child;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AtomColors.surface,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtomFlowBar(title: title),
        Expanded(child: child),
        ?bottom,
      ],
    ),
  );
}
