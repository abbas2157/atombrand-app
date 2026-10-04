import 'package:flutter/material.dart';
import '../../core/app_icons.dart';

import '../../core/theme.dart';
import 'partner_content.dart';

/// Small uppercase heading between sections.
class AuthSectionTitle extends StatelessWidget {
  const AuthSectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppPalette.of(context).muted,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
              fontSize: 12,
            ),
      ),
    );
  }
}

/// Numbered steps joined by a thin line: Apply → Review → Go live.
class PartnerSteps extends StatelessWidget {
  const PartnerSteps({super.key, this.steps = PartnerContent.steps, this.current});

  final List<({String title, String body})> steps;

  /// Steps before this index show as done (a tick instead of a number).
  final int? current;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = AppPalette.of(context);
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      _Dot(index: i, done: current != null && i < current!),
                      if (i < steps.length - 1)
                        Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: p.border)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 4, bottom: i < steps.length - 1 ? 20 : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(steps[i].title, style: t.titleMedium?.copyWith(color: p.text)),
                        const SizedBox(height: 3),
                        Text(steps[i].body, style: t.bodySmall?.copyWith(fontSize: 13, height: 1.45, color: p.muted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.index, required this.done});
  final int index;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final fg = done ? p.onSuccess : p.onPrimary;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: done ? p.success : p.primary, shape: BoxShape.circle),
      child: done
          ? Icon(AppIcons.check, color: fg, size: 18)
          : Text(
              '${index + 1}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg, fontSize: 14, fontWeight: FontWeight.w700),
            ),
    );
  }
}

class CheckLine extends StatelessWidget {
  const CheckLine(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(AppIcons.checkCircleFill, size: 18, color: p.success),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4, color: p.text)),
          ),
        ],
      ),
    );
  }
}
