import '../../../../l10n/app_localizations.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/pdf/phone_pdf.dart';
import 'orders_models.dart';

/// The receipt (6.7) as PDF lines and as a WhatsApp message, from the
/// server's receipt data. The PDF is laid out on the phone
/// (`core/pdf/phone_pdf.dart`) for PDF and Print.

/// "Paid in full · 2 payments", or "Part paid · Rs 62,500 left".
String receiptState(OrderReceipt r, AppLocalizations l) {
  final n = r.payments.length;
  if (r.left <= 0) return l.ordersReceiptPaidFull(n);
  if (r.paidTotal <= 0) return l.ordersReceiptNotPaid;
  return l.ordersReceiptPartLeft(formatRs(r.left));
}

/// "Zenvo Refrigerator 14 cft · Silver · 1".
String receiptItem(OrderReceipt r) => [
  r.order.productTitle,
  if (r.order.variant case final v? when v.isNotEmpty) v,
  '${r.order.quantity}',
].join(' · ');

/// The payments oldest first, as (label, amount): "4 Nov · Cash on delivery".
List<(String, String)> receiptPaymentLines(
  OrderReceipt r,
  AppLocalizations l,
) => [
  for (final p in r.payments.reversed)
    (
      [
        if (p.paidOn != null) AtomDates.short(p.paidOn!),
        p.methodName(l),
      ].join(' · '),
      formatRs(p.amount),
    ),
];

/// The receipt's lines for the phone-built PDF (`buildReceiptPdf`).
ReceiptLines receiptLines(OrderReceipt r, AppLocalizations l) {
  final date = r.date;
  return ReceiptLines(
    brand: r.brand,
    from: [?r.outlet, ?r.address, ?r.phone].join(' · '),
    number: r.number.isEmpty ? null : r.number,
    title: [
      l.ordersCashReceipt,
      l.ordersOrderNumber(r.order.number),
      if (date != null) AtomDates.day(date),
    ].join(' · '),
    amount: formatRs(r.order.total),
    amountNote: receiptState(r, l),
    rows: [
      if (r.customer?.name case final n? when n.isNotEmpty)
        (l.ordersCustomer, n),
      (l.ordersItem, receiptItem(r)),
      if (r.serial case final s? when s.isNotEmpty) (l.ordersSerial, s),
      ...receiptPaymentLines(r, l),
      (l.ordersLeftToPay, formatRs(r.left)),
    ],
    note: r.note,
    footer: l.ordersSoldOn,
  );
}

/// The receipt as a WhatsApp message to the customer.
String receiptMessage(OrderReceipt r, AppLocalizations l) {
  final lines = [
    l.ordersReceiptMsgHead(r.brand, r.number),
    '${l.ordersOrderNumber(r.order.number)} · ${receiptItem(r)}',
    if (r.serial case final s? when s.isNotEmpty) l.ordersSerialValue(s),
    '${l.ordersTotalValue(formatRs(r.order.total))} · ${receiptState(r, l)}',
    for (final (k, v) in receiptPaymentLines(r, l)) '$k: $v',
    if (r.note case final n? when n.trim().isNotEmpty) n.trim(),
  ];
  return lines.join('\n');
}
