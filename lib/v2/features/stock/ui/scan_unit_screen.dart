import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/stock_repository.dart';
import 'inventory_home_screen.dart' show UnitFoundCard;
import 'scanner.dart' show ScanFrame;
import 'stock_parts.dart';

/// 9.8 Scan a serial or IMEI: the camera, and what the number is — in
/// stock, delivered, removed or not found — with what to do next.
class ScanUnitScreen extends ConsumerStatefulWidget {
  const ScanUnitScreen({super.key});

  @override
  ConsumerState<ScanUnitScreen> createState() => _ScanUnitScreenState();
}

class _ScanUnitScreenState extends ConsumerState<ScanUnitScreen> {
  final _camera = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  String? _serial;

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  void _found(String raw) {
    final s = raw.trim();
    if (s.length < 3 || s == _serial) return;
    setState(() => _serial = s);
  }

  Future<void> _type() async {
    final l = AppLocalizations.of(context);
    final typed = TextEditingController();
    final s = await showAtomSheet<String>(
      context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            AtomSheetHeader(title: l.stockTypeNumber),
            AtomTextField(
              label: l.stockSerialOrImei,
              controller: typed,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => Navigator.of(context).pop(v),
            ),
            AtomButton(
              label: l.stockLookUp,
              onPressed: () => Navigator.of(context).pop(typed.text),
            ),
          ],
        ),
      ),
    );
    typed.dispose();
    if (s != null && s.trim().isNotEmpty) _found(s);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final serial = _serial;
    return Scaffold(
      backgroundColor: AtomColors.nav,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AtomIconButton(
                  icon: LucideIcons.x,
                  label: l.commonClose,
                  color: Colors.white,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Text(
                    l.stockScanTitle,
                    style: AtomText.heading.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                AtomIconButton(
                  icon: LucideIcons.keyboard,
                  label: l.stockTypeInstead,
                  color: Colors.white,
                  onTap: _type,
                ),
              ],
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _camera,
                    onDetect: (capture) {
                      for (final b in capture.barcodes) {
                        final raw = b.rawValue;
                        if (raw != null) {
                          _found(raw);
                          break;
                        }
                      }
                    },
                  ),
                  const Center(child: ScanFrame()),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: AtomColors.surface,
                borderRadius: AtomRadius.brSheetTop,
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AtomColors.line2,
                        borderRadius: AtomRadius.brPill,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (serial == null)
                    Text(
                      l.stockScanPoint,
                      style: AtomText.secondary,
                      textAlign: TextAlign.center,
                    )
                  else ...[
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                      ),
                      child: SingleChildScrollView(
                        child: ref
                            .watch(unitLookupProvider(serial))
                            .when(
                              loading: () => const AtomLoadingCard(count: 1),
                              error: (e, _) => SizedBox(
                                height: 260,
                                child: StockFailed(
                                  error: e,
                                  onRetry: () => ref.invalidate(
                                    unitLookupProvider(serial),
                                  ),
                                ),
                              ),
                              data: (found) => UnitFoundCard(found: found),
                            ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    AtomButton(
                      label: l.stockScanAnother,
                      kind: AtomButtonKind.outline,
                      compact: true,
                      onPressed: () => setState(() => _serial = null),
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
