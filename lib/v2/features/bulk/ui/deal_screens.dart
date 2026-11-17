import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/app_providers.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/pdf/server_pdf.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../sync/data/offline_saves.dart';
import '../../sync/ui/offline_bar.dart';
import '../../sync/ui/saved_here_sheet.dart';
import '../data/bulk_logic.dart';
import '../data/bulk_models.dart';
import '../data/bulk_repository.dart';
import 'bulk_parts.dart';
import 'bulk_scanner.dart';

bool _canDeal(WidgetRef ref) => ref.watch(
  sessionProvider.select(
    (s) => s is SignedIn ? s.session.who.can(BrandPermission.bulkDeal) : false,
  ),
);

/// Loads a deal and builds [builder] with it, or the loading / error frame.
class _WithDeal extends ConsumerWidget {
  const _WithDeal({
    required this.id,
    required this.title,
    required this.builder,
  });

  final int id;
  final String title;
  final Widget Function(Deal deal) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(dealProvider(id))) {
      AsyncValue(:final value?) => builder(value),
      AsyncValue(:final error?) => BulkLoadFrame(
        title: title,
        error: error,
        onRetry: () => ref.invalidate(dealProvider(id)),
      ),
      _ => BulkLoadFrame(title: title, error: null, onRetry: () {}),
    };
  }
}

// ───────────────────────────────────────────────────────────── 7.7 deal

class DealScreen extends StatelessWidget {
  const DealScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) => _WithDeal(
    id: id,
    title: AppLocalizations.of(context).bulkDeal,
    builder: (d) => _DealView(deal: d),
  );
}

