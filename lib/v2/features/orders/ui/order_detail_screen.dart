import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../atompay/ui/atompay_detail_screen.dart' show AtompayView;
import '../../sync/data/offline_saves.dart';
import '../../sync/ui/offline_bar.dart';
import '../../sync/ui/saved_here_sheet.dart';
import '../data/order_rules.dart';
import '../data/order_texts.dart';
import '../data/orders_models.dart';
import '../data/orders_providers.dart';
import '../data/orders_repository.dart';
import 'order_parts.dart';
import 'order_sheets.dart';

/// The cash order page (6.2, 6b): the deal, the next step, where it is,
/// what was ordered, payments, history, the customer, delivery, and what
/// else can be done.
class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key, required this.uuid});
  final String uuid;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AtomColors.surface,
    body: OrderView(uuid: uuid),
  );
}

/// The body of the order page; [embedded] beside the list on a tablet
/// (14.2), with no Back.
class OrderView extends ConsumerWidget {
  const OrderView({super.key, required this.uuid, this.embedded = false});

  final String uuid;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final order = ref.watch(orderDetailProvider(uuid));
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
            : AtomErrorState(
                message: e is ApiFailure ? sayOrderFailure(e, l) : null,
                onRetry: () => ref.invalidate(orderDetailProvider(uuid)),
              ),
      ),
      // An AtomPay order opened by its cash link (a push, a search) shows
      // its own page.
      data: (o) => o.order.isAtompay
          ? AtompayView(uuid: uuid, embedded: embedded)
          : _OrderBody(order: o, embedded: embedded),
    );
  }
}

class _OrderBody extends ConsumerStatefulWidget {
  const _OrderBody({required this.order, required this.embedded});
  final CashOrderDetail order;
  final bool embedded;

  @override
  ConsumerState<_OrderBody> createState() => _OrderBodyState();
}

class _OrderBodyState extends ConsumerState<_OrderBody> {
  bool _saving = false;

