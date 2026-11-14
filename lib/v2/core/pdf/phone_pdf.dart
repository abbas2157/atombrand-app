import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// The lines of a cash receipt (6.7), already in the person's language and
/// already formatted. The PDF only lays them out.
class ReceiptLines {
  const ReceiptLines({
    required this.brand,
    required this.title,
    required this.amount,
    required this.amountNote,
    required this.rows,
    required this.footer,
    this.from,
    this.number,
    this.note,
  });

  /// The brand's name, at the top.
  final String brand;

  /// The outlet, address and phone under the name ("Gulberg · 12 Main
  /// Boulevard · 0300 1234567"), when known.
  final String? from;

  /// The server's receipt number ("BR-3-2026-11-48224").
  final String? number;

  /// "Cash receipt · Order 48224 · 6 Nov 2026"
  final String title;

  /// "Rs 112,500"
  final String amount;

  /// "Paid in full · 2 payments"
  final String amountNote;

  /// Label → value.
  final List<(String, String)> rows;

  /// The brand's own receipt note (Shop settings), when it has one.
  final String? note;
  final String footer;
}

/// Builds the receipt as an A6 PDF on the phone, in the app's Inter, so it
/// looks like the app and works with no signal. The brand server sends the
/// receipt as data (`GET orders/{uuid}/receipt`), not as a PDF.
Future<Uint8List> buildReceiptPdf(ReceiptLines r) async {
  final fonts = await _fonts();
  final mark = await _mark();
  const ink = PdfColor.fromInt(0xFF101828);
  const muted = PdfColor.fromInt(0xFF5E6779);
  const line = PdfColor.fromInt(0xFFD0D5DD);

  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
    title: r.number == null ? r.title : '${r.number} · ${r.title}',
  );
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a6,
      margin: const pw.EdgeInsets.all(18),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Image(mark, width: 26, height: 26),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      r.brand,
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: 12,
                        color: ink,
                      ),
                    ),
                    if (r.from case final from? when from.isNotEmpty)
                      pw.Text(
                        from,
                        style: const pw.TextStyle(fontSize: 7, color: muted),
                      ),
                    pw.Text(
                      r.title,
                      style: const pw.TextStyle(fontSize: 8, color: muted),
                    ),
                    if (r.number case final n? when n.isNotEmpty)
                      pw.Text(
                        n,
                        style: pw.TextStyle(
                          font: fonts.bold,
                          fontSize: 8,
                          color: ink,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: line, style: pw.BorderStyle.dashed),
                bottom: pw.BorderSide(
                  color: line,
                  style: pw.BorderStyle.dashed,
                ),
              ),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  r.amount,
                  style: pw.TextStyle(
                    font: fonts.heavy,
                    fontSize: 22,
                    color: ink,
                  ),
                ),
                pw.Text(
                  r.amountNote,
                  style: const pw.TextStyle(fontSize: 8, color: muted),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 6),
          for (final (label, value) in r.rows)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      label,
                      style: const pw.TextStyle(fontSize: 9, color: muted),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Flexible(
                    child: pw.Text(
                      value,
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: 9,
                        color: ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (r.note case final note? when note.trim().isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              note.trim(),
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 8, color: muted),
            ),
          ],
          pw.Spacer(),
          pw.Text(
            r.footer,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 7, color: muted),
          ),
        ],
      ),
    ),
  );
  return doc.save();
}

/// A report as the app shows it, ready for the PDF: the server's figures,
/// already formatted.
class ReportSheet {
  const ReportSheet({
    required this.title,
    required this.summary,
    required this.tables,
    this.subtitle,
    this.note,
    this.footer,
  });

  final String title;

  /// "Zenith · This month · All outlets"
  final String? subtitle;

  /// Label → value.
  final List<(String, String)> summary;

  /// Each table: its title (may be empty), column headings, rows of cells,
  /// and whether each column is a number (right-aligned).
  final List<ReportSheetTable> tables;
  final String? note;
  final String? footer;
}

class ReportSheetTable {
  const ReportSheetTable({
    required this.head,
    required this.rows,
    this.title = '',
    this.numeric = const [],
  });

  final String title;
  final List<String> head;
  final List<List<String>> rows;

  /// Per column; missing means text.
  final List<bool> numeric;
}

/// Builds a report (12.5) as an A4 PDF on the phone, in Inter, to share on
/// WhatsApp. The brand server's reports are data; downloads of its own
/// files are on the portal.
Future<Uint8List> buildReportPdf(ReportSheet r) async {
  final fonts = await _fonts();
  final mark = await _mark();
  const ink = PdfColor.fromInt(0xFF101828);
  const muted = PdfColor.fromInt(0xFF5E6779);
  const faint = PdfColor.fromInt(0xFF667085);
  const line = PdfColor.fromInt(0xFFE4E7EC);
  const head = PdfColor.fromInt(0xFFF8F9FB);

  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
    title: r.title,
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      footer: r.footer == null
          ? null
          : (context) => pw.Text(
              '${r.footer} · ${context.pageNumber}/${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: faint),
            ),
      build: (context) => [
        pw.Row(
          children: [
            pw.Image(mark, width: 28, height: 28),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    r.title,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: ink,
                    ),
                  ),
                  if (r.subtitle case final s? when s.isNotEmpty)
                    pw.Text(
                      s,
                      style: const pw.TextStyle(fontSize: 10, color: muted),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (r.summary.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: const pw.BoxDecoration(color: head),
            child: pw.Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                for (final (label, value) in r.summary)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        label,
                        style: const pw.TextStyle(fontSize: 9, color: muted),
                      ),
                      pw.Text(
                        value,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
        for (final t in r.tables) ...[
          pw.SizedBox(height: 12),
          if (t.title.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text(
                t.title,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: ink,
                ),
              ),
            ),
          pw.TableHelper.fromTextArray(
            headers: t.head,
            data: t.rows,
            border: const pw.TableBorder(
              horizontalInside: pw.BorderSide(color: line),
              bottom: pw.BorderSide(color: line),
            ),
            headerStyle: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: faint,
            ),
            headerDecoration: const pw.BoxDecoration(color: head),
            cellStyle: const pw.TextStyle(fontSize: 9, color: ink),
            cellAlignments: {
              for (var i = 0; i < t.head.length; i++)
                i: i < t.numeric.length && t.numeric[i]
                    ? pw.Alignment.centerRight
                    : pw.Alignment.centerLeft,
            },
            headerAlignments: {
              for (var i = 0; i < t.head.length; i++)
                i: i < t.numeric.length && t.numeric[i]
                    ? pw.Alignment.centerRight
                    : pw.Alignment.centerLeft,
            },
          ),
        ],
        if (r.note case final n? when n.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Text(n, style: const pw.TextStyle(fontSize: 9, color: muted)),
        ],
      ],
    ),
  );
  return doc.save();
}

Future<({pw.Font regular, pw.Font bold, pw.Font heavy})> _fonts() async => (
  regular: pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Regular.ttf')),
  bold: pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Bold.ttf')),
  heavy: pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-ExtraBold.ttf')),
);

Future<pw.MemoryImage> _mark() async => pw.MemoryImage(
  (await rootBundle.load('assets/brand/mark.png')).buffer.asUint8List(),
);
