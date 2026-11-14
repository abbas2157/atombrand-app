import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';

/// Marks a settings page shown on the right of Settings on a wide tablet
/// (19.19): both are in view, so it has no Back arrow and doesn't close
/// itself after saving.
class SettingsPane extends InheritedWidget {
  const SettingsPane({super.key, required super.child});

  /// Whether [context] is inside the Settings split's right pane.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsPane>() != null;

  @override
  bool updateShouldNotify(SettingsPane oldWidget) => false;
}

/// The Back arrow, or none beside the Settings list (19.19).
AtomFlowLeading settingsLeading(BuildContext context) =>
    SettingsPane.of(context) ? AtomFlowLeading.none : AtomFlowLeading.back;

/// Whether text is at 130% or more, where the boards let a row's second
/// line wrap (`.ts130 .set-item .tx span{white-space:normal}`).
bool setLargeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(10) >= 13;

/// A settings page as the 19.x boards draw it (`.scr.home` + `.pagehead`):
/// a grey page under a white header with a hairline, the title 20/700 after
/// a Back arrow, the body full width (groups keep their own 16 margins) and
/// an optional white bar at the bottom (`.bottombar`).
///
/// Beside the Settings list on a tablet (19.19) the header is the pane's
/// 20/700 title with an optional line under it, and the body is inset 32.
class SetPage extends StatelessWidget {
  const SetPage({
    super.key,
    required this.title,
    required this.children,
    this.bottom,
    this.paneSub,
  });

  final String title;
  final List<Widget> children;
  final Widget? bottom;

  /// The grey line under the title in the tablet's pane.
  final String? paneSub;

  @override
  Widget build(BuildContext context) {
    final pane = SettingsPane.of(context);
    final l = AppLocalizations.of(context);
    final scrollBottom = MediaQuery.textScalerOf(context).scale(10) >= 15;
    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!pane)
            AtomPageHeader(
              title: title,
              leading: AtomIconButton(
                icon: LucideIcons.chevronLeft,
                label: l.commonBack,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
          Expanded(
            child: ListView(
              padding: pane
                  ? EdgeInsets.fromLTRB(
                      16,
                      22 + MediaQuery.paddingOf(context).top,
                      16,
                      24,
                    )
                  : const EdgeInsets.only(bottom: 24),
              children: [
                if (pane) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Semantics(
                      header: true,
                      child: Text(title, style: AtomText.pageTitle),
                    ),
                  ),
                  if (paneSub != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Text(paneSub!, style: AtomText.secondary),
                    ),
                ],
                ...children,
                // At 200% text the bar scrolls with the page, so a tall
                // button can't push the page off the screen.
                if (bottom != null && scrollBottom) ...[
                  const SizedBox(height: 16),
                  SetBottomBar(child: bottom!),
                ],
              ],
            ),
          ),
          if (bottom != null && !scrollBottom) SetBottomBar(child: bottom!),
        ],
      ),
    );
  }
}

/// The white bar at the foot of a form (`.bottombar`): a hairline on top,
/// 12 16 26 around the button.
class SetBottomBar extends StatelessWidget {
  const SetBottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AtomColors.paper,
        border: Border(top: BorderSide(color: AtomColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, safe > 14 ? safe + 12 : 26),
      child: child,
    );
  }
}

/// Content inset 16 from the sides, [top] from what is above.
class SetPad extends StatelessWidget {
  const SetPad({super.key, required this.child, this.top = 12});

  final Widget child;
  final double top;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: EdgeInsets.fromLTRB(16, top, 16, 0), child: child);
}

/// Small print under a group (`p.tiny`, 12 grey, 10 18 0).
class SetTiny extends StatelessWidget {
  const SetTiny(this.text, {super.key, this.top = 10, this.center = false});

  final String text;
  final double top;
  final bool center;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(center ? 24 : 18, top, center ? 24 : 18, 0),
    child: Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: AtomText.small.copyWith(color: AtomColors.faint),
    ),
  );
}

/// A grey line of explanation (`.small` / `.set-desc`, 13 muted).
class SetDesc extends StatelessWidget {
  const SetDesc(this.text, {super.key, this.margin});