  Future<void> _move(CashOrderDetail o, OrderStage to) async {
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    final r = await ref
        .read(ordersRepositoryProvider)
        .setStatus(o.uuid, to: to, seen: o.stage);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (r) {
      case SavedOnServer():
        refreshOrder(ref, o.uuid);
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: l.ordersNowStage(to.label(l)),
        );
      case SavedHere():
        refreshOrder(ref, o.uuid);
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
    final o = widget.order;
    final c = o.order;
    final session = ref.watch(sessionProvider.notifier).current;
    final who = session?.who;
    final access = ref.watch(accessProvider);
    final inventory = access.has(Addon.inventory);
    final writes = !access.account.blocksWrites && !o.locked;
    final canStatus =
        writes && (who?.can(BrandPermission.ordersStatus) ?? false);
    final canPay = writes && (who?.can(BrandPermission.ordersPayment) ?? false);
    final canCancel =
        writes &&
        (who?.can(BrandPermission.ordersCancel) ?? false) &&
        canCancelOrder(o.stage, o.nextStatuses);
    final multi = session?.multiOutlet ?? false;
    final canMove =
        writes &&
        canMoveOrder(
          o.stage,
          isOwner: who?.isOwner ?? false,
          multiOutlet: multi,
        ) &&
        !o.fromCopy;
    final me = session?.name;
    final cancelled = o.stage == OrderStage.cancelled;
    final completed = o.stage == OrderStage.completed;
    final hasReceipt = c.paid > 0 && !o.fromCopy;

    final next = nextStepFor(
      o.stage,
      balance: c.balance,
      moves: o.nextStatuses,
    );
    final nextAllowed = switch (next) {
      null => false,
      NextStep.recordPayment => canPay,
      _ => canStatus,
    };

    final subtitle = [
      l.ordersFor(o.customer?.name ?? c.customerName ?? l.ordersTheCustomer),
      if (c.createdAt != null) l.ordersPlacedOn(AtomDates.short(c.createdAt!)),
      if (multi && c.outlet != null) c.outlet!.name,
    ].join(' · ');

    final top = OrderNavyTop(
      number: l.ordersCashOrderNumber(c.number),
      pill: NavyPill(label: c.stageName(l), tone: stageTone(o.stage)),
      title: c.productTitle,
      subtitle: subtitle,
      showBack: !widget.embedded,
      actions: [
        if (hasReceipt)
          Transform.translate(
            offset: const Offset(16, 0),
            child: AtomIconButton(
              icon: LucideIcons.receipt,
              label: l.ordersReceipt,
              color: Colors.white,
              onTap: () => context.push(V2Routes.orderReceiptOf(o.uuid)),
            ),
          ),
      ],
      figures: NavyFigures(
        figures: [
          NavyFigure(label: l.ordersOrderValue, value: formatRs(c.total)),
          NavyFigure(
            label: l.ordersPayPaid,
            value: formatRs(c.paid),
            progress: c.total <= 0 ? 0 : c.paid / c.total,
          ),
          NavyFigure(
            label: l.ordersToCollect,
            value: cancelled ? 'Rs 0' : formatRs(c.balance),
            note: cancelled
                ? l.ordersPayNotNeeded
                : c.balance == 0
                ? l.ordersPaidInFull
                : l.ordersLeftToPay,
          ),
        ],
      ),
    );

    final cancelEvent = cancelled ? o.eventFor(OrderStage.cancelled) : null;
    const gap = SizedBox(height: 12);

    final body = <Widget>[
      if (o.fromCopy)
        AtomNote(kind: AtomNoteKind.info, message: l.ordersFromCopy),
      if (o.locked && o.lockedReason != null && !cancelled && !completed)
        AtomNote(kind: AtomNoteKind.info, message: o.lockedReason!),
      if (cancelled)
        AtomNote(
          kind: AtomNoteKind.problem,
          title: cancelEvent?.at == null
              ? l.ordersCancelledDot
              : l.ordersCancelledOn(AtomDates.short(cancelEvent!.at!)),
          message: [
            if (cancelEvent != null) ?cancelWhy(cancelEvent),
            if (c.paid == 0) l.ordersNoRefund,
          ].join(' '),
        ),
      if (completed)
        AtomNote(
          kind: AtomNoteKind.success,
          title: l.ordersCompletedDot,
          message: hasReceipt
              ? l.ordersCompletedReceipt
              : l.ordersCompletedBody,
        ),
      if (next != null && nextAllowed)
        _NextCard(
          order: o,
          step: next,
          inventory: inventory,
          saving: _saving,
          canStatus: canStatus,
          onMove: (to) => _move(o, to),
        ),
      if (!cancelled) _StatusCard(order: o, inventory: inventory, me: me),
      _OrderedCard(order: o),
      _PaymentCard(order: o, canPay: canPay, me: me),
      HistoryCard(
        events: historyLines(o, l, me: me, inventory: inventory),
      ),
      if (o.customer != null) _CustomerCard(customer: o.customer!),
      _DeliveryCard(order: o, multi: multi),
      if (o.alsoBought.isNotEmpty)
        LinesCard(
          title: l.ordersAlsoBought,
          lines: [
            for (final a in o.alsoBought.take(5))
              OrderLine(
                label: [
                  a.productTitle,
                  a.number,
                  if (a.createdAt != null) AtomDates.monthYear(a.createdAt!),
                ].join(' · '),
                value: formatRs(a.total),
              ),
          ],
        ),
      if (canMove || hasReceipt || canCancel)
        OrderCard(
          divided: true,
          children: [
            if (canMove)
              MoreRow(
                icon: LucideIcons.store,
                label: l.ordersMoveTitle,
                onTap: () => showMoveSheet(context, o),
              ),
            if (hasReceipt)
              MoreRow(
                icon: LucideIcons.receipt,
                label: l.ordersReceipt,
                onTap: () => context.push(V2Routes.orderReceiptOf(o.uuid)),
              ),
            if (canCancel)
              MoreRow(
                icon: LucideIcons.circleX,
                label: l.commonCancel,
                danger: true,
                onTap: () => showCancelSheet(context, o),
              ),
          ],
        ),
    ];

    return RefreshIndicator(
      onRefresh: () => ref.refresh(orderDetailProvider(o.uuid).future),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          top,
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

class _NextCard extends StatelessWidget {
  const _NextCard({
    required this.order,
    required this.step,
    required this.inventory,
    required this.saving,
    required this.canStatus,
    required this.onMove,
  });

  final CashOrderDetail order;
  final NextStep step;
  final bool inventory;
  final bool saving;
  final bool canStatus;
  final ValueChanged<OrderStage> onMove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final o = order;
    final (title, body, button) = nextStepWords(
      step,
      o,
      l,
      inventory: inventory,
    );
    final to = moveOf(step);
    return NextStepCard(
      title: title,
      body: body,
      button: button,
      saving: saving,
      onPressed: switch (step) {
        NextStep.deliver => () => context.push(V2Routes.orderDeliverOf(o.uuid)),
        NextStep.recordPayment => () => context.push(
          V2Routes.orderPaymentOf(o.uuid),
        ),
        _ => () => onMove(to!),
      },
      extra: step == NextStep.recordPayment && canStatus
          ? AtomButton(
              label: l.ordersCompleteStillToPay(formatRs(o.order.balance)),
              kind: AtomButtonKind.outline,
              compact: true,
              onPressed: null,
            )
          : null,
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.order,
    required this.inventory,
    required this.me,
  });

  final CashOrderDetail order;
  final bool inventory;
  final String? me;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final o = order;
    final steps = OrderStage.steps;
    final at = steps.indexOf(o.stage);
    return OrderCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      children: [
        CardTitle(
          l.ordersStatus,
          trailing: Text(
            l.ordersTapStep,
            style: AtomText.small.copyWith(color: AtomColors.faint),
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < steps.length; i++)
          StepRow(
            name: stepName(steps[i], l),
            sub: stepSub(steps[i], o, l, inventory: inventory, me: me),
            done: i <= at,
            now: i == at + 1,
            rail: i < steps.length - 1,
            onTap: () => _preview(context, steps[i]),
          ),
      ],
    );
  }

  void _preview(BuildContext context, OrderStage s) {
    final l = AppLocalizations.of(context);
    final o = order;
    final sub = stepSub(s, o, l, inventory: inventory, me: me);
    final step = switch (s) {
      OrderStage.confirming => NextStep.startConfirming,
      OrderStage.processing => NextStep.confirm,
      OrderStage.delivered => NextStep.deliver,
      OrderStage.completed => NextStep.complete,
      _ => null,
    };
    final words = step == null
        ? null
        : nextStepWords(step, o, l, inventory: inventory);
    showAtomSheet<void>(
      context,
      builder: (_) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AtomSheetHeader(title: stepName(s, l)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sub.isNotEmpty) ...[
                    Text(sub, style: AtomText.secondary),
                    const SizedBox(height: 12),
                  ],
                  if (words != null) ...[
                    Text(words.$1, style: AtomText.listTitle),
                    const SizedBox(height: 4),
                    Text(
                      words.$2,
                      style: AtomText.body.copyWith(color: AtomColors.text),
                    ),
                  ] else
                    Text(
                      l.ordersArrived,
                      style: AtomText.body.copyWith(color: AtomColors.text),
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

class _OrderedCard extends StatelessWidget {
  const _OrderedCard({required this.order});
  final CashOrderDetail order;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = order.order;
    return LinesCard(
      title: l.ordersWhatOrdered,
      lines: [
        OrderLine(
          label: [
            c.productTitle,
            if (c.variant case final v? when v.isNotEmpty) v,
            '${c.quantity}',
          ].join(' · '),
          value: formatRs(c.total),
        ),
        OrderLine(label: l.ordersTotal, value: formatRs(c.total), bold: true),
        if (order.serial case final s?)
          OrderLine(label: l.ordersSerial, value: s),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.order,
    required this.canPay,
    required this.me,
  });

  final CashOrderDetail order;
  final bool canPay;
  final String? me;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final o = order;
    final c = o.order;
    final showPay = canPay && !o.stage.isFinal && c.balance > 0;
    return LinesCard(
      title: l.ordersPayment,
      trailing: StageTag(label: c.payState.label(l), tone: payTone(c.payState)),
      lines: [
        OrderLine(label: l.ordersDue, value: formatRs(c.total)),
        OrderLine(label: l.ordersPaidSoFar, value: formatRs(c.paid)),
        OrderLine(
          label: l.ordersLeftToPay,
          value: o.stage == OrderStage.cancelled ? 'Rs 0' : formatRs(c.balance),
        ),
        for (final p in o.payments)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                const AtomIconTile(
                  icon: LucideIcons.banknote,
                  tone: AtomTone.green,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formatRs(p.amount), style: AtomText.money),
                      Text(
                        paymentLine(p, l, me: me),
                        style: AtomText.secondary,
                      ),
                    ],
                  ),
                ),
                if (p.receipt case final url?)
                  AtomButton.small(
                    label: l.ordersReceiptPhoto,
                    onPressed: () => _showPhoto(context, url),
                  ),
              ],
            ),
          ),
      ],
      footer: [
        if (showPay)
          AtomButton(
            label: l.ordersRecordPayment,
            kind: AtomButtonKind.outline,
            compact: true,
            onPressed: () => context.push(V2Routes.orderPaymentOf(o.uuid)),
          ),
      ],
    );
  }
}

