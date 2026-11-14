import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
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
import 'order_gate.dart';
import 'order_parts.dart';
import 'order_scanner.dart';

/// Mark as delivered (6.3, 6b BasicHandOver): with Inventory, scan the
/// serial of the unit given; without, type it if you like. Who received
/// it, the cash collected at the door and how, and a proof photo.
class MarkDeliveredScreen extends StatelessWidget {
  const MarkDeliveredScreen({super.key, required this.uuid});
  final String uuid;

  @override
  Widget build(BuildContext context) => OrderStepGate(
    uuid: uuid,
    notOpenTitle: AppLocalizations.of(context).ordersDeliverNotOpen,
    fits: (o) =>
        o.stage == OrderStage.processing &&
        o.moves.contains(OrderStage.delivered),
    builder: (o) => _DeliverForm(order: o),
  );
}

class _DeliverForm extends ConsumerStatefulWidget {
  const _DeliverForm({required this.order});
  final CashOrderDetail order;

  @override
  ConsumerState<_DeliverForm> createState() => _DeliverFormState();
}

class _DeliverFormState extends ConsumerState<_DeliverForm> {
  final _serial = TextEditingController();
  final _someone = TextEditingController();
  late final _cod = TextEditingController(
    text: widget.order.order.balance > 0
        ? groupDigits(widget.order.order.balance)
        : '',
  );
  bool _customer = true;
  late String? _method = _defaultMethod();
  File? _photo;
  bool _saving = false;
  String? _error;

  String? _defaultMethod() {
    final m = offeredMethods(widget.order.paymentMethods);
    return m.contains('cod') ? 'cod' : m.firstOrNull;
  }

  @override
  void dispose() {
    _serial.dispose();
    _someone.dispose();
    _cod.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final code = await scanSerial(context);
    if (code == null || !mounted) return;
    setState(() => _serial.text = code);
  }

  Future<void> _save(int cod) async {
    final o = widget.order;
    final name = _customer
        ? (o.customer?.name ?? o.order.customerName ?? 'Customer')
        : _someone.text.trim();
    setState(() {
      _saving = true;
      _error = null;
    });
    final r = await ref
        .read(ordersRepositoryProvider)
        .setStatus(
          o.uuid,
          to: OrderStage.delivered,
          seen: o.stage,
          receivedBy: name,
          serial: _serial.text,
          codAmount: cod,
          codMethod: cod > 0 ? _method : null,
          photo: _photo,
        );
    if (!mounted) return;
    switch (r) {
      case SavedOnServer():
        refreshOrder(ref, o.uuid);
        Navigator.of(context).pop();
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: AppLocalizations.of(context).ordersDeliverySaved,
        );
      case SavedHere():
        refreshOrder(ref, o.uuid);
        Navigator.of(context).pop();
        showSavedHereToast(context);
      case SaveFailed(:final failure):
        setState(() {
          _saving = false;
          _error =
              failure.fieldErrors['serial'] ??
              failure.fieldErrors['cod_amount'] ??
              sayOrderFailure(failure, AppLocalizations.of(context));
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final o = widget.order;
    final c = o.order;
    final inventory = ref.watch(accessProvider).has(Addon.inventory);
    final who = ref.watch(sessionProvider.notifier).current?.who;
    final canPay = who?.can(BrandPermission.ordersPayment) ?? false;
    final left = c.balance;
    final cod = left > 0 && canPay ? parseRupees(_cod.text) : 0;
    final first = o.customer?.firstName ?? c.customerName?.split(' ').first;
    final methods = offeredMethods(o.paymentMethods);
    final serial = _serial.text.trim();
    final problem = deliveryProblem(
      inventory: inventory,
      serial: serial,
      someoneElse: !_customer,
      receiverName: _someone.text,
      cod: cod,
      left: left,
      codMethod: _method,
      l: l,
    );
    const gap = SizedBox(height: 16);

    return AtomUnsavedGuard(
      dirty: !_saving && (_photo != null || serial.isNotEmpty),
      child: OrderFormPage(
        title: l.ordersMarkAsDelivered,
        subtitle: [
          c.number,
          c.productTitle,
          ?(o.customer?.name ?? c.customerName),
        ].join(' · '),
        body: [
          if (inventory) ...[
            ScanTile(
              scanned: serial.isNotEmpty,
              onTap: _scan,
              caption: serial.isNotEmpty
                  ? l.ordersScanReadHeld
                  : l.ordersScanPoint,
            ),
            if (serial.isNotEmpty) ...[
              const SizedBox(height: 10),
              OrderCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                children: [
                  Row(
                    children: [
                      const AtomIconTile(
                        icon: LucideIcons.check,
                        tone: AtomTone.green,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.ordersSerialValue(serial),
                              style: AtomText.listTitle.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            Text(
                              [
                                l.ordersHeldUnit,
                                if (c.outlet != null) c.outlet!.name,
                              ].join(' · '),
                              style: AtomText.secondary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AtomButton.small(
                        label: l.ordersChange,
                        onPressed: () {
                          setState(_serial.clear);
                          _scan();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ] else
            AtomTextField(
              label: l.ordersSerialOptional,
              controller: _serial,
              placeholder: l.ordersTypeFromBox,
              hint: l.ordersSerialHint,
              inputFormatters: [LengthLimitingTextInputFormatter(60)],
              trailing: AtomIconButton(
                icon: LucideIcons.scanLine,
                label: l.ordersScanSerial,
                onTap: _scan,
              ),
              onChanged: (_) => setState(() {}),
            ),
          gap,
          FieldLabel(l.ordersReceivedBy),
          ChoiceButtons<bool>(
            choices: [
              (
                true,
                first == null ? l.ordersCustomer : l.ordersFirstCustomer(first),
              ),
              (false, l.ordersSomeoneElse),
            ],
            selected: _customer,
            onChanged: (v) => setState(() => _customer = v),
          ),
          if (!_customer) ...[
            gap,
            AtomTextField(
              label: l.ordersNameRelation,
              controller: _someone,
              placeholder: l.ordersNameRelationHint,
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
              onChanged: (_) => setState(() {}),
            ),
          ],
          // Cash at the door is a payment: only for someone who may record
          // one, and only while something is left to pay.
          if (left > 0 && canPay) ...[
            gap,
            AtomTextField(
              label: l.ordersCashCollected,
              controller: _cod,
              prefix: const Text('Rs'),
              keyboardType: TextInputType.number,
              inputFormatters: const [RupeesInputFormatter()],
              hint: l.ordersCashCollectedHint(formatRs(left)),
              error: cod > left ? l.ordersPayTooMuch : null,
              onChanged: (_) => setState(() {}),
            ),
            if (cod > 0) ...[
              gap,
              FieldLabel(l.ordersPaidBy),
              ChoiceButtons<String>(
                columns: 2,
                choices: [for (final m in methods) (m, labelOfMethod(m, l))],
                selected: _method,
                onChanged: (v) => setState(() => _method = v),
              ),
            ],
          ],
          gap,
          FieldLabel(l.ordersProof),
          PhotoBox(
            label: l.ordersTakePhoto,
            done: _photo != null,
            onTap: () async {
              final f = await takeOrderPhoto();
              if (f != null && mounted) setState(() => _photo = f);
            },
          ),
        ],
        bottom: [
          if (_error != null) ...[
            AtomNote(kind: AtomNoteKind.problem, message: _error!),
            const SizedBox(height: 10),
          ],
          AtomButton(
            label: problem ?? l.ordersSaveDelivery,
            saving: _saving,
            onPressed: problem == null ? () => _save(cod) : null,
          ),
        ],
      ),
    );
  }
}
