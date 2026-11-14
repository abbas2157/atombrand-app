import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/db/sync_store.dart';
import '../../../core/format/money.dart';
import '../../../core/net/network_status.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/getting_ready_due.dart';
import '../data/sync_engine.dart';
import '../data/sync_providers.dart';
import 'sync_parts.dart';

/// The steps of the first copy (2.7), each a few snapshot tables.
List<(String, List<String>)> _steps(AppLocalizations l) => [
  (l.syncReadyOrders, ['orders', 'order_payments', 'order_history']),
  (
    l.syncReadyBulk,
    ['bulk_requests', 'quotes', 'deals', 'deliveries', 'deal_payments'],
  ),
  (l.syncReadyProducts, ['account', 'outlets', 'team', 'products']),
  (
    l.syncReadyStock,
    [
      'warehouses',
      'stock_products',
      'stock_variants',
      'stock_balances',
      'stock_units',
      'stock_holds',
    ],
  ),
  (l.syncReadyAtompay, ['atompay_orders']),
];

/// Getting ready for offline (2.7): the first copy of the brand's orders,
/// deals and stock coming down to this phone, table by table, then the
/// photos. "Start working now" leaves it running: the copy finishes in the
/// background, and the app reads the server meanwhile.
class GettingReadyScreen extends ConsumerStatefulWidget {
  const GettingReadyScreen({super.key});

  @override
  ConsumerState<GettingReadyScreen> createState() => _GettingReadyState();
}

class _GettingReadyState extends ConsumerState<GettingReadyScreen> {
  /// Rows written per table, as the run reports them.
  final _rows = <String, int>{};
  String? _table;
  int _seen = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !ref.read(syncStatusProvider).running) {
        ref.read(syncStatusProvider.notifier).syncNow();
      }
    });
  }

  void _track(SyncProgress p) {
    if (p.phase != SyncPhase.downloading) return;
    final t = _table;
    if (t != null) _rows[t] = (_rows[t] ?? 0) + (p.rows - _seen);
    _seen = p.rows;
    if (p.table != null) _table = p.table;
  }

  /// On the way in the guards move on once [gettingReadyDueProvider] is
  /// done (to where the person was going); opened over the app, it pops.
  void _start() {
    final wayIn = ref.read(gettingReadyDueProvider);
    ref.read(gettingReadyDueProvider.notifier).done();
    if (wayIn) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(V2Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final status = ref.watch(syncStatusProvider);
    final p = status.progress;
    ref.listen(
      syncStatusProvider.select((s) => s.progress),
      (_, next) => setState(() => _track(next)),
    );
    final online = ref.watch(onlineProvider).value ?? true;
    final session = ref.watch(
      sessionProvider.select((s) => s is SignedIn ? s.session : null),
    );
    final where = session?.outletName ?? session?.brandName ?? l.syncYourBrand;

    final tables = SyncStore.tables;
    final at = _table == null ? 0 : tables.indexOf(_table!).clamp(0, 99);
    final pct = switch (p.phase) {
      SyncPhase.done => 100,
      SyncPhase.photos => 92,
      SyncPhase.downloading => (at * 88 / tables.length).round() + 4,
      SyncPhase.sending => 3,
      SyncPhase.checking => 1,
      SyncPhase.idle || SyncPhase.failed => status.lastSyncAt == null ? 0 : 100,
    };
    final downloadedPast =
        p.phase == SyncPhase.photos || p.phase == SyncPhase.done;

    SyncStepState stateOf(List<String> group) {
      if (downloadedPast || pct == 100) return SyncStepState.done;
      if (p.phase != SyncPhase.downloading) return SyncStepState.waiting;
      if (group.contains(_table)) return SyncStepState.running;
      final last = group.map(tables.indexOf).reduce((a, b) => a > b ? a : b);
      return last < at ? SyncStepState.done : SyncStepState.waiting;
    }

    String count(List<String> group) {
      final n = group.fold<int>(0, (s, t) => s + (_rows[t] ?? 0));
      return n == 0 ? '' : groupDigits(n);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AtomColors.nav,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AtomPill(
                  label: online ? l.syncOnlineTag : l.syncOffBar,
                  tone: online ? AtomTone.green : AtomTone.amber,
                  dot: true,
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(
                  l.syncReadyTitle(where),
                  style: AtomText.successTitle.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l.syncReadyBody,
                style: AtomText.body.copyWith(color: AtomColors.navText),
              ),
              const SizedBox(height: 26),
              Text(
                '$pct%',
                style: AtomText.amountLg.copyWith(
                  color: Colors.white,
                  fontSize: 34,
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
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: AtomColors.nav2,
                  borderRadius: AtomRadius.brCard,
                  border: Border.all(color: AtomColors.navLine),
                ),
                child: Column(
                  children: [
                    for (final (label, group) in _steps(l))
                      SyncStepRow(
                        dark: true,
                        state: stateOf(group),
                        label: label,
                        trailing: count(group),
                      ),
                    SyncStepRow(
                      dark: true,
                      state: p.phase == SyncPhase.done || pct == 100
                          ? SyncStepState.done
                          : p.phase == SyncPhase.photos
                          ? SyncStepState.running
                          : SyncStepState.waiting,
                      label: l.syncReadyPhotos,
                    ),
                  ],
                ),
              ),
              if (p.phase == SyncPhase.failed) ...[
                const SizedBox(height: 14),
                AtomNote(
                  kind: AtomNoteKind.warning,
                  message: status.message ?? l.syncReadyFailed,
                ),
              ] else if (pct == 100) ...[
                const SizedBox(height: 14),
                AtomNote(kind: AtomNoteKind.success, message: l.syncReadyDone),
              ],
              const SizedBox(height: 28),
              AtomButton(
                label: l.syncStartNow,
                kind: AtomButtonKind.light,
                onPressed: _start,
              ),
              const SizedBox(height: 10),
              Text(
                l.syncReadyNote,
                textAlign: TextAlign.center,
                style: AtomText.small.copyWith(color: AtomColors.navMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