  final String text;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) => Padding(
    padding: margin ?? const EdgeInsets.fromLTRB(18, 12, 18, 0),
    child: Text(text, style: AtomText.secondary.copyWith(height: 1.45)),
  );
}

/// One settings row (`.set-item`): an icon on a tinted 36 tile, the title
/// 15/600, a second line 13 grey (one line at 100% text, wrapping from
/// 130%), then a trailing value, a widget (a pill, a small button, a switch,
/// a radio), a red count and a chevron.
///
/// [disabledReason] greys the row (50%), says why in the second line and
/// stops taps; [loading] puts a spinner where the value goes; [error]
/// shows the second line in rose and keeps the row tappable to retry.
class SetItem extends StatelessWidget {
  const SetItem({
    super.key,
    required this.title,
    this.icon,
    this.tone = AtomTone.grey,
    this.subtitle,
    this.subWraps = false,
    this.value,
    this.trailing,
    this.badge,
    this.onTap,
    this.chevron = false,
    this.danger = false,
    this.selected = false,
    this.disabledReason,
    this.loading = false,
    this.error,
    this.dim = false,
    this.minHeight = AtomSize.row,
    this.semanticLabel,
    this.checked,
  });

  final String title;
  final IconData? icon;
  final AtomTone tone;
  final String? subtitle;

  /// The second line wraps at every size (`white-space: normal`).
  final bool subWraps;

  /// A grey value at the end ("English", "On", "84 MB").
  final String? value;
  final Widget? trailing;
  final int? badge;
  final VoidCallback? onTap;
  final bool chevron;
  final bool danger;

  /// The page beside the list on a tablet (`.set-item.sel`).
  final bool selected;
  final String? disabledReason;
  final bool loading;
  final String? error;

  /// Faded as not available yet (55%), still read out.
  final bool dim;
  final double minHeight;
  final String? semanticLabel;

  /// A radio row's state for screen readers (19.14), without the
  /// selected look.
  final bool? checked;

  @override
  Widget build(BuildContext context) {
    final disabled = disabledReason != null;
    final second = disabledReason ?? error ?? subtitle;
    final wrap = subWraps || setLargeText(context);
    final tileTone = danger ? AtomTone.rose : tone;
    final titleColor = danger
        ? AtomColors.rose
        : selected
        ? AtomColors.primary
        : AtomColors.ink;
    final showValue = value != null && !loading && !disabled && error == null;
    // At 200% text (`.ts200 .set-item`) the value and a wide control drop
    // under the text and the chevron goes; a switch or a radio stays.
    final stacked = MediaQuery.textScalerOf(context).scale(10) >= 15;
    final smallControl = trailing is AtomSwitch || trailing is AtomRadio;
    final valueText = showValue
        ? Text(
            value!,
            style: AtomText.body.copyWith(
              color: AtomColors.muted,
              fontWeight: FontWeight.w500,
            ),
          )
        : null;
    final below = stacked
        ? [
            ?valueText,
            if (trailing != null && !disabled && !smallControl) trailing!,
          ]
        : const <Widget>[];
    final row = Row(
      children: [
        if (icon != null) ...[
          Container(
            width: AtomSize.rowTile,
            height: AtomSize.rowTile,
            decoration: BoxDecoration(
              color: tileTone.bg,
              borderRadius: AtomRadius.brControl,
            ),
            child: Icon(icon, size: AtomIcon.setRow, color: tileTone.fg),
          ),
          const SizedBox(width: AtomSpace.s3),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AtomText.listTitle.copyWith(color: titleColor),
              ),
              if (second != null)
                Text(
                  second,
                  maxLines: wrap ? null : 1,
                  overflow: wrap ? null : TextOverflow.ellipsis,
                  style: AtomText.secondary.copyWith(
                    color: error != null && !disabled
                        ? AtomColors.rose
                        : AtomColors.muted,
                  ),
                ),
              for (final w in below) ...[const SizedBox(height: 6), w],
            ],
          ),
        ),
        if (loading) ...[
          const SizedBox(width: AtomSpace.s3),
          const AtomSpinner(),
        ] else if (valueText != null && !stacked) ...[
          const SizedBox(width: AtomSpace.s3),
          valueText,
        ],
        if (trailing != null && !disabled && (!stacked || smallControl)) ...[
          const SizedBox(width: AtomSpace.s3),
          trailing!,
        ],
        if (badge != null && !disabled) ...[
          const SizedBox(width: AtomSpace.s3),
          AtomCountBadge(count: badge!),
        ],
        if (chevron && !stacked) ...[
          const SizedBox(width: AtomSpace.s3),
          const Icon(
            LucideIcons.chevronRight,
            size: AtomIcon.setRow,
            color: AtomColors.chevron,
          ),
        ],
      ],
    );
    return AtomPressable(
      onTap: disabled ? null : onTap,
      scaleOnPress: false,
      focusRadius: BorderRadius.zero,
      selected: checked ?? (selected ? true : null),
      semanticLabel:
          semanticLabel ??
          [
            title,
            ?second,
            if (showValue) ?value,
            if (badge != null && !disabled) '$badge',
          ].join(', '),
      builder: (context, pressed) => Opacity(
        opacity: disabled ? 0.5 : (dim ? 0.55 : 1),
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AtomSpace.inset,
            vertical: 10,
          ),
          color: selected
              ? AtomColors.primarySoft
              : pressed && onTap != null
              ? AtomColors.surface
              : AtomColors.paper,
          // A trailing control (a switch, a button) keeps its own
          // semantics; the rest is read as one label.
          child: trailing == null ? ExcludeSemantics(child: row) : row,
        ),
      ),
    );
  }
}

