import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access.dart';
import '../../../core/api/api_client.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/lock/app_lock.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../notifications/ui/notifications_screens.dart'
    show noticeLook, openNotice;
import '../data/home_logic.dart';
import '../data/home_models.dart';
import '../data/home_repository.dart';
import 'home_parts.dart';

/// The sections under the hero: the full Home (5.1, shaped by role for
/// 5.2 and by add-ons for 5.5), the offline Home (5.3) and the first day
/// (5.4).

/// The pipeline's colours (`.pipe`), by the server's status.
const _pipeColours = <String, Color>{
  'Pending': AtomColors.amber,
  'Varification': Color(0xFFE59A1F),
  'Processing': Color(0xFF7A5AF8),
  'Delivered': Color(0xFF0E9384),
  'Completed': AtomColors.green,
  'Cancelled': AtomColors.rose,
};

/// Payments received on the chart (the board's amber pair).
const _paidOn = Color(0xFFE59A1F);
const _paidOff = Color(0xFFF3C98A);

void _open(BuildContext context, HomeRoute r) =>
    r.tab ? context.go(r.path) : context.push(r.path);

/// The icon of a task, by its key.
IconData taskIcon(String key) => switch (key) {
  'confirm' => LucideIcons.fileText,
  'hand_over' => LucideIcons.creditCard,
  'record' => LucideIcons.dollarSign,
  'sourcing' || 'bulk' => LucideIcons.funnel,
  'sourcing_change' => LucideIcons.messageCircle,
  'quotes' => LucideIcons.clock,
  'on_hold' => LucideIcons.triangleAlert,
  'stock' => LucideIcons.package,
  _ => LucideIcons.circleAlert,
};

/// "Needs your attention": today's tasks, each with its button.
class HomeTasksSection extends ConsumerWidget {
  const HomeTasksSection({super.key, required this.tasks});

  final List<HomeTask> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final stockOn = ref.watch(accessProvider).has(Addon.inventory);
    return AtomSection(
      title: l.homeNeedsAttention,
      trailing: tasks.isEmpty
          ? null
          : AtomPill(label: l.homeOpen(tasks.length)),
      child: tasks.isEmpty
          ? AtomNote(
              kind: AtomNoteKind.success,
              message: l.homeNothingToDo,
              compact: true,
            )
          : HomeCard(
              children: [
                for (final t in tasks)
                  AtomTaskRow(
                    icon: taskIcon(t.key),
                    tone: taskTone(t.tone),
                    title: t.title,
                    subtitle: t.detail,
                    due: t.deadline,
                    action: switch (taskRoute(t, stockOn: stockOn)) {
                      final r? => MiniButton(
                        label: t.button ?? l.homeViewAll,
                        primary: t.urgent,
                        onTap: () => _open(context, r),
                      ),
                      null => null,
                    },
                  ),
              ],
            ),
    );
  }
}

/// Which of the full Home's sections to draw: all of them (the phone), or
/// one column of the tablet (TabletHome): the money on the left, what to
/// do and what just happened on the right.
enum HomeColumn { all, left, right }

/// Everything under the tasks on the full Home. Each section shows only
/// when the server sent it (the role can see it) and the add-on is on.
class HomeFullSections extends ConsumerWidget {
  const HomeFullSections({
    super.key,
    required this.home,
    this.column = HomeColumn.all,
  });

