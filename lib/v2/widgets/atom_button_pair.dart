import 'package:flutter/material.dart';

/// Two buttons side by side, 10 apart, sharing the width by [firstFlex] and
/// [secondFlex] (14.3's OK and Ask Atom why: 1 and 1.3). When they don't
/// fit (a small phone or large text) they stack, the main one first, as the
/// navigation rules ask. With no [second], [first] fills the width.
class AtomButtonPair extends StatelessWidget {
  const AtomButtonPair({
    super.key,
    required this.first,
    this.second,
    this.firstFlex = 1,
    this.secondFlex = 1,
  });

  final Widget first;
  final Widget? second;
  final int firstFlex;
  final int secondFlex;

  @override
  Widget build(BuildContext context) {
    final second = this.second;
    if (second == null) return first;
    return LayoutBuilder(
      builder: (context, box) {
        final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
        if (box.maxWidth < 300 || box.maxWidth / scale < 280) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [second, const SizedBox(height: 10), first],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: firstFlex, child: first),
            const SizedBox(width: 10),
            Expanded(flex: secondFlex, child: second),
          ],
        );
      },
    );
  }
}
