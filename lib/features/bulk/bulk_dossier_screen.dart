import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/app_icons.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/models/bulk.dart';
import '../../data/repositories/orders_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/status_badge.dart';
import 'bulk_logic.dart';
import 'bulk_screen.dart';

/// Bulk request (DESIGN.md §4.5): who the buyer is, what they want, and
/// what to do next. The requester's dealings are with this brand only (§2.4).
class BulkDossierScreen extends ConsumerStatefulWidget {
  const BulkDossierScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<BulkDossierScreen> createState() => _BulkDossierScreenState();
}

class _BulkDossierScreenState extends ConsumerState<BulkDossierScreen> {
  BulkDossier? _d;
  String? _error;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final d = await ref.read(bulkRepositoryProvider).dossier(widget.id);
      if (mounted) setState(() => _d = d);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _updateStatus() async {
    final d = _d;
    if (d == null) return;
    final statuses = ref.read(configProvider).value?.bulkStatuses ?? const ['New Lead', 'Contacted', 'Quoted', 'Won', 'Lost'];
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _UpdateLeadSheet(request: d.request, statuses: statuses.where((s) => s != 'New Lead').toList()),
    );
    if (updated == true) {
      _changed = true;
      ref.read(sessionProvider.notifier).refreshBadge();
      if (mounted) showToast(context, 'Lead updated');
      await _load();
    }
  }

  Future<void> _copyPhone(String phone) async {
    await Clipboard.setData(ClipboardData(text: phone));
    if (mounted) showToast(context, 'Phone number copied');
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    final phone = d?.request.phone ?? d?.requester?.phone;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bulk request'),
          actions: [
            if (phone != null)
              PopupMenuButton<String>(
                tooltip: 'More options',
                onSelected: (_) => _copyPhone(phone),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'copy', child: ListTile(leading: Icon(AppIcons.copy), title: Text('Copy phone'))),
                ],
              ),
          ],
        ),
        body: d == null
            ? (_error != null ? ErrorView(message: _error!, onRetry: _load) : const _Skeleton())
            : Column(
                children: [
                  _PipelineBar(d.request.status),
                  Expanded(child: RefreshIndicator(onRefresh: _load, child: _body(d))),
                ],
              ),
        bottomNavigationBar: d == null ? null : _ActionBar(d.request, onUpdate: _updateStatus),
      ),
    );
  }

  Widget _body(BulkDossier d) {
    final r = d.request;
    final quote = latestQuote(r.comments);
    const gap = SizedBox(height: 16);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (r.status == 'Won') ...[_WonBanner(r, quote), gap],
        _LeadCard(r, quote),
        gap,
        _TimelineCard(r, onAdd: _updateStatus),
        gap,
        _RequesterCard(d),
        gap,
        _DealingsCard(d),
        if (d.otherRequests.isNotEmpty) ...[
          const SectionTitle('Other requests from this buyer'),
          for (final o in d.otherRequests) ...[
            BulkTile(request: o, onTap: () => context.push('/bulk/${o.id}')),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

TextStyle? _title(BuildContext context) => Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16);

Tone _toneFor(AppPalette p, String status) => switch (status) {
      'New Lead' => p.lead,
      'Contacted' => p.info,
      'Quoted' => p.violet,
      'Won' => p.positive,
      _ => p.neutral,
    };

/// "Rs. 14.56M" for millions, else the usual "Rs. 82,500".
String compactMoney(int n) {
  if (n < 1000000) return money(n);
  final m = (n / 1000000).toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  return 'Rs. ${m}M';
}

/// Muted label on the left, value on the right; long values wrap and stay
/// right-aligned.
class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.bodyMedium?.copyWith(fontSize: 13, color: p.muted, height: 1.45)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value!, textAlign: TextAlign.end, style: t.bodyMedium?.copyWith(height: 1.45, fontFeatures: tabularFigures)),
          ),
        ],
      ),
    );
  }
}

