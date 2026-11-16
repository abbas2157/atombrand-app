import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/api/api_client.dart' show Json;
import '../../../core/api/api_result.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../orders/data/order_rules.dart';
import '../../orders/data/orders_models.dart';
import '../../orders/data/orders_providers.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/ui/order_parts.dart';
import '../../sync/data/offline_saves.dart';
import '../../sync/ui/offline_bar.dart';
import '../../sync/ui/saved_here_sheet.dart';
import '../data/atompay_models.dart';
import '../data/atompay_repository.dart';
import 'atompay_parts.dart';

/// The AtomPay order page (6.9): the cash price, what the seller owes, the
/// customer's plan, the brand's step, the steps, the seller, the
/// customer, the hand-over and the history.
class AtompayScreen extends StatelessWidget {
  const AtompayScreen({super.key, required this.uuid});
  final String uuid;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AtomColors.surface,
    body: AtompayView(uuid: uuid),
  );
}

class AtompayView extends ConsumerWidget {
  const AtompayView({super.key, required this.uuid, this.embedded = false});

  final String uuid;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final order = ref.watch(atompayDetailProvider(uuid));
    Widget withBar(Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!embedded) const AtomFlowBar(),
        Expanded(child: child),
      ],
    );
    return order.when(
      skipLoadingOnReload: true,
      loading: () => withBar(const Center(child: AtomSpinner(size: 28))),
      error: (e, _) => withBar(
        e is ApiFailure && e.kind == ApiFailureKind.notFound
            ? AtomMessageState(
                icon: LucideIcons.searchX,
                art: false,
                title: l.ordersNotFound,
                body: l.ordersNotFoundBody,
                actionLabel: embedded ? null : l.commonBack,
                onAction: embedded
                    ? null
                    : () => Navigator.of(context).maybePop(),
              )
            : OrdersLoadError(
                error: e,
                onRetry: () => ref.invalidate(atompayDetailProvider(uuid)),
              ),
      ),
      data: (d) => _AtompayBody(detail: d, embedded: embedded),
    );
  }
}

/// The notice under the header, by step: (kind, words).
(AtomNoteKind, String) atompayNotice(
  AtompayDetail d,
  AppLocalizations l, {
  String? outlet,
}) {
  final seller = d.seller?.name ?? l.atompayTheSeller;
  return switch (d.step) {
    AtompayStep.approving => (AtomNoteKind.info, l.atompayNoticeApproving),
    AtompayStep.seller => (
      AtomNoteKind.info,
      outlet == null ? l.atompayNoticeSeller : l.atompayNoticeSellerAt(outlet),
    ),
    AtompayStep.handover => (
      AtomNoteKind.warning,
      l.atompayNoticeHandover(seller),
    ),
    AtompayStep.handed => (
      AtomNoteKind.info,
      d.handedAt == null
          ? l.atompayNoticeHanded(seller)
          : l.atompayNoticeHandedOn(seller, AtomDates.short(d.handedAt!)),
    ),
    AtompayStep.paid => (AtomNoteKind.success, l.atompayNoticePaid(seller)),
    AtompayStep.cancelled => (AtomNoteKind.problem, l.atompayNoticeCancelled),
  };
}

/// One line of an AtomPay order's history.
String atompayEventText(OrderEvent e, AppLocalizations l, {String? me}) {
  final p = e.payload;
  final who = e.byName == null
      ? null
      : (e.byName == me ? l.ordersYou : e.byName);
  String withWho(String s) => [s, ?who].join(' · ');
  if (p['handover'] != null || p['received_by'] != null) {
    return withWho(
      [
        l.atompayHandedOver,
        if (Json.str(p['serial']) case final s? when s.isNotEmpty)
          l.atompayEvSerial(s),
        if (Json.str(p['received_by']) case final r? when r.isNotEmpty)
          l.atompayEvTo(r),
      ].join(', '),
    );
  }
  if (p['brand_sale'] != null) return withWho(l.atompayEvSaleDone);
  return switch (e.stage) {
    OrderStage.cancelled => l.atompayEvNotApproved,
    OrderStage.confirming => l.atompayEvChecking,
    OrderStage.processing => l.atompayEvApproved,
    OrderStage.pending => l.ordersPlacedOnline,
    _ => withWho(e.status),
  };
}

class _AtompayBody extends ConsumerStatefulWidget {
  const _AtompayBody({required this.detail, required this.embedded});
  final AtompayDetail detail;
  final bool embedded;

  @override
  ConsumerState<_AtompayBody> createState() => _AtompayBodyState();
}

class _AtompayBodyState extends ConsumerState<_AtompayBody> {
  bool _saving = false;

