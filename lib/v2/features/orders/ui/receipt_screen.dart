import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
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
          // A white top bar with a hairline under it, on the grey page.
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AtomColors.paper,
              border: Border(bottom: BorderSide(color: AtomColors.line)),
            ),
            child: AtomFlowBar(
              title: l.ordersReceipt,
              trailing: [
                if (receipt.value case final r?)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: AtomPill(label: r.order.number),
                  ),
              ],
            ),
          ),
          Expanded(
            child: receipt.when(
              loading: () => const Center(child: AtomSpinner(size: 28)),
              error: (e, _) => OrdersLoadError(
                error: e,
                onRetry: () => ref.invalidate(orderReceiptProvider(uuid)),
              ),
              data: (r) => ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
    final issued = r.issuedAt;
    final date = r.date;
    final small = AtomText.small.copyWith(color: AtomColors.muted);
    final rows = <(String, String)>[
      if (r.customer?.name case final n? when n.isNotEmpty)
        (l.ordersCustomer, n),
      (l.ordersItem, receiptItem(r)),
      if (r.serial case final s? when s.isNotEmpty) (l.ordersSerial, s),
      ...receiptPaymentLines(r, l),
      (l.ordersLeftToPay, formatRs(r.left)),
      if (r.deliveredBy case final d? when d.isNotEmpty)
        (l.ordersDeliveredBy, d),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      decoration: BoxDecoration(
        color: AtomColors.paper,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F101828),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
          BoxShadow(color: AtomColors.line, spreadRadius: 1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The brand's logo, else its initials.
              AtomInitials(
                name: r.brand,
                size: 32,
                imageUrl: logo != null && logo.isNotEmpty ? logo : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.brand,
                      style: AtomText.listTitle.copyWith(fontSize: 16),
                    ),
                    if ([?r.outlet, ?r.address].isNotEmpty)
                      Text([?r.outlet, ?r.address].join(' · '), style: small),
                    if (r.phone case final p? when p.isNotEmpty)
                      Text(p, style: small),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l.ordersCashReceipt,
                    style: AtomText.small.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AtomColors.ink,
                    ),
                  ),
                  Text(l.ordersOrderNumber(r.order.number), style: small),
                  if (issued != null)
                    Text(
                      '${AtomDates.day(issued)}, ${AtomDates.time(issued)}',
                      style: small,
                    )
                  else if (date != null)
                    Text(AtomDates.day(date), style: small),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // `.big`: the amount centred between dashed rules.
          CustomPaint(
            painter: const _DashedRules(color: AtomColors.line2),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatRs(r.order.total),
                      style: AtomText.amount.copyWith(color: AtomColors.ink),
                    ),
                  ),
                  Text(
                    receiptState(r, l),
                    textAlign: TextAlign.center,
                    style: small,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AtomColors.line),
            OrderLine(label: rows[i].$1, value: rows[i].$2, compact: true),
          ],
          if (r.note case final n? when n.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('"${n.trim()}"', textAlign: TextAlign.center, style: small),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Image.asset('assets/brand/atomshop_logo.png', height: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.ordersSoldOn,
                  textAlign: TextAlign.end,
                  style: AtomText.tag.copyWith(
                    color: AtomColors.faint,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The dashed rules above and below the receipt's amount.
class _DashedRules extends CustomPainter {
  const _DashedRules({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (final y in [0.5, size.height - 0.5]) {
      for (var x = 0.0; x < size.width; x += 6) {
        canvas.drawLine(Offset(x, y), Offset(x + 3, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRules old) => old.color != color;
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
                flex: 14,
                child: AtomButton(
                  label: l.ordersWhatsApp,
                  kind: AtomButtonKind.whatsapp,
                  compact: true,
                  oneLine: true,
                  padding: 10,
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
              flex: 10,
              child: AtomButton(
                label: l.ordersPdf,
                kind: AtomButtonKind.outline,
                oneLine: true,
                padding: 10,
                compact: true,
                onPressed: () => _pdf(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 10,
              child: AtomButton(
                label: l.ordersPrint,
                kind: AtomButtonKind.outline,
                oneLine: true,
                padding: 10,
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