  final HomeDashboard home;
  final HomeColumn column;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider.notifier).current;
    ref.watch(sessionProvider);
    final who = session?.who ?? const Who.owner();
    final access = ref.watch(accessProvider);
    final pipeline = home.pipeline;
    final bulk = home.bulk;
    final latest = home.latestOrders;
    final seesOrders = who.can(BrandPermission.ordersView);
    final left = column != HomeColumn.right;
    final right = column != HomeColumn.left;
    // A team member's Home (5.2) is the hero, the tasks, the latest orders
    // and the role note; the totals only when the role has `home.totals`.
    // The pipeline, bulk tiles, top products, Atom noticed and the activity
    // feed are the owner's (5.1).
    final owner = who.isOwner;
    final noticed = home.noticed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (right) HomeTasksSection(tasks: home.tasks),
        if (left && home.hasTotals)
          _SalesSection(
            periods: home.periods,
            showReport: who.can(BrandPermission.moneyReports),
          ),
        if (home.chart case final months? when left && months.isNotEmpty)
          AtomSection(
            title: l.homeSalesAndPayments,
            trailing: seesOrders
                ? AtomLink(
                    label: l.homeAllOrders,
                    onTap: () => context.go(V2Routes.orders),
                  )
                : null,
            child: SalesChart(months: months, now: AtomDates.now()),
          ),
        if (pipeline != null && left && owner)
          AtomSection(
            title: l.homeOrderPipeline,
            trailing: AtomLink(
              label: l.homeAllOrders,
              onTap: () => context.go(V2Routes.orders),
            ),
            child: OrderPipeline(
              semanticLabel: l.homePipelineLabel(
                pipeline
                    .map((p) => '${p.count} ${p.label.toLowerCase()}')
                    .join(', '),
              ),
              steps: [
                for (final p in pipeline)
                  PipeStep(
                    p.label,
                    p.count,
                    _pipeColours[p.status] ?? AtomColors.faint,
                    () => context.go(V2Routes.orders),
                  ),
              ],
            ),
          ),
        if (bulk != null && left && owner) _BulkSection(bulk: bulk),
        if (left && home.outlets.isNotEmpty && who.isOwner)
          _OutletsSection(outlets: home.outlets),
        if (right &&
            owner &&
            home.topProducts.isNotEmpty &&
            who.can(BrandPermission.catalogueView))
          AtomSection(
            title: l.homeTopProducts,
            trailing: AtomLink(
              label: l.homeCatalogue,
              onTap: () => context.go(V2Routes.products),
            ),
            child: HomeCard(
              children: [
                for (var i = 0; i < home.topProducts.length && i < 3; i++)
                  HomeRow(
                    leading: _Rank(i + 1),
                    title: home.topProducts[i].title,
                    subtitle: home.topProducts[i].price == null
                        ? null
                        : l.homeCashPriceLine(
                            formatRs(home.topProducts[i].price!),
                          ),
                    amount: l.homeSold(home.topProducts[i].units),
                    onTap: who.can(BrandPermission.catalogueEdit)
                        ? () => context.push(
                            V2Routes.productEditOf(home.topProducts[i].id),
                          )
                        : null,
                  ),
              ],
            ),
          ),
        if (latest != null && right)
          AtomSection(
            title: l.homeLatestOrders,
            trailing: AtomLink(
              label: l.homeViewAll,
              onTap: () => context.go(V2Routes.orders),
            ),
            child: latest.isEmpty
                ? AtomNote(
                    kind: AtomNoteKind.info,
                    message: l.homeNoOrdersYet,
                    compact: true,
                  )
                : HomeCard(
                    children: [
                      for (final o in latest.take(4))
                        _OrderRow(
                          order: o,
                          canAtompay: who.can(BrandPermission.atompayView),
                        ),
                    ],
                  ),
          ),
        // "Atom noticed" (Ask Atom add-on): one insight from the server.
        if (noticed != null && right && owner && access.has(Addon.askAtom))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: HomeNoticedCard(noticed: noticed),
          ),
        if (right && owner && home.activity.isNotEmpty)
          AtomSection(
            title: l.homeRecentActivity,
            trailing: AtomLink(
              label: l.homeAll,
              onTap: () => context.push(V2Routes.notifications),
            ),
            child: HomeCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < home.activity.length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: AtomColors.line),
                    _ActivityRow(activity: home.activity[i]),
                  ],
                ],
              ),
            ),
          ),
        if (home.plan case final plan? when left && who.isOwner)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: _PlanCard(plan: plan),
          ),
        if (right && !who.isOwner && !who.can(BrandPermission.homeTotals))
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Text(
              l.homeAgentNote(who.roleName ?? l.homeTeamMember),
              style: AtomText.small.copyWith(color: AtomColors.faint),
            ),
          ),
        // An add-on that is off leaves its parts out (5.5): nothing more
        // to do here; `access` is watched so they come back when it's on.
        if (access.addons == null) const SizedBox.shrink(),
      ],
    );
  }
}