/// A small status pill at the end of a row (`.pill` at 22 tall).
class SetPill extends StatelessWidget {
  const SetPill(this.label, {super.key, this.tone = AtomTone.green});

  final String label;
  final AtomTone tone;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 22),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    decoration: BoxDecoration(
      color: tone.bg,
      borderRadius: AtomRadius.brPill,
      border: Border.all(color: tone.border),
    ),
    // As wide as its label, also when it drops under the text at 200%.
    child: Center(
      widthFactor: 1,
      heightFactor: 1,
      child: Text(
        label,
        style: AtomText.small.copyWith(
          color: tone.fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

/// The boards' secondary button: an outline (or WhatsApp) button 46 tall
/// with 15 text (`.btn ... style="height: 46px; font-size: 15px"`). At
/// large text it grows like any button.
class SetCompactButton extends StatelessWidget {
  const SetCompactButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = AtomButtonKind.outline,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AtomButtonKind kind;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final button = AtomButton(
      label: label,
      kind: kind,
      icon: icon,
      onPressed: onPressed,
    );
    if (setLargeText(context)) return button;
    return SizedBox(height: 46, child: button);
  }
}

/// A multi-line text box with its label (`textarea`, [minHeight] tall,
/// 15 text, 12 14 padding).
class SetTextArea extends StatefulWidget {
  const SetTextArea({
    super.key,
    required this.label,
    required this.controller,
    this.labelNote,
    this.placeholder,
    this.minHeight = 140,
    this.maxLength,
    this.onChanged,
  });

  final String label;
  final String? labelNote;
  final TextEditingController controller;
  final String? placeholder;
  final double minHeight;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  State<SetTextArea> createState() => _SetTextAreaState();
}

class _SetTextAreaState extends State<SetTextArea> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AtomField(
      label: widget.label,
      labelNote: widget.labelNote,
      child: Container(
        constraints: BoxConstraints(minHeight: widget.minHeight),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: atomInputBox(
          focused: _focus.hasFocus,
          error: false,
          disabled: false,
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focus,
          minLines: 3,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          maxLength: widget.maxLength,
          onChanged: widget.onChanged,
          style: AtomText.input.copyWith(fontSize: 15, height: 1.4),
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: AtomText.input.copyWith(
              fontSize: 15,
              color: AtomColors.placeholder,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            isCollapsed: true,
            // The box has the board's 12 14; none from the theme on top.
            contentPadding: EdgeInsets.zero,
            counterText: '',
          ),
        ),
      ),
    );
  }
}
