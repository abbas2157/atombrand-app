import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/db/copy_key.dart';
import '../../../core/lock/quick_sign_in.dart';
import '../../../core/net/network_status.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';

/// Pieces the sign-in, way-in and lock screens share (boards 1.x–4.x).

/// Atomshop's WhatsApp, as on the boards and in atomshop's
/// `config/website.php` (`whatsapp_number`).
const atomshopWhatsApp = '+923331214955';

Future<void> openAtomshopWhatsApp() => launchUrl(
  Uri.parse('https://wa.me/${atomshopWhatsApp.substring(1)}'),
  mode: LaunchMode.externalApplication,
);

/// The system prompt's texts for the saved sign-in.
QuickPrompt quickPrompt(AppLocalizations l, {bool save = false}) => (
  title: l.auth3PromptTitle,
  subtitle: save ? l.auth3PromptSave : l.auth3PromptRead,
  cancel: l.commonCancel,
);

/// The system prompt's texts when the fingerprint reads, or is given, the
/// key to what is saved on the phone (`CopyKey`). [keep]: it is being
/// given the key, so the prompt says what for.
CopyPrompt copyPrompt(AppLocalizations l, {bool keep = false}) => (
  title: l.auth3PromptTitle,
  subtitle: keep ? l.copyBioPromptSub : l.lockBioReason,
  cancel: l.commonCancel,
);

/// Why the saved fingerprint sign-in was erased, for Sign in to say.
enum QuickNotice { fingerprintsChanged, passwordChanged }

final quickNoticeProvider = NotifierProvider<QuickNoticeNote, QuickNotice?>(
  QuickNoticeNote.new,
);

class QuickNoticeNote extends Notifier<QuickNotice?> {
  @override
  QuickNotice? build() => null;

  void show(QuickNotice n) => state = n;

  void clear() => state = null;
}

/// The board type the auth screens use.
abstract final class AuthText {
  /// `.h1`: 24/700, line 1.2, −.3.
  static final h1 = AtomText.successTitle.copyWith(
    height: 1.2,
    letterSpacing: -0.3,
  );

  /// `.sub`: 15, line 1.5, muted.
  static final sub = AtomText.body.copyWith(
    fontSize: 15,
    height: 1.5,
    color: AtomColors.muted,
  );

  /// `.small`: 13, line 1.45, muted.
  static final small = AtomText.secondary.copyWith(
    height: 1.45,
    color: AtomColors.muted,
  );

  /// `.tiny`: 12, faint.
  static final tiny = AtomText.small.copyWith(color: AtomColors.faint);

  /// A link (`a`): 600, primary.
  static final link = AtomText.body.copyWith(
    color: AtomColors.primary,
    fontWeight: FontWeight.w600,
  );
}

/// The page under a flow bar: scrolls when the text is large, and lets a
/// [Spacer] push the bottom part down when there is room
/// (`margin-top: auto`).
class AuthScrollBody extends StatelessWidget {
  const AuthScrollBody({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 28),
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AtomSize.formMaxWidth,
              ),
              child: Padding(
                padding: padding.copyWith(bottom: padding.bottom + bottom),
                child: Column(
                  crossAxisAlignment: crossAxisAlignment,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "Step 1 of 2" at the end of a flow bar (`.tiny`, 16 in). Flexible, so
/// it wraps instead of running off at large text.
class AuthStepLabel extends StatelessWidget {
  const AuthStepLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsetsDirectional.only(end: 20),
      child: Text(text, style: AuthText.tiny, textAlign: TextAlign.end),
    ),
  );
}

/// A text link with a 48dp tap area.
class AuthLink extends StatelessWidget {
  const AuthLink({
    super.key,
    required this.label,
    required this.onTap,
    this.style,
  });

