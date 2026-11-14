import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/app_localizations.dart';
import '../design/design.dart';
import 'atom_nav_row.dart';
import 'atom_pressable.dart';

/// The three header kinds (style guide, "Headers"):
/// - [AtomNavyHeader] for overview screens and money records (Home,
///   Inventory, Sync, My plan, Branches, an order, a customer);
/// - [AtomPageHeader], white with optional tabs, for lists;
/// - [AtomFlowBar], a plain bar for steps and forms: X closes the flow,
///   ‹ goes back one step.
///
/// Each one draws its own status-bar area and sets the status-bar icons to
/// match.

/// Navy header. [top] is the first row (shop switcher and buttons, or ‹ and
/// a title); [child] is what sits under it (greeting, figures).
class AtomNavyHeader extends StatelessWidget {
  const AtomNavyHeader({
    super.key,
    required this.top,
    this.child,
    this.bottom = 18,
  });

  final Widget top;
  final Widget? child;

  /// The space under [child] (`.hdr` 18; My plan's is 16, 13.7).
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        color: AtomColors.nav,
        padding: EdgeInsets.fromLTRB(
          AtomSpace.gutter,
          MediaQuery.paddingOf(context).top,
          AtomSpace.gutter,
          child == null ? 0 : bottom,
        ),
        child: DefaultTextStyle(
          // Normal line height, as the theme's default (`.hdr` sets none).
          style: AtomText.body.copyWith(
            color: AtomColors.navText,
            height: AtomText.normalHeight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: top,
              ),
              ?child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps the status bar navy over a page whose navy header scrolls away,
/// so the page never shows under the clock. Put it last in a [Stack] over
/// the scrolling list.
class AtomNavyStatusStrip extends StatelessWidget {
  const AtomNavyStatusStrip({super.key});

  @override
  Widget build(BuildContext context) => Positioned(
    top: 0,
    left: 0,
    right: 0,
    height: MediaQuery.paddingOf(context).top,
    child: const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(color: AtomColors.nav),
    ),
  );
}

/// A square button on the navy header (search, alerts), with an optional
/// count.
class AtomNavyIconButton extends StatelessWidget {
  const AtomNavyIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.count,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return AtomPressable(
      onTap: onTap,
      semanticLabel: count == null || count == 0 ? label : '$label, $count',
      builder: (context, pressed) => ExcludeSemantics(
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: pressed ? AtomColors.nav3 : AtomColors.nav2,
            borderRadius: AtomRadius.brControl,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, size: AtomIcon.row, color: Colors.white),
              if (count != null && count! > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 17),
                    height: 17,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AtomColors.alertBadge,
                      borderRadius: AtomRadius.brPill,
                      border: Border.all(color: AtomColors.nav, width: 2),
                    ),
                    child: Text(
                      count! > 99 ? '99+' : '$count',
                      style: AtomText.tag.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The round avatar with initials that opens the menu.
class AtomAvatar extends StatelessWidget {
  const AtomAvatar({
    super.key,
    required this.initials,
    this.onTap,
    this.size = 42,
    this.semanticLabel,
  });

  final String initials;
  final VoidCallback? onTap;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AtomColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: AtomColors.nav3, width: 2),
      ),
      child: Text(
        initials,
        style: AtomText.body.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    if (onTap == null) return circle;
    return AtomPressable(
      onTap: onTap,
      semanticLabel: semanticLabel ?? initials,
      focusRadius: AtomRadius.brPill,
      // The label says who it is; the initials would be read twice.
      builder: (_, _) => ExcludeSemantics(child: circle),
    );
  }
}

/// One tab under a white header, with an optional count.
class AtomHeaderTab {
  const AtomHeaderTab(this.label, {this.count});
  final String label;
  final int? count;
}

/// White header for lists: the title, buttons on the right, and tabs.
class AtomPageHeader extends StatelessWidget {
  const AtomPageHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.tabs,
    this.selectedTab = 0,
    this.onTab,
    this.leading,
  });

  final String title;
  final List<Widget> actions;
  final List<AtomHeaderTab>? tabs;
  final int selectedTab;
  final ValueChanged<int>? onTab;

  /// A ‹ for a list that isn't a tab root (Leads, Notifications).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        decoration: const BoxDecoration(
          color: AtomColors.paper,
          border: Border(bottom: BorderSide(color: AtomColors.line)),
        ),
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: EdgeInsets.only(
                  left: leading == null ? AtomSpace.gutter : 4,
                  right: 8,
                ),
                child: Row(
                  children: [
                    ?leading,
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(title, style: AtomText.pageTitle),
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
            ),
            if (tabs != null)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AtomSpace.s3),
                child: Row(
                  children: [
                    for (var i = 0; i < tabs!.length; i++)
                      _HeaderTab(
                        tab: tabs![i],
                        on: i == selectedTab,
                        onTap: onTab == null ? null : () => onTab!(i),
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

class _HeaderTab extends StatelessWidget {
  const _HeaderTab({required this.tab, required this.on, this.onTap});

  final AtomHeaderTab tab;
  final bool on;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colour = on ? AtomColors.primary : AtomColors.muted;
    return AtomPressable(
      onTap: onTap,
      selected: on,
      scaleOnPress: false,
      semanticLabel: tab.count == null
          ? tab.label
          : '${tab.label}, ${tab.count}',
      builder: (context, _) => Container(
        constraints: const BoxConstraints(minHeight: AtomSize.tapTarget),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: on ? AtomColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tab.label,
                style: AtomText.body.copyWith(
                  color: colour,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (tab.count != null) ...[
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? AtomColors.primarySoft : AtomColors.surface,
                    borderRadius: AtomRadius.brControl,
                  ),
                  child: Text(
                    '${tab.count}',
                    style: AtomText.small.copyWith(
                      color: on ? AtomColors.primary : AtomColors.text,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// How a flow bar's leading button behaves.
enum AtomFlowLeading {
  /// ‹: back one step.
  back,

  /// X: close the whole flow.
  close,

  /// Nothing: a root screen (Sign in after Welcome is not one).
  none,
}

/// The plain bar for steps and forms.
///
/// The leading button calls `Navigator.maybePop`, so an [AtomUnsavedGuard]
/// on the screen asks "Leave without saving?" first.
class AtomFlowBar extends StatelessWidget {
  const AtomFlowBar({
    super.key,
    this.leading = AtomFlowLeading.back,
    this.title,
    this.subtitle,
    this.trailing = const [],
    this.onLeading,
    this.oneLine = false,
    this.subtitleBold,
  });

  final AtomFlowLeading leading;
  final String? title;
  final String? subtitle;

  /// A part of [subtitle] in bold, as the board's `<b>` ("this month
  /// **Rs 8,400**").
  final String? subtitleBold;
  final List<Widget> trailing;

  /// The title on one line, cut short, beside the icons (a long name
  /// "PO-0003 · dpEP Wholesale" at 360dp).
  final bool oneLine;

  /// Overrides the default pop.
  final VoidCallback? onLeading;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                if (leading != AtomFlowLeading.none)
                  AtomIconButton(
                    icon: leading == AtomFlowLeading.back
                        ? LucideIcons.chevronLeft
                        : LucideIcons.x,
                    label: leading == AtomFlowLeading.back
                        ? l.commonBack
                        : l.commonClose,
                    onTap: onLeading ?? () => Navigator.of(context).maybePop(),
                  )
                else
                  const SizedBox(width: 12),
                Expanded(
                  child: title == null
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                title!,
                                maxLines: oneLine ? 1 : null,
                                overflow: oneLine
                                    ? TextOverflow.ellipsis
                                    : null,
                                style: subtitle == null
                                    ? AtomText.heading
                                    : AtomText.input.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                              ),
                            ),
                            if (subtitle != null)
                              Text.rich(
                                _subtitleSpan(subtitle!, subtitleBold),
                                style: AtomText.secondary,
                              ),
                          ],
                        ),
                ),
                ...trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

TextSpan _subtitleSpan(String text, String? bold) {
  final at = bold == null || bold.isEmpty ? -1 : text.indexOf(bold);
  if (at < 0) return TextSpan(text: text);
  return TextSpan(
    children: [
      TextSpan(text: text.substring(0, at)),
      TextSpan(
        text: bold,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      TextSpan(text: text.substring(at + bold!.length)),
    ],
  );
}

/// A 48×48 icon button on a white bar.
class AtomIconButton extends StatelessWidget {
  const AtomIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AtomColors.ink,
    this.count,
    this.glyph,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final int? count;

  /// A drawn glyph in place of [icon], for a board icon no Lucide icon
  /// draws (opt-in).
  final Widget? glyph;

  @override
  Widget build(BuildContext context) {
    return AtomPressable(
      onTap: onTap,
      semanticLabel: count == null || count == 0 ? label : '$label, $count',
      builder: (context, pressed) => ExcludeSemantics(
        child: Container(
          width: AtomSize.tapTarget,
          height: AtomSize.tapTarget,
          decoration: BoxDecoration(
            color: pressed ? AtomColors.surface : Colors.transparent,
            borderRadius: AtomRadius.brControl,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              glyph ?? Icon(icon, size: AtomIcon.bar, color: color),
              if (count != null && count! > 0)
                Positioned(
                  top: 4,
                  right: 2,
                  child: AtomCountBadge(count: count!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