/// "Your sales on Atomshop": the period switch and four tiles. Every
/// period came in the one call, so switching asks nothing.
class _SalesSection extends StatefulWidget {
  const _SalesSection({required this.periods, required this.showReport});

  final Map<String, SalesFigures> periods;
  final bool showReport;

  @override
  State<_SalesSection> createState() => _SalesSectionState();
}

class _SalesSectionState extends State<_SalesSection> {
  String _period = 'month';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final options = [
      for (final p in salesPeriods)
        if (widget.periods.containsKey(p)) p,
    ];
    final period = options.contains(_period) ? _period : options.first;
    final s = widget.periods[period]!;
    return AtomSection(
      title: l.homeYourSales,
      trailing: widget.showReport
          ? AtomLink(
              label: l.homeReport,
              onTap: () => context.push(V2Routes.reports),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (options.length > 1) ...[
            AtomSegmented<String>(
              segments: [
                for (final p in options) AtomSegment(p, periodName(p, l)),
              ],
              selected: period,
              onChanged: (p) => setState(() => _period = p),
            ),
            const SizedBox(height: 10),
          ],
          AtomKpiGrid(
            kpis: [
              AtomKpi(
                label: l.homeCashSales,
                value: formatRs(s.cashSales),
                note: l.homeOrdersNote(s.orders),
              ),
              AtomKpi(
                label: l.homePaymentsReceived,
                value: formatRs(s.paymentsReceived),
                note: s.stillDue > 0
                    ? l.homeStillDue(formatRs(s.stillDue))
                    : l.homeNothingDue,
              ),
              AtomKpi(
                label: l.homeUnitsSold,
                value: '${s.unitsSold}',
                note: l.homeUnitsNote,
              ),
              AtomKpi(
                label: l.homeLiveOnAtomshop,
                value: l.homeLiveOf(s.live, s.catalogueTotal),
                // In the tile, as on the board, not under the whole grid.
                progress: s.catalogueTotal > 0 ? s.liveShare : null,
                // `.prog i`: the primary blue.
                progressColour: AtomColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Six months of cash sales and payments received; tap a month to read
/// it. The current month is chosen at first.
class SalesChart extends StatefulWidget {
  const SalesChart({super.key, required this.months, required this.now});

  final List<ChartMonth> months;
  final DateTime now;

  @override
  State<SalesChart> createState() => _SalesChartState();
}

class _SalesChartState extends State<SalesChart> {
  late int _picked = widget.months.length - 1;

  String _long(int i) {
    final back = widget.months.length - 1 - i;
    final d = DateTime(widget.now.year, widget.now.month - back);
    final l = AppLocalizations.of(context);
    final name = DateFormat('MMMM').format(d);
    return back == 0 ? l.homeMonthSoFar(name) : name;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final months = widget.months;
    final picked = _picked.clamp(0, months.length - 1);
    final heights = chartHeights(months);
    final m = months[picked];
    return HomeCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text(_long(picked), style: AtomText.secondary)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  formatRs(m.sales),
                  textAlign: TextAlign.end,
                  style: AtomText.money.copyWith(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              l.homeReceived(formatRs(m.paid)),
              style: AtomText.small.copyWith(color: AtomColors.amberInk),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < months.length; i++)
                  Expanded(
                    child: AtomPressable(
                      onTap: () => setState(() => _picked = i),
                      selected: i == picked,
                      scaleOnPress: false,
                      semanticLabel: l.homeChartBarLabel(
                        _long(i),
                        formatRs(months[i].sales),
                        formatRs(months[i].paid),
                      ),
                      builder: (_, _) => ExcludeSemantics(
                        child: _Bars(
                          sales: heights[i].$1,
                          paid: heights[i].$2,
                          on: i == picked,
                          tag: i == picked
                              ? compactAmount(months[i].sales)
                              : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < months.length; i++)
                Expanded(
                  child: Text(
                    months[i].label,
                    textAlign: TextAlign.center,
                    style: AtomText.small.copyWith(
                      color: i == picked ? AtomColors.ink : AtomColors.muted,
                      fontWeight: i == picked ? FontWeight.w700 : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            children: [
              _legend(AtomColors.primary, l.homeCashSales),
              _legend(_paidOn, l.homePaymentsReceived),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: c,
          borderRadius: const BorderRadius.all(Radius.circular(3)),
        ),
      ),
      const SizedBox(width: 6),
      Flexible(child: Text(label, style: AtomText.small)),
    ],
  );
}

class _Bars extends StatelessWidget {
  const _Bars({
    required this.sales,
    required this.paid,
    required this.on,
    this.tag,
  });

  final double sales;
  final double paid;
  final bool on;
  final String? tag;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const tagSpace = 18.0;
      final h = box.maxHeight - tagSpace;
      Widget bar(double f, Color c) => Container(
        width: 12,
        height: (h * f).clamp(f > 0 ? 2.0 : 0.0, h),
        decoration: BoxDecoration(
          color: c,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
        ),
      );
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: tagSpace,
            child: tag == null
                ? null
                : Text(
                    tag!,
                    style: AtomText.tag.copyWith(color: AtomColors.primary),
                  ),
          ),
          SizedBox(
            height: h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                bar(sales, on ? AtomColors.primary : AtomColors.chartBar),
                const SizedBox(width: 3),
                bar(paid, on ? _paidOn : _paidOff),
              ],
            ),
          ),
        ],
      );
    },
  );
}

/// The Bulk deals tiles: New, Contacted, Quoted, Won, Lost, Delivering.
class _BulkSection extends StatelessWidget {
  const _BulkSection({required this.bulk});
  final BulkTiles bulk;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tiles = <(String, int, Color?, String)>[
      (l.homeBulkNew, bulk.newCount, AtomColors.primary, 'website'),
      (l.homeBulkContacted, bulk.contacted, null, 'website'),
      (l.homeBulkQuoted, bulk.quoted, AtomColors.amberInk, 'website'),
      (l.homeBulkWon, bulk.won, AtomColors.green, 'deals'),
      (l.homeBulkLost, bulk.lost, AtomColors.rose, 'website'),
      if (bulk.delivering case final d?)
        (l.homeBulkDelivering, d, null, 'deals'),
    ];
    return AtomSection(
      title: l.homeBulkDeals,
      trailing: AtomLink(
        label: l.homeAllRequests,
        onTap: () => context.go(V2Routes.bulk),
      ),
      // Rows of three, every tile the same width and height (a fractional
      // width in a Wrap pushed the third tile onto its own line).
      child: Column(
        children: [
          for (var r = 0; r < tiles.length; r += 3) ...[
            if (r > 0) const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var c = r; c < r + 3; c++) ...[
                    if (c > r) const SizedBox(width: 8),
                    Expanded(
                      child: c < tiles.length
                          ? _BulkTile(tile: tiles[c])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One Bulk deals tile: the label, then the count in the stage's colour.
class _BulkTile extends StatelessWidget {
  const _BulkTile({required this.tile});
  final (String, int, Color?, String) tile;

  @override
  Widget build(BuildContext context) {
    final (label, n, colour, tab) = tile;
    return AtomPressable(
      onTap: () => context.go(V2Routes.bulkTab(tab)),
      semanticLabel: '$label, $n',
      builder: (_, pressed) => ExcludeSemantics(
        child: Container(
          // Fill the column, so every tile in a row is the same size.
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: pressed
              ? AtomDecor.card.copyWith(color: AtomColors.head)
              : AtomDecor.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtomText.secondary,
              ),
              const SizedBox(height: 2),
              Text(
                '$n',
                style: AtomText.pageTitle.copyWith(
                  color: colour,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Your outlets this month" (owner of a multi-outlet brand, All outlets).
class _OutletsSection extends StatelessWidget {
  const _OutletsSection({required this.outlets});
  final List<OutletMonth> outlets;

  static const _tones = [AtomTone.blue, AtomTone.green, AtomTone.amber];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AtomSection(
      title: l.homeOutletsThisMonth,
      trailing: AtomLink(
        label: l.homeOutlets,
        onTap: () => context.push(V2Routes.outlets),
      ),
      child: HomeCard(
        children: [
          for (var i = 0; i < outlets.length; i++)
            HomeRow(
              leading: AtomInitials(
                name: outlets[i].name,
                tone: _tones[i % _tones.length],
              ),
              title: outlets[i].name,
              subtitle: l.homeOutletLine(
                outlets[i].orders,
                outlets[i].toConfirm,
              ),
              amount: formatRs(outlets[i].sales),
              pill: outlets[i].open
                  ? RowPill(label: l.homeOpenPill, tone: AtomTone.green)
                  : RowPill(label: l.homePausedPill, tone: AtomTone.grey),
              onTap: () => context.push(V2Routes.outletOf(outlets[i].id)),
            ),
        ],
      ),
    );
  }
}

/// When an order or a notice happened: "today 9:12 am", "yesterday",
/// "11 Nov".
String whenText(DateTime? at, DateTime now, AppLocalizations l) {
  if (at == null) return '';
  final days = AtomDates.daysFrom(at, today: now);
  if (days == 0) return l.homeWhenToday(AtomDates.time(at));
  if (days == -1) return l.homeYesterday;
  return AtomDates.shortOrYear(at);
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.canAtompay});
  final HomeOrder order;
  final bool canAtompay;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final o = order;
    final open = !o.atompay || canAtompay;
    return HomeRow(
      title: [
        '#${o.id}',
        if (o.productTitle != null) o.productTitle!,
      ].join(' · '),
      subtitle: [
        o.atompay ? l.homeAtompay : l.homeCash,
        if (o.city != null && o.city!.isNotEmpty) o.city!,
        whenText(o.createdAt, AtomDates.now(), l),
      ].where((s) => s.isNotEmpty).join(' · '),
      amount: formatRs(o.total),
      pill: RowPill(label: o.statusLabel, tone: orderTone(o.status)),
      onTap: open && o.uuid.isNotEmpty
          ? () => context.push(
              o.atompay ? V2Routes.atompayOf(o.uuid) : V2Routes.orderOf(o.uuid),
            )
          : null,
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});
  final HomeActivity activity;

  @override
  Widget build(BuildContext context) {
    final n = activity.notice;
    final (icon, tone) = noticeLook(n.type, n.data);
    final at = n.at;
    final time = at == null
        ? activity.timeAgo ?? ''
        : AtomDates.daysFrom(at, today: AtomDates.now()) == 0
        ? AtomDates.time(at)
        : whenText(at, AtomDates.now(), AppLocalizations.of(context));
    return ActivityLine(
      icon: icon,
      tone: tone,
      text: n.body.isNotEmpty ? n.body : n.title,
      meta: [
        time,
        if (n.body.isNotEmpty) n.title,
      ].where((s) => s.isNotEmpty).join(' · '),
      onTap: () => openNotice(context, n),
    );
  }
}

/// The plan card: the package, paid until, the add-ons that are on.
class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});
  final PlanSummary plan;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final line = [
      if (plan.paidUntil != null)
        l.homePaidUntil(AtomDates.short(plan.paidUntil!)),
      plan.addonsOn.isEmpty ? l.homeNoAddons : plan.addonsOn.join(', '),
    ].join(' · ');
    return AtomPressable(
      onTap: () => context.push(V2Routes.plan),
      semanticLabel: '${plan.packageName}, $line, ${l.homePlanAndBilling}',
      focusRadius: AtomRadius.brCard,
      builder: (_, pressed) => ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: pressed
              ? AtomDecor.card.copyWith(color: AtomColors.head)
              : AtomDecor.card,
          foregroundDecoration: AtomDecor.cardOutline,
          child: Row(
            children: [
              const HomeIconTile(icon: LucideIcons.star, tone: AtomTone.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.packageName,
                      style: AtomText.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AtomColors.ink,
                      ),
                    ),
                    Text(line, style: AtomText.secondary),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // At most a third of the row, so the plan line keeps the rest
              // and large text wraps rather than overflowing.
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width / 3,
                ),
                child: Text(
                  l.homePlanAndBilling,
                  style: AtomText.secondary.copyWith(
                    color: AtomColors.primary,
                    fontWeight: FontWeight.w600,
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

// ───────────────────────────────────────────── offline (5.3)

/// The tasks this phone can still do with no signal, from its copy.
class HomeOfflineSections extends ConsumerWidget {
  const HomeOfflineSections({super.key, required this.figures});

  final OfflineHome figures;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final who =
        ref.watch(sessionProvider.notifier).current?.who ?? const Who.owner();
    ref.watch(sessionProvider);
    final f = figures;
    final rows = <Widget>[
      if (f.toDeliver > 0 && who.can(BrandPermission.ordersStatus))
        AtomTaskRow(
          icon: LucideIcons.truck,
          tone: AtomTone.amber,
          title: l.homeMarkDelivered(f.toDeliver),
          subtitle: l.homeWithProof,
          action: MiniButton(
            label: l.homeDeliver,
            primary: true,
            onTap: () => context.go(V2Routes.orders),
          ),
        ),
      if (f.unpaidOrders > 0 && who.can(BrandPermission.ordersPayment))
        AtomTaskRow(
          icon: LucideIcons.dollarSign,
          tone: AtomTone.green,
          title: l.homeToRecord(formatRs(f.unpaidAmount), f.unpaidOrders),
          subtitle: l.homeWorksOffline,
          action: MiniButton(
            label: l.homeRecord,
            onTap: () => context.go(V2Routes.orders),
          ),
        ),
      if (f.newRequests > 0 && who.can(BrandPermission.bulkView))
        ColoredBox(
          color: AtomColors.head,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const HomeIconTile(
                  icon: LucideIcons.funnel,
                  tone: AtomTone.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.homeReplyRequests(f.newRequests),
                        style: AtomText.listTitle.copyWith(
                          color: AtomColors.muted,
                        ),
                      ),
                      Text(l.homeQuoteNeedsInternet, style: AtomText.secondary),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AtomPill(label: l.homeOnlineOnly),
              ],
            ),
          ),
        ),
    ];
    return AtomSection(
      title: l.homeNeedsAttention,
      trailing: Text(
        l.homeFromCopy,
        style: AtomText.small.copyWith(color: AtomColors.faint),
      ),
      child: rows.isEmpty
          ? AtomNote(
              kind: AtomNoteKind.info,
              message: l.homeNothingOffline,
              compact: true,
            )
          : HomeCard(children: rows),
    );
  }
}

// ───────────────────────────────────────────── first day (5.4)

/// The first steps of a new brand, each opening its screen.
class HomeFirstSteps extends ConsumerWidget {
  const HomeFirstSteps({super.key, required this.steps});

  final List<FirstStep> steps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final askAtom = ref.watch(accessProvider).has(Addon.askAtom);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtomSection(
          title: l.homeFirstSteps,
          trailing: Text(
            l.homeAboutTen,
            style: AtomText.small.copyWith(color: AtomColors.faint),
          ),
          child: HomeCard(children: [for (final s in steps) _StepRow(step: s)]),
        ),
        if (askAtom)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: AtomPressable(
              onTap: () => context.push(V2Routes.askAtom),
              semanticLabel: l.homeStuck,
              focusRadius: AtomRadius.brCard,
              builder: (_, _) => ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AtomColors.primarySoft,
                    borderRadius: AtomRadius.brCard,
                    border: Border.all(color: AtomColors.primaryLine),
                  ),
                  child: Row(
                    children: [
                      const AtomAiMark(size: 40, radius: AtomRadius.brControl),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.homeStuck, style: AtomText.listTitle),
                            Text(
                              l.homeStuckQ,
                              style: AtomText.secondary.copyWith(
                                color: AtomColors.noteBlueText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});
  final FirstStep step;

  @override
  Widget build(BuildContext context) => AtomPressable(
    onTap: () => context.push(step.path),
    scaleOnPress: false,
    semanticLabel: '${step.title}${step.done ? ', done' : ''}',
    builder: (_, pressed) => ExcludeSemantics(
      child: Container(
        constraints: const BoxConstraints(minHeight: 62),
        color: pressed ? AtomColors.head : AtomColors.paper,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.done ? AtomColors.green : null,
                border: Border.all(
                  color: step.done ? AtomColors.green : AtomColors.line2,
                  width: 2,
                ),
              ),
              child: step.done
                  ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: AtomText.listTitle.copyWith(
                      color: step.done ? AtomColors.muted : AtomColors.ink,
                      decoration: step.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(step.sub, style: AtomText.secondary),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AtomColors.chevron,
            ),
          ],
        ),
      ),
    ),
  );
}

/// The first-day steps for this brand, from what the phone and the
/// server know.
List<FirstStep> firstStepsFor(
  WidgetRef ref,
  HomeDashboard home,
  AppLocalizations l,
) {
  final session = ref.watch(sessionProvider.notifier).current;
  final known = ref.watch(homeFirstStepsProvider).value;
  return firstSteps(
    hasPin: ref.watch(appLockProvider).prefs.hasPin,
    products: home.catalogueTotal,
    hasLogo: (session?.brandLogo ?? '').isNotEmpty,
    paymentsChosen: known?.payments ?? false,
    teamOn: ref.watch(accessProvider).has(Addon.team),
    teamMembers: known?.team ?? 0,
    l: l,
  );
}

/// A top product's rank (`.ini`): a blue circle for every place.
class _Rank extends StatelessWidget {
  const _Rank(this.n);
  final int n;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: AtomColors.primarySoft,
      shape: BoxShape.circle,
    ),
    child: Text(
      '$n',
      style: AtomText.body.copyWith(
        color: AtomColors.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// "Atom noticed" (5.1 `.atom`): the server's one insight, in bold then
/// plain, and a button to where it can be acted on.
class HomeNoticedCard extends ConsumerWidget {
  const HomeNoticedCard({super.key, required this.noticed});
  final HomeNoticed noticed;

  /// Where the insight's button goes, and its label; null when the person
  /// can't open it.
  (String, bool, String)? _action(AppLocalizations l, Who who) {
    final p = noticed.params;
    int? id(String k) => Json.integer(p[k]);
    switch (noticed.screen) {
      case 'stock_product' when id('product_id') != null:
        return (
          V2Routes.productStockOf(id('product_id')!),
          false,
          l.homeNoticedSeeStock,
        );
      case 'orders' when who.can(BrandPermission.ordersView):
        return (
          V2Routes.ordersWith(status: Json.str(p['status'])),
          true,
          l.homeConfirmOrders,
        );
      case 'outlets' when id('outlet_id') != null && who.isOwner:
        return (
          V2Routes.outletOf(id('outlet_id')!),
          false,
          l.homeNoticedOpenOutlet,
        );
      case 'bulk_orders' when who.can(BrandPermission.bulkView):
        return (V2Routes.bulkTab('website'), true, l.homeNoticedFollowUp);
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final who =
        ref.watch(sessionProvider.notifier).current?.who ?? const Who.owner();
    final hour = ref.watch(homeClockProvider)().hour;
    final sub = hour < 12
        ? l.homeNoticedMorning
        : hour < 17
        ? l.homeNoticedAfternoon
        : l.homeNoticedEvening;
    final action = _action(l, who);
    const ink = Color(0xFF1C318C);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AtomColors.primarySoft,
        borderRadius: AtomRadius.brCard,
        border: Border.all(color: AtomColors.primaryLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HomeIconTile(
                icon: LucideIcons.sparkles,
                tone: AtomTone.blue,
                background: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        l.homeNoticedTitle,
                        style: AtomText.listTitle,
                      ),
                    ),
                    Text(
                      sub,
                      style: AtomText.small.copyWith(color: AtomColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: AtomText.body.copyWith(color: ink, height: 1.5),
              children: [
                if (noticed.title.isNotEmpty) ...[
                  TextSpan(
                    text: noticed.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (noticed.text.isNotEmpty) const TextSpan(text: '. '),
                ],
                TextSpan(text: noticed.text),
              ],
            ),
          ),
          if (action case (final path, final tab, final label)) ...[
            const SizedBox(height: 10),
            MiniButton(
              label: label,
              primary: true,
              onTap: () => tab ? context.go(path) : context.push(path),
            ),
          ],
        ],
      ),
    );
  }
}
