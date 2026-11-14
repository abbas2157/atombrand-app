import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/ids.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/order_rules.dart';

/// Pieces the order and AtomPay screens share: the step pill, the navy
/// header's figures, the next-step card, the stepper, cards and lines, the
/// form page and its bottom bar, choice buttons and the photo box.

/// A failure as one sentence: no signal, else the server's words.
String sayOrderFailure(ApiFailure f, AppLocalizations l) => switch (f.kind) {
  ApiFailureKind.offline || ApiFailureKind.timeout => l.ordersNoSignal,
  _ => f.message ?? l.ordersSomethingWrong,
};

/// The tone of a cash order's step (the boards' `.stage` colours).
AtomTone stageTone(OrderStage s) => switch (s) {
  OrderStage.pending => AtomTone.grey,
  OrderStage.confirming => AtomTone.amber,
  OrderStage.processing => AtomTone.purple,
  OrderStage.delivered => const AtomTone(
    fg: Color(0xFF0E6B73),
    bg: Color(0xFFE6F4F5),
    border: Color(0xFFE6F4F5),
  ),
  OrderStage.completed => AtomTone.green,
  OrderStage.cancelled => AtomTone.rose,
};

/// The tone of a payment state.
AtomTone payTone(PaymentState p) => switch (p) {
  PaymentState.unpaid => AtomTone.rose,
  PaymentState.part => AtomTone.amber,
  PaymentState.paid => AtomTone.green,
  PaymentState.notNeeded => const AtomTone(
    fg: AtomColors.muted,
    bg: AtomColors.surface,
    border: AtomColors.surface,
  ),
};

/// The small rounded step tag on a row (`.stage`): 22 high, bold.
class StageTag extends StatelessWidget {
  const StageTag({super.key, required this.label, required this.tone});

  final String label;
  final AtomTone tone;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 22),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: tone.bg,
      borderRadius: AtomRadius.brControl,
    ),
    child: Text(
      label,
      maxLines: 1,
      style: AtomText.small.copyWith(
        color: tone.fg,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    ),
  );
}

/// "Today", "Yesterday" or "2 Nov".
String whenShort(DateTime? d, AppLocalizations l, {DateTime? today}) {
  if (d == null) return '';
  return switch (AtomDates.daysFrom(d, today: today ?? AtomDates.now())) {
    0 => l.dateToday,
    -1 => l.dateYesterday,
    _ => AtomDates.short(d),
  };
}

/// "Today 10:12", "Yesterday", "2 Nov" (the list's time).
String whenRow(DateTime? d, AppLocalizations l, {DateTime? today}) {
  if (d == null) return '';
  final day = whenShort(d, l, today: today);
  final isToday = AtomDates.daysFrom(d, today: today ?? AtomDates.now()) == 0;
  return isToday ? '$day ${AtomDates.time(d)}' : day;
}

/// "3 Nov 10:05" (history).
String whenHistory(DateTime d) => '${AtomDates.short(d)} ${AtomDates.time(d)}';

/// The white list card with a hairline and rounded corners (`.ocard`,
/// `.card`); [divided] puts a hairline between the children.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
    this.divided = false,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final bool divided;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding.add(const EdgeInsets.all(1)),
    clipBehavior: Clip.antiAlias,
    decoration: const BoxDecoration(
      color: AtomColors.paper,
      borderRadius: AtomRadius.brCard,
    ),
    foregroundDecoration: BoxDecoration(
      borderRadius: AtomRadius.brCard,
      border: Border.all(color: AtomColors.line),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (divided && i > 0)
            const Divider(height: 1, color: AtomColors.line),
          children[i],
        ],
      ],
    ),
  );
}

