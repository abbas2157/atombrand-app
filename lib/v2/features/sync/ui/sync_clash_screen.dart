import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/db/outbox_actions.dart';
import '../../../core/db/outbox_db.dart';
import '../../../core/format/dates.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/clash_fix.dart';
import '../data/sync_providers.dart';
import 'sync_attention_screen.dart' show attentionItemsProvider;
import 'sync_parts.dart';

/// What the clash screen shows: the change, the serials the server named,
/// and where each side has the unit.
typedef ClashView = ({
  OutboxEntry entry,
  List<String> serials,
  String? product,

  /// Where the server's unit is (its warehouse), from the copy.
  String? theirs,

  /// This change's warehouse.
  String? mine,
  int? mineWarehouseId,
  int? productId,
});

final clashProvider = FutureProvider.autoDispose.family<ClashView?, String>((
  ref,
  id,
) async {
  final store = ref.watch(syncStoreProvider);
  final entry = await store.entry(id);
  if (entry == null) return null;
  final answer = await store.answerOf(id) ?? const {};
  final data = entryData(entry);
  final named = [
    for (final s in Json.list(Json.map(answer['details'])['serials']))
      ?Json.str(s),
  ];
  final serials = named.isNotEmpty
      ? named
      : OfflineAction.serialsOf(entry.action, data);
  final shopId = ref.watch(syncShopIdProvider) ?? 0;

  Future<Map<String, dynamic>?> row(String table, Object? rowId) async {
    final n = Json.integer(rowId);
    if (n == null || !ref.read(copyOpenProvider)) return null;
    try {
      return await store.row(table, n, shopId: shopId);
    } catch (_) {
      return null;
    }
  }

  // The server's unit, once the sync after the clash brought it down.
  Map<String, dynamic>? unit;
  if (serials.isNotEmpty && ref.read(copyOpenProvider)) {
    try {
      final wanted = serials.first.toLowerCase();
      for (final u in await store.rows('stock_units', shopId: shopId)) {
        if ('${u['serial']}'.toLowerCase() == wanted ||
            '${u['serial_2']}'.toLowerCase() == wanted) {
          unit = u;
          break;
        }
      }
    } catch (_) {}
  }
  final variant = await row(
    'stock_variants',
    data['variant_id'] ?? unit?['variant_id'],
  );
  final product = await row('stock_products', variant?['seller_product_id']);
  final theirs = await row('warehouses', unit?['warehouse_id']);
  final mineId = Json.integer(data['warehouse_id'] ?? data['to_warehouse_id']);
  final mine = await row('warehouses', mineId);
  return (
    entry: entry,
    serials: serials,
    product: [
      ?Json.str(product?['title']),
      ?Json.str(variant?['name']),
    ].join(' · '),
    theirs: [
      ?Json.str(theirs?['name']),
      ?Json.str(unit?['status'])?.replaceAll('_', ' '),
    ].join(' · '),
    mine: Json.str(mine?['name']),
    mineWarehouseId: mineId,
    productId: Json.integer(product?['product_id']),
  );
});

/// Fix a serial clash (10.4): a serial in this change was taken meanwhile
/// (stocked in on another phone, already sold, handed over). Nothing of
/// the change was applied. The person says what happened, and the outbox
/// is put right: the clashing serials dropped (the rest sent again under a
/// new id), the unit moved here, or the change given up.
class SyncClashScreen extends ConsumerStatefulWidget {
  const SyncClashScreen({super.key, required this.id});

  /// The outbox row's id (`?id=`).
  final String id;

  @override
  ConsumerState<SyncClashScreen> createState() => _SyncClashScreenState();
}

class _SyncClashScreenState extends ConsumerState<SyncClashScreen> {
  int _pick = 0;
  bool _busy = false;

