import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/net/network_status.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/billing_models.dart';
import '../data/billing_repository.dart';
import '../data/plan_logic.dart';
import 'account_parts.dart';
import 'plan_screen.dart' show CopyLine;

/// I've paid (12.8, owner): how to pay Atomshop, then the bill, amount,
/// method, day, transaction ID and the screenshot (`POST billing/pay`).
/// [billNumber] is in the address so the bill is found again after Android
/// restarts the app behind the photo picker.
class PayBillScreen extends ConsumerStatefulWidget {
  const PayBillScreen({super.key, this.billNumber});
  final String? billNumber;

  @override
  ConsumerState<PayBillScreen> createState() => _PayBillScreenState();
}

/// "Not for one bill": a payment towards the account.
const _noBill = 0;

class _PayBillScreenState extends ConsumerState<PayBillScreen> {
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  String _method = 'bank';
  DateTime _paidOn = AtomDates.now();
  int? _invoiceId;
  File? _shot;
  bool _filled = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amount.addListener(_changed);
    _reference.addListener(_changed);
    if (Platform.isAndroid) _lostShot();
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _lostShot() async {
    try {
      final lost = await ImagePicker().retrieveLostData();
      final f = lost.file;
      if (f != null && mounted) setState(() => _shot = File(f.path));
    } catch (_) {
      // nothing to bring back
    }
  }

  /// Picks the bill from the address (else the first open one) and its
  /// amount, once.
  void _fill(BillingOverview p) {
    if (_filled) return;
    _filled = true;
    final bill =
        (widget.billNumber == null
            ? null
            : p.invoiceByNumber(widget.billNumber!)) ??
        p.openInvoices.firstOrNull;
    _invoiceId = bill != null && bill.open ? bill.id : _noBill;
    final due = bill != null && bill.open ? bill.due : p.due;
    if (due > 0) _amount.text = groupDigits(due);
    final l = AppLocalizations.of(context);
    final methods = payMethods(l, p.methods);
    if (methods.isNotEmpty && !methods.any((m) => m.key == _method)) {
      _method = methods.first.key;
    }
  }

  Future<void> _pick() async {
    final f = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (f != null && mounted) setState(() => _shot = File(f.path));
  }

  Future<void> _day() async {
    final d = await showPastDaySheet(
      context,
      selected: _paidOn,
      today: AtomDates.now(),
      title: AppLocalizations.of(context).acctPaidOn,
    );
    if (d != null && mounted) setState(() => _paidOn = d);
  }