/// A card's title (`.ch`), with an optional pill or note on the right.
class CardTitle extends StatelessWidget {
  const CardTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              text,
              style: AtomText.listTitle.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// A label and its value on one line (`.line`).
class OrderLine extends StatelessWidget {
  const OrderLine({
    super.key,
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;

  /// The total line.
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AtomText.body.copyWith(
              color: bold ? AtomColors.ink : AtomColors.muted,
              fontWeight: bold ? FontWeight.w600 : null,
              height: AtomText.normalHeight,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AtomText.body.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: AtomColors.ink,
              height: AtomText.normalHeight,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    ),
  );
}

/// A card of [OrderLine]s under a title.
class LinesCard extends StatelessWidget {
  const LinesCard({
    super.key,
    required this.title,
    required this.lines,
    this.trailing,
    this.footer = const [],
  });

  final String title;
  final Widget? trailing;
  final List<Widget> lines;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) => OrderCard(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
    children: [
      CardTitle(title, trailing: trailing),
      for (var i = 0; i < lines.length; i++) ...[
        if (i > 0) const Divider(height: 1, color: AtomColors.line),
        lines[i],
      ],
      if (footer.isNotEmpty) ...[const SizedBox(height: 8), ...footer],
    ],
  );
}

/// One figure on the navy header (`.amts div`): a label over the amount,
/// with an optional bar or note under it.
class NavyFigure extends StatelessWidget {
  const NavyFigure({
    super.key,
    required this.label,
    required this.value,
    this.note,
    this.progress,
  });

  final String label;
  final String value;
  final String? note;

  /// 0–1: the paid bar under the amount.
  final double? progress;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: AtomColors.nav2,
      borderRadius: AtomRadius.brControl,
      border: Border.all(color: AtomColors.navLine),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AtomText.small.copyWith(color: AtomColors.navText)),
        const SizedBox(height: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            maxLines: 1,
            style: AtomText.money.copyWith(color: Colors.white),
          ),
        ),
        if (progress != null) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress!.clamp(0, 1),
              minHeight: 4,
              backgroundColor: AtomColors.heroBarRest,
              color: AtomColors.toastOkIcon,
            ),
          ),
        ],
        if (note != null)
          Text(
            note!,
            maxLines: 2,
            style: AtomText.tag.copyWith(
              color: AtomColors.navMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    ),
  );
}

/// The three figures side by side, the same height.
class NavyFigures extends StatelessWidget {
  const NavyFigures({super.key, required this.figures});
  final List<Widget> figures;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < figures.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: figures[i]),
        ],
      ],
    ),
  );
}

/// The step's pill on the navy header: soft colour, no border.
class NavyPill extends StatelessWidget {
  const NavyPill({super.key, required this.label, required this.tone});
  final String label;
  final AtomTone tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: tone.bg, borderRadius: AtomRadius.brPill),
    child: Text(
      label,
      style: AtomText.small.copyWith(
        color: tone.fg,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// The navy top of an order page (6.2, 6.9): back, the number and step,
/// the title, a line under it and the figures.
class OrderNavyTop extends StatelessWidget {
  const OrderNavyTop({
    super.key,
    required this.number,
    required this.pill,
    required this.title,
    required this.subtitle,
    required this.figures,
    this.showBack = true,
    this.actions = const [],
  });

  final String number;
  final Widget pill;
  final String title;
  final String subtitle;
  final Widget figures;
  final bool showBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final secondary = AtomText.secondary.copyWith(color: AtomColors.navText);
    return AtomNavyHeader(
      top: Transform.translate(
        offset: const Offset(-8, 0),
        child: Row(
          children: [
            if (showBack)
              AtomIconButton(
                icon: LucideIcons.chevronLeft,
                label: AppLocalizations.of(context).commonBack,
                color: Colors.white,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            const Spacer(),
            ...actions,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(number, style: secondary),
              pill,
            ],
          ),
          const SizedBox(height: 4),
          Semantics(
            header: true,
            child: Text(
              title,
              style: AtomText.pageTitle.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: secondary),
          const SizedBox(height: 14),
          figures,
        ],
      ),
    );
  }
}

final _eyebrow = AtomText.small.copyWith(
  fontWeight: FontWeight.w700,
  letterSpacing: .8,
  color: AtomColors.primary,
);

/// The "Next step" card (`.next`): a blue ring, the step, what it asks and
/// its button; [extra] goes under the button (the disabled Complete).
class NextStepCard extends StatelessWidget {
  const NextStepCard({
    super.key,
    required this.title,
    required this.body,
    required this.button,
    required this.onPressed,
    this.eyebrow,
    this.saving = false,
    this.extra,
  });

  /// "NEXT STEP" when null.
  final String? eyebrow;
  final String title;
  final String body;
  final String button;
  final VoidCallback? onPressed;
  final bool saving;
  final Widget? extra;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AtomColors.paper,
      borderRadius: AtomRadius.brCard,
      border: Border.all(color: AtomColors.primary, width: 2),
      boxShadow: const [
        BoxShadow(color: AtomColors.primarySoft, spreadRadius: 3),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const AtomIconTile(icon: LucideIcons.arrowRight),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow ??
                        AppLocalizations.of(context).ordersNextStepEyebrow,
                    style: _eyebrow,
                  ),
                  Text(
                    title,
                    style: AtomText.input.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AtomColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(body, style: AtomText.body.copyWith(color: AtomColors.text)),
        const SizedBox(height: 10),
        AtomButton(
          label: button,
          compact: true,
          saving: saving,
          onPressed: onPressed,
        ),
        if (extra != null) ...[const SizedBox(height: 8), extra!],
      ],
    ),
  );
}