class _DealView extends ConsumerWidget {
  const _DealView({required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final d = deal;
    final canDeal = _canDeal(ref) && !d.status.finished;
    final advancePaid = d.advance <= 0 || d.paid >= d.advance;
    final steps = dealStepsReached(d);
    final where = d.outletName == null ? null : l.bulkFromOutlet(d.outletName!);
    final itemsLine = d.items.length == 1
        ? '${d.items.first.qty} × ${d.items.first.title}'
        : l.bulkUnits(d.units);

    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          refreshDeal(ref, d.id);
          try {
            await ref.read(dealProvider(d.id).future);
          } on Object {
            // shown by the screen
          }
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            BulkDetailHeader(
              eyebrow: [
                l.bulkDealNumber(d.number),
                if (d.createdAt != null)
                  l.bulkWonDate(AtomDates.short(d.createdAt!)),
              ].join(' · '),
              title: d.who,
              subtitle: [
                if (d.fromSeller) l.bulkAtomshopSeller,
                itemsLine,
                ?where,
              ].join(' · '),
              status: AtomPill(
                label: d.statusLabel ?? d.status.label(l),
                tone: dealTone(d.status),
              ),
              children: [
                BulkSteps(
                  labels: [
                    advancePaid && d.advance > 0
                        ? l.bulkStepOpenAdvance
                        : l.bulkDealOpen,
                    d.status == DealStatus.delivering
                        ? l.bulkStepDeliveringOf(d.deliveredUnits, d.units)
                        : l.bulkDealDelivering,
                    l.bulkDealDelivered,
                    l.bulkDealPaid,
                    d.status == DealStatus.lost
                        ? l.bulkStatusLost
                        : l.bulkDealClosed,
                  ],
                  reached: d.status == DealStatus.lost ? 5 : steps,
                  lostAt: d.status == DealStatus.lost ? 4 : null,
                ),
                Row(
                  children: [
                    // `.hb .btn`: three equal buttons, 44 tall, 14px, 6px
                    // side padding; a long label shrinks, never wraps.
                    Expanded(
                      child: AtomPdfButton(
                        label: l.bulkInvoice,
                        icon: LucideIcons.fileText,
                        compact: true,
                        padding: 6,
                        fontSize: 14,
                        onPressed: () => handOverServerPdf(
                          ref.read(apiClientProvider),
                          ref.read(bulkRepositoryProvider).invoice(d),
                        ),
                      ),
                    ),
                    if (canDeal && d.balance > 0) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: AtomButton(
                          label: l.bulkRecordPayment,
                          kind: AtomButtonKind.outline,
                          compact: true,
                          padding: 6,
                          fontSize: 14,
                          oneLine: true,
                          onPressed: () =>
                              context.push(V2Routes.dealPaymentOf(d.id)),
                        ),
                      ),
                    ],
                    if (canDeal && d.leftUnits > 0) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: AtomButton(
                          label: l.bulkDeliverUnits,
                          compact: true,
                          padding: 6,
                          fontSize: 14,
                          oneLine: true,
                          onPressed: () =>
                              context.push(V2Routes.dealDeliverOf(d.id)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const OfflineBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AtomKpiGrid(
                    kpis: [
                      AtomKpi(
                        label: l.bulkDealValue,
                        value: formatRs(d.total),
                        note:
                            '${l.bulkUnits(d.units)} · ${d.deliveryCharge > 0 ? l.bulkDeliveryAmount(formatRs(d.deliveryCharge)) : l.bulkFreeDelivery}',
                      ),
                      AtomKpi(
                        label: l.bulkDealDelivered,
                        value: l.bulkDoneOf(d.deliveredUnits, d.units),
                        note: l.bulkDeliveriesCount(d.deliveries.length),
                      ),
                      AtomKpi(
                        label: l.bulkDealPaid,
                        value: formatRs(d.paid),
                        progress: d.paidShare,
                        progressColour: AtomColors.green,
                      ),
                      AtomKpi(
                        label: l.bulkBalanceDue,
                        value: formatRs(d.balance),
                        valueColour: d.balance > 0 ? AtomColors.amberInk : null,
                        note: d.balance <= 0
                            ? l.bulkPaidInFull
                            : !advancePaid && d.deliveredUnits == 0
                            ? l.bulkAdvanceBeforeFirst(
                                formatRs(d.advance - d.paid),
                              )
                            : d.balanceTerms == 'before_each'
                            ? l.bulkTakeBeforeNext
                            : l.bulkDueBeforeLast,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ItemsCard(deal: d),
                  const SizedBox(height: 12),
                  _DeliveriesCard(deal: d),
                  const SizedBox(height: 12),
                  _PaymentsCard(deal: d),
                  const SizedBox(height: 12),
                  _WhoCard(deal: d),
                  const SizedBox(height: 12),
                  BulkLinesCard(
                    title: l.bulkTerms,
                    lines: [
                      AtomInfoLine(
                        label: l.bulkPayAdvance,
                        value: d.advancePct == 0
                            ? l.bulkNone
                            : advancePaid
                            ? l.bulkAdvancePaidPct(d.advancePct)
                            : l.bulkAdvanceToTake(
                                d.advancePct,
                                formatRs(d.advance - d.paid),
                              ),
                      ),
                      AtomInfoLine(
                        label: l.bulkBalance,
                        value: balanceTermsLabel(l, d.balanceTerms),
                      ),
                      AtomInfoLine(
                        label: l.bulkDelivery,
                        value: d.deliveries.length > 1
                            ? l.bulkInParts
                            : deliveryText(l, d.deliveryCharge),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DealHistory(deal: d),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final head = AtomText.small.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: .4,
    );
    final num = AtomText.money.copyWith(fontSize: 13);
    const line = BoxDecoration(
      border: Border(top: BorderSide(color: AtomColors.line)),
    );
    Widget cell(Widget child, {bool right = true, double top = 10}) => Padding(
      padding: EdgeInsets.fromLTRB(right ? 6 : 0, top, 0, top),
      child: Align(
        alignment: right
            ? AlignmentDirectional.topEnd
            : AlignmentDirectional.topStart,
        child: child,
      ),
    );
    // `.it`: the product takes what the figures leave, so its name wraps
    // at word breaks in a wide column, not one word to a line.
    return BulkCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BulkCardTitle(l.bulkItems),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(),
              1: IntrinsicColumnWidth(),
              2: IntrinsicColumnWidth(),
              3: IntrinsicColumnWidth(),
            },
            children: [
              TableRow(
                children: [
                  cell(
                    Text(l.bulkProduct.toUpperCase(), style: head),
                    right: false,
                    top: 6,
                  ),
                  cell(Text(l.bulkOrdered.toUpperCase(), style: head), top: 6),
                  cell(Text(l.bulkLeft.toUpperCase(), style: head), top: 6),
                  cell(Text(l.bulkAmount.toUpperCase(), style: head), top: 6),
                ],
              ),
              for (final i in deal.items)
                TableRow(
                  decoration: line,
                  children: [
                    cell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            i.title,
                            style: AtomText.secondary.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AtomColors.ink,
                            ),
                          ),
                          Text(
                            [
                              ?i.colour,
                              l.bulkNDelivered(i.deliveredQty),
                            ].join(' · '),
                            style: AtomText.small,
                          ),
                        ],
                      ),
                      right: false,
                    ),
                    cell(Text('${i.qty}', style: num)),
                    cell(Text('${i.remaining}', style: num)),
                    cell(
                      Text(
                        formatRs(i.lineTotal),
                        style: num.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const Divider(height: 1, color: AtomColors.line),
          AtomInfoLine(
            label: l.bulkDelivery,
            value: deliveryText(l, deal.deliveryCharge),
          ),
          const Divider(height: 1, color: AtomColors.line),
          AtomInfoLine(label: l.bulkTotal, value: formatRs(deal.total)),
        ],
      ),
    );
  }
}

class _DeliveriesCard extends StatelessWidget {
  const _DeliveriesCard({required this.deal});

  final Deal deal;

  String _serials(AppLocalizations l, List<String> s) => switch (s.length) {
    0 => '',
    1 => l.bulkSerialOne(s.first),
    <= 3 => l.bulkSerialsList(s.join(', ')),
    _ => l.bulkSerialsRange(s.first, s.last),
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BulkCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BulkCardTitle(l.bulkDeliveries),
          if (deal.deliveries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Text(l.bulkNoDelivery, style: AtomText.secondary),
            ),
          for (var i = 0; i < deal.deliveries.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AtomColors.line),
            Builder(
              builder: (context) {
                final n = deal.deliveries[i];
                return BulkTwoLine(
                  title: [
                    n.number,
                    if (n.deliveredOn != null) AtomDates.short(n.deliveredOn!),
                  ].join(' · '),
                  subtitle: [
                    _serials(l, n.serials),
                    if (n.receivedBy != null)
                      l.bulkReceivedByName(n.receivedBy!),
                    ?n.note,
                  ].where((s) => s.isNotEmpty).join(' · '),
                  extra: Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (deal.fromSeller)
                        n.sellerConfirmedAt == null
                            ? AtomPill(
                                label: l.bulkWaitingSeller,
                                tone: AtomTone.amber,
                              )
                            : AtomPill(
                                label: l.bulkSellerConfirmed(
                                  AtomDates.short(n.sellerConfirmedAt!),
                                ),
                                tone: AtomTone.green,
                              ),
                      if (n.photo != null)
                        AtomTextLink(
                          label: l.bulkSignedNote,
                          onTap: () => _showPhoto(context, n.photo!),
                        ),
                    ],
                  ),
                  value: l.bulkUnits(n.units),
                );
              },
            ),
          ],
          if (deal.fromSeller)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(l.bulkSellerConfirmsNote, style: AtomText.small),
            ),
        ],
      ),
    );
  }
}

