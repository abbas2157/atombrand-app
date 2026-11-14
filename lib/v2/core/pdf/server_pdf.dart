import 'package:printing/printing.dart';

import '../api/api_client.dart';
import '../api/api_result.dart';

/// A PDF that seller admin designs and builds: a report, a receipt, a
/// statement, the day's summary. The app only fetches it and hands it over,
/// so the phone shares the same document the seller downloads on the web,
/// and a change to its design needs no app release.
class ServerPdf {
  const ServerPdf(this.path, {this.query = const {}, required this.filename});

  /// Under the API root, e.g. `reports/collection/pdf`.
  final String path;

  /// The same filters as the screen's own call, so the PDF matches what
  /// the seller is looking at.
  final Map<String, dynamic> query;

  /// What the file is called in the share sheet when the server doesn't name
  /// it. The server's own name (`Content-Disposition`) wins, so the receipt
  /// carries its receipt number and the statement the shop's order number.
  final String filename;
}

/// Gets [pdf] and hands it to the phone's share sheet (WhatsApp first for
/// most people), or with [print] to the print dialog, which also saves it
/// and reaches Bluetooth printers.
///
/// Answers the failure for the screen to say, or null once handed over.
Future<ApiFailure?> handOverServerPdf(
  ApiClient api,
  ServerPdf pdf, {
  bool print = false,
}) async {
  switch (await api.getPdf(pdf.path, query: pdf.query)) {
    case ApiOk(:final value):
      final name = value.filename ?? pdf.filename;
      if (print) {
        await Printing.layoutPdf(
          onLayout: (_) async => value.bytes,
          name: name,
        );
      } else {
        await Printing.sharePdf(bytes: value.bytes, filename: name);
      }
      return null;
    case ApiErr(:final failure):
      return failure;
  }
}
