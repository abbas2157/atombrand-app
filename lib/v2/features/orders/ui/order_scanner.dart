import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';

/// Reads one serial or IMEI with the camera, or lets it be typed. Null when
/// closed. Tests swap it for a fake.
/// [title] is "Scan the serial" when null.
Future<String?> Function(BuildContext context, {String? title}) scanSerial =
    _scanWithCamera;

Future<String?> _scanWithCamera(BuildContext context, {String? title}) {
  final t = title ?? AppLocalizations.of(context).ordersScanSerial;
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _SerialScanner(title: t),
    ),
  );
}

/// A serial is 3–60 characters (the server's `serial` rule is ≤ 60).
bool looksLikeSerial(String raw) {
  final v = raw.trim();
  return v.length >= 3 && v.length <= 60;
}

class _SerialScanner extends StatefulWidget {
  const _SerialScanner({required this.title});
  final String title;

  @override
  State<_SerialScanner> createState() => _SerialScannerState();
}

class _SerialScannerState extends State<_SerialScanner> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final _typed = TextEditingController();
  bool _typing = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _typed.dispose();
    super.dispose();
  }

  void _finish(String raw) {
    final v = raw.trim();
    if (_done || !looksLikeSerial(v)) return;
    _done = true;
    Navigator.of(context).pop(v);
  }

  void _useTyped() {
    final v = _typed.text.trim();
    if (!looksLikeSerial(v)) {
      setState(() => _error = AppLocalizations.of(context).ordersSerialLength);
      return;
    }
    _finish(v);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
                  onTap: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    widget.title,
                    style: AtomText.heading.copyWith(color: Colors.white),
                  ),
                ),
                AtomIconButton(
                  icon: _typing ? LucideIcons.scanLine : LucideIcons.keyboard,
                  label: _typing ? l.ordersScanCamera : l.ordersTypeIt,
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
                                label: l.ordersSerialOrImei,
                                controller: _typed,
                                autofocus: true,
                                placeholder: l.ordersTypeFromBox,
                                textInputAction: TextInputAction.done,
                                error: _error,
                                onChanged: (_) => setState(() => _error = null),
                                onSubmitted: (_) => _useTyped(),
                              ),
                              const SizedBox(height: 10),
                              AtomButton(
                                label: l.ordersUseSerial,
                                compact: true,
                                onPressed: _useTyped,
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
                              if (b.rawValue case final raw?) _finish(raw);
                            }
                          },
                        ),
                        Center(
                          child: Container(
                            width: 290,
                            height: 110,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: AtomRadius.brCard,
                              border: Border.all(
                                color: AtomColors.scanFrame,
                                width: 2,
                              ),
                            ),
                            child: Container(
                              height: 2,
                              decoration: const BoxDecoration(
                                color: AtomColors.amber,
                                boxShadow: [
                                  BoxShadow(
                                    color: AtomColors.amber,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            Container(
              color: AtomColors.paper,
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Text(l.ordersScanHelp, style: AtomText.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