Future<void> _showPhoto(BuildContext context, String url) => showDialog<void>(
  context: context,
  builder: (context) => Dialog(
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(borderRadius: AtomRadius.brCard),
    child: InteractiveViewer(child: AtomPhoto(url, fit: BoxFit.contain)),
  ),
);

class _PaymentsCard extends StatelessWidget {
  const _PaymentsCard({required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final list = deal.payments.reversed.toList();
    return BulkCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BulkCardTitle(l.bulkPayments),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Text(l.bulkNoPayment, style: AtomText.secondary),
            ),
          for (var i = 0; i < list.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AtomColors.line),
            BulkTwoLine(
              // the first payment of a deal with an advance is the advance
              title: deal.advance > 0 && list[i].id == deal.payments.first.id
                  ? l.bulkPayAdvance
                  : l.bulkPayment,
              subtitle: [
                list[i].methodLabel ?? list[i].method ?? '',
                if (list[i].paidOn != null) AtomDates.short(list[i].paidOn!),
                if (list[i].reference != null) l.bulkRef(list[i].reference!),
              ].where((s) => s.isNotEmpty).join(' · '),
              extra: list[i].receipt == null
                  ? null
                  : AtomTextLink(
                      label: l.bulkReceipt,
                      onTap: () => _showPhoto(context, list[i].receipt!),
                    ),
              value: formatRs(list[i].amount),
            ),
          ],
          const Divider(height: 1, color: AtomColors.line),
          AtomInfoLine(
            label: l.bulkBalanceDue,
            value: formatRs(deal.balance),
            valueColor: deal.balance > 0
                ? AtomColors.amberInk
                : AtomColors.green,
          ),
        ],
      ),
    );
  }
}

class _WhoCard extends StatelessWidget {
  const _WhoCard({required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = deal;
    final s = d.seller;
    final request = d.bulkOrderId;
    final fromRequest = request == null
        ? null
        : _LinkLine(
            label: l.bulkFromRequest,
            link: [
              d.fromSeller ? l.bulkSellerRequest : l.bulkBulkRequest,
              ?d.quoteLabel,
            ].join(' · '),
            onTap: () => context.push(
              d.fromSeller
                  ? V2Routes.sellerRequestOf(request)
                  : V2Routes.bulkRequestOf(request),
            ),
          );
    return BulkLinesCard(
      title: d.fromSeller ? l.bulkAtomshopSeller : l.bulkBusiness,
      lines: [
        if (d.fromSeller && s != null) ...[
          AtomInfoLine(
            label: l.bulkShop,
            value: s.verified ? l.bulkShopVerified(s.name) : s.name,
          ),
          if (s.branch != null || s.city != null)
            AtomInfoLine(
              label: l.bulkBranch,
              value: [?s.branch, ?s.city].join(', '),
            ),
          if (s.code != null)
            AtomInfoLine(label: l.bulkSellerCode, value: s.code!),
        ] else
          AtomInfoLine(
            label: l.bulkContact,
            value: l.bulkWebsiteBuyer(d.buyerName ?? ''),
          ),
        if (d.buyerPhone != null)
          AtomInfoLine(label: l.bulkPhone, value: d.buyerPhone!),
        if (!d.fromSeller && d.deliverTo != null)
          AtomInfoLine(label: l.bulkAddress, value: d.deliverTo!),
        ?fromRequest,
        if (d.fromSeller)
          AtomInfoLine(
            label: l.bulkCommission,
            value: d.commission == null
                ? l.bulkNone
                : [
                    formatRs(d.commission!.amount),
                    ?d.commission!.label,
                  ].join(' · '),
          ),
      ],
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
        child: ContactButtons(phone: d.buyerPhone),
      ),
    );
  }
}