/// New Lead → Contacted → Quoted → Won (or Lost), on a white strip.
class _PipelineBar extends StatelessWidget {
  const _PipelineBar(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final steps = pipeline(status);
    bool reached(int i) => steps[i].done || steps[i].current;
    return Semantics(
      label: 'Pipeline: $status',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(color: p.card, border: Border(bottom: BorderSide(color: p.divider))),
        child: Row(
          children: [
            for (final (i, s) in steps.indexed)
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: 12,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Container(height: 2, color: i == 0 ? Colors.transparent : (reached(i) ? p.primary : p.divider))),
                              Expanded(
                                child: Container(
                                  height: 2,
                                  color: i == steps.length - 1 ? Colors.transparent : (steps[i].done ? p.primary : p.divider),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: s.current ? _toneFor(p, s.label).fg : (s.done ? p.primary : p.card),
                              border: s.done || s.current ? null : Border.all(color: p.border, width: 2),
                              boxShadow: s.current ? [BoxShadow(color: _toneFor(p, s.label).bg, spreadRadius: 4)] : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.label,
                      maxLines: 1,
                      style: t.bodySmall?.copyWith(
                        fontWeight: s.current ? FontWeight.w700 : (s.done ? FontWeight.w600 : FontWeight.w500),
                        color: s.current ? _toneFor(p, s.label).fg : (s.done ? p.text : p.muted),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WonBanner extends StatelessWidget {
  const _WonBanner(this.r, this.quote);
  final BulkRequest r;
  final BulkQuote? quote;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final units = quote?.quantity ?? r.quantity;
    final won = r.comments.where((c) => c.status == 'Won').lastOrNull;
    final headline = ['Deal won', '${count(units)} units', if (quote != null) compactMoney(quote!.total)].join(' · ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.positive.bg, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: p.success, shape: BoxShape.circle),
            child: Icon(AppIcons.check, color: p.onSuccess, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(headline, style: _title(context)?.copyWith(fontWeight: FontWeight.w700, color: p.positive.fg, fontFeatures: tabularFigures)),
                if (won?.createdAt != null)
                  Text('Confirmed ${formatDateTime(won!.createdAt)}', style: t.bodySmall?.copyWith(fontSize: 13, color: p.positive.fg)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard(this.r, this.quote);
  final BulkRequest r;
  final BulkQuote? quote;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final waiting = waitingDays(r);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(r.fullName, style: t.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700))),
              const SizedBox(width: 12),
              StatusBadge.bulk(r.status),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                Row(
                  children: [
                    NetThumb(r.product?.picture, size: 64, radius: 12),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.productTitle ?? 'Product', style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            '${count(r.quantity)} ${r.quantity == 1 ? 'unit' : 'units'}',
                            style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700, fontFeatures: tabularFigures),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (quote != null) ...[
                  const SizedBox(height: 12),
                  Divider(color: p.border),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(AppIcons.tag, size: 16, color: p.violet.fg),
                      const SizedBox(width: 6),
                      Text('Your quote', style: t.bodySmall?.copyWith(fontSize: 13, color: p.muted)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${money(quote!.perUnit)} / unit',
                              textAlign: TextAlign.end,
                              style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: p.violet.fg, fontFeatures: tabularFigures),
                            ),
                            Text(
                              [
                                '${money(quote!.total)} total',
                                if (quote!.validUntil != null) 'valid until ${quote!.validUntil}',
                              ].join(' · '),
                              textAlign: TextAlign.end,
                              style: t.bodySmall?.copyWith(color: p.muted, fontFeatures: tabularFigures),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          _Row('Phone', r.phone),
          _Row('Location', r.location),
          _Row('Address', r.address),
          _Row('Channel', r.portal),
          _Row('Received', formatDateTime(r.createdAt)),
          if (r.status == 'Lost') _Row('Reason', r.reason),
          if (waiting != null && waiting > 0) ...[
            const SizedBox(height: 8),
            Builder(builder: (context) {
              final tone = waiting >= 3 ? p.negative : p.warning;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(AppIcons.clock, size: 18, color: tone.fg),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Waiting $waiting ${waiting == 1 ? 'day' : 'days'} for a response',
                        style: t.bodySmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: tone.fg),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard(this.r, {required this.onAdd});
  final BulkRequest r;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final add = TextButton.icon(onPressed: onAdd, icon: const Icon(AppIcons.add, size: 20), label: const Text('Add update'));
    if (r.comments.isEmpty) {
      return AppCard(
        child: Column(
          children: [
            Align(alignment: Alignment.centerLeft, child: Text('Timeline', style: _title(context))),
            const SizedBox(height: 12),
            const ExcludeSemantics(child: _PhoneArt()),
            const SizedBox(height: 12),
            Text('No updates yet', style: _title(context)?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Call the buyer, then record what happened', textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: p.muted)),
            add,
          ],
        ),
      );
    }
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [Expanded(child: Text('Timeline', style: _title(context))), add]),
          const SizedBox(height: 4),
          for (final (i, c) in r.comments.indexed) _TimelineEntry(c, last: i == r.comments.length - 1),
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry(this.c, {required this.last});
  final BulkComment c;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final parsed = parseComment(c.comments);
    final q = parsed.quote;
    final status = c.status ?? '';
    final (icon, tone) = switch (status) {
      'Contacted' => (AppIcons.comment, p.info),
      'Quoted' => (AppIcons.tag, p.violet),
      'Won' => (AppIcons.check, p.positive),
      'Lost' => (AppIcons.close, p.neutral),
      _ => (AppIcons.note, p.neutral),
    };
    final title = switch (status) {
      'Quoted' when q != null => 'Quote sent · ${money(q.perUnit)} per unit',
      'Quoted' => 'Quote sent',
      '' || 'New Lead' => 'Note',
      _ => status,
    };
    final lines = [
      if (q != null)
        [
          '${money(q.total)} for ${count(q.quantity)} units',
          if (q.validUntil != null) 'valid until ${q.validUntil}',
        ].join(', '),
      ?parsed.note,
    ];
    final meta = [formatDateTime(c.createdAt), ?c.byName].where((s) => s.isNotEmpty).join(' · ');
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: tone.bg, shape: BoxShape.circle),
                  child: Icon(icon, size: 16, color: tone.fg),
                ),
                if (!last) Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: p.divider)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 5, right: 8, bottom: last ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  for (final l in lines) Text(l, style: t.bodySmall?.copyWith(fontSize: 13, height: 1.45, color: p.text)),
                  if (meta.isNotEmpty) Text(meta, style: t.bodySmall?.copyWith(color: p.muted, fontFeatures: tabularFigures)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequesterCard extends StatelessWidget {
  const _RequesterCard(this.d);
  final BulkDossier d;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final who = d.requester;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Requester', style: _title(context)),
          const SizedBox(height: 12),
          if (who == null)
            Text('Guest buyer with no AtomShop account.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: p.muted))
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(who.name ?? d.request.fullName, style: _title(context)?.copyWith(fontWeight: FontWeight.w700)),
                who.verified ? const StatusBadge('Verified', BadgeTone.success) : const StatusBadge('Unverified', BadgeTone.neutral),
              ],
            ),
            const SizedBox(height: 6),
            _Row('Phone', who.phone),
            _Row('Email', who.email),
            _Row('City', [who.area, who.city].whereType<String>().join(', ')),
            _Row('Customer ID', who.identifier),
            _Row('Customer since', formatDate(who.customerSince)),
          ],
        ],
      ),
    );
  }
}

class _DealingsCard extends StatefulWidget {
  const _DealingsCard(this.d);
  final BulkDossier d;

  @override
  State<_DealingsCard> createState() => _DealingsCardState();
}

class _DealingsCardState extends State<_DealingsCard> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final hint = trustHint(d);
    final orders = _all ? d.orders : d.orders.take(3).toList();
    Widget stat(String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: _title(context)?.copyWith(fontWeight: FontWeight.w700, fontFeatures: tabularFigures)),
                ),
                const SizedBox(height: 2),
                Text(label, style: t.bodySmall?.copyWith(color: p.muted)),
              ],
            ),
          ),
        );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Dealings with your brand', style: _title(context)),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                stat(compactMoney(d.lifetimeValue), 'Lifetime value'),
                const SizedBox(width: 8),
                stat(count(d.orders.length), 'Orders'),
                const SizedBox(width: 8),
                stat('${count(d.instalmentsPaid)} / ${count(d.instalmentsUnpaid)}', 'Instalments paid / unpaid'),
              ],
            ),
          ),
          if (orders.isNotEmpty) const SizedBox(height: 6),
          for (final o in orders)
            InkWell(
              onTap: () => context.push('/orders/retail/${o.uuid}'),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: p.divider))),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.product ?? 'Order', style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            '${money(o.totalDealPrice)} · ${formatDate(o.createdAt)}',
                            style: t.bodySmall?.copyWith(color: p.muted, fontFeatures: tabularFigures),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge.order(o.status),
                  ],
                ),
              ),
            ),
          if (d.orders.length > 3)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _all = !_all),
                child: Text(_all ? 'Show fewer' : 'See all ${d.orders.length} orders'),
              ),
            ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: hint.warn ? p.negative.bg : p.surface, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(
                  hint.warn ? AppIcons.warning : AppIcons.info,
                  size: 18,
                  color: hint.warn ? p.negative.fg : p.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(hint.text, style: t.bodySmall?.copyWith(fontSize: 13, color: hint.warn ? p.negative.fg : p.text)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Call · WhatsApp · Update status, pinned above the home indicator.
class _ActionBar extends StatelessWidget {
  const _ActionBar(this.r, {required this.onUpdate});
  final BulkRequest r;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final round = IconButton.styleFrom(
      fixedSize: const Size(52, 52),
      side: BorderSide(color: p.border, width: 1.5),
      backgroundColor: p.card,
    );
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(color: p.card, border: Border(top: BorderSide(color: p.divider))),
        child: Row(
          children: [
            if (r.phone != null) ...[
              IconButton(
                tooltip: 'Call ${r.fullName}',
                style: round,
                onPressed: () => callPhone(context, r.phone),
                icon: Icon(AppIcons.phone, color: p.primary),
              ),
              const SizedBox(width: 10),
            ],
            if (r.whatsapp != null) ...[
              IconButton(
                tooltip: 'WhatsApp ${r.fullName}',
                style: round,
                onPressed: () => openExternal(context, r.whatsapp),
                icon: Icon(AppIcons.chat, color: p.success),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: FilledButton.icon(
                onPressed: onUpdate,
                style: FilledButton.styleFrom(minimumSize: const Size(64, 52)),
                icon: const Icon(AppIcons.edit, size: 20),
                label: const Text('Update status'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A ringing phone (empty timeline).
class _PhoneArt extends StatelessWidget {
  const _PhoneArt();

  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(120, 96), painter: _PhonePainter(AppPalette.of(context)));
}

class _PhonePainter extends CustomPainter {
  const _PhonePainter(this.p);
  final AppPalette p;

  @override
  void paint(Canvas canvas, Size size) {
    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(const Offset(60, 48), 44, Paint()..color = p.primarySoft2);
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(42, 14, 36, 66), const Radius.circular(8));
    canvas.drawRRect(body, Paint()..color = p.card);
    canvas.drawRRect(body, stroke(p.primary, 3));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(54, 20, 12, 3), const Radius.circular(1.5)), Paint()..color = p.primarySoft2);
    canvas.drawCircle(const Offset(60, 47), 10, Paint()..color = p.primarySoft2);
    canvas.drawCircle(const Offset(60, 47), 4, Paint()..color = p.primary);
    for (final (dx, sign) in const [(86.0, 1.0), (34.0, -1.0)]) {
      for (final r in const [12.0, 20.0]) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset(dx - sign * 8, 40), radius: r),
          sign > 0 ? -0.8 : 3.14159 - 0.8,
          1.6,
          false,
          stroke(p.accent, 3),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PhonePainter old) => old.p != p;
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    Widget card(Widget child) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: p.cardShadow),
          child: child,
        );
    return Semantics(
      label: 'Loading bulk request',
      child: Shimmer(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            card(const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Expanded(child: Bone(height: 20)), SizedBox(width: 40), Bone(width: 72, height: 24, radius: 999)]),
                SizedBox(height: 16),
                Bone(height: 88, radius: 14),
                SizedBox(height: 16),
                Bone(height: 12),
                SizedBox(height: 12),
                Bone(height: 12),
              ],
            )),
            const SizedBox(height: 16),
            card(const Column(
              children: [Bone(width: 90, height: 16), SizedBox(height: 20), Bone(width: 120, height: 96, radius: 48), SizedBox(height: 16), Bone(width: 160)],
            )),
          ],
        ),
      ),
    );
  }
}

