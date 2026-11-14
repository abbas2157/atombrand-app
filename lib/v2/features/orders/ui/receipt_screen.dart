import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/ids.dart';
import '../../../core/format/money.dart';
import '../../../core/pdf/phone_pdf.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/orders_models.dart';
import '../data/orders_providers.dart';
import '../data/receipt_text.dart';
import 'order_parts.dart';

/// Receipt (6.7): the receipt as the customer sees it, shared on WhatsApp,
/// as a PDF or printed. The note at the bottom is the brand's Shop
/// settings · Receipt note.
class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key, required this.uuid});
  final String uuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final receipt = ref.watch(orderReceiptProvider(uuid));
    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtomFlowBar(
            title: l.ordersReceipt,
            trailing: [
              if (receipt.value case final r?)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AtomPill(label: r.order.number),
                ),
            ],
          ),
          Expanded(
            child: receipt.when(
              loading: () => const Center(child: AtomSpinner(size: 28)),
              error: (e, _) => AtomErrorState(
                message: e is ApiFailure ? sayOrderFailure(e, l) : null,
                onRetry: () => ref.invalidate(orderReceiptProvider(uuid)),
              ),
              data: (r) => ListView(
                padding: const EdgeInsets.all(16),
                children: [AtomReadableWidth(child: _Paper(receipt: r))],
              ),
            ),
          ),
          if (receipt.value case final r?) _ShareBar(receipt: r),
        ],
      ),
    );
  }
}

class _Paper extends ConsumerWidget {
  const _Paper({required this.receipt});
  final OrderReceipt receipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final r = receipt;
    final logo = ref.watch(sessionProvider.notifier).current?.brandLogo;
    final date = r.date;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AtomDecor.raisedCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (logo != null && logo.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: AtomRadius.brControl,
                  child: AtomPhoto(
                    logo,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.brand, style: AtomText.listTitle),
                    if ([?r.outlet, ?r.address].isNotEmpty)
                      Text(
                        [?r.outlet, ?r.address].join(' · '),
                        style: AtomText.small,
                      ),
                    if (r.phone case final p? when p.isNotEmpty)
                      Text(p, style: AtomText.small),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l.ordersCashReceipt,
                    style: AtomText.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    l.ordersOrderNumber(r.order.number),
                    style: AtomText.small,
                  ),
                  if (date != null)
                    Text(AtomDates.day(date), style: AtomText.small),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AtomColors.surface,
              borderRadius: AtomRadius.brControl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatRs(r.order.total), style: AtomText.amount),
                Text(receiptState(r, l), style: AtomText.secondary),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (r.customer?.name case final n? when n.isNotEmpty)
            OrderLine(label: l.ordersCustomer, value: n),
          OrderLine(label: l.ordersItem, value: receiptItem(r)),
          if (r.serial case final s? when s.isNotEmpty)
            OrderLine(label: l.ordersSerial, value: s),
          for (final (k, v) in receiptPaymentLines(r, l))
            OrderLine(label: k, value: v),
          OrderLine(
            label: l.ordersLeftToPay,
            value: formatRs(r.left),
            bold: true,
          ),
          if (r.note case final n? when n.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '“${n.trim()}”',
              style: AtomText.secondary.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1, color: AtomColors.line),
          const SizedBox(height: 12),
          Row(
            children: [
              Image.asset('assets/brand/atomshop_logo.png', height: 18),
              const SizedBox(width: 8),
              Text(l.ordersSoldOn, style: AtomText.small),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.receipt});
  final OrderReceipt receipt;

  String get _file =>
      'Receipt ${receipt.number.isEmpty ? receipt.order.number : receipt.number}.pdf';

  Future<void> _pdf(BuildContext context) async {
    try {
      final bytes = await buildReceiptPdf(
        receiptLines(receipt, AppLocalizations.of(context)),
      );
      await Printing.sharePdf(bytes: bytes, filename: _file);
    } on Object {
      if (context.mounted) _failed(context);
    }
  }

  Future<void> _print(BuildContext context) async {
    final l = AppLocalizations.of(context);
    try {
      await Printing.layoutPdf(
        name: _file,
        onLayout: (_) => buildReceiptPdf(receiptLines(receipt, l)),
      );
    } on Object {
      if (context.mounted) _failed(context);
    }
  }

  void _failed(BuildContext context) => showAtomToast(
    context,
    kind: AtomToastKind.bad,
    message: AppLocalizations.of(context).ordersPdfFailed,
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final phone = receipt.customer?.phone;
    return FormBottomBar(
      children: [
        Row(
          children: [
            if (phone != null && phone.isNotEmpty) ...[
              Expanded(
                child: AtomButton(
                  label: l.ordersWhatsApp,
                  kind: AtomButtonKind.whatsapp,
                  compact: true,
                  onPressed: () => launchUrl(
                    whatsAppUri(
                      AtomIds.digits(phone),
                      text: receiptMessage(receipt, l),
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: AtomButton(
                label: l.ordersPdf,
                kind: AtomButtonKind.outline,
                icon: LucideIcons.fileText,
                compact: true,
                onPressed: () => _pdf(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AtomButton(
                label: l.ordersPrint,
                kind: AtomButtonKind.outline,
                icon: LucideIcons.printer,
                compact: true,
                onPressed: () => _print(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l.ordersReceiptNoteFrom,
          textAlign: TextAlign.center,
          style: AtomText.small.copyWith(color: AtomColors.faint),
        ),
      ],
    );
  }
}