  Future<void> _apply(ClashView v, ClashChoice choice) async {
    if (_busy) return;
    setState(() => _busy = true);
    final fixed = await fixClash(
      ref.read(syncStoreProvider),
      v.entry,
      clashing: v.serials,
      choice: choice,
    );
    await ref.read(syncStatusProvider.notifier).refresh();
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    ref.invalidate(attentionItemsProvider);
    showAtomToast(
      context,
      kind: AtomToastKind.ok,
      message: fixed.kept.isEmpty
          ? l.syncClashFixed
          : '${l.syncClashRest(fixed.kept.length)} ${l.syncClashFixed}',
    );
    if (choice == ClashChoice.wrongBox) {
      context.pushReplacement(V2Routes.stockIn(productId: v.productId));
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final view = ref.watch(clashProvider(widget.id));
    return SyncScaffold(
      title: l.syncClashTitle,
      child: switch (view) {
        AsyncData(value: null) => SyncEmpty(
          title: l.syncClashGone,
          body: l.syncClashFixed,
        ),
        AsyncData(:final value?) => _body(l, value),
        AsyncError() => AtomErrorState(
          onRetry: () => ref.invalidate(clashProvider(widget.id)),
        ),
        _ => const Center(child: AtomSpinner(size: 28)),
      },
    );
  }

  Widget _body(AppLocalizations l, ClashView v) {
    final where = v.mine ?? l.syncThisWarehouse;
    final choices = clashChoices(v.entry.action);
    final pick = choices[_pick.clamp(0, choices.length - 1)];
    (String, String, String) words(ClashChoice c) => switch (c) {
      ClashChoice.dropMine => (
        l.syncClashTwice,
        l.syncClashTwiceSub,
        l.syncClashTwiceDo,
      ),
      ClashChoice.moveHere => (
        l.syncClashMove(where),
        l.syncClashMoveSub(where),
        l.syncClashMoveDo(where),
      ),
      ClashChoice.wrongBox => (
        l.syncClashWrong,
        l.syncClashWrongSub,
        l.syncClashWrongDo,
      ),
      ClashChoice.discard => (
        l.syncClashDiscard,
        l.syncClashDiscardSub,
        l.syncDiscard,
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: AtomDecor.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.serials.join(', '),
                      style: AtomText.listTitle.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      v.product == null || v.product!.isEmpty
                          ? sayAction(l, v.entry.action)
                          : v.product!,
                      style: AtomText.secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Side(
                      tint: AtomColors.surface,
                      label: l.syncClashOther,
                      where: v.theirs == null || v.theirs!.isEmpty
                          ? '—'
                          : v.theirs!,
                      line: l.syncClashSentFirst,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Side(
                      tint: AtomColors.amberSoft,
                      label: l.syncClashMine,
                      where: [?v.mine, AtomDates.time(v.entry.at)].join(' · '),
                      line:
                          '${sayAction(l, v.entry.action)} · '
                          '${l.syncOnThisPhone.toLowerCase()}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                l.syncClashWhat,
                style: AtomText.fieldLabel.copyWith(color: AtomColors.ink),
              ),
              const SizedBox(height: 8),
              for (final (i, c) in choices.indexed) ...[
                AtomOptionCard(
                  selected: _pick == i,
                  title: words(c).$1,
                  subtitle: words(c).$2,
                  onTap: () => setState(() => _pick = i),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: AtomColors.paper,
            border: Border(top: BorderSide(color: AtomColors.line)),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12 + MediaQuery.paddingOf(context).bottom,
          ),
          child: AtomButton(
            label: words(pick).$3,
            saving: _busy,
            kind: pick == ClashChoice.discard
                ? AtomButtonKind.danger
                : AtomButtonKind.primary,
            onPressed: () => _apply(v, pick),
          ),
        ),
      ],
    );
  }
}

/// One side of the comparison (`.cmp > div`).
class _Side extends StatelessWidget {
  const _Side({
    required this.tint,
    required this.label,
    required this.where,
    required this.line,
  });

  final Color tint;
  final String label;
  final String where;
  final String line;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: tint, borderRadius: AtomRadius.brCard),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AtomText.small),
        const SizedBox(height: 4),
        Text(
          where,
          style: AtomText.secondary.copyWith(
            color: AtomColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(line, style: AtomText.small.copyWith(color: AtomColors.text)),
      ],
    ),
  );
}
