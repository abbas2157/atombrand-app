import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';

/// Scans serials off the boxes for a delivery (7.8): many in a row, up to
/// [max]. Typing is always offered. Tests swap [scanSerials] for a fake.
typedef SerialScanner = Future<List<String>> Function(
  BuildContext context, {
  required int max,
  required String title,
  List<String> already,
});

SerialScanner scanSerials = _scanWithCamera;

Future<List<String>> _scanWithCamera(
  BuildContext context, {
  required int max,
  required String title,
  List<String> already = const [],
}) async {
  final codes = await Navigator.of(context, rootNavigator: true)
      .push<List<String>>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) =>
              _ScannerScreen(max: max, title: title, already: already),
        ),
      );
  return codes ?? const [];
}

class _ScannerScreen extends StatefulWidget {
  const _ScannerScreen({
    required this.max,
    required this.title,
    required this.already,
  });

  final int max;
  final String title;
  final List<String> already;

  @override
  State<_ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<_ScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final _codes = <String>[];
  final _typed = TextEditingController();
  bool _typing = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _typed.dispose();
    super.dispose();
  }

  bool get _full => _codes.length >= widget.max;

  void _add(String raw) {
    final l = AppLocalizations.of(context);
    final v = raw.trim();
    if (v.length < 3 || v.length > 60) {
      setState(() => _error = l.bulkScanTooShort);
      return;
    }
    if (_codes.contains(v) || widget.already.contains(v)) {
      setState(() => _error = l.bulkScanAlready(v));
      return;
    }
    if (_full) return;
    setState(() {
      _error = null;
      _codes.add(v);
    });
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
                  onTap: () => Navigator.of(context).pop(const <String>[]),
                ),
                Expanded(
                  child: Text(
                    widget.title,
                    style: AtomText.heading.copyWith(color: Colors.white),
                  ),
                ),
                AtomIconButton(
                  icon: LucideIcons.keyboard,
                  label: l.bulkScanTypeIt,
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
                                label: l.bulkScanSerial,
                                controller: _typed,
                                autofocus: true,
                                error: _error,
                                textInputAction: TextInputAction.done,
                                onEditingComplete: () {
                                  _add(_typed.text);
                                  _typed.clear();
                                },
                              ),
                              const SizedBox(height: 10),
                              AtomButton(
                                label: l.bulkScanAdd,
                                kind: AtomButtonKind.outline,
                                small: true,
                                onPressed: _full
                                    ? null
                                    : () {
                                        _add(_typed.text);
                                        _typed.clear();
                                      },
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
                              if (b.rawValue case final raw?) _add(raw);
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
                              color: AtomColors.amber,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.bulkScanCount(_codes.length, widget.max),
                    style: AtomText.listTitle,
                  ),
                  if (_codes.isNotEmpty)
                    Text(
                      _codes.reversed.take(3).join('\n'),
                      style: AtomText.small,
                    ),
                  if (!_typing && _error != null)
                    Text(_error!, style: AtomText.fieldError),
                  const SizedBox(height: 10),
                  AtomButton(
                    label: l.bulkScanDone,
                    onPressed: _codes.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(List.of(_codes)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