  final String label;
  final VoidCallback onTap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return AtomPressable(
      onTap: onTap,
      semanticLabel: label,
      scaleOnPress: false,
      builder: (_, _) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AtomSize.tapTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: style ?? AuthText.link,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Online" (green) or "No internet" (amber), from the phone's network
/// (`.pill.on` / `.pill.off`). On the navy lock screens only "Online"
/// shows: the offline text belongs to the Offline add-on.
class AuthNetworkPill extends ConsumerWidget {
  const AuthNetworkPill({super.key, this.dark = false, this.offline});

  final bool dark;

  /// Overrides the network ("No internet" after a call failed to connect).
  final bool? offline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final online = ref.watch(onlineProvider).value ?? true;
    final isOffline = offline ?? !online;
    if (dark) {
      if (isOffline) return const SizedBox(height: 26);
      return const DarkOnlinePill();
    }
    return AtomPill(
      label: isOffline ? l.auth2NoInternet : l.auth2Online,
      tone: isOffline ? AtomTone.amber : AtomTone.green,
      dot: true,
    );
  }
}

/// `.dark .pill.on`.
class DarkOnlinePill extends StatelessWidget {
  const DarkOnlinePill({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AtomColors.darkGreenFill,
        borderRadius: AtomRadius.brPill,
        border: Border.all(color: AtomColors.darkGreenLine),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AtomColors.darkGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            l.auth2Online,
            style: AtomText.small.copyWith(
              color: AtomColors.darkGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A note (`.note`) whose text starts with a bold part and may have a bold
/// part in the middle: "**No internet.** The first sign-in…".
class AuthNote extends StatelessWidget {
  const AuthNote({
    super.key,
    required this.kind,
    required this.icon,
    required this.text,
    this.bold,
    this.lead,
  });

  final AtomNoteKind kind;
  final IconData icon;

  /// The text; [bold] inside it is drawn bold.
  final String text;
  final String? bold;

  /// Bold words before [text].
  final String? lead;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border, Color fg) = switch (kind) {
      AtomNoteKind.info => (
        AtomColors.primarySoft,
        AtomColors.primaryLine,
        AtomColors.noteBlueText,
      ),
      AtomNoteKind.success => (
        AtomColors.greenSoft,
        AtomColors.greenLine,
        AtomColors.noteGreenText,
      ),
      AtomNoteKind.warning => (
        AtomColors.amberSoft,
        AtomColors.amberLine,
        AtomColors.amberInk,
      ),
      AtomNoteKind.problem => (
        AtomColors.roseSoft,
        AtomColors.roseLine,
        AtomColors.noteRoseText,
      ),
    };
    return Semantics(
      container: true,
      liveRegion: kind != AtomNoteKind.info,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AtomRadius.brControl,
          border: Border.all(color: border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 18, color: fg),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: AtomText.body.copyWith(color: fg),
                  children: [
                    if (lead != null)
                      TextSpan(
                        text: '$lead ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ...boldSpans(
                      text,
                      bold,
                      const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// [text] as spans, with [bold] (when it is in the text) in [boldStyle].
List<TextSpan> boldSpans(String text, String? bold, TextStyle boldStyle) {
  final at = bold == null || bold.isEmpty ? -1 : text.indexOf(bold);
  if (at < 0) return [TextSpan(text: text)];
  return [
    TextSpan(text: text.substring(0, at)),
    TextSpan(text: bold, style: boldStyle),
    TextSpan(text: text.substring(at + bold!.length)),
  ];
}

/// The shield with a keyhole on 2.4 (no Lucide glyph has it): drawn from
/// the board's path on a 24 grid, stroke 2.
class ShieldKeyholeIcon extends StatelessWidget {
  const ShieldKeyholeIcon({super.key, this.size = 26, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _ShieldKeyholePainter(color),
  );
}

class _ShieldKeyholePainter extends CustomPainter {
  _ShieldKeyholePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final shield = Path()
      ..moveTo(12, 3)
      ..lineTo(20, 6)
      ..lineTo(20, 12)
      ..cubicTo(20, 17, 16.5, 20, 12, 21)
      ..cubicTo(7.5, 20, 4, 17, 4, 12)
      ..lineTo(4, 6)
      ..close();
    canvas
      ..drawPath(shield, paint)
      ..drawCircle(const Offset(12, 11), 2, paint)
      ..drawLine(const Offset(12, 13), const Offset(12, 16), paint);
  }

  @override
  bool shouldRepaint(_ShieldKeyholePainter old) => old.color != color;
}

/// The key on 4.1 (Lucide's key now has its ring at the top): drawn from
/// the board's path on a 24 grid, stroke 2.
class BoardKeyIcon extends StatelessWidget {
  const BoardKeyIcon({super.key, this.size = 24, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _KeyPainter(color));
}

class _KeyPainter extends CustomPainter {
  _KeyPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawCircle(const Offset(8, 15), 4, paint)
      ..drawLine(const Offset(11, 12), const Offset(20, 3), paint)
      ..drawLine(const Offset(17, 6), const Offset(20, 9), paint)
      ..drawLine(const Offset(15, 8), const Offset(17, 10), paint);
  }

  @override
  bool shouldRepaint(_KeyPainter old) => old.color != color;
}