  Future<void> _send() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    final ref0 = _reference.text.trim();
    final r = await ref
        .read(billingRepositoryProvider)
        .pay(
          amount: parseRupees(_amount.text),
          method: _method,
          paidOn: _paidOn,
          screenshot: _shot!,
          invoiceId: _invoiceId == _noBill ? null : _invoiceId,
          reference: ref0.isEmpty ? null : ref0,
        );
    if (!mounted) return;
    switch (r) {
      case ApiOk():
        ref.invalidate(billingProvider);
        unawaited(ref.read(accessProvider.notifier).refresh());
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: l.acctPaymentSent,
        );
        Navigator.of(context).pop();
      case ApiErr(:final failure):
        setState(() {
          _saving = false;
          _error =
              failure.fieldErrors.values.firstOrNull ?? sayFailure(l, failure);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(billingProvider);
    final online = ref.watch(onlineProvider).value ?? true;
    final p = data.value;
    if (p != null) _fill(p);
    final bill = p?.openInvoices.where((b) => b.id == _invoiceId).firstOrNull;
    return AtomUnsavedGuard(
      dirty: (_shot != null || _reference.text.isNotEmpty) && !_saving,
      child: Scaffold(
        backgroundColor: AtomColors.paper,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AtomFlowBar(
              title: l.acctIvePaid,
              subtitle: bill == null
                  ? null
                  : '${bill.number} · ${billTitle(l, bill)} · ${formatRs(bill.due)}',
            ),
            Expanded(
              child: switch (data) {
                AsyncValue(value: final p?) => _form(p, bill),
                AsyncError(:final error) => AccountError(
                  error: error,
                  onRetry: () => ref.invalidate(billingProvider),
                ),
                _ => const Padding(
                  padding: EdgeInsets.all(16),
                  child: AtomLoadingRows(count: 5),
                ),
              },
            ),
            if (p != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16 + MediaQuery.paddingOf(context).bottom,
                ),
                child: _bottom(online),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bottom(bool online) {
    final l = AppLocalizations.of(context);
    if (!online) {
      return AtomButton(label: l.syncNeedsInternet, onPressed: null);
    }
    final problem = payProblem(
      l,
      amount: parseRupees(_amount.text),
      method: _method,
      paidOn: _paidOn,
      hasScreenshot: _shot != null,
      today: AtomDates.now(),
      reference: _reference.text,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          AtomNote(kind: AtomNoteKind.problem, message: _error!),
          const SizedBox(height: 10),
        ],
        if (problem != null) AtomButtonReason(reason: problem),
        AtomButton(
          label: l.acctSendPayment,
          saving: _saving,
          onPressed: problem == null ? _send : null,
        ),
      ],
    );
  }

  Widget _form(BillingOverview p, Invoice? bill) {
    final l = AppLocalizations.of(context);
    final methods = payMethods(l, p.methods);
    final pe = p.payee;
    final wallet = _method == 'jazzcash' || _method == 'easypaisa';
    final amount = parseRupees(_amount.text);
    final payee = <(String, String)>[
      if (wallet) ...[
        if (pe[_method] case final v?)
          (
            l.acctWalletNumber(
              _method == 'jazzcash' ? l.acctJazzCash : l.acctEasypaisa,
            ),
            v,
          ),
      ] else ...[
        if (pe['bank_name'] case final v?) (l.acctBank, v),
        if (pe['account_title'] case final v?) (l.acctAccountTitle, v),
        if (pe['iban'] case final v?) (l.acctIban, v),
      ],
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        AtomSectionLabel(l.acctHowToPay, page: false),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in methods)
              AtomFilterChip(
                label: m.label,
                active: _method == m.key,
                minHeight: 40,
                onTap: () => setState(() => _method = m.key),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: AtomDecor.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (label, value) in payee)
                CopyLine(label: label, value: value),
              if (payee.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(l.acctAskForAccount, style: AtomText.secondary),
                ),
              AtomInfoLine(
                label: l.acctAmount,
                value: amount > 0 ? formatRs(amount) : '—',
                total: true,
              ),
              if (pe['note'] case final note?)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(note, style: AtomText.small),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AtomSelectField<int>(
          label: l.acctBill,
          value: _invoiceId,
          valueLabel: bill == null
              ? l.acctNotForOneBill
              : '${bill.number} · ${formatRs(bill.due)}',
          sheetTitle: l.acctWhichBill,
          options: [
            for (final b in p.openInvoices)
              AtomOption(
                value: b.id,
                label: '${b.number} · ${formatRs(b.due)}',
                subtitle: billTitle(l, b),
              ),
            AtomOption(value: _noBill, label: l.acctNotForOneBill),
          ],
          onChanged: (id) => setState(() {
            _invoiceId = id;
            final b = p.openInvoices.where((x) => x.id == id).firstOrNull;
            if (b != null && b.due > 0) _amount.text = groupDigits(b.due);
          }),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AtomTextField(
                label: l.acctAmount,
                controller: _amount,
                prefix: Text('Rs ', style: AtomText.input),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  const RupeesInputFormatter(),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DayField(
                label: l.acctPaidOn,
                value: AtomDates.day(_paidOn),
                onTap: _day,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AtomTextField(
          label: l.acctTransactionId,
          labelNote: l.acctOptional,
          controller: _reference,
          placeholder: l.acctTransactionIdHint,
          inputFormatters: [LengthLimitingTextInputFormatter(100)],
        ),
        const SizedBox(height: 12),
        _ShotBox(done: _shot != null, onTap: _pick),
        const SizedBox(height: 12),
        AtomNote(
          kind: AtomNoteKind.info,
          message: l.acctPayCheckedNote,
          bold: [l.acctBeingChecked],
        ),
      ],
    );
  }
}

/// A field that opens the day sheet.
class _DayField extends StatelessWidget {
  const _DayField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(label, style: AtomText.fieldLabel),
        ),
        AtomPressable(
          onTap: onTap,
          scaleOnPress: false,
          semanticLabel: '$label, $value',
          builder: (_, pressed) => Container(
            height: AtomSize.control,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: pressed ? AtomColors.head : AtomColors.paper,
              borderRadius: AtomRadius.brControl,
              border: Border.all(color: AtomColors.line2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: AtomText.input,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  LucideIcons.calendar,
                  size: AtomIcon.inline,
                  color: AtomColors.muted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "Add the payment screenshot" / "Screenshot added · change".
class _ShotBox extends StatelessWidget {
  const _ShotBox({required this.done, required this.onTap});
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = done ? AtomColors.noteGreenText : AtomColors.text;
    final l = AppLocalizations.of(context);
    final label = done ? l.acctScreenshotAdded : l.acctPayNoScreenshot;
    return AtomPressable(
      onTap: onTap,
      semanticLabel: label,
      builder: (context, pressed) => Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: done
              ? AtomColors.greenSoft
              : pressed
              ? AtomColors.surface
              : AtomColors.head,
          borderRadius: AtomRadius.brCard,
          border: Border.all(
            color: done ? AtomColors.greenLine : AtomColors.line2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.image, size: 20, color: fg),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: AtomText.body.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
