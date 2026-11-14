import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../atompay/data/atompay_repository.dart';
import '../../sync/data/offline_saves.dart';
import '../../sync/ui/saved_here_sheet.dart';
import '../data/order_rules.dart';
import '../data/orders_models.dart';
import '../data/orders_providers.dart';
import '../data/orders_repository.dart';
import 'order_gate.dart';
import 'order_parts.dart';

/// Record a payment (6.4): a customer's on a cash order, or the seller's
/// on a handed-over AtomPay order ("Record seller's payment"). How much
/// (all, half or typed), how they paid, the day (never the future), a
/// reference and a photo of the receipt.
class OrderPaymentScreen extends StatelessWidget {
  const OrderPaymentScreen({super.key, required this.uuid});
  final String uuid;

  @override
  Widget build(BuildContext context) => OrderStepGate(
    uuid: uuid,
    notOpenTitle: AppLocalizations.of(context).ordersNothingToRecord,
    fits: (o) =>
        o.order.balance > 0 &&
        o.stage != OrderStage.cancelled &&
        (o.order.isAtompay || o.stage != OrderStage.completed),
    builder: (o) => _PaymentForm(order: o),
  );
}

class _PaymentForm extends ConsumerStatefulWidget {
  const _PaymentForm({required this.order});
  final CashOrderDetail order;