/// A `.line` whose value is a link ("From request · Seller request ·
/// Q-1037").
class _LinkLine extends StatelessWidget {
  const _LinkLine({
    required this.label,
    required this.link,
    required this.onTap,
  });

  final String label;
  final String link;
  final VoidCallback onTap;

  @override
  // The whole line is the tap target, so the link sits on the label's
  // line at the right edge like the other values (a 48-tall pressable
  // around the link alone dropped it below the label).
  Widget build(BuildContext context) => AtomPressable(
    onTap: onTap,
    semanticLabel: '$label, $link',
    scaleOnPress: false,
    builder: (_, _) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AtomSpace.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: AtomText.body.copyWith(
                color: AtomColors.muted,
                height: AtomText.normalHeight,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              link,
              textAlign: TextAlign.end,
              style: AtomText.body.copyWith(
                color: AtomColors.primary,
                fontWeight: FontWeight.w600,
                height: AtomText.normalHeight,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DealHistory extends StatelessWidget {
  const _DealHistory({required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = deal;
    String by(String text, String? who) => who == null ? text : '$text · $who';
    // When it was saved (to the minute) when the server says, else its day.
    String when(DateTime? at, {bool day = false}) => at == null
        ? ''
        : day
        ? AtomDates.short(at.toLocal())
        : bulkWhen(l, at);
    final events = <(DateTime?, String, String)>[
      for (final n in d.deliveries)
        (
          n.createdAt ?? n.deliveredOn,
          when(n.createdAt ?? n.deliveredOn, day: n.createdAt == null),
          by(l.bulkHistDelivered(n.units, n.number), n.recordedBy),
        ),
      for (final (i, p) in d.payments.indexed)
        (
          p.createdAt ?? p.paidOn,
          when(p.createdAt ?? p.paidOn, day: p.createdAt == null),
          by(
            l.bulkHistPayment(
                  i == 0 && d.advance > 0 ? l.bulkPayAdvance : l.bulkPayment,
                  formatRs(p.amount),
                ) +
                (p.methodLabel == null
                    ? ''
                    : ' ${l.bulkHistBy(p.methodLabel!.toLowerCase())}'),
            p.recordedBy,
          ),
        ),
      (
        d.createdAt,
        when(d.createdAt),
        by(
          d.quoteLabel == null
              ? l.bulkDealMadeEvent
              : l.bulkWonFromQuote(d.quoteLabel!),
          d.createdBy,
        ),
      ),
      if (d.closedAt != null)
        (
          d.closedAt,
          when(d.closedAt),
          d.status == DealStatus.lost ? l.bulkStatusLost : l.bulkDealClosed,
        ),
    ]..sort((a, b) => (b.$1 ?? DateTime(0)).compareTo(a.$1 ?? DateTime(0)));
    return BulkCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BulkCardTitle(l.bulkHistory),
          for (final (_, at, what) in events)
            BulkHistoryRow(
              when: at,
              what: TextSpan(text: what),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── photo

/// A photo taken or picked for a form (signed note, receipt).
class _PhotoField extends StatelessWidget {
  const _PhotoField({
    required this.label,
    required this.prompt,
    required this.file,
    required this.onChanged,
    this.height = 96,
  });

  /// The dashed box's height (`.photo`: 96 on 7.8, 84 on 7.9).
  final double height;
  final String label;
  final String prompt;
  final File? file;
  final ValueChanged<File?> onChanged;

  Future<void> _pick(ImageSource source) async {
    final f = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 70,
    );
    if (f != null) onChanged(File(f.path));
  }

  /// Take a photo or pick one from the gallery.
  Future<void> _choose(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final v = await showAtomSelect<ImageSource>(
      context,
      title: l.bulkAddPhotoTitle,
      selected: null,
      options: [
        AtomOption(value: ImageSource.camera, label: l.bulkTakePhoto),
        AtomOption(value: ImageSource.gallery, label: l.bulkGallery),
      ],
    );
    if (v != null) await _pick(v);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = file;
    // The boards' photo fields carry no "optional" note.
    return AtomField(
      label: label,
      child: f != null
          ? Row(
              children: [
                ClipRRect(
                  borderRadius: AtomRadius.brControl,
                  child: Image.file(
                    f,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(l.bulkPhotoAdded, style: AtomText.body)),
                AtomIconButton(
                  icon: LucideIcons.x,
                  label: l.bulkRemovePhoto,
                  onTap: () => onChanged(null),
                ),
              ],
            )
          // `.photo`: one dashed box; it asks camera or gallery.
          : AtomPressable(
              onTap: () => _choose(context),
              semanticLabel: prompt,
              focusRadius: AtomRadius.brCard,
              builder: (_, pressed) => CustomPaint(
                foregroundPainter: _DashedBorder(),
                child: Container(
                  constraints: BoxConstraints(minHeight: height),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: pressed ? AtomColors.surface : AtomColors.paper,
                    borderRadius: AtomRadius.brCard,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.camera,
                        size: 20,
                        color: AtomColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          prompt,
                          style: AtomText.body.copyWith(
                            color: AtomColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/// The dashed 1.5px border of `.photo`.
class _DashedBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AtomColors.line2
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AtomRadius.card),
        ).deflate(0.75),
      );
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, (d + 5).clamp(0, m.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => false;
}

// ───────────────────────────────────────────────────────── 7.8 deliver

class DealDeliverScreen extends StatelessWidget {
  const DealDeliverScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) => _WithDeal(
    id: id,
    title: AppLocalizations.of(context).bulkDeliverUnits,
    builder: (d) => _DeliverForm(key: ValueKey(d.id), deal: d),
  );
}

class _DeliverForm extends ConsumerStatefulWidget {
  const _DeliverForm({super.key, required this.deal});

  final Deal deal;

  @override
  ConsumerState<_DeliverForm> createState() => _DeliverFormState();
}

class _DeliverFormState extends ConsumerState<_DeliverForm> {
  final _qty = <int, int>{};
  final _serials = <int, TextEditingController>{};
  final _receivedBy = TextEditingController();
  final _note = TextEditingController();
  DateTime _on = AtomDates.now();
  File? _photo;
  bool _saving = false;
  String? _error;
  bool _dirty = false;

  List<DealItem> get _open => [
    for (final i in widget.deal.items)
      if (i.remaining > 0) i,
  ];

  @override
  void initState() {
    super.initState();
    final open = _open;
    for (final i in open) {
      _qty[i.id] = open.length == 1 ? i.remaining : 0;
      _serials[i.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _serials.values) {
      c.dispose();
    }
    _receivedBy.dispose();
    _note.dispose();
    super.dispose();
  }

  void _changed(VoidCallback f) => setState(() {
    f();
    _dirty = true;
    _error = null;
  });

  int get _units => _qty.values.fold(0, (s, q) => s + q);

  Future<void> _scan(DealItem item) async {
    final c = _serials[item.id]!;
    final have = splitSerials(c.text);
    final qty = _qty[item.id] ?? 0;
    final room = (qty > 0 ? qty : item.remaining) - have.length;
    if (room <= 0) {
      showAtomToast(
        context,
        kind: AtomToastKind.bad,
        message: AppLocalizations.of(context).bulkSerialsFull,
      );
      return;
    }
    final codes = await scanSerials(
      context,
      max: room,
      title: AppLocalizations.of(context).bulkScanTitle(item.title),
      already: [for (final s in _serials.values) ...splitSerials(s.text)],
    );
    if (codes.isEmpty || !mounted) return;
    _changed(() {
      c.text = [...have, ...codes].join('\n');
      final n = have.length + codes.length;
      if ((_qty[item.id] ?? 0) < n) _qty[item.id] = n.clamp(0, item.remaining);
    });
  }

  Future<void> _pickDay() async {
    final today = AtomDates.now();
    final d = await showPastDaySheet(
      context,
      selected: _on,
      today: today,
      title: AppLocalizations.of(context).bulkDeliveredOn,
    );
    if (d != null) _changed(() => _on = d);
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final d = widget.deal;
    final picked = <int, ({int qty, List<String> serials})>{};
    for (final i in _open) {
      final q = _qty[i.id] ?? 0;
      if (q <= 0) continue;
      final serials = splitSerials(_serials[i.id]!.text);
      final p = serialProblem(l, i.title, q, serials);
      if (p != null) {
        setState(() => _error = p);
        return;
      }
      picked[i.id] = (qty: q, serials: serials);
    }
    final form = deliverFormProblem(
      l,
      receivedBy: _receivedBy.text,
      note: _note.text,
    );
    if (form != null) {
      setState(() => _error = form);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await ref
        .read(bulkRepositoryProvider)
        .deliver(
          d,
          picked: picked,
          receivedBy: _receivedBy.text,
          deliveredOn: _on,
          note: _note.text,
          photo: _photo,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (saved) {
      case SavedOnServer():
        refreshDeal(ref, d.id);
        _dirty = false;
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: l.bulkDeliverySaved(_units),
        );
        Navigator.of(context).pop();
      case SavedHere():
        refreshDeal(ref, d.id);
        _dirty = false;
        showSavedHereToast(context);
        Navigator.of(context).pop();
      case SaveFailed(:final failure):
        setState(() => _error = sayFailure(l, failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = widget.deal;
    final canDeal = _canDeal(ref);
    final open = _open;
    final block = deliveryBlock(d, {
      for (final e in _qty.entries) e.key: e.value,
    });
    final advanceDue = d.deliveredUnits == 0 && d.paid < d.advance;
    final units = _units;

    final String rule;
    final AtomNoteKind ruleKind;
    if (advanceDue) {
      rule = l.bulkRuleAdvance(formatRs(d.advance), formatRs(d.paid));
      ruleKind = AtomNoteKind.warning;
    } else if (d.balanceTerms == 'before_each') {
      rule =
          (d.advance > 0 ? l.bulkAdvancePaidPrefix : '') +
          l.bulkRuleEach(formatRs(paidCoverLeft(d)));
      ruleKind = AtomNoteKind.success;
    } else {
      rule = (d.advance > 0 ? l.bulkAdvancePaidPrefix : '') + l.bulkRuleLast;
      ruleKind = AtomNoteKind.success;
    }

    final blockText = switch (block) {
      PayForUnits(:final short) => l.bulkBlockPayUnits(formatRs(short)),
      BalanceFirst(:final due) => l.bulkBlockBalance(formatRs(due)),
      TooMany(:final title, :final left) => l.bulkBlockTooMany(title, left),
      _ => null,
    };
    void pay() => context.pushReplacement(V2Routes.dealPaymentOf(d.id));
    final reason = switch (block) {
      NothingPicked() => l.bulkReasonPick,
      AdvanceFirst() => l.bulkReasonAdvance,
      PayForUnits() || BalanceFirst() => l.bulkReasonPay,
      TooMany() => l.bulkReasonTooMany,
      null => null,
    };

    return AtomUnsavedGuard(
      dirty: _dirty && !_saving,
      child: Scaffold(
        backgroundColor: AtomColors.surface,
        body: Column(
          children: [
            AtomFlowBar(
              leading: AtomFlowLeading.close,
              title: l.bulkDeliverTitle(d.number),
              oneLine: true,
            ),
            const OfflineBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // The rule, and what blocks this delivery with "Record a
                  // payment" inside the amber note (7.8's `.note.amber`).
                  if (advanceDue)
                    BulkLinkNote(
                      kind: AtomNoteKind.warning,
                      lead: rule,
                      boldLead: false,
                      links: [if (canDeal) (l.bulkRecordAPayment, pay)],
                    )
                  else
                    AtomNote(kind: ruleKind, compact: true, message: rule),
                  if (blockText != null) ...[
                    const SizedBox(height: 8),
                    BulkLinkNote(
                      kind: AtomNoteKind.warning,
                      lead: blockText,
                      boldLead: false,
                      links: [
                        if (canDeal &&
                            (block is PayForUnits || block is BalanceFirst))
                          (l.bulkRecordAPayment, pay),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.bulkGoesOutHeader,
                          style: AtomText.section,
                        ),
                      ),
                      Text(l.bulkUnits(units), style: AtomText.small),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (open.isEmpty)
                    AtomNote(
                      kind: AtomNoteKind.info,
                      message: l.bulkAllDelivered,
                    )
                  else
                    BulkCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var k = 0; k < open.length; k++) ...[
                            if (k > 0)
                              const Divider(height: 1, color: AtomColors.line),
                            _itemEditor(open[k]),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  BulkCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AtomTextField(
                          label: l.bulkReceivedBy,
                          controller: _receivedBy,
                          placeholder: l.bulkReceivedByHint,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(100),
                          ],
                          onChanged: (_) => _changed(() {}),
                        ),
                        const SizedBox(height: 14),
                        AtomField(
                          label: l.bulkDeliveredOn,
                          child: AtomSelectBox(
                            text: _sameDay(_on, AtomDates.now())
                                ? l.bulkTodayDate(AtomDates.short(_on))
                                : AtomDates.day(_on),
                            onTap: _pickDay,
                            semanticLabel: l.bulkDeliveredOn,
                          ),
                        ),
                        const SizedBox(height: 14),
                        AtomTextField(
                          label: l.bulkNote,
                          labelNote: l.bulkOptional,
                          labelNoteInline: true,
                          controller: _note,
                          placeholder: l.bulkDeliverNoteHint,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(maxNotes),
                          ],
                          onChanged: (_) => _changed(() {}),
                        ),
                        const SizedBox(height: 14),
                        _PhotoField(
                          label: l.bulkSignedDeliveryNote,
                          prompt: l.bulkTakePhoto,
                          file: _photo,
                          onChanged: (f) => _changed(() => _photo = f),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.bulkLastNeedsBalance,
                    style: AtomText.small.copyWith(color: AtomColors.faint),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    AtomNote(
                      kind: AtomNoteKind.problem,
                      compact: true,
                      message: _error!,
                    ),
                  ],
                ],
              ),
            ),
            BulkBottomBar(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (reason != null && units > 0) ...[
                    AtomButtonReason(reason: reason),
                    const SizedBox(height: 6),
                  ],
                  AtomButton(
                    label: l.bulkSaveDelivery(units),
                    saving: _saving,
                    onPressed: !canDeal || block != null || _saving
                        ? null
                        : _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _itemEditor(DealItem i) {
    final l = AppLocalizations.of(context);
    final q = _qty[i.id] ?? 0;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i.title,
                      style: AtomText.listTitle.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l.bulkLeftOf(i.remaining, i.qty),
                      style: AtomText.small,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _QtyStepper(
                value: q,
                max: i.remaining,
                onChanged: (v) => _changed(() => _qty[i.id] = v),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AtomTextField(
            label: l.bulkSerials,
            labelNote: l.bulkOnePerLine,
            labelNoteInline: true,
            controller: _serials[i.id],
            placeholder: q == 0 ? l.bulkOptionalCap : l.bulkSerialsHint,
            minLines: 2,
            keyboardType: TextInputType.multiline,
            onChanged: (_) => _changed(() {}),
            trailing: AtomIconButton(
              icon: LucideIcons.scanLine,
              label: l.bulkScanSerialsFor(i.title),
              color: AtomColors.primary,
              onTap: () => _scan(i),
            ),
          ),
        ],
      ),
    );
  }
}

/// − qty + from 0 to [max].
class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget button(IconData icon, String label, int? next) => AtomPressable(
      onTap: next == null ? null : () => onChanged(next),
      semanticLabel: label,
      builder: (_, _) => SizedBox(
        width: 40,
        height: 40,
        child: Icon(
          icon,
          size: 18,
          color: next == null ? AtomColors.line2 : AtomColors.ink,
        ),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: AtomColors.paper,
        borderRadius: AtomRadius.brControl,
        border: Border.all(color: AtomColors.line2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(LucideIcons.minus, l.bulkFewer, value > 0 ? value - 1 : null),
          SizedBox(
            width: 36,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AtomText.money,
            ),
          ),
          button(LucideIcons.plus, l.bulkMore, value < max ? value + 1 : null),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────── 7.9 payment

class DealPaymentScreen extends StatelessWidget {
  const DealPaymentScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) => _WithDeal(
    id: id,
    title: AppLocalizations.of(context).bulkRecordPayment,
    builder: (d) => _PaymentForm(key: ValueKey(d.id), deal: d),
  );
}

class _PaymentForm extends ConsumerStatefulWidget {
  const _PaymentForm({super.key, required this.deal});

  final Deal deal;

  @override
  ConsumerState<_PaymentForm> createState() => _PaymentFormState();
}

/// `.amtbox .cur`: 44px, 800, tight tracking, tabular.
final _bigAmount = AtomText.amountLg.copyWith(
  fontSize: 44,
  fontWeight: FontWeight.w800,
  letterSpacing: -1,
  height: 1.1,
  fontFeatures: const [FontFeature.tabularFigures()],
);

class _PaymentFormState extends ConsumerState<_PaymentForm> {
  late final _amount = TextEditingController(
    text: _first > 0 ? groupDigits(_first) : '',
  );
  final _reference = TextEditingController();
  String _method = 'bank';
  DateTime _on = AtomDates.now();
  File? _receipt;
  bool _saving = false;
  String? _error;
  bool _dirty = false;

  /// What the amount starts at: the advance still to take, else nothing.
  int get _first {
    final l = AppLocalizations.of(context);
    final q = paymentQuickAmounts(l, widget.deal);
    return q.isNotEmpty && q.first.label == l.bulkPayAdvance
        ? q.first.amount
        : 0;
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  void _changed(VoidCallback f) => setState(() {
    f();
    _dirty = true;
    _error = null;
  });

  Future<void> _pickDay() async {
    final d = await showPastDaySheet(
      context,
      selected: _on,
      today: AtomDates.now(),
      title: AppLocalizations.of(context).bulkPaymentDate,
    );
    if (d != null) _changed(() => _on = d);
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final d = widget.deal;
    final amount = parseRupees(_amount.text);
    final p = paymentProblem(l, amount, d.balance);
    if (p != null) {
      setState(() => _error = p);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await ref
        .read(bulkRepositoryProvider)
        .payment(
          d,
          amount: amount,
          method: _method,
          paidOn: _on,
          reference: _reference.text,
          receipt: _receipt,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (saved) {
      case SavedOnServer():
        refreshDeal(ref, d.id);
        _dirty = false;
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: l.bulkPaymentSaved(formatRs(amount)),
        );
        Navigator.of(context).pop();
      case SavedHere():
        refreshDeal(ref, d.id);
        _dirty = false;
        showSavedHereToast(context);
        Navigator.of(context).pop();
      case SaveFailed(:final failure):
        setState(() => _error = sayFailure(l, failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = widget.deal;
    final canDeal = _canDeal(ref);
    final amount = parseRupees(_amount.text);
    final tooMuch = amount > d.balance;
    final quick = paymentQuickAmounts(l, d);
    final methods = ref.watch(quoteOptionsProvider).value?.paymentMethods;
    final methodList = methods == null || methods.isEmpty
        ? dealPaymentMethods(l)
        : methods;

    return AtomUnsavedGuard(
      dirty: _dirty && !_saving,
      child: Scaffold(
        backgroundColor: AtomColors.paper,
        body: Column(
          children: [
            AtomFlowBar(
              leading: AtomFlowLeading.close,
              title: l.bulkRecordPaymentTitle(d.number),
              oneLine: true,
            ),
            const OfflineBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  if (d.balance <= 0)
                    AtomNote(
                      kind: AtomNoteKind.success,
                      message: l.bulkDealPaidFull,
                    )
                  else ...[
                    // `.amtbox`: the balance line, then the amount itself,
                    // big (44/800), centred and borderless.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 18, 0, 6),
                      child: Column(
                        children: [
                          Text(
                            l.bulkWhoBalance(d.who, formatRs(d.balance)),
                            style: AtomText.secondary,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: IntrinsicWidth(
                              child: TextField(
                                controller: _amount,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                inputFormatters: const [
                                  RupeesInputFormatter(maxDigits: 10),
                                ],
                                style: _bigAmount.copyWith(
                                  color: tooMuch
                                      ? AtomColors.rose
                                      : AtomColors.ink,
                                ),
                                cursorColor: AtomColors.primary,
                                // Every border state off: the app theme draws
                                // enabled/focused borders over `border`.
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                  isCollapsed: true,
                                  prefixText: 'Rs ',
                                  prefixStyle: _bigAmount.copyWith(
                                    color: tooMuch
                                        ? AtomColors.rose
                                        : AtomColors.ink,
                                  ),
                                  hintText: '0',
                                  hintStyle: _bigAmount.copyWith(
                                    color: AtomColors.faint,
                                  ),
                                ),
                                onChanged: (_) => _changed(() {}),
                              ),
                            ),
                          ),
                          if (tooMuch) ...[
                            const SizedBox(height: 4),
                            Text(
                              l.bulkPayOverBalance(formatRs(d.balance)),
                              style: AtomText.fieldError,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (quick.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      // `.quick .mini`: small pills, centred.
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final q in quick)
                            AtomButton(
                              label: q.label,
                              kind: AtomButtonKind.outline,
                              small: true,
                              expand: false,
                              onPressed: () => _changed(
                                () => _amount.text = groupDigits(q.amount),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    AtomField(
                      label: l.bulkHowPaid,
                      child: AtomChoiceGrid<String>(
                        columns: 3,
                        choices: [
                          for (final m in methodList)
                            AtomSegment(m.key, m.label),
                        ],
                        selected: _method,
                        onChanged: (m) => _changed(() => _method = m),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AtomField(
                            label: l.bulkPaymentDate,
                            child: AtomSelectBox(
                              text: AtomDates.day(_on),
                              onTap: _pickDay,
                              semanticLabel: l.bulkPaymentDate,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AtomTextField(
                            label: l.bulkReference,
                            controller: _reference,
                            placeholder: l.bulkOptionalCap,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(80),
                            ],
                            onChanged: (_) => _changed(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _PhotoField(
                      label: l.bulkReceipt,
                      prompt: l.bulkSlipPhoto,
                      height: 84,
                      file: _receipt,
                      onChanged: (f) => _changed(() => _receipt = f),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    AtomNote(
                      kind: AtomNoteKind.problem,
                      compact: true,
                      message: _error!,
                    ),
                  ],
                ],
              ),
            ),
            if (d.balance > 0)
              BulkBottomBar(
                child: AtomButton(
                  label: l.bulkSavePayment,
                  saving: _saving,
                  onPressed: !canDeal || amount <= 0 || tooMuch || _saving
                      ? null
                      : _save,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
