import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../data/bulk_logic.dart';
import '../data/bulk_models.dart';
import '../data/bulk_repository.dart';
import 'bulk_parts.dart';
import 'status_sheets.dart';

/// 7.2 Seller request and 7.3 Website bulk request: one route each, one
/// screen. A website link to a seller's request (a push opens
/// `bulk-request/{id}`) shows the seller's view, as the server says which
/// it is.
class BulkRequestScreen extends ConsumerWidget {
  const BulkRequestScreen({super.key, required this.id, this.seller = false});

  final int id;

  /// Opened as a seller request (only the loading title differs).
  final bool seller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final dossier = ref.watch(bulkDossierProvider(id));
    final title = seller ? l.bulkSellerRequest : l.bulkBulkRequest;
    return switch (dossier) {
      AsyncValue(:final value?) =>
        value.isSeller
            ? _SourcingView(dossier: value)
            : _WebsiteView(dossier: value),
      AsyncValue(:final error?) => BulkLoadFrame(
        title: title,
        error: error,
        onRetry: () => ref.invalidate(bulkDossierProvider(id)),
      ),
      _ => BulkLoadFrame(title: title, error: null, onRetry: () {}),
    };
  }
}

bool _can(WidgetRef ref, String permission) => ref.watch(
  sessionProvider.select(
    (s) => s is SignedIn ? s.session.who.can(permission) : false,
  ),
);

Future<void> _sharePdf(BuildContext context, WidgetRef ref, Quote q) async {
  final l = AppLocalizations.of(context);
  showAtomToast(context, kind: AtomToastKind.wait, message: l.bulkGettingPdf);
  final failure = await handOverServerPdf(
    ref.read(apiClientProvider),
    ref.read(bulkRepositoryProvider).quotePdf(q),
  );
  if (failure != null && context.mounted) {
    showAtomToast(
      context,
      kind: AtomToastKind.bad,
      message: sayPdfFailure(l, failure),
    );
  }
}

/// The catalogue price of [productId], from the quote options.
int? _priceOf(WidgetRef ref, int? productId) =>
    ref.watch(quoteOptionsProvider).value?.product(productId)?.price;

// ───────────────────────────────────────────────────── 7.2 seller request

class _SourcingView extends ConsumerWidget {
  const _SourcingView({required this.dossier});

