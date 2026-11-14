import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/money.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../sync/data/offline_saves.dart';
import '../../sync/ui/saved_here_sheet.dart';
import '../data/order_rules.dart';
import '../data/orders_models.dart';
import '../data/orders_providers.dart';
import '../data/orders_repository.dart';
import 'order_parts.dart';

/// Cancel this order (6.5) and Move to another outlet (6.6): sheets over
/// the order page. Their routes open the same forms as a page, for a link.

/// "#48224 · Faisal Qureshi · Zenvo Refrigerator 14 cft · Rs 112,500".
String _orderLine(CashOrderDetail o, {bool price = true}) => [
  o.order.number,
  ?(o.customer?.name ?? o.order.customerName),
  o.order.productTitle,
  if (price) formatRs(o.order.total),
].join(' · ');

Future<void> showCancelSheet(BuildContext context, CashOrderDetail o) =>
    showAtomSheet<void>(context, builder: (_) => CancelOrderForm(order: o));

Future<void> showMoveSheet(BuildContext context, CashOrderDetail o) =>
    showAtomSheet<void>(context, builder: (_) => MoveOrderForm(order: o));

/// The form's heading inside a sheet or a page.
class _Heading extends StatelessWidget {
  const _Heading({required this.title, required this.line});
  final String title;
  final String line;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(header: true, child: Text(title, style: AtomText.heading)),
      const SizedBox(height: 4),
      Text(line, style: AtomText.small),
    ],
  );
}

/// Cancel this order (6.5): the reasons (any of them), a note the customer
/// doesn't see, and what cancelling does.
class CancelOrderForm extends ConsumerStatefulWidget {
  const CancelOrderForm({super.key, required this.order});
  final CashOrderDetail order;

  @override
  ConsumerState<CancelOrderForm> createState() => _CancelOrderFormState();
}