  /// Complete the cash sale to the seller (`POST orders/{uuid}/status`
  /// Completed), once it is paid.
  Future<void> _complete() async {
    final d = widget.detail;
    setState(() => _saving = true);
    final repo = ref.read(ordersRepositoryProvider);
    // What the order's own status is now, as the server checks it.
    final seen = switch (await repo.detail(d.uuid)) {
      ApiOk(:final value) => value.stage,
      ApiErr() => OrderStage.delivered,
    };
    final r = await repo.setStatus(
      d.uuid,
      to: OrderStage.completed,
      seen: seen,
    );
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    setState(() => _saving = false);
    switch (r) {
      case SavedOnServer():
        refreshAtompay(ref, d.uuid);
        refreshOrder(ref, d.uuid);
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: l.atompaySaleCompleted,
        );
      case SavedHere():
        refreshAtompay(ref, d.uuid);
        showSavedHereToast(context);
      case SaveFailed(:final failure):
        showAtomToast(
          context,
          kind: AtomToastKind.bad,
          message: sayOrderFailure(failure, l),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = widget.detail;
    final o = d.order;
    final session = ref.watch(sessionProvider.notifier).current;
    final who = session?.who;
    final writes = !ref.watch(accessProvider).account.blocksWrites;
    final multi = session?.multiOutlet ?? false;
    final me = session?.name;
    final allowed = d.allowed;
    final paid = d.step == AtompayStep.paid;
    // The seller's payment, Complete and the receipt go through the cash
    // order calls, which need Orders in the role too.
    final cashCalls = who?.can(BrandPermission.ordersView) ?? false;
    final seller = d.seller;
    final at = AtompayStep.flow.indexOf(d.step);
    final doneTo = at < 0 ? -1 : at;

    // The brand's step, if the person may take it.
    final (String, String, String, VoidCallback)? next = !writes
        ? null
        : allowed.contains(AtompayAction.handover)
        ? (
            l.atompayHandOverUnit,
            l.atompayHandOverBody,
            l.atompayHandOverUnit,
            () => context.push(V2Routes.atompayHandoverOf(d.uuid)),
          )
        : allowed.contains(AtompayAction.payment) &&
              cashCalls &&
              (who?.can(BrandPermission.ordersPayment) ?? false)
        ? (
            l.ordersRecordSellerPayment,
            l.atompayPayBody(
              formatRs(o.balance),
              seller?.name ?? l.atompayTheSeller,
            ),
            l.ordersRecordSellerPayment,
            () => context.push(V2Routes.orderPaymentOf(d.uuid)),
          )
        : allowed.contains(AtompayAction.complete) &&
              cashCalls &&
              (who?.can(BrandPermission.ordersStatus) ?? false) &&
              !d.fromCopy
        ? (
            l.atompayCompleteSale,
            l.atompayCompleteBody,
            l.ordersComplete,
            _complete,
          )
        : null;

    final (noteKind, noteText) = atompayNotice(d, l, outlet: o.outlet?.name);

    final stepNames = [
      (
        l.ordersEvPlaced,
        o.createdAt == null ? '' : AtomDates.short(o.createdAt!),
      ),
      (l.atompayStApproved, doneTo >= 1 ? l.atompayApproved : ''),
      (
        l.atompayStSeller,
        seller == null
            ? ''
            : [
                seller.name,
                if (seller.place.isNotEmpty) seller.place,
              ].join(' · '),
      ),
      (
        l.atompayHandOver,
        d.handedAt != null ? whenHistory(d.handedAt!) : l.atompayYourStep,
      ),
      (l.atompayStDone, paid ? l.ordersPaidInFull : l.atompaySellerPaysYou),
    ];

    final lastPay = d.payments.firstOrNull;
    final history = <(DateTime, String)>[
      for (final e in d.history)
        if (e.at != null) (e.at!, atompayEventText(e, l, me: me)),
      for (final p in d.payments)
        if (p.paidOn != null)
          (
            p.paidOn!,
            l.atompayEvPaid(
              seller?.name ?? l.atompayTheSellerCap,
              formatRs(p.amount),
              p.methodName(l).toLowerCase(),
            ),
          ),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    if (!d.history.any((e) => e.stage == OrderStage.pending) &&
        o.createdAt != null) {
      history.add((o.createdAt!, l.ordersPlacedOnline));
    }

    const gap = SizedBox(height: 12);
    final body = <Widget>[
      if (d.fromCopy)
        AtomNote(kind: AtomNoteKind.info, message: l.atompayFromCopy),
      AtomNote(kind: noteKind, message: noteText),
      if (next != null)
        NextStepCard(
          eyebrow: l.atompayYourStepEyebrow,
          title: next.$1,
          body: next.$2,
          button: next.$3,
          saving: _saving,
          onPressed: next.$4,
        ),
      if (d.step != AtompayStep.cancelled)
        OrderCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          children: [
            CardTitle(l.atompaySteps),
            const SizedBox(height: 8),
            for (var i = 0; i < stepNames.length; i++)
              StepRow(
                name: stepNames[i].$1,
                sub: i <= doneTo + 1 ? stepNames[i].$2 : '',
                done: i <= doneTo,
                now: i == doneTo + 1,
                rail: i < stepNames.length - 1,
              ),
          ],
        ),
      LinesCard(
        title: l.ordersWhatOrdered,
        lines: [
          OrderLine(
            label: '${o.productLine} × ${o.quantity}',
            value: formatRs(o.cashPrice),
          ),
        ],
      ),
      LinesCard(
        title: l.atompayPaymentToYou,
        lines: [
          OrderLine(label: l.ordersCashPrice, value: formatRs(o.cashPrice)),
          OrderLine(
            label: l.ordersPaidBy,
            value: lastPay == null
                ? '-'
                : [
                    lastPay.methodName(l),
                    if (lastPay.paidOn != null)
                      AtomDates.short(lastPay.paidOn!),
                  ].join(' · '),
          ),
          OrderLine(label: l.ordersPaidSoFar, value: formatRs(o.paid)),
          OrderLine(
            label: l.ordersLeftToReceive,
            value: formatRs(o.balance),
            bold: true,
          ),
        ],
      ),
      if (seller != null)
        LinesCard(
          title: l.atompaySeller,
          trailing: AtomPill(label: l.ordersVerified, tone: AtomTone.green),
          lines: [
            OrderLine(
              label: l.atompayShop,
              value: [seller.name, ?seller.code].join(' · '),
            ),
            if (seller.place.isNotEmpty)
              OrderLine(label: l.atompayArea, value: seller.place),
            if (seller.contact case final c? when c.isNotEmpty)
              OrderLine(label: l.atompayContact, value: c),
            if (seller.phone case final p? when p.isNotEmpty)
              OrderLine(label: l.ordersPhone, value: p),
            if (seller.address case final a? when a.isNotEmpty)
              OrderLine(label: l.ordersAddress, value: a),
          ],
          footer: [
            if (seller.phone case final p? when p.isNotEmpty)
              CallWhatsApp(phone: p),
          ],
        ),
      if (d.customerName != null)
        LinesCard(
          title: l.ordersCustomer,
          lines: [
            OrderLine(label: l.ordersName, value: d.customerName!),
            if ([?d.customerArea, ?d.customerCity].isNotEmpty)
              OrderLine(
                label: l.ordersCity,
                value: [?d.customerArea, ?d.customerCity].join(', '),
              ),
          ],
        ),
      LinesCard(
        title: l.atompayHandOverCard,
        lines: [
          if (multi && o.outlet != null)
            OrderLine(label: l.ordersOutlet, value: o.outlet!.name),
          OrderLine(
            label: l.atompayHandedOver,
            value: d.handedAt == null
                ? l.atompayNotYet
                : whenHistory(d.handedAt!),
          ),
          if (d.serial case final s? when s.isNotEmpty)
            OrderLine(label: l.ordersSerial, value: s)
          else if (d.handedAt == null)
            OrderLine(
              label: l.atompayHandTo,
              value: seller?.name ?? l.atompaySellerNotGiven,
            ),
        ],
      ),
      HistoryCard(events: [for (final (t, s) in history) (whenHistory(t), s)]),
    ];

    return RefreshIndicator(
      onRefresh: () => ref.refresh(atompayDetailProvider(d.uuid).future),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          OrderNavyTop(
            number: l.atompayOrderNumber(o.number),
            pill: NavyPill(label: o.stepName(l), tone: atompayTone(d.step)),
            title: o.productTitle,
            subtitle: [
              if (o.createdAt != null)
                l.atompayPlacedOn(AtomDates.short(o.createdAt!)),
              if (multi && o.outlet != null) o.outlet!.name,
            ].join(' · '),
            showBack: !widget.embedded,
            actions: [
              if (paid && cashCalls)
                Transform.translate(
                  offset: const Offset(16, 0),
                  child: AtomIconButton(
                    icon: LucideIcons.receipt,
                    label: l.ordersReceipt,
                    color: Colors.white,
                    onTap: () => context.push(V2Routes.orderReceiptOf(d.uuid)),
                  ),
                ),
            ],
            figures: NavyFigures(
              figures: [
                NavyFigure(
                  label: l.ordersCashPrice,
                  value: formatRs(o.cashPrice),
                ),
                NavyFigure(
                  label: l.atompaySellerPaysYou,
                  value: formatRs(o.balance),
                  note: paid
                      ? l.ordersPaidInFull
                      : seller?.name ?? l.atompayOnceSeller,
                ),
                NavyFigure(
                  label: l.atompayCustomerPays,
                  value: d.monthly > 0
                      ? l.atompayMonthly(d.months, formatRs(d.monthly))
                      : l.atompayMonths(d.months),
                  note: l.atompayNoMarkup,
                ),
              ],
            ),
          ),
          const OfflineBar(),
          AtomReadableWidth(
            maxWidth: 720,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < body.length; i++) ...[
                    if (i > 0) gap,
                    body[i],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