  @override
  ConsumerState<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends ConsumerState<_PaymentForm> {
  late final _amount = TextEditingController(
    text: groupDigits(widget.order.order.balance),
  );
  final _reference = TextEditingController();
  String? _method;
  late DateTime _day = AtomDates.now();
  File? _receipt;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  void _setAmount(int n) => setState(() {
    _amount.text = groupDigits(n);
    _amount.selection = TextSelection.collapsed(offset: _amount.text.length);
  });

  Future<void> _pickDay() async {
    final d = await showPastDaySheet(
      context,
      selected: _day,
      today: AtomDates.now(),
      title: AppLocalizations.of(context).ordersPaymentDate,
    );
    if (d != null && mounted) setState(() => _day = d);
  }

  Future<void> _save(int amount) async {
    final o = widget.order;
    setState(() {
      _saving = true;
      _error = null;
    });
    final r = await ref
        .read(ordersRepositoryProvider)
        .pay(
          o.uuid,
          amount: amount,
          method: _method!,
          paidOn: _day,
          seenPaid: o.order.paid,
          reference: _reference.text,
          receipt: _receipt,
        );
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    void refresh() {
      refreshOrder(ref, o.uuid);
      if (o.order.isAtompay) refreshAtompay(ref, o.uuid);
    }

    switch (r) {
      case SavedOnServer():
        refresh();
        Navigator.of(context).pop();
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: l.ordersPaymentSaved(formatRs(amount)),
        );
      case SavedHere():
        refresh();
        Navigator.of(context).pop();
        showSavedHere(
          context,
          what: l.ordersPaymentSavedHere(formatRs(amount)),
          waitingFor: l.ordersTheReceipt,
        );
      case SaveFailed(:final failure):
        setState(() {
          _saving = false;
          _error =
              failure.fieldErrors['amount'] ??
              failure.fieldErrors['method'] ??
              failure.fieldErrors['paid_on'] ??
              sayOrderFailure(failure, l);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final o = widget.order;
    final c = o.order;
    final ap = c.isAtompay;
    final seller = ap
        ? ref.watch(atompayDetailProvider(o.uuid)).value?.seller?.name
        : null;
    final left = c.balance;
    final amount = parseRupees(_amount.text);
    final problem = paymentAmountProblem(amount, left, l);
    final methods = offeredMethods(o.paymentMethods);
    final today = AtomDates.daysFrom(_day, today: AtomDates.now()) == 0;
    final half = halfOf(left);

    Widget quick(String label, int value) {
      final on = amount == value;
      return Expanded(
        child: AtomPressable(
          onTap: () => _setAmount(value),
          selected: on,
          semanticLabel: label,
          builder: (_, pressed) => Container(
            constraints: const BoxConstraints(minHeight: 40),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: on
                  ? AtomColors.primarySoft
                  : pressed
                  ? AtomColors.surface
                  : AtomColors.paper,
              borderRadius: AtomRadius.brPill,
              border: Border.all(
                color: on ? AtomColors.primary : AtomColors.line2,
                width: on ? 2 : 1,
              ),
            ),
            child: Text(
              label,
              style: AtomText.smallButton.copyWith(
                color: on ? AtomColors.primary : AtomColors.text,
              ),
            ),
          ),
        ),
      );
    }

    final saveReason =
        problem ?? (_method == null ? l.ordersPickHowPaid : null);

    return AtomUnsavedGuard(
      dirty: !_saving && (_receipt != null || _reference.text.isNotEmpty),
      child: OrderFormPage(
        title: ap ? l.ordersRecordSellerPayment : l.ordersRecordAPayment,
        subtitle: ap
            ? [l.ordersAtompayNumber('${c.id}'), ?seller].join(' · ')
            : [
                c.number,
                ?(o.customer?.name ?? c.customerName),
                c.productTitle,
              ].join(' · '),
        body: [
          OrderCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            divided: true,
            children: [
              OrderLine(
                label: ap ? l.ordersCashPrice : l.ordersDue,
                value: formatRs(c.total),
              ),
              OrderLine(label: l.ordersPaidSoFar, value: formatRs(c.paid)),
              OrderLine(
                label: ap ? l.ordersLeftToReceive : l.ordersLeftToPay,
                value: formatRs(left),
                bold: true,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Semantics(
            label: l.ordersAmount,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Rs',
                  style: AtomText.heading.copyWith(color: AtomColors.faint),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [RupeesInputFormatter()],
                    style: AtomText.amountLg.copyWith(color: AtomColors.ink),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '0',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AtomColors.line),
          if (amount > 0) ...[
            const SizedBox(height: 6),
            Text(amountInWords(amount), style: AtomText.small),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              quick(l.ordersAllAmount(formatRs(left)), left),
              if (half > 0 && half < left) ...[
                const SizedBox(width: 8),
                quick(l.ordersHalf, half),
              ],
            ],
          ),
          if (amount > left) ...[
            const SizedBox(height: 8),
            Text(l.ordersPayTooMuch, style: AtomText.fieldError),
          ],
          const SizedBox(height: 18),
          FieldLabel(l.ordersHowPaid),
          ChoiceButtons<String>(
            columns: 3,
            choices: [for (final m in methods) (m, labelOfMethod(m, l))],
            selected: _method,
            onChanged: (v) => setState(() => _method = v),
          ),
          const SizedBox(height: 18),
          AtomField(
            label: l.ordersPaymentDate,
            hint: l.ordersNoFutureDate,
            child: AtomPressable(
              onTap: _pickDay,
              semanticLabel: l.ordersPaymentDateSem(AtomDates.day(_day)),
              builder: (_, _) => Container(
                constraints: const BoxConstraints(minHeight: AtomSize.control),
                padding: const EdgeInsets.symmetric(
                  horizontal: AtomSpace.inset,
                ),
                decoration: atomInputBox(
                  focused: false,
                  error: false,
                  disabled: false,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        today
                            ? l.ordersTodayDay(AtomDates.day(_day))
                            : AtomDates.weekday(_day),
                        style: AtomText.input,
                      ),
                    ),
                    const Icon(
                      LucideIcons.calendar,
                      size: AtomIcon.row,
                      color: AtomColors.faint,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          AtomTextField(
            label: l.ordersReference,
            labelNote: l.ordersOptional,
            labelNoteInline: true,
            controller: _reference,
            placeholder: l.ordersReferenceHint,
            inputFormatters: [LengthLimitingTextInputFormatter(80)],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          FieldLabel(l.ordersReceipt),
          PhotoBox(
            label: l.ordersReceiptPhotoHint,
            done: _receipt != null,
            onTap: () async {
              final f = await takeOrderPhoto();
              if (f != null && mounted) setState(() => _receipt = f);
            },
          ),
        ],
        bottom: [
          if (_error != null) ...[
            AtomNote(kind: AtomNoteKind.problem, message: _error!),
            const SizedBox(height: 10),
          ],
          AtomButton(
            label: saveReason == null
                ? l.ordersSavePayment
                : problem != null
                ? l.ordersEnterUpTo(formatRs(left))
                : saveReason,
            saving: _saving,
            onPressed: saveReason == null ? () => _save(amount) : null,
          ),
        ],
      ),
    );
  }
}
