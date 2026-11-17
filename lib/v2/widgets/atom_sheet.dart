import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/app_localizations.dart';
import '../design/design.dart';
import 'atom_pressable.dart';

/// Opens a v2 bottom sheet: 20 corners, a grab handle, the dim behind it.
///
/// The sheet rides above the keyboard. With [expand] it takes most of the
/// screen (the dropdown sheet does, so its list has room with the keyboard
/// up); otherwise it is as tall as its content.
///
/// Android back and the swipe down close the sheet before anything else, as
/// the navigation rules ask.
///
/// [useRootNavigator] puts it over the tab bar too (5.4, 5.5).
Future<T?> showAtomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool expand = false,
  bool useRootNavigator = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      final media = MediaQuery.of(context);
      final keyboard = media.viewInsets.bottom;
      final child = Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: Column(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Grab(),
            if (expand)
              Expanded(child: builder(context))
            else
              // Scrolls when large text makes it taller than the screen.
              Flexible(child: SingleChildScrollView(child: builder(context))),
          ],
        ),
      );
      if (!expand) return SafeArea(top: false, child: child);
      // The canvas sheet (`.pick`) starts 96px from the top of an 844
      // screen: 52 under the status bar.
      return SizedBox(
        height: media.size.height - media.padding.top - 52,
        child: SafeArea(top: false, child: child),
      );
    },
  );
}

class _Grab extends StatelessWidget {
  const _Grab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        width: 40,
        height: 4,
        decoration: const BoxDecoration(
          color: AtomColors.line2,
          borderRadius: AtomRadius.brPill,
        ),
      ),
    );
  }
}

/// A sheet's title row with the X that closes it.
class AtomSheetHeader extends StatelessWidget {
  const AtomSheetHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AtomSpace.gutter, 6, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: AtomText.heading),
            ),
          ),
          AtomPressable(
            onTap: () => Navigator.of(context).maybePop(),
            semanticLabel: l.commonClose,
            builder: (_, _) => const Icon(
              LucideIcons.x,
              size: AtomIcon.bar,
              color: AtomColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