  final BulkDossier dossier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final d = dossier;
    final r = d.request;
    final s = d.sourcing;
    final quotes = ref.watch(requestQuotesProvider(r.id)).value;
    final deal = s?.deal ?? quotes?.deal;
    final live = s?.liveQuote ?? _latestSent(quotes?.quotes);
    final state = sourcingStateOf(
      status: r.status,
      answer: s?.answer,
      liveQuote: live,
      deal: deal,
    );
    final canQuote = _can(ref, BrandPermission.bulkQuote);
    final seller = s?.seller ?? r.seller;
    final title = s?.title ?? r.title;
    final qty = s?.quantity ?? r.quantity;
    final reached = sourcingStepsReached(state, dealStatus: deal?.status);
    final price = _priceOf(ref, s?.productId ?? r.productId);
    final declined =
        state == SourcingState.declined || state == SourcingState.closed;
    final showBar =
        canQuote &&
        (state == SourcingState.fresh ||
            state == SourcingState.quoted ||
            state == SourcingState.declined);

    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                refreshRequest(ref, r.id);
                try {
                  await ref.read(bulkDossierProvider(r.id).future);
                } on Object {
                  // shown by the screen
                }
              },
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  BulkDetailHeader(
                    eyebrow: l.bulkSellerRequestWhen(bulkWhen(l, r.createdAt)),
                    title: '$qty × $title',
                    subtitle: [
                      seller?.name ?? r.fullName,
                      l.bulkAtomshopSeller,
                      ?(seller?.city ?? r.city),
                    ].join(' · '),
                    status: AtomPill(
                      label: state.label(l),
                      tone: sourcingTone(state),
                    ),
                    children: [
                      BulkSteps(
                        labels: [
                          l.bulkStepAsked,
                          l.bulkStatusQuoted,
                          declined
                              ? l.bulkStatusDeclined
                              : l.bulkStepSellerAnswers,
                          l.bulkDeal,
                          l.bulkDealDelivered,
                        ],
                        reached: reached,
                        lostAt: declined ? 2 : null,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ..._stateNote(
                          context,
                          ref,
                          d,
                          state,
                          live,
                          deal,
                          canQuote,
                        ),
                        if (seller != null) ...[
                          _SellerRecord(seller: seller, dossier: d),
                          const SizedBox(height: 12),
                        ],
                        _WhatTheyNeed(
                          dossier: d,
                          price: price,
                          quiet: !state.canQuote,
                        ),
                        const SizedBox(height: 12),
                        _QuotesCard(
                          quotes: quotes?.quotes ?? [?live],
                          empty: l.bulkNoQuoteSeller,
                          onPdf: (q) => _sharePdf(context, ref, q),
                          answer: s?.answer,
                        ),
                        const SizedBox(height: 12),
                        _CommissionCard(
                          commission: s?.commission,
                          hasDeal: deal != null,
                        ),
                        if (s != null && s.history.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _SourcingHistory(
                            history: s.history,
                            seller: seller?.name,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showBar)
            BulkBottomBar(
              child: Row(
                children: [
                  Expanded(
                    flex: 10,
                    child: AtomButton(
                      label: l.bulkDecline,
                      kind: AtomButtonKind.outline,
                      onPressed: () =>
                          showStatusSheet(context, r.id, declineOnly: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 16,
                    child: AtomButton(
                      label: state == SourcingState.fresh
                          ? l.bulkActSendQuote
                          : l.bulkSendANewQuote,
                      onPressed: () =>
                          context.push(V2Routes.sellerRequestQuoteOf(r.id)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _stateNote(
    BuildContext context,
    WidgetRef ref,
    BulkDossier d,
    SourcingState state,
    Quote? live,
    DealRef? deal,
    bool canQuote,
  ) {
    final l = AppLocalizations.of(context);
    final s = d.sourcing;
    const gap = SizedBox(height: 12);
    switch (state) {
      case SourcingState.fresh:
        final need = s?.neededBy == null
            ? null
            : needByOf(s!.neededBy!, today: AtomDates.now());
        final day = s?.neededBy == null ? '' : AtomDates.weekday(s!.neededBy!);
        final lead = need == null
            ? l.bulkReplySoon
            : need.days < 0
            ? l.bulkNeededByLate(day, daysLeftText(l, need.days))
            : need.days <= 1
            // "today" and "tomorrow" read wrong before "left"
            ? l.bulkNeededByWhen(day, daysLeftText(l, need.days))
            : l.bulkNeededByLeft(day, daysLeftText(l, need.days));
        return [
          AtomNote(
            kind: need != null && need.urgency > 0
                ? AtomNoteKind.warning
                : AtomNoteKind.info,
            icon: LucideIcons.clock,
            message: '$lead ${l.bulkAskOthers}',
            bold: [lead],
          ),
          gap,
        ];
      case SourcingState.changeAsked:
        final a = s?.answer;
        return [
          BulkCard(
            tone: AtomTone.amber,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const AtomIconTile(
                      icon: LucideIcons.messageSquareWarning,
                      tone: AtomTone.amber,
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.bulkChangeAskedTitle,
                        style: AtomText.listTitle.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(bulkAgo(l, a?.at), style: AtomText.small),
                  ],
                ),
                if (a?.message != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '“${a!.message}”',
                    style: AtomText.body.copyWith(color: AtomColors.text),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  (live == null ? '' : l.bulkOnQuote(live.name)) +
                      l.bulkSendRevisionNote,
                  style: AtomText.small,
                ),
                if (canQuote) ...[
                  const SizedBox(height: 10),
                  AtomButton(
                    label: l.bulkSendANewQuote,
                    onPressed: () => context.push(
                      V2Routes.sellerRequestQuoteOf(d.request.id),
                    ),
                  ),
                ],
              ],
            ),
          ),
          gap,
        ];
      case SourcingState.quoted:
        if (live == null) return const [];
        final until = live.validUntil == null
            ? ''
            : ' ${l.bulkValidUntilSentence(AtomDates.short(live.validUntil!))}';
        return [
          if (live.expired)
            AtomNote(
              kind: AtomNoteKind.warning,
              message:
                  '${l.bulkQuoteExpiredLead(live.name)}$until ${l.bulkKeepSeller}',
              bold: [l.bulkQuoteExpiredLead(live.name)],
            )
          else
            AtomNote(
              kind: AtomNoteKind.info,
              icon: LucideIcons.send,
              message:
                  '${l.bulkQuoteWithSellerLead(live.name)} ${l.bulkQuoteWithSellerBody}$until',
              bold: [l.bulkQuoteWithSellerLead(live.name)],
            ),
          gap,
        ];
      case SourcingState.declined:
        final a = s?.answer;
        final why = a?.reason ?? a?.message;
        final lead = why == null ? l.bulkTurnedDownDot : l.bulkTurnedDownColon;
        return [
          AtomNote(
            kind: AtomNoteKind.problem,
            message: d.request.status == RequestStatus.lost
                ? '$lead ${why ?? ''} ${l.bulkRequestClosed}'
                : '$lead ${why ?? ''} ${l.bulkStillQuote}',
            bold: [lead],
          ),
          gap,
        ];
      case SourcingState.closed:
        final lead = l.bulkYouDeclined;
        return [
          AtomNote(
            kind: AtomNoteKind.problem,
            message: d.reason == null
                ? lead
                : '$lead ${l.bulkReasonSentence(d.reason!)}',
            bold: [lead],
          ),
          gap,
        ];
      case SourcingState.accepted:
        final lead = deal == null
            ? l.bulkAcceptedDot
            : l.bulkAcceptedDeal(deal.number);
        final adv = live != null && live.advancePct > 0
            ? l.bulkWonInfoAdvance(live.advancePct)
            : '';
        return [
          AtomNote(
            kind: AtomNoteKind.success,
            message: '$lead$adv',
            bold: [lead],
          ),
          if (deal != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: AtomTextLink(
                  label: l.bulkOpenDealNumber(deal.number),
                  onTap: () => context.push(V2Routes.dealOf(deal.id)),
                ),
              ),
            ),
          gap,
        ];
    }
  }
}

Quote? _latestSent(List<Quote>? quotes) {
  if (quotes == null) return null;
  for (final q in quotes) {
    if (!q.isDraft) return q;
  }
  return null;
}

class _SellerRecord extends StatelessWidget {
  const _SellerRecord({required this.seller, required this.dossier});

  final BulkSeller seller;
  final BulkDossier dossier;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = dossier.request;
    final other = seller.otherRequests.isEmpty
        ? '${seller.otherOpen}'
        : '${seller.otherOpen} (${seller.otherRequests.first.title})';
    return BulkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AtomInitials(name: seller.name, size: 44, tone: AtomTone.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            seller.name,
                            style: AtomText.listTitle.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (seller.verified) ...[
                          const SizedBox(width: 6),
                          const VerifiedMark(),
                        ],
                      ],
                    ),
                    Text(
                      [
                        ?seller.branch,
                        ?seller.city,
                        if (seller.code != null) l.bulkCode(seller.code!),
                      ].join(' · '),
                      style: AtomText.secondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (seller.since != null) ...[
            AtomInfoLine(
              label: l.bulkOnAtomshopSince,
              value: AtomDates.monthYear(seller.since!),
            ),
            const Divider(height: 1, color: AtomColors.line),
          ],
          AtomInfoLine(
            label: l.bulkBoughtFromYou,
            value: seller.dealsWithYou == 0
                ? l.bulkNotYet
                : '${l.bulkKpiDeals(seller.dealsWithYou)} · ${formatRs(seller.dealsAmount)}',
          ),
          if (seller.dealsWithYou > 0) ...[
            const Divider(height: 1, color: AtomColors.line),
            AtomInfoLine(
              label: l.bulkPaidOnTime,
              value: l.bulkDoneOf(seller.paidOnTime, seller.dealsWithYou),
              valueColor: AtomColors.green,
            ),
          ],
          const Divider(height: 1, color: AtomColors.line),
          AtomInfoLine(label: l.bulkOtherOpen, value: other),
          const SizedBox(height: 8),
          ContactButtons(phone: r.phone, whatsapp: dossier.whatsapp),
        ],
      ),
    );
  }
}

class _WhatTheyNeed extends StatelessWidget {
  const _WhatTheyNeed({
    required this.dossier,
    required this.price,
    required this.quiet,
  });

  final BulkDossier dossier;

  /// The brand's cash price for the product, when it is in the catalogue.
  final int? price;

  /// A closed request: the needed-by date isn't urgent any more.
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = dossier.sourcing;
    final r = dossier.request;
    final title = s?.title ?? r.title;
    final qty = s?.quantity ?? r.quantity;
    final typed = s?.typed ?? r.productId == null;
    final target = s?.targetPrice ?? r.targetPrice;
    final needed = s?.neededBy ?? r.neededBy;
    final need = needed == null
        ? null
        : needByOf(needed, today: AtomDates.now());
    final deliverTo = s?.deliverTo ?? '';
    return BulkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BulkCardTitle(l.bulkWhatTheyNeed),
          const SizedBox(height: 8),
          Row(
            children: [
              AtomThumb(url: s?.picture ?? r.productPicture, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AtomText.listTitle.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (typed)
                      BulkTag(l.bulkTypedTag, tone: AtomTone.purple)
                    else
                      Text(l.bulkFromCatalogue, style: AtomText.secondary),
                  ],
                ),
              ),
              Text(
                '× $qty',
                style: AtomText.money.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (target != null || price != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (target != null)
                  Expanded(
                    child: _CompareBox(
                      label: l.bulkHopesToPay,
                      value: formatRs(target),
                      note: l.bulkAUnit,
                    ),
                  ),
                if (target != null && price != null) const SizedBox(width: 8),
                if (price != null)
                  Expanded(
                    child: _CompareBox(
                      label: l.bulkCashPrice,
                      value: formatRs(price!),
                      note: target == null
                          ? l.bulkAUnit
                          : switch (percentAbove(price!, target)) {
                              0 => l.bulkSamePrice,
                              > 0 && final p => l.bulkAbovePrice(p),
                              final p => l.bulkBelowPrice(-p),
                            },
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          if (needed != null)
            AtomInfoLine(
              label: l.bulkNeededBy,
              value: [
                AtomDates.weekday(needed),
                if (need!.days <= 7 && !quiet) daysLeftText(l, need.days),
              ].join(' · '),
              valueColor: !quiet && need.urgency == 2 ? AtomColors.rose : null,
            ),
          if (deliverTo.isNotEmpty) ...[
            const Divider(height: 1, color: AtomColors.line),
            AtomInfoLine(label: l.bulkDeliverTo, value: deliverTo),
          ],
          if (price != null) ...[
            const Divider(height: 1, color: AtomColors.line),
            AtomInfoLine(
              label: l.bulkAtYourPrice,
              value: formatRs(price! * qty),
            ),
          ],
          if (s?.note != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: AtomColors.head,
                borderRadius: AtomRadius.brControl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.bulkSellersNoteLabel, style: AtomText.small),
                  const SizedBox(height: 2),
                  Text(
                    s!.note!,
                    style: AtomText.body.copyWith(color: AtomColors.text),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `.cmp`: a small figure box.
class _CompareBox extends StatelessWidget {
  const _CompareBox({required this.label, required this.value, this.note});

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: const BoxDecoration(
      color: AtomColors.head,
      borderRadius: AtomRadius.brControl,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AtomText.small),
        Text(value, style: AtomText.money.copyWith(fontSize: 17)),
        if (note != null) Text(note!, style: AtomText.small),
      ],
    ),
  );
}

/// The quotes sent on a request, newest first.
class _QuotesCard extends StatelessWidget {
  const _QuotesCard({
    required this.quotes,
    required this.empty,
    required this.onPdf,
    this.answer,
    this.trailing,
  });

  final List<Quote> quotes;
  final String empty;
  final ValueChanged<Quote> onPdf;
  final SellerAnswer? answer;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BulkCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BulkCardTitle(l.bulkQuotesSent, trailing: trailing),
          if (quotes.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Text(empty, style: AtomText.secondary),
            )
          else
            for (var i = 0; i < quotes.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AtomColors.line),
              _QuoteRow(
                quote: quotes[i],
                answer: i == 0 ? answer : null,
                onPdf: () => onPdf(quotes[i]),
              ),
            ],
        ],
      ),
    );
  }
}

class _QuoteRow extends StatelessWidget {
  const _QuoteRow({required this.quote, required this.onPdf, this.answer});

  final Quote quote;
  final SellerAnswer? answer;
  final VoidCallback onPdf;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final q = quote;
    var (label, tone) = quoteLook(l, q);
    if (answer case SellerAnswer(action: 'change_asked', pending: true)) {
      (label, tone) = (l.bulkStatusChangeAsked, AtomTone.amber);
    } else if (answer case SellerAnswer(action: 'declined' || 'cancelled')
        when q.status == 'sent') {
      (label, tone) = (l.bulkStatusDeclined, AtomTone.rose);
    }
    final line = [
      if (q.items.length == 1)
        '${q.items.first.qty} × ${formatRs(q.items.first.unitPrice)}'
      else if (q.items.isNotEmpty)
        l.bulkUnits(q.units),
      if (q.advancePct > 0) l.bulkAdvancePct(q.advancePct),
      if (q.validUntil != null)
        l.bulkValidUntil(AtomDates.short(q.validUntil!)),
    ].join(' · ');
    return AtomPressable(
      onTap: q.isDraft ? null : onPdf,
      semanticLabel: l.bulkQuoteSemantics(q.name, formatRs(q.total), label),
      scaleOnPress: false,
      builder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      q.name,
                      if (q.sentAt != null)
                        l.bulkSentDate(AtomDates.short(q.sentAt!)),
                    ].join(' · '),
                    style: AtomText.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AtomColors.ink,
                    ),
                  ),
                  if (line.isNotEmpty) Text(line, style: AtomText.small),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatRs(q.total),
                  style: AtomText.money.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 4),
                AtomPill(label: label, tone: tone),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommissionCard extends StatelessWidget {
  const _CommissionCard({required this.commission, required this.hasDeal});

  final Commission? commission;
  final bool hasDeal;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = commission;
    return BulkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BulkCardTitle(l.bulkCommission),
          const SizedBox(height: 4),
          Text(
            hasDeal ? l.bulkCommissionFixed : l.bulkCommissionInfo,
            style: AtomText.secondary,
          ),
          if (c != null)
            AtomInfoLine(
              label: l.bulkOnThisRequest,
              value: c.amount == 0
                  ? 'Rs 0${c.label == null ? '' : ' · ${c.label}'}'
                  : '${formatRs(c.amount)}${c.label == null ? '' : ' · ${c.label}'}',
            ),
        ],
      ),
    );
  }
}