/// "Update lead": pick the new stage; a quote adds price, quantity, total
/// and valid-until; Lost asks why. Everything lands in one status change
/// (§8.7), the quote as the comment's first line (see [quoteComment]).
class _UpdateLeadSheet extends ConsumerStatefulWidget {
  const _UpdateLeadSheet({required this.request, required this.statuses});

  final BulkRequest request;
  final List<String> statuses;

  @override
  ConsumerState<_UpdateLeadSheet> createState() => _UpdateLeadSheetState();
}

class _UpdateLeadSheetState extends ConsumerState<_UpdateLeadSheet> {
  static const _reasons = ['Price too high', 'Bought elsewhere', 'Not reachable', 'Other'];
  static final _validFmt = DateFormat('d MMM y', 'en_US');

  late String _status = switch (widget.request.status) {
    'New Lead' => 'Contacted',
    'Contacted' => 'Quoted',
    'Quoted' => 'Won',
    final s => s,
  };
  final _price = TextEditingController();
  late final _qty = TextEditingController(text: widget.request.quantity > 0 ? '${widget.request.quantity}' : '');
  final _notes = TextEditingController();
  final _otherReason = TextEditingController();
  DateTime _validUntil = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 7));
  String? _reason;
  bool _busy = false;
  bool _tried = false;
  ApiException? _error;

  @override
  void dispose() {
    for (final c in [_price, _qty, _notes, _otherReason]) {
      c.dispose();
    }
    super.dispose();
  }

  int _n(TextEditingController c) => int.tryParse(c.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _validUntil.isBefore(today) ? today : _validUntil,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _validUntil = picked);
  }

  Future<void> _save() async {
    setState(() => _tried = true);
    final quoting = _status == 'Quoted';
    if (quoting && (_n(_price) <= 0 || _n(_qty) <= 0)) return;
    final comment = quoting
        ? quoteComment(BulkQuote(perUnit: _n(_price), quantity: _n(_qty), validUntil: _validFmt.format(_validUntil)), _notes.text)
        : _notes.text.trim();
    final reason = _status != 'Lost'
        ? null
        : (_reason == 'Other' ? _otherReason.text.trim() : _reason);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(bulkRepositoryProvider).updateStatus(
            widget.request.id,
            _status,
            comments: comment.length > 1000 ? comment.substring(0, 1000) : comment,
            reason: reason,
          );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
      if (e.fieldErrors.isEmpty) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    const descriptions = {
      'Contacted': 'You spoke to the buyer',
      'Quoted': 'You sent a price',
      'Won': 'The buyer confirmed',
      'Lost': 'The deal fell through',
    };
    const icons = {
      'Contacted': AppIcons.comment,
      'Quoted': AppIcons.tag,
      'Won': AppIcons.check,
      'Lost': AppIcons.close,
    };
    final total = _n(_price) * _n(_qty);
    final priceMissing = _tried && _n(_price) <= 0;
    final qtyMissing = _tried && _n(_qty) <= 0;

    Widget option(String s) {
      final tone = _toneFor(p, s);
      final selected = _status == s;
      return Semantics(
        selected: selected,
        button: true,
        label: '$s. ${descriptions[s] ?? ''}',
        excludeSemantics: true,
        child: InkWell(
          onTap: () => setState(() => _status = s),
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 96),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected ? tone.bg : p.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: selected ? tone.fg : p.border, width: selected ? 2 : 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: selected ? p.card : tone.bg, borderRadius: BorderRadius.circular(10)),
                      child: Icon(icons[s] ?? AppIcons.flag, size: 18, color: tone.fg),
                    ),
                    const Spacer(),
                    if (selected)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(color: tone.fg, shape: BoxShape.circle),
                        child: Icon(AppIcons.check, size: 14, color: p.card),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(s, style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                if (descriptions[s] != null) Text(descriptions[s]!, style: t.bodySmall?.copyWith(color: p.muted)),
              ],
            ),
          ),
        ),
      );
    }

    final options = widget.statuses;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
            child: Row(
              children: [
                Expanded(child: Text('Update lead', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
                IconButton(tooltip: 'Close', onPressed: () => Navigator.pop(context), icon: const Icon(AppIcons.close)),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < options.length; i += 2) ...[
                    if (i > 0) const SizedBox(height: 10),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: option(options[i])),
                          const SizedBox(width: 10),
                          Expanded(child: i + 1 < options.length ? option(options[i + 1]) : const SizedBox()),
                        ],
                      ),
                    ),
                  ],
                  if (_status == 'Quoted') ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _price,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Price per unit',
                              prefixText: 'Rs. ',
                              errorText: priceMissing ? 'Enter the price' : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _qty,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              suffixText: 'units',
                              errorText: qtyMissing ? 'Enter units' : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(color: p.violet.bg, borderRadius: BorderRadius.circular(AppRadius.control)),
                        child: Row(
                          children: [
                            Text('Total', style: t.bodyMedium?.copyWith(color: p.violet.fg)),
                            const Spacer(),
                            Text(
                              money(total),
                              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: p.violet.fg, fontFeatures: tabularFigures),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(AppRadius.control),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Valid until', suffixIcon: Icon(AppIcons.calendar)),
                        child: Text(_validFmt.format(_validUntil), style: t.bodyLarge),
                      ),
                    ),
                  ],
                  if (_status == 'Lost') ...[
                    const SizedBox(height: 16),
                    Text('Why was it lost?', style: t.labelMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final r in _reasons)
                          ChoiceChip(
                            label: Text(r),
                            selected: _reason == r,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _reason = r),
                          ),
                      ],
                    ),
                    if (_reason == 'Other') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _otherReason,
                        maxLength: 255,
                        decoration: InputDecoration(labelText: 'Reason', errorText: _error?.fieldError('reason')),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notes,
                    maxLength: 900,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      hintText: 'What did the buyer say?',
                      alignLabelWithHint: true,
                      errorText: _error?.fieldError('comments'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: p.divider))),
              child: BusyButton(label: 'Save update', busy: _busy, onPressed: _save),
            ),
          ),
        ],
      ),
    );
  }
}
