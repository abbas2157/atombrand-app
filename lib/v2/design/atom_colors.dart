import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  Brand Partner v2 — Colour tokens
///
///  The `:root` tokens of the canvas `project/app.css` (v1.1, 4 Nov 2026),
///  one for one, under the same names. The canvas is the source of truth: if
///  a value here and the canvas disagree, the canvas wins and this file is
///  wrong.
///
///  v2 has one light theme, the seller dashboard v2 look. There is no dark
///  mode, so these are plain constants rather than a ThemeExtension.
/// ─────────────────────────────────────────────────────────────────────────
abstract final class AtomColors {
  // ── Text ────────────────────────────────────────────────────────────────
  static const ink = Color(0xFF101828);
  static const text = Color(0xFF344054);
  static const muted = Color(0xFF5E6779);
  static const faint = Color(0xFF667085);

  // ── Primary ─────────────────────────────────────────────────────────────
  static const primary = Color(0xFF2747C7);
  static const primaryDark = Color(0xFF1D3AA6);

  /// A pressed primary button.
  static const primaryPressed = Color(0xFF17318F);
  static const primarySoft = Color(0xFFEEF2FD);
  static const primaryLine = Color(0xFFCDD7FA);

  // ── Navy headers ────────────────────────────────────────────────────────
  static const nav = Color(0xFF0F1B35);
  static const nav2 = Color(0xFF16244A);
  static const nav3 = Color(0xFF1C2D5C);
  static const navText = Color(0xFFB9C3DA);
  static const navMuted = Color(0xFF97A3BF);
  static const navLine = Color(0xFF26365F);

  // ── Status ──────────────────────────────────────────────────────────────
  static const amber = Color(0xFFF7A928);
  static const amberSoft = Color(0xFFFFF6E5);
  static const amberInk = Color(0xFF8A5A08);
  static const amberLine = Color(0xFFF8DDA9);

  static const green = Color(0xFF0F7552);
  static const greenSoft = Color(0xFFE7F6EF);
  static const greenLine = Color(0xFFB5E6CF);

  static const rose = Color(0xFFC0323F);
  static const roseSoft = Color(0xFFFDECEE);
  static const roseLine = Color(0xFFF6CDD1);

  static const purple = Color(0xFF5B3FA8);
  static const purpleInk = Color(0xFF6941C6);
  static const purpleSoft = Color(0xFFF3EFFC);

  /// Logo coral. Only in the "steps" stripe.
  static const coral = Color(0xFFD63A4C);

  // ── Surfaces and lines ──────────────────────────────────────────────────
  static const surface = Color(0xFFF3F5F8);
  static const paper = Color(0xFFFFFFFF);
  static const line = Color(0xFFE4E7EC);
  static const line2 = Color(0xFFD0D5DD);

  /// Loading placeholders (`.sk`, `.skel i`).
  static const skeleton = Color(0xFFE9ECF2);

  /// Hover and table-head fill.
  static const head = Color(0xFFF8F9FB);

  /// Disabled button fill and its text.
  static const disabledFill = Color(0xFFE4E7EC);
  static const disabledText = Color(0xFF7A8291);

  /// The dim behind a sheet or dialog.
  static const scrim = Color(0x8C0A1226);

  // ── Fixed for contrast (plan §3.5) ──────────────────────────────────────
  static const chevron = Color(0xFF808999);
  static const placeholder = Color(0xFF6B7385);
  static const whatsapp = Color(0xFF0F7A41);
  static const alertBadge = Color(0xFFD63A4C);

  /// The 2px focus ring.
  static const focus = primary;

  // ── Notes: the text colour on each soft fill ────────────────────────────
  static const noteRoseText = Color(0xFF8F1E29);
  static const noteBlueText = Color(0xFF1C318C);
  static const noteGreenText = Color(0xFF0B5A3F);

  /// The text in a WhatsApp message bubble on its green fill (19.12).
  static const bubbleGreenText = Color(0xFF0B3D2B);

  // ── Charts and Ask Atom ─────────────────────────────────────────────────
  /// `.bars i`: a bar that isn't picked (13.6).
  static const chartBar = Color(0xFF7890E8);

  /// `.confirm` text on its amber fill (Ask Atom, 13.12).
  static const confirmText = Color(0xFF5C3D06);

  // ── Toast ───────────────────────────────────────────────────────────────
  static const toastOkIcon = Color(0xFF7BE3B9);
  static const toastLink = Color(0xFFAFC0FF);

