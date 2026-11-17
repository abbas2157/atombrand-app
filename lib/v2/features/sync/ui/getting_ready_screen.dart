import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  /// The table the copy is on, as the run reports it.
  String? _table;

  /// Rows the copy holds per step, by the step's index in [_steps].
  final _counts = <int, int>{};
  (SyncPhase, String?)? _countedAt;

  /// The stock step counts units ("1,436 units").
  static const _stockStep = 3;

  /// The tables each step's count is read from.
  static const _countTables = [
    ['orders'],
    ['bulk_requests', 'deals'],
    ['products'],
    ['stock_units'],
    ['atompay_orders'],
  ];

  Future<void> _loadCounts() async {
    if (!mounted) return;
    final store = ref.read(syncStoreProvider);
    final shopId = ref.read(syncShopIdProvider) ?? 0;
    try {
      final next = <int, int>{};
      for (final (i, tables) in _countTables.indexed) {
        var n = 0;
        for (final t in tables) {
          n += await store.count(t, shopId: shopId);
        }
        next[i] = n;
      }
      if (!mounted) return;
      setState(
        () => _counts
          ..clear()
          ..addAll(next),
      );
    } catch (_) {
      // The copy is shut or not there yet: the counts stay blank.
    }
  }

  /// When the copy started moving, for "About N seconds left".
  final _clock = Stopwatch();

  /// The phone is on Wi-Fi: the pill says "Online · Wi-Fi" (2.7).
  bool _wifi = false;
  StreamSubscription<List<ConnectivityResult>>? _net;

  void _onNet(List<ConnectivityResult> r) {
    final wifi = r.contains(ConnectivityResult.wifi);
    if (mounted && wifi != _wifi) setState(() => _wifi = wifi);
  }

  @override
  void dispose() {
    _net?.cancel();
    super.dispose();
  }

  /// "About 25 seconds left", from how fast the copy has gone so far. Null
  /// until there is enough to tell, and once it is done.
  String? _left(AppLocalizations l, int pct) {
    if (pct <= 0 || pct >= 100) return null;
    if (!_clock.isRunning) _clock.start();
    final spent = _clock.elapsedMilliseconds / 1000;
    if (pct < 5 || spent < 2) return null;
    final secs = (spent * (100 - pct) / pct).round();
    if (secs >= 90) return l.authReadyMinutesLeft((secs / 60).round());
    return l.authReadySecondsLeft(secs < 5 ? 5 : (secs / 5).round() * 5);
  }

  @override
  void initState() {
    super.initState();
    final net = Connectivity();
    net.checkConnectivity().then(_onNet, onError: (_) {});
    _net = net.onConnectivityChanged.listen(_onNet, onError: (_) {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !ref.read(syncStatusProvider).running) {
        ref.read(syncStatusProvider.notifier).syncNow();
      }
    });
  }

  void _track(SyncProgress p) {
    if (p.phase != SyncPhase.downloading) return;
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

    // What the copy holds per step, read from the phone as the copy moves
    // ("1,184", "1,436 units").
    if (_countedAt != (p.phase, _table)) {
      _countedAt = (p.phase, _table);
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadCounts());
    }
    String count(int i) {
      final n = _counts[i] ?? 0;
      if (n == 0) return '';
      return i == _stockStep ? l.syncCopyUnits(n) : groupDigits(n);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AtomColors.nav,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _DarkPill(
                          label: online
                              ? (_wifi
                                    ? l.authReadyOnlineWifi
                                    : l.syncOnlineTag)
                              : l.syncOffBar,
                          online: online,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Semantics(
                        header: true,
                        child: Text(
                          l.syncReadyTitle(where),
                          style: AtomText.successTitle.copyWith(
                            color: Colors.white,
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // `.dark .sub`: 15, line 1.5.
                      Text(
                        l.syncReadyBody,
                        style: AtomText.body.copyWith(
                          fontSize: 15,
                          height: 1.5,
                          color: AtomColors.navText,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$pct%',
                            style: AtomText.amountLg.copyWith(
                              color: Colors.white,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _left(l, pct) ?? '',
                              textAlign: TextAlign.end,
                              style: AtomText.secondary.copyWith(
                                color: AtomColors.navMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // `.dark .prog`: a white fill on the navy track.
                      ClipRRect(
                        borderRadius: AtomRadius.brPill,
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          minHeight: 8,
                          backgroundColor: AtomColors.nav2,
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AtomColors.nav2,
                          borderRadius: AtomRadius.brCard,
                          border: Border.all(color: AtomColors.navLine),
                        ),
                        child: Column(
                          children: [
                            for (final (i, (label, group)) in _steps(l).indexed)
                              _Step(
                                first: i == 0,
                                state: stateOf(group),
                                label: label,
                                count: count(i),
                              ),
                            _Step(
                              first: false,
                              state: p.phase == SyncPhase.done || pct == 100
                                  ? SyncStepState.done
                                  : p.phase == SyncPhase.photos
                                  ? SyncStepState.running
                                  : SyncStepState.waiting,
                              label: l.syncReadyPhotos,
                              count: '',
                            ),
                          ],
                        ),
                      ),
                      if (p.phase == SyncPhase.failed) ...[
                        const SizedBox(height: 14),
                        AtomNote(
                          kind: AtomNoteKind.warning,
                          message: l.syncReadyFailed,
                        ),
                      ] else if (pct == 100) ...[
                        const SizedBox(height: 14),
                        AtomNote(
                          kind: AtomNoteKind.success,
                          message: l.syncReadyDone,
                        ),
                      ],
                      const Spacer(),
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
                        style: AtomText.secondary.copyWith(
                          color: AtomColors.navMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.dark .pill.on` / `.dark .pill.off`: "Online · Wi-Fi" on navy.
class _DarkPill extends StatelessWidget {
  const _DarkPill({required this.label, required this.online});

  final String label;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final fg = online ? AtomColors.darkGreen : AtomColors.darkAmber;
    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        // `.dark .pill.off`: rgba(247,169,40,.16) fill, .3 line.
        color: online ? AtomColors.darkGreenFill : const Color(0x29F7A928),
        borderRadius: AtomRadius.brPill,
        border: Border.all(
          color: online ? AtomColors.darkGreenLine : const Color(0x4DF7A928),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: AtomText.small.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One step of the copy (`.step`): 52 tall, a line between steps, the mark
/// (`.st.ok` / `.st.run` / `.st.wait`), the name and what came down.
class _Step extends StatelessWidget {
  const _Step({
    required this.first,
    required this.state,
    required this.label,
    required this.count,
  });

  final bool first;
  final SyncStepState state;
  final String label;
  final String count;

  @override
  Widget build(BuildContext context) {
    final mark = switch (state) {
      // `.st.ok`: rgba(15,117,82,.25) disc, #7BE3B9 tick.
      SyncStepState.done => Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Color(0x400F7552),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          LucideIcons.check,
          size: 16,
          color: AtomColors.darkGreen,
        ),
      ),
      SyncStepState.running => const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ),
      SyncStepState.waiting => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AtomColors.darkDot, width: 2),
        ),
      ),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: first
          ? null
          : const BoxDecoration(
              border: Border(top: BorderSide(color: AtomColors.navLine)),
            ),
      child: Row(
        children: [
          mark,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AtomText.body.copyWith(
                fontSize: 15,
                height: 1.3,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          if (count.isNotEmpty) ...[
            const SizedBox(width: 12),
            Text(
              count,
              style: AtomText.secondary.copyWith(
                color: AtomColors.navMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