/// One step of a stepper (`.st`): a dot on a rail, green when done, ringed
/// blue when it is next.
class StepRow extends StatelessWidget {
  const StepRow({
    super.key,
    required this.name,
    required this.sub,
    required this.done,
    required this.now,
    required this.rail,
    this.onTap,
  });

  final String name;
  final String sub;
  final bool done;
  final bool now;
  final bool rail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const dot = 24.0;
    final circle = Container(
      width: dot,
      height: dot,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AtomColors.green : AtomColors.paper,
        border: Border.all(
          color: done
              ? AtomColors.green
              : now
              ? AtomColors.primary
              : AtomColors.line2,
          width: 2,
        ),
        boxShadow: now
            ? const [BoxShadow(color: AtomColors.primarySoft, spreadRadius: 4)]
            : null,
      ),
      child: done
          ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
          : now
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AtomColors.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
    final row = Semantics(
      container: true,
      button: onTap != null,
      label: [name, if (sub.isNotEmpty) sub].join(', '),
      child: ExcludeSemantics(
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: dot,
                child: Column(
                  children: [
                    circle,
                    if (rail)
                      Expanded(
                        child: Container(
                          width: 2,
                          constraints: const BoxConstraints(minHeight: 14),
                          color: done ? AtomColors.green : AtomColors.line,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1, bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AtomText.listTitle.copyWith(
                          height: AtomText.normalHeight,
                          color: done || now
                              ? AtomColors.ink
                              : AtomColors.muted,
                          fontWeight: done || now ? null : FontWeight.w600,
                        ),
                      ),
                      if (sub.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          sub,
                          style: AtomText.secondary.copyWith(
                            height: AtomText.normalHeight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (onTap == null) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: row,
    );
  }
}

/// The history card (`.ev2`): the time on the left, what happened.
class HistoryCard extends StatelessWidget {
  const HistoryCard({super.key, required this.events});

  /// (time, text), newest first.
  final List<(String, String)> events;

  @override
  Widget build(BuildContext context) => OrderCard(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
    children: [
      CardTitle(AppLocalizations.of(context).ordersHistory),
      for (var i = 0; i < events.length; i++)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: i == 0
                ? null
                : const Border(top: BorderSide(color: AtomColors.line)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 92,
                child: Text(
                  events[i].$1,
                  style: AtomText.small.copyWith(color: AtomColors.faint),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  events[i].$2,
                  style: AtomText.secondary.copyWith(color: AtomColors.text),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

/// Call and WhatsApp side by side (`.two2`).
class CallWhatsApp extends StatelessWidget {
  const CallWhatsApp({super.key, required this.phone});
  final String phone;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: AtomButton(
          label: AppLocalizations.of(context).ordersCall,
          kind: AtomButtonKind.outline,
          icon: LucideIcons.phone,
          compact: true,
          onPressed: () =>
              launchUrl(Uri(scheme: 'tel', path: AtomIds.digits(phone))),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: AtomButton(
          label: AppLocalizations.of(context).ordersWhatsApp,
          kind: AtomButtonKind.whatsapp,
          compact: true,
          onPressed: () => launchUrl(
            whatsAppUri(phone),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ),
    ],
  );
}

/// A link row at the bottom of an order (`.more`): Move, Receipt, Cancel.
class MoreRow extends StatelessWidget {
  const MoreRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colour = danger ? AtomColors.rose : AtomColors.ink;
    return AtomPressable(
      onTap: onTap,
      scaleOnPress: false,
      focusRadius: BorderRadius.zero,
      semanticLabel: label,
      builder: (_, pressed) => Container(
        color: pressed ? AtomColors.head : AtomColors.paper,
        constraints: const BoxConstraints(minHeight: AtomSize.tapTarget),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: AtomIcon.row, color: colour),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AtomText.listTitle.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colour,
                ),
              ),
            ),
            if (!danger)
              const Icon(
                LucideIcons.chevronRight,
                size: AtomIcon.row,
                color: AtomColors.chevron,
              ),
          ],
        ),
      ),
    );
  }
}

/// `.bottombar`: white, a hairline above, the main button.
class FormBottomBar extends StatelessWidget {
  const FormBottomBar({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      16,
      12,
      16,
      16 + MediaQuery.paddingOf(context).bottom,
    ),
    decoration: const BoxDecoration(
      color: AtomColors.paper,
      border: Border(top: BorderSide(color: AtomColors.line)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

/// A form of the order flows (6.3, 6.4, 6.10): the flow bar with ✕, the
/// scrolling body and the bottom bar.
class OrderFormPage extends StatelessWidget {
  const OrderFormPage({
    super.key,
    required this.title,
    required this.body,
    required this.bottom,
    this.subtitle,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
  });

  final String title;
  final String? subtitle;
  final List<Widget> body;
  final List<Widget> bottom;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final big = MediaQuery.textScalerOf(context).scale(10) >= 15;
    return Scaffold(
      backgroundColor: AtomColors.paper,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtomFlowBar(
            leading: AtomFlowLeading.close,
            title: title,
            subtitle: subtitle,
          ),
          if (big)
            Expanded(
              child: AtomReadableWidth(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: padding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: body,
                      ),
                    ),
                    FormBottomBar(children: bottom),
                  ],
                ),
              ),
            )
          else ...[
            Expanded(
              child: AtomReadableWidth(
                child: ListView(padding: padding, children: body),
              ),
            ),
            AtomReadableWidth(child: FormBottomBar(children: bottom)),
          ],
        ],
      ),
    );
  }
}

