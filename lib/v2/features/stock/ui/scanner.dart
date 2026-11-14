import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/format/ids.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';

/// Scans serials with the camera: one code, or many in a row (stock in,
/// move). With [imeiOnly] only valid IMEIs are kept (15 digits passing the
/// Luhn check), which tells the IMEI apart from the EAN on a phone box.
/// Typing is always offered. Tests swap it for a fake.
typedef CodeScanner = Future<List<String>> Function(
  BuildContext context, {
  required bool many,
  bool imeiOnly,
  String? title,
});

CodeScanner scanCodes = _scanWithCamera;

Future<List<String>> _scanWithCamera(
  BuildContext context, {
  required bool many,
  bool imeiOnly = false,
  String? title,
}) async {
  final codes = await Navigator.of(context).push<List<String>>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) =>
          StockScannerScreen(many: many, imeiOnly: imeiOnly, title: title),
    ),
  );
  return codes ?? const [];
}

/// The camera with a frame, what has been read, Done and Type it.
class StockScannerScreen extends StatefulWidget {
  const StockScannerScreen({
    super.key,
    required this.many,
    this.imeiOnly = false,
    this.title,
  });

  final bool many;
  final bool imeiOnly;
  final String? title;

  @override
  State<StockScannerScreen> createState() => _StockScannerScreenState();
}

class _StockScannerScreenState extends State<StockScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final _codes = <String>[];
  final _typed = TextEditingController();
  bool _typing = false;
  String? _typedError;

  @override
  void dispose() {
    _controller.dispose();
    _typed.dispose();
    super.dispose();
  }

  bool _keep(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return false;
    if (widget.imeiOnly) return AtomIds.isValidImei(v);
    return v.length >= 3 && v.length <= 60;
  }

  void _addTyped() {
    final v = _typed.text.trim();
    if (v.isEmpty) return;
    if (!_keep(v)) {
      final l = AppLocalizations.of(context);
      setState(
        () => _typedError = widget.imeiOnly
            ? l.stockScanNotImei
            : l.stockScanLength,
      );
      return;
    }
    setState(() => _typedError = null);
    _typed.clear();
    _add(v);
  }

  void _add(String raw) {
    final v = raw.trim();
    if (!_keep(v) || _codes.contains(v)) return;
    setState(() => _codes.add(v));
    if (!widget.many) Navigator.of(context).pop([v]);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hint = widget.imeiOnly ? l.stockScanHintImei : l.stockScanHintSerial;
    return Scaffold(
      backgroundColor: AtomColors.nav,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AtomIconButton(
                  icon: LucideIcons.x,
                  label: l.commonClose,
                  color: Colors.white,
                  onTap: () => Navigator.of(context).pop(const <String>[]),
                ),
                Expanded(
                  child: Text(
                    widget.title ?? l.stockScanTitle,
                    style: AtomText.heading.copyWith(color: Colors.white),
                  ),
                ),
                AtomIconButton(
                  icon: LucideIcons.keyboard,
                  label: l.stockTypeInstead,
                  color: Colors.white,
                  onTap: () => setState(() => _typing = !_typing),
                ),
              ],
            ),
            Expanded(
              child: _typing
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AtomColors.paper,
                            borderRadius: AtomRadius.brCard,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AtomTextField(
                                key: ValueKey(_codes.length),
                                label: widget.imeiOnly
                                    ? l.stockTrackingImei
                                    : l.stockSerialOrImei,
                                controller: _typed,
                                autofocus: true,
                                keyboardType: widget.imeiOnly
                                    ? TextInputType.number
                                    : TextInputType.text,
                                textInputAction: TextInputAction.done,
                                error: _typedError,
                                onChanged: (_) =>
                                    setState(() => _typedError = null),
                                onEditingComplete: _addTyped,
                              ),
                              const SizedBox(height: 10),
                              AtomButton(
                                label: widget.many ? l.stockAdd : l.stockLookUp,
                                kind: AtomButtonKind.outline,
                                small: true,
                                onPressed: _addTyped,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _controller,
                          onDetect: (capture) {
                            for (final b in capture.barcodes) {
                              final raw = b.rawValue;
                              if (raw != null) _add(raw);
                            }
                          },
                        ),
                        const Center(child: ScanFrame()),
                      ],
                    ),
            ),
            Container(
              color: AtomColors.paper,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_typing) Text(hint, style: AtomText.secondary),
                  if (widget.many) ...[
                    if (!_typing) const SizedBox(height: 8),
                    Text(
                      l.stockScannedN(_codes.length),
                      style: AtomText.listTitle,
                    ),
                    if (_codes.isNotEmpty)
                      Text(
                        _codes.reversed.take(3).join('\n'),
                        style: AtomText.small,
                      ),
                    const SizedBox(height: 10),
                    AtomButton(
                      label: l.stockDone,
                      onPressed: _codes.isEmpty && _typed.text.trim().isEmpty
                          ? null
                          : () {
                              if (_typed.text.trim().isNotEmpty) {
                                _addTyped();
                                if (_typedError != null) return;
                              }
                              Navigator.of(context).pop(List.of(_codes));
                            },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The white frame with the amber laser across it.
class ScanFrame extends StatelessWidget {
  const ScanFrame({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 290,
    height: 110,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: AtomRadius.brCard,
      border: Border.all(color: AtomColors.scanFrame, width: 2),
    ),
    child: Container(
      height: 2,
      decoration: const BoxDecoration(
        color: AtomColors.amber,
        boxShadow: [BoxShadow(color: AtomColors.amber, blurRadius: 10)],
      ),
    ),
  );
}