class _CancelOrderFormState extends ConsumerState<CancelOrderForm> {
  final _picked = <String>{};
  final _note = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final o = widget.order;
    final l = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    final r = await ref
        .read(ordersRepositoryProvider)
        .cancel(
          o.uuid,
          seen: o.stage,
          reasons: [
            for (final k in cancelReasons(l).keys)
              if (_picked.contains(k)) k,
          ],
          note: _note.text,
        );
    if (!mounted) return;
    switch (r) {
      case SavedOnServer():
        refreshOrder(ref, o.uuid);
        Navigator.of(context).pop();
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: l.ordersCancelledToast,
        );
      case SavedHere():
        refreshOrder(ref, o.uuid);
        Navigator.of(context).pop();
        showSavedHereToast(context);
      case SaveFailed(:final failure):
        setState(() {
          _saving = false;
          _error = sayOrderFailure(failure, l);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final o = widget.order;
    final inventory = ref.watch(accessProvider).has(Addon.inventory);
    final ready = _picked.isNotEmpty;
    return AtomUnsavedGuard(
      dirty: !_saving && (_picked.isNotEmpty || _note.text.isNotEmpty),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Heading(title: l.ordersCancelTitle, line: _orderLine(o)),
            const SizedBox(height: 16),
            FieldLabel(l.ordersCancelWhy),
            OrderCard(
              divided: true,
              children: [
                for (final e in cancelReasons(l).entries)
                  AtomPressable(
                    onTap: () => setState(
                      () => _picked.contains(e.key)
                          ? _picked.remove(e.key)
                          : _picked.add(e.key),
                    ),
                    toggled: _picked.contains(e.key),
                    scaleOnPress: false,
                    focusRadius: BorderRadius.zero,
                    semanticLabel: e.value,
                    builder: (_, pressed) => Container(
                      color: pressed ? AtomColors.head : AtomColors.paper,
                      constraints: const BoxConstraints(
                        minHeight: AtomSize.optionRow,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          AtomCheckbox(on: _picked.contains(e.key)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              e.value,
                              style: AtomText.body.copyWith(
                                color: AtomColors.ink,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            AtomTextField(
              label: l.ordersCancelNote,
              controller: _note,
              minLines: 3,
              placeholder: l.ordersCancelNoteHint,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            AtomNote(
              kind: AtomNoteKind.warning,
              compact: true,
              message: inventory ? l.ordersCancelWarnHeld : l.ordersCancelWarn,
              bold: [l.ordersCancelWarnBold],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              AtomNote(kind: AtomNoteKind.problem, message: _error!),
            ],
            const SizedBox(height: 16),
            AtomButtonPair(
              first: AtomButton(
                label: l.ordersKeepOrder,
                kind: AtomButtonKind.outline,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              second: AtomButton(
                label: ready ? l.ordersCancelOrder : l.ordersPickReason,
                kind: AtomButtonKind.danger,
                saving: _saving,
                onPressed: ready ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Move to another outlet (6.6, the owner): the brand's open outlets, the
/// one it is at greyed out.
class MoveOrderForm extends ConsumerStatefulWidget {
  const MoveOrderForm({super.key, required this.order});
  final CashOrderDetail order;

  @override
  ConsumerState<MoveOrderForm> createState() => _MoveOrderFormState();
}

class _MoveOrderFormState extends ConsumerState<MoveOrderForm> {
  int? _picked;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final o = widget.order;
    setState(() {
      _saving = true;
      _error = null;
    });
    final r = await ref.read(ordersRepositoryProvider).move(o.uuid, _picked!);
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    switch (r) {
      case ApiOk():
        refreshOrder(ref, o.uuid);
        Navigator.of(context).pop();
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: l.ordersMovedToast,
        );
      case ApiErr(:final failure):
        setState(() {
          _saving = false;
          _error =
              failure.fieldErrors['outlet_id'] ?? sayOrderFailure(failure, l);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final o = widget.order;
    final inventory = ref.watch(accessProvider).has(Addon.inventory);
    final outlets = [
      for (final x
          in ref.watch(sessionProvider.notifier).current?.outlets ??
              const <Outlet>[])
        if (x.active) x,
    ];
    final now = o.order.outlet?.id;
    final nowName = o.order.outlet?.name;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Heading(
            title: l.ordersMoveTitle,
            line: [
              o.order.number,
              o.order.productTitle,
              if (nowName != null) l.ordersNowAt(nowName),
            ].join(' · '),
          ),
          const SizedBox(height: 16),
          OrderCard(
            divided: true,
            children: [
              for (final x in outlets)
                AtomPressable(
                  onTap: x.id == now
                      ? null
                      : () => setState(() => _picked = x.id),
                  selected: _picked == x.id,
                  scaleOnPress: false,
                  focusRadius: BorderRadius.zero,
                  semanticLabel: x.id == now
                      ? l.ordersWhereNowSem(x.name)
                      : x.name,
                  builder: (_, pressed) => Opacity(
                    opacity: x.id == now ? .6 : 1,
                    child: Container(
                      color: _picked == x.id
                          ? AtomColors.primarySoft
                          : pressed
                          ? AtomColors.head
                          : AtomColors.paper,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const AtomIconTile(
                            icon: LucideIcons.store,
                            tone: AtomTone.grey,
                            size: 36,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(x.name, style: AtomText.listTitle),
                                Text(
                                  [
                                    ?x.city,
                                    if (x.id == now) l.ordersWhereNow,
                                  ].join(' · '),
                                  style: AtomText.secondary,
                                ),
                              ],
                            ),
                          ),
                          if (x.id != now) AtomRadio(on: _picked == x.id),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          AtomNote(
            kind: AtomNoteKind.info,
            compact: true,
            message: inventory ? l.ordersMoveNoteHeld : l.ordersMoveNote,
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            AtomNote(kind: AtomNoteKind.problem, message: _error!),
          ],
          const SizedBox(height: 16),
          AtomButtonPair(
            first: AtomButton(
              label: l.commonCancel,
              kind: AtomButtonKind.outline,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            second: AtomButton(
              label: l.ordersMoveOrder,
              saving: _saving,
              onPressed: _picked == null ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}

/// The routes' page for the two forms (a link to `/order/:uuid/cancel` or
/// `/move`): the order is read, then the form shows on a plain page.
class OrderSheetPage extends ConsumerWidget {
  const OrderSheetPage({super.key, required this.uuid, required this.move});

  final String uuid;
  final bool move;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final order = ref.watch(orderDetailProvider(uuid));
    return Scaffold(
      backgroundColor: AtomColors.paper,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AtomFlowBar(leading: AtomFlowLeading.close),
          Expanded(
            child: order.when(
              loading: () => const Center(child: AtomSpinner(size: 28)),
              error: (e, _) => AtomErrorState(
                message: e is ApiFailure ? sayOrderFailure(e, l) : null,
                onRetry: () => ref.invalidate(orderDetailProvider(uuid)),
              ),
              data: (o) {
                final s = ref.read(sessionProvider.notifier).current;
                final writes = !ref.read(accessProvider).account.blocksWrites;
                final open =
                    writes &&
                    (move
                        ? canMoveOrder(
                            o.stage,
                            isOwner: s?.who.isOwner ?? false,
                            multiOutlet: s?.multiOutlet ?? false,
                          )
                        : (s?.who.can(BrandPermission.ordersCancel) ?? false) &&
                              canCancelOrder(o.stage, o.nextStatuses));
                if (!open) {
                  return AtomMessageState(
                    icon: LucideIcons.listChecks,
                    title: move ? l.ordersCantMove : l.ordersCantCancel,
                    body: l.ordersItIsNow(o.order.stageName(l).toLowerCase()),
                    actionLabel: l.commonBack,
                    onAction: () => Navigator.of(context).maybePop(),
                  );
                }
                return SingleChildScrollView(
                  child: AtomReadableWidth(
                    child: move
                        ? MoveOrderForm(order: o)
                        : CancelOrderForm(order: o),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