/// A form label (`.flabel`).
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.note});
  final String text;
  final String? note;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text.rich(
      TextSpan(
        text: text,
        children: [
          if (note != null)
            TextSpan(
              text: ' $note',
              style: AtomText.fieldLabel.copyWith(
                fontWeight: FontWeight.w500,
                color: AtomColors.faint,
              ),
            ),
        ],
      ),
      style: AtomText.fieldLabel,
    ),
  );
}

/// Equal buttons in a wrap, one picked (`.chips`, `.recv`): the picked one
/// has a 2px blue border on blue-soft.
class ChoiceButtons<T> extends StatelessWidget {
  const ChoiceButtons({
    super.key,
    required this.choices,
    required this.selected,
    required this.onChanged,
    this.columns,
    this.height = 44,
  });

  final List<(T, String)> choices;
  final T? selected;
  final ValueChanged<T> onChanged;

  /// Columns; all in one row when null.
  final int? columns;
  final double height;

  @override
  Widget build(BuildContext context) {
    final big = MediaQuery.textScalerOf(context).scale(10) >= 15;
    final per = columns ?? choices.length;
    final cols = big && per > 2 ? (per / 2).ceil() : per;
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 8.0;
        final w = (box.maxWidth - (cols - 1) * gap) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (value, label) in choices)
              SizedBox(
                width: w,
                child: AtomPressable(
                  onTap: () => onChanged(value),
                  selected: value == selected,
                  semanticLabel: label,
                  builder: (context, pressed) {
                    final on = value == selected;
                    return Container(
                      constraints: BoxConstraints(minHeight: height),
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(
                        horizontal: on ? 5 : 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: on
                            ? AtomColors.primarySoft
                            : pressed
                            ? AtomColors.surface
                            : AtomColors.paper,
                        borderRadius: AtomRadius.brControl,
                        border: Border.all(
                          color: on ? AtomColors.primary : AtomColors.line2,
                          width: on ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: AtomText.smallButton.copyWith(
                          fontSize: 14,
                          color: on ? AtomColors.primary : AtomColors.text,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The dashed photo box (`.photo`): green with a tick once taken.
class PhotoBox extends StatelessWidget {
  const PhotoBox({
    super.key,
    required this.label,
    required this.onTap,
    this.done = false,
    this.doneLabel,
  });

  final String label;

  /// "Photo added · tap to change" when null.
  final String? doneLabel;
  final VoidCallback onTap;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final colour = done ? AtomColors.noteGreenText : AtomColors.text;
    final text = done
        ? doneLabel ?? AppLocalizations.of(context).ordersPhotoAdded
        : label;
    return AtomPressable(
      onTap: onTap,
      semanticLabel: text,
      builder: (_, pressed) => CustomPaint(
        foregroundPainter: done ? null : _Dashes(),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: done
                ? AtomColors.greenSoft
                : pressed
                ? AtomColors.surface
                : AtomColors.head,
            borderRadius: AtomRadius.brCard,
            border: done ? Border.all(color: AtomColors.greenLine) : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                done ? LucideIcons.check : LucideIcons.camera,
                size: 20,
                color: colour,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: AtomText.smallButton.copyWith(
                    fontSize: 14,
                    color: colour,
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

class _Dashes extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AtomColors.line2
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AtomRadius.card),
        ).deflate(0.75),
      );
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Dashes oldDelegate) => false;
}

/// A photo from the camera (or the gallery), sized down for upload.
/// Tests swap it.
Future<File?> Function({bool camera}) takeOrderPhoto = _takePhoto;

Future<File?> _takePhoto({bool camera = true}) async {
  final f = await ImagePicker().pickImage(
    source: camera ? ImageSource.camera : ImageSource.gallery,
    maxWidth: 1600,
    imageQuality: 70,
  );
  return f == null ? null : File(f.path);
}

/// The camera tile above a hand-over (`.cam`): a frame on navy with the
/// scanning line until the serial is read; tapping opens the camera.
class ScanTile extends StatelessWidget {
  const ScanTile({
    super.key,
    required this.scanned,
    required this.onTap,
    required this.caption,
  });

  final bool scanned;
  final VoidCallback onTap;
  final String caption;

  @override
  Widget build(BuildContext context) => AtomPressable(
    onTap: onTap,
    semanticLabel: AppLocalizations.of(context).ordersScanSerial,
    builder: (_, _) => Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AtomColors.nav,
        borderRadius: BorderRadius.circular(AtomRadius.sheet),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 250,
            height: 86,
            decoration: BoxDecoration(
              borderRadius: AtomRadius.brCard,
              color: scanned ? AtomColors.frameOkFill : null,
              border: Border.all(
                color: scanned ? AtomColors.darkGreen : AtomColors.scanFrame,
                width: 2,
              ),
            ),
            child: scanned
                ? const Icon(
                    LucideIcons.check,
                    color: AtomColors.darkGreen,
                    size: 28,
                  )
                : Center(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: const BoxDecoration(
                        color: AtomColors.amber,
                        boxShadow: [
                          BoxShadow(color: AtomColors.amber, blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Text(
              caption,
              textAlign: TextAlign.center,
              style: AtomText.secondary.copyWith(color: AtomColors.navText),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The Cash / AtomPay toggle with counts (`.seg` with `.n`).
class OrdersToggle extends StatelessWidget {
  const OrdersToggle({
    super.key,
    required this.atompay,
    required this.onChanged,
    this.cashCount,
    this.atompayCount,
  });

  final bool atompay;
  final ValueChanged<bool> onChanged;
  final int? cashCount;
  final int? atompayCount;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget seg(String label, int? n, bool on, VoidCallback onTap) => Expanded(
      child: AtomPressable(
        onTap: onTap,
        selected: on,
        scaleOnPress: false,
        semanticLabel: n == null ? label : '$label, $n',
        builder: (_, _) => Container(
          constraints: const BoxConstraints(minHeight: 38),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: on ? AtomColors.paper : Colors.transparent,
            borderRadius: AtomRadius.brControl,
            boxShadow: on
                ? const [
                    BoxShadow(
                      color: Color(0x14101828),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                    BoxShadow(color: AtomColors.line, spreadRadius: 1),
                  ]
                : null,
          ),
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtomText.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: on ? AtomColors.ink : AtomColors.muted,
                    ),
                  ),
                ),
                if (n != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AtomColors.line,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$n',
                      style: AtomText.small.copyWith(
                        color: AtomColors.text,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: AtomColors.surface,
        borderRadius: AtomRadius.brControl,
      ),
      child: Row(
        children: [
          seg(l.ordersCashOrders, cashCount, !atompay, () => onChanged(false)),
          const SizedBox(width: 4),
          seg(
            l.ordersAtompayOrders,
            atompayCount,
            atompay,
            () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

/// The status chips with counts (`.stchips`).
class CountChips<T> extends StatelessWidget {
  const CountChips({
    super.key,
    required this.chips,
    required this.selected,
    required this.onPick,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 0),
  });

  /// Around the row; zero inside a page that is already padded (Team).
  final EdgeInsets padding;

  /// (value, label, count).
  final List<(T, String, int?)> chips;
  final T selected;
  final ValueChanged<T> onPick;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: padding,
    child: Row(
      children: [
        for (final (value, label, n) in chips) ...[
          AtomPressable(
            onTap: () => onPick(value),
            selected: value == selected,
            scaleOnPress: false,
            focusRadius: AtomRadius.brPill,
            semanticLabel: n == null ? label : '$label, $n',
            builder: (_, pressed) {
              final on = value == selected;
              return Container(
                constraints: const BoxConstraints(minHeight: 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: on
                      ? AtomColors.primarySoft
                      : pressed
                      ? AtomColors.surface
                      : AtomColors.paper,
                  borderRadius: AtomRadius.brPill,
                  border: Border.all(
                    color: on ? AtomColors.primary : AtomColors.line2,
                    width: on ? 2 : 1,
                  ),
                ),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: AtomText.smallButton.copyWith(
                          color: on ? AtomColors.primary : AtomColors.text,
                        ),
                      ),
                      if (n != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '$n',
                          style: AtomText.smallButton.copyWith(
                            fontWeight: FontWeight.w700,
                            color: on ? AtomColors.primary : AtomColors.text,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ],
    ),
  );
}

/// The list's search box (`.input` with a search icon), no label above.
class OrdersSearchBox extends StatelessWidget {
  const OrdersSearchBox({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
    child: Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: AtomSpace.inset),
      decoration: atomInputBox(focused: false, error: false, disabled: false),
      child: Row(
        children: [
          const Icon(
            LucideIcons.search,
            size: AtomIcon.row,
            color: AtomColors.faint,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: AtomText.input.copyWith(fontSize: 15),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: placeholder,
                hintStyle: AtomText.input.copyWith(
                  fontSize: 15,
                  color: AtomColors.placeholder,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