class _SourcingHistory extends StatelessWidget {
  const _SourcingHistory({required this.history, this.seller});

  final List<HistoryEntry> history;
  final String? seller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BulkCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BulkCardTitle(l.bulkHistory),
          for (final h in history)
            BulkHistoryRow(
              when: bulkWhen(l, h.at),
              what: TextSpan(
                children: [
                  TextSpan(
                    text: switch (h.actor) {
                      'seller' => seller ?? l.bulkTheSeller,
                      'brand' => h.by ?? l.bulkYou,
                      'atomshop' => 'Atomshop',
                      _ => h.by ?? '',
                    },
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text:
                        ' ${h.label.toLowerCase()}'
                        '${h.details == null ? '' : ': ${h.details}'}',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────── 7.3 website request

class _WebsiteView extends ConsumerWidget {
  const _WebsiteView({required this.dossier});

  final BulkDossier dossier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final d = dossier;
    final r = d.request;
    final quotes = ref.watch(requestQuotesProvider(r.id)).value;
    final list = quotes?.quotes ?? const <Quote>[];
    final deal = quotes?.deal;
    final canQuote = _can(ref, BrandPermission.bulkQuote);
    final open = r.status.open;
    final latest = _latestSent(list);
    final canWin =
        canQuote &&
        deal == null &&
        open &&
        list.any((q) => q.status == 'sent' || q.status == 'accepted');
    final price = _priceOf(ref, r.productId);
    final lost = r.status == RequestStatus.lost;
    final delivered = switch (deal?.status) {
      'delivered' || 'paid' || 'closed' => true,
      _ => false,
    };
    final req = d.requester;

    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                refreshRequest(ref, r.id);
                try {
                  await ref.read(bulkDossierProvider(r.id).future);
                } on Object {
                  // shown by the screen
                }
              },
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  BulkDetailHeader(
                    eyebrow: l.bulkBulkRequestWhen(bulkWhen(l, r.createdAt)),
                    title: '${r.quantity} × ${r.title}',
                    subtitle: [r.fullName, ?r.city].join(' · '),
                    status: AtomPill(
                      label: requestLabel(l, r.status),
                      tone: requestTone(r.status),
                    ),
                    children: [
                      BulkSteps(
                        labels: [
                          l.bulkStatusNew,
                          l.bulkStatusContacted,
                          lost ? l.bulkStatusLost : l.bulkStatusQuoted,
                          l.bulkStatusWon,
                          l.bulkStepDeliveredPaid,
                        ],
                        reached: delivered ? 5 : requestStepIndex(r.status) + 1,
                        lostAt: lost ? 2 : null,
                      ),
                      ContactButtons(
                        phone: r.phone,
                        whatsapp: d.whatsapp,
                        extra: canQuote && open
                            ? AtomButton(
                                label: l.bulkStatusButton,
                                kind: AtomButtonKind.outline,
                                small: true,
                                onPressed: () => showStatusSheet(context, r.id),
                              )
                            : null,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (r.status == RequestStatus.quoted &&
                            latest != null) ...[
                          AtomNote(
                            kind: AtomNoteKind.success,
                            message: l.bulkQuoteReady(latest.name),
                            bold: [l.bulkQuoteReady(latest.name)],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 16,
                              children: [
                                if (latest.whatsappLink != null)
                                  AtomTextLink(
                                    label: l.bulkOpenWhatsApp,
                                    onTap: () =>
                                        openWhatsApp(link: latest.whatsappLink),
                                  ),
                                AtomTextLink(
                                  label: l.bulkDownloadPdf,
                                  onTap: () => _sharePdf(context, ref, latest),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (r.status == RequestStatus.won) ...[
                          AtomNote(
                            kind: AtomNoteKind.success,
                            message: deal == null
                                ? l.bulkWonDot
                                : l.bulkWonDeal(deal.number),
                          ),
                          if (deal != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: AtomTextLink(
                                  label: l.bulkActOpenDeal,
                                  onTap: () =>
                                      context.push(V2Routes.dealOf(deal.id)),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                        ],
                        if (lost) ...[
                          AtomNote(
                            kind: AtomNoteKind.problem,
                            message: d.reason == null
                                ? l.bulkLostDot
                                : l.bulkLostReason(d.reason!),
                            bold: [
                              d.reason == null
                                  ? l.bulkLostDot
                                  : l.bulkLostReason(d.reason!),
                            ],
                          ),
                          if (canQuote)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: AtomTextLink(
                                  label: l.bulkStatusBackToNew,
                                  onTap: () => showStatusSheet(
                                    context,
                                    r.id,
                                    preset: StatusChoice.backToNew,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                        ],
                        BulkLinesCard(
                          title: l.bulkTheRequest,
                          lines: [
                            AtomInfoLine(label: l.bulkProduct, value: r.title),
                            AtomInfoLine(
                              label: l.bulkQuantity,
                              value: l.bulkUnits(r.quantity),
                            ),
                            if (price != null)
                              AtomInfoLine(
                                label: l.bulkAtListPrice,
                                value: formatRs(price * r.quantity),
                              ),
                            if (r.targetPrice != null)
                              AtomInfoLine(
                                label: l.bulkPriceHope,
                                value: l.bulkPriceAUnit(
                                  formatRs(r.targetPrice!),
                                ),
                              ),
                            if (r.neededBy != null)
                              AtomInfoLine(
                                label: l.bulkNeededBy,
                                value: AtomDates.short(r.neededBy!),
                              ),
                            if ([?d.address, ?r.area, ?r.city].isNotEmpty)
                              AtomInfoLine(
                                label: l.bulkDeliverTo,
                                value: [
                                  ?d.address,
                                  ?r.area,
                                  ?r.city,
                                ].join(', '),
                              ),
                            if (r.phone != null)
                              AtomInfoLine(label: l.bulkPhone, value: r.phone!),
                            if (lost && d.reason != null)
                              AtomInfoLine(
                                label: l.bulkLostBecause,
                                value: d.reason!,
                              ),
                          ],
                        ),
                        if (list.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _QuotesCard(
                            quotes: list,
                            empty: '',
                            onPdf: (q) => _sharePdf(context, ref, q),
                            trailing: canQuote && open
                                ? AtomTextLink(
                                    label: l.bulkNewRevision,
                                    onTap: () => context.push(
                                      V2Routes.bulkQuoteOf(r.id),
                                    ),
                                  )
                                : null,
                          ),
                        ],
                        if (canWin) ...[
                          const SizedBox(height: 12),
                          BulkCard(
                            tone: AtomTone.green,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                BulkCardTitle(l.bulkSaidYesQ),
                                Text(
                                  l.bulkMarkWonNote,
                                  style: AtomText.secondary,
                                ),
                                const SizedBox(height: 10),
                                AtomButton(
                                  label: l.bulkMarkWon,
                                  onPressed: () => showWonSheet(context, r.id),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (d.comments.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          BulkCard(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                BulkCardTitle(l.bulkConversation),
                                for (final c in d.comments)
                                  BulkHistoryRow(
                                    when: bulkWhen(l, c.at),
                                    what: TextSpan(
                                      text: [c.text, ?c.byName].join(' · '),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        BulkLinesCard(
                          title: l.bulkContactStanding,
                          lines: [
                            AtomInfoLine(
                              label: l.bulkName,
                              value: req?.name ?? r.fullName,
                            ),
                            if ((req?.phone ?? r.phone) != null)
                              AtomInfoLine(
                                label: l.bulkPhone,
                                value: (req?.phone ?? r.phone)!,
                              ),
                            if (req?.email != null)
                              AtomInfoLine(
                                label: l.bulkEmail,
                                value: req!.email!,
                              ),
                            if (req?.since != null)
                              AtomInfoLine(
                                label: l.bulkOnAtomshopSince,
                                value: AtomDates.monthYear(req!.since!),
                              ),
                            if (req != null)
                              AtomInfoLine(
                                label: l.bulkVerified,
                                value: req.verified ? l.commonYes : l.commonNo,
                                valueColor: req.verified
                                    ? AtomColors.green
                                    : null,
                              )
                            else
                              AtomInfoLine(
                                label: l.bulkAccount,
                                value: l.bulkGuest,
                              ),
                            AtomInfoLine(
                              label: l.bulkBoughtFromYou,
                              value: d.ordersCount == 0
                                  ? l.bulkNotYet
                                  : '${l.bulkOrdersCount(d.ordersCount)} · ${formatRs(d.lifetimeValue)}',
                            ),
                            AtomInfoLine(
                              label: l.bulkOtherRequests,
                              value: '${d.otherRequests.length}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (canQuote && open)
            BulkBottomBar(
              child: Row(
                children: [
                  Expanded(
                    flex: 10,
                    child: AtomButton(
                      label: l.bulkUpdateStatus,
                      kind: AtomButtonKind.outline,
                      onPressed: () => showStatusSheet(context, r.id),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 16,
                    child: AtomButton(
                      label: r.status == RequestStatus.quoted
                          ? l.bulkNewQuoteRevision
                          : l.bulkActSendQuote,
                      onPressed: () => context.push(V2Routes.bulkQuoteOf(r.id)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
