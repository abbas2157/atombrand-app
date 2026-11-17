import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/models/bulk.dart';

/// A quote the brand sent, read back from the comment it was saved in.
class BulkQuote {
  const BulkQuote({required this.perUnit, required this.quantity, this.validUntil});
  final int perUnit;
  final int quantity;

  /// Display date, e.g. "10 Oct 2026".
  final String? validUntil;

  int get total => perUnit * quantity;
}

final _quoteLine = RegExp(r'^Quote: Rs\. ([\d,]+)/unit × ([\d,]+)(?: = Rs\. [\d,]+)?(?: · valid until (.+))?$');

/// The comment a quote is saved as: a machine-readable first line, then the
/// brand's own notes. The API stores comments only (§8.7), so this line is
/// how the quote survives.
String quoteComment(BulkQuote q, String notes) {
  final line = [
    'Quote: ${money(q.perUnit)}/unit × ${count(q.quantity)} = ${money(q.total)}',
    if (q.validUntil != null) 'valid until ${q.validUntil}',
  ].join(' · ');
  return notes.trim().isEmpty ? line : '$line\n${notes.trim()}';
}

/// Splits a comment into its quote line (if any) and the rest.
({BulkQuote? quote, String? note}) parseComment(String? text) {
  if (text == null || text.trim().isEmpty) return (quote: null, note: null);
  final lines = text.trim().split('\n');
  final m = _quoteLine.firstMatch(lines.first.trim());
  if (m == null) return (quote: null, note: text.trim());
  int n(String s) => int.parse(s.replaceAll(',', ''));
  final rest = lines.skip(1).join('\n').trim();
  return (
    quote: BulkQuote(perUnit: n(m.group(1)!), quantity: n(m.group(2)!), validUntil: m.group(3)?.trim()),
    note: rest.isEmpty ? null : rest,
  );
}

/// The newest quote among [comments] (the API lists them oldest first).
BulkQuote? latestQuote(List<BulkComment> comments) {
  for (final c in comments.reversed) {
    final q = parseComment(c.comments).quote;
    if (q != null) return q;
  }
  return null;
}

/// Whole days a New Lead has waited, or null once someone has acted on it.
int? waitingDays(BulkRequest r, {DateTime? now}) {
  if (r.status != 'New Lead') return null;
  final created = parseServerDate(r.createdAt);
  if (created == null) return null;
  return DateUtils.dateOnly(now ?? DateTime.now()).difference(DateUtils.dateOnly(created)).inDays;
}

/// One line on how much to trust the buyer, from their orders with the brand.
({String text, bool warn}) trustHint(BulkDossier d) {
  if (d.instalmentsOverdue > 0) {
    final n = d.instalmentsOverdue;
    return (text: '$n ${n == 1 ? 'instalment' : 'instalments'} overdue with your brand', warn: true);
  }
  final delivered = d.orders.where((o) => o.status == 'Delivered' || o.status == 'Completed').length;
  if (d.orders.isEmpty) return (text: 'New buyer, no orders with your brand yet', warn: false);
  if (delivered == 0) return (text: 'New buyer, no completed orders yet', warn: false);
  return (text: 'Reliable buyer, $delivered ${delivered == 1 ? 'order' : 'orders'} delivered', warn: false);
}

/// New Lead → Contacted → Quoted → Won (or Lost at the end).
List<({String label, bool done, bool current})> pipeline(String status) {
  final labels = ['New Lead', 'Contacted', 'Quoted', status == 'Lost' ? 'Lost' : 'Won'];
  final at = status == 'Lost' ? 3 : labels.indexOf(status).clamp(0, 3);
  return [
    for (final (i, l) in labels.indexed) (label: l, done: i < at, current: i == at),
  ];
}