/// A receipt or proof photo, full width in a sheet.
void _showPhoto(BuildContext context, String url) => showAtomSheet<void>(
  context,
  builder: (_) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
    child: ClipRRect(
      borderRadius: AtomRadius.brCard,
      child: AtomPhoto(url, fit: BoxFit.contain),
    ),
  ),
);

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer});
  final OrderCustomer customer;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = customer;
    return LinesCard(
      title: l.ordersCustomer,
      trailing: c.verified
          ? AtomPill(label: l.ordersVerified, tone: AtomTone.green)
          : null,
      lines: [
        OrderLine(label: l.ordersName, value: c.name),
        if (c.since != null)
          OrderLine(
            label: l.ordersCustomerSince,
            value: AtomDates.monthYear(c.since!),
          ),
        if (c.phone case final p? when p.isNotEmpty)
          OrderLine(label: l.ordersPhone, value: p),
        if (c.email case final e? when e.isNotEmpty)
          OrderLine(label: l.ordersEmail, value: e),
      ],
      footer: [
        if (c.phone case final p? when p.isNotEmpty) CallWhatsApp(phone: p),
      ],
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.order, required this.multi});
  final CashOrderDetail order;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = order.customer;
    final address = [
      if (c?.address case final a? when a.isNotEmpty) a,
      if (c?.area case final a? when a.isNotEmpty) a,
    ].join(', ');
    final city = c?.city ?? order.order.city;
    final lines = [
      if (address.isNotEmpty) OrderLine(label: l.ordersAddress, value: address),
      if (city != null && city.isNotEmpty)
        OrderLine(label: l.ordersCity, value: city),
      if (multi && order.order.outlet != null)
        OrderLine(label: l.ordersOutlet, value: order.order.outlet!.name),
    ];
    if (lines.isEmpty) return const SizedBox.shrink();
    return LinesCard(title: l.ordersDelivery, lines: lines);
  }
}