  // ── On the navy screens (`.dark`: splash, lock, tour) ───────────────────
  /// `.dark .pill.on`: rgba(15,117,82,.22) fill, #7BE3B9 text,
  /// rgba(123,227,185,.25) line.
  static const darkGreenFill = Color(0x380F7552);
  static const darkGreen = Color(0xFF7BE3B9);
  static const darkGreenLine = Color(0x407BE3B9);

  /// A problem on navy: "Wrong PIN", the 3.2 lock tile.
  static const darkRose = Color(0xFFFF9AA5);

  /// The 3.2 lock tile: rgba(192,50,63,.18).
  static const darkRoseFill = Color(0x2EC0323F);

  /// A warning icon on navy.
  static const darkAmber = Color(0xFFFFD27F);

  /// `.dark .dots i` and the tour's dots: an empty dot on navy.
  static const darkDot = Color(0xFF4A5B85);

  /// The ring behind 4.4's tick: #F3FBF7.
  static const greenHalo = Color(0xFFF3FBF7);

  /// An unread notification row (16.1 `.nt.new`): #F7F9FE.
  static const unreadRow = Color(0xFFF7F9FE);

  /// Light text on navy (16.3 and 16.8 `#D6DCEB`).
  static const navSoftText = Color(0xFFD6DCEB);

  // Customers and leads (8.x, 9.x).

  /// 8.13 `.missing p`: the text in the "CNIC not added yet" card.
  static const missingText = Color(0xFF5C3D06);

  /// 8.4 `.read .th`: a CNIC thumbnail on the green "read" strip.
  static const readThumb = Color(0xFFCFE9DC);

  /// 8.3 `.card-frame.ok`: rgba(123,227,185,.08) inside a saved frame.
  static const frameOkFill = Color(0x147BE3B9);

  // Home and Collections (5.x, 6.x).

  /// 5.1 `.btn-light:hover`: a white button pressed on navy.
  static const lightPressed = Color(0xFFEEF1F7);

  /// 5.1 `.hero .bar`: the part of the day still to collect.
  static const heroBarRest = Color(0xFF3A4B7A);

  /// 5.1 `.pipe`: the order steps, lightest first.
  static const pipe1 = Color(0xFFC9D4F8);
  static const pipe2 = Color(0xFF9DB0F0);
  static const pipe3 = Color(0xFF6F8BE6);
  static const pipe4 = Color(0xFF4766D6);

  /// 6.4 `.ico` halo: the ring round the received tick.
  static const paidHalo = Color(0xFFE0F2EA);

  /// 6.3 `.k2 button:hover`: a key pressed.
  static const keyPressed = Color(0xFFE9ECF2);

  /// 6.5 `.msg`: the WhatsApp message bubble's text.
  static const waBubbleText = Color(0xFF0B3D2B);

  /// 5.6 `mark`: a search match.
  static const searchMark = Color(0xFFFFF0C7);

  /// 6.3 `.cal button[disabled]`: a future day.
  static const calendarOff = Color(0xFFC1C7D0);

  /// 10.4 / 10.5 `.frame`, `.fr`: the white scan frame on navy (85–90%).
  static const scanFrame = Color(0xE6FFFFFF);
}

/// A soft status colour set: text on [bg], with a hairline [border].
@immutable
class AtomTone {
  const AtomTone({required this.fg, required this.bg, required this.border});

  final Color fg;
  final Color bg;
  final Color border;

  /// Used for online, paid and success.
  static const green = AtomTone(
    fg: AtomColors.green,
    bg: AtomColors.greenSoft,
    border: AtomColors.greenLine,
  );

  /// Used for offline, due and waiting.
  static const amber = AtomTone(
    fg: AtomColors.amberInk,
    bg: AtomColors.amberSoft,
    border: AtomColors.amberLine,
  );

  /// Used for error, late and on hold.
  static const rose = AtomTone(
    fg: AtomColors.rose,
    bg: AtomColors.roseSoft,
    border: AtomColors.roseLine,
  );

  /// Used for information and the primary tag.
  static const blue = AtomTone(
    fg: AtomColors.primary,
    bg: AtomColors.primarySoft,
    border: AtomColors.primaryLine,
  );

  static const grey = AtomTone(
    fg: AtomColors.text,
    bg: AtomColors.surface,
    border: AtomColors.line,
  );

  static const purple = AtomTone(
    fg: AtomColors.purpleInk,
    bg: AtomColors.purpleSoft,
    border: AtomColors.purpleSoft,
  );
}
