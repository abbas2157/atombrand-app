import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/update/updates_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';

/// What's new in [version]: the release notes admin wrote (App updates),
/// one point per line.
Future<void> showWhatsNew(
  BuildContext context,
  String? version,
  List<String> points,
) => showAtomSheet<void>(
  context,
  useRootNavigator: true,
  builder: (context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtomSheetHeader(
            title: version == null
                ? l.updateWhatsNewTitleNoVersion
                : l.updateWhatsNewTitle(version),
          ),
          const SizedBox(height: AtomSpace.s2),
          for (final p in points)
            Padding(
              padding: const EdgeInsets.only(bottom: AtomSpace.s3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      LucideIcons.circleCheck,
                      size: 18,
                      color: AtomColors.green,
                    ),
                  ),
                  const SizedBox(width: AtomSpace.s3),
                  Expanded(child: Text(p, style: AtomText.body)),
                ],
              ),
            ),
          const SizedBox(height: AtomSpace.s2),
          AtomButton(
            label: l.updateWhatsNewDone,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  },
);

/// On Home only, so the update never interrupts the PIN, sign-in or a
/// payment:
///
/// - What's new, once, the first time Home opens after an update.
/// - Google Play's own prompts for a high-priority release
///   ([UpdatesController.offerOnHome]), within their quiet periods.
///
/// Draws nothing.
class UpdatePrompts extends ConsumerStatefulWidget {
  const UpdatePrompts({super.key});

  @override
  ConsumerState<UpdatePrompts> createState() => _UpdatePromptsState();
}

class _UpdatePromptsState extends ConsumerState<UpdatePrompts> {
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _act());
  }

  Future<void> _act() async {
    if (!mounted) return;
    final s = ref.read(updatesProvider);
    if (!s.checked) return;
    if (s.whatsNew && !_sheetOpen) {
      _sheetOpen = true;
      ref.read(updatesProvider.notifier).closeWhatsNew();
      await showWhatsNew(
        context,
        s.policy?.latestVersion,
        s.policy?.notePoints ?? const [],
      );
      _sheetOpen = false;
      return;
    }
    await ref.read(updatesProvider.notifier).offerOnHome();
  }

  @override
  Widget build(BuildContext context) {
    // A check that finishes while Home is open (launch, resume, a push).
    ref.listen(updatesProvider, (prev, next) {
      final newCheck =
          next.checked &&
          (prev?.checked != true ||
              prev?.store != next.store ||
              prev?.whatsNew != next.whatsNew);
      if (newCheck) WidgetsBinding.instance.addPostFrameCallback((_) => _act());
    });
    return const SizedBox.shrink();
  }
}
