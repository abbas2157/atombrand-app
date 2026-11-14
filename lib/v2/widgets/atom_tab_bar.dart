import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design/design.dart';
import 'atom_pressable.dart';
import 'atom_photo.dart';

/// One of the four main destinations.
class AtomDestination {
  const AtomDestination({
    required this.icon,
    required this.label,
    this.initials,
    this.imageUrl,
  });
  final IconData icon;
  final String label;

  /// The person's photo, drawn round in place of [icon]; their [initials]
  /// while it loads or when there is none.
  final String? imageUrl;

  /// Drawn as a small round avatar instead of [icon] (the Account tab: the
  /// person's initials).
  final String? initials;
}

/// A destination's icon, or its initials in a ring of [colour].
class _DestinationIcon extends StatelessWidget {
  const _DestinationIcon({required this.destination, required this.colour});
  final AtomDestination destination;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final initials = destination.initials;
    final url = destination.imageUrl;
    if ((initials == null || initials.isEmpty) && url == null) {
      return Icon(destination.icon, size: AtomIcon.bar, color: colour);
    }
    final letters = Container(
      width: AtomIcon.bar + 2,
      height: AtomIcon.bar + 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colour, width: 1.6),
      ),
      child: Text(
        initials ?? '',
        textScaler: TextScaler.noScaling,
        style: AtomText.tag.copyWith(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: colour,
          height: 1,
        ),
      ),
    );
    if (url == null || url.isEmpty) return letters;
    // The photo in a ring of the tab's colour (blue when on).
    return Container(
      width: AtomIcon.bar + 4,
      height: AtomIcon.bar + 4,
      padding: const EdgeInsets.all(1.6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colour, width: 1.6),
      ),
      child: ClipOval(
        child: AtomPhoto(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => letters,
          frameBuilder: (_, child, frame, sync) =>
              frame == null && !sync ? letters : child,
        ),
      ),
    );
  }
}

/// The tab bar: two tabs, the ＋ in the middle, two tabs. It shows only on
/// its main screens; sub-screens have no tab bar.
class AtomTabBar extends StatelessWidget {
  const AtomTabBar({
    super.key,
    required this.destinations,
    required this.selected,
    required this.onSelect,
    required this.onPlus,
    required this.plusLabel,
  }) : assert(destinations.length == 4);

  final List<AtomDestination> destinations;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onPlus;
  final String plusLabel;

  @override
  Widget build(BuildContext context) {
    Widget tab(int i) => Expanded(
      child: _Tab(
        destination: destinations[i],
        on: i == selected,
        onTap: () => onSelect(i),
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        color: AtomColors.paper,
        border: Border(top: BorderSide(color: AtomColors.line)),
      ),
      padding: EdgeInsets.only(
        left: 6,
        right: 6,
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      child: SizedBox(
        height: 62,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tab(0),
            tab(1),
            Expanded(
              child: _PlusButton(onTap: onPlus, label: plusLabel),
            ),
            tab(2),
            tab(3),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.destination,
    required this.on,
    required this.onTap,
  });

  final AtomDestination destination;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colour = on ? AtomColors.primary : AtomColors.faint;
    return AtomPressable(
      onTap: onTap,
      selected: on,
      scaleOnPress: false,
      semanticLabel: destination.label,
      builder: (context, _) => ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DestinationIcon(destination: destination, colour: colour),
              const SizedBox(height: 3),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // The bar's labels stay one line at any text size; the
                // icons carry the meaning and the label is in semantics.
                textScaler: MediaQuery.textScalerOf(context)
                    .clamp(maxScaleFactor: 1.3),
                style: AtomText.tag.copyWith(
                  color: colour,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlusButton extends StatelessWidget {
  const _PlusButton({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      maxHeight: 90,
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: AtomPressable(
          onTap: onTap,
          semanticLabel: label,
          focusRadius: const BorderRadius.all(Radius.circular(20)),
          builder: (context, pressed) => Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: pressed ? AtomColors.primaryPressed : AtomColors.primary,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              border: Border.all(color: AtomColors.paper, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x592747C7),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.plus,
              size: AtomIcon.plus,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// The tablet rail (600dp and wider, 15.1 `.rail`): navy, the mark, the
/// ＋, the destinations, and More (the menu) at the foot when [onMore] is
/// given.
class AtomRail extends StatelessWidget {
  const AtomRail({
    super.key,
    required this.destinations,
    required this.selected,
    required this.onSelect,
    required this.onPlus,
    required this.plusLabel,
    this.onMore,
    this.moreLabel,
  });

  final List<AtomDestination> destinations;

  /// -1 when none is on.
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onPlus;
  final String plusLabel;
  final VoidCallback? onMore;
  final String? moreLabel;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        width: AtomSize.railWidth,
        color: AtomColors.nav,
        padding: EdgeInsets.only(top: pad.top + 20, bottom: pad.bottom + 20),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: AtomRadius.brCard,
              ),
              child: Image.asset(
                'assets/brand/mark.png',
                width: 36,
                height: 36,
                semanticLabel: 'Brand Partner',
              ),
            ),
            const SizedBox(height: 18),
            AtomPressable(
              onTap: onPlus,
              semanticLabel: plusLabel,
              focusRadius: AtomRadius.brCard,
              builder: (_, pressed) => Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: pressed
                      ? AtomColors.primaryPressed
                      : AtomColors.primary,
                  borderRadius: AtomRadius.brCard,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x592747C7),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.plus,
                  size: AtomIcon.plus,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < destinations.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              _RailItem(
                destination: destinations[i],
                on: i == selected,
                onTap: () => onSelect(i),
              ),
            ],
            const Spacer(),
            if (onMore != null)
              _RailItem(
                destination: AtomDestination(
                  icon: LucideIcons.menu,
                  label: moreLabel ?? '',
                ),
                on: false,
                onTap: onMore!,
              ),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.on,
    required this.onTap,
  });

  final AtomDestination destination;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AtomPressable(
    onTap: onTap,
    selected: on,
    scaleOnPress: false,
    semanticLabel: destination.label,
    focusRadius: AtomRadius.brCard,
    builder: (_, pressed) => ExcludeSemantics(
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: on || pressed ? AtomColors.nav2 : Colors.transparent,
          borderRadius: AtomRadius.brCard,
        ),
        child: Column(
          children: [
            _DestinationIcon(
              destination: destination,
              colour: on ? Colors.white : AtomColors.navMuted,
            ),
            const SizedBox(height: 4),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textScaler: MediaQuery.textScalerOf(context)
                  .clamp(maxScaleFactor: 1.3),
              style: AtomText.small.copyWith(
                color: on ? Colors.white : AtomColors.navMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
