import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../states/ui/state_screens.dart' show NoInternetBody;
import '../../sync/data/offline_saves.dart';
import '../../sync/ui/saved_here_sheet.dart' show showSavedHereToast;
import '../data/stock_models.dart';

/// Pieces shared by the stock screens (9.x).

Who? stockWho(WidgetRef ref) => switch (ref.watch(sessionProvider)) {
  SignedIn(:final session) => session.who,
  _ => null,
};

BrandSession? stockSession(WidgetRef ref) =>
    switch (ref.watch(sessionProvider)) {
      SignedIn(:final session) => session,
      _ => null,
    };

/// Stock in, move and adjust may run: the role, and the add-on not lapsed.
bool canChangeStock(Who? who, StockAccess access) =>
    (who?.can(BrandPermission.stockChange) ?? false) && !access.readOnly;

/// Warehouses may be added and edited.
bool canManageStock(Who? who, StockAccess access) =>
    (who?.can(BrandPermission.stockManage) ?? false) && !access.readOnly;

/// The server's 403 reason (`inventory` or `read_only`), if any.
String? stockRefusal(ApiFailure f) =>
    Json.str(Json.map(f.body?['data'])['reason']);

/// The words for a failed stock call.
String sayStockFailure(BuildContext context, ApiFailure f) {
  final l = AppLocalizations.of(context);
  return switch (stockRefusal(f)) {
    'inventory' => l.stockOffMessage,
    'read_only' => l.stockReadOnlyMessage,
    _ => sayFailure(l, f),
  };
}

/// Says how a save ended: sent, waiting on the phone, or refused. True
/// when it is saved (here or on the server).
bool sayStockSaved<T>(
  BuildContext context,
  Saved<T> saved, {
  required String done,
}) {
  switch (saved) {
    case SavedOnServer():
      showAtomToast(context, kind: AtomToastKind.ok, message: done);
      return true;
    case SavedHere():
      showSavedHereToast(context);
      return true;
    case SaveFailed(:final failure):
      showAtomToast(
        context,
        kind: AtomToastKind.bad,
        message: sayStockFailure(context, failure),
      );
      return false;
  }
}

/// A whole-screen failure: no signal, the add-on off, or Try again.
class StockFailed extends StatelessWidget {
  const StockFailed({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final e = error;
    if (e is ApiFailure &&
        (e.kind == ApiFailureKind.offline ||
            e.kind == ApiFailureKind.timeout)) {
      return NoInternetBody(onRetry: onRetry);
    }
    if (e is ApiFailure &&
        (stockRefusal(e) == 'inventory' ||
            e.kind == ApiFailureKind.featureOff)) {
      return Center(
        child: AtomMessageState(
          icon: LucideIcons.package,
          title: l.stockOffTitle,
          body: l.stockOffBody,
        ),
      );
    }
    if (e is ApiFailure && e.kind == ApiFailureKind.notFound) {
      return Center(
        child: AtomMessageState(
          icon: LucideIcons.searchX,
          title: l.stockNotFoundTitle,
          body: l.stockNotFoundBody,
        ),
      );
    }
    return AtomErrorState(
      // A 403 shows "Your role doesn't include this" (13.3).
      error: e,
      message: e is ApiFailure ? e.message : null,
      onRetry: onRetry,
    );
  }
}

/// A white card (`.card`).
class StockCard extends StatelessWidget {
  const StockCard({super.key, required this.child, this.padding, this.tone});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// A tinted card (the out-of-stock alert). Rose uses the canvas's
  /// paler `#FFF8F8` so a rose icon tile still shows on it.
  final AtomTone? tone;

  static const _roseCard = Color(0xFFFFF8F8);

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    clipBehavior: Clip.antiAlias,
    decoration: tone == null
        ? AtomDecor.card
        : BoxDecoration(
            color: tone == AtomTone.rose ? _roseCard : tone!.bg,
            borderRadius: AtomRadius.brCard,
            border: Border.all(color: tone!.border),
          ),
    child: child,
  );
}

/// A card with a heading (`.blk h2`), as on the product page.
class StockBlock extends StatelessWidget {
  const StockBlock({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => StockCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: AtomText.listTitle.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        child,
      ],
    ),
  );
}

/// Rows in a card with lines between them.
class StockRows extends StatelessWidget {
  const StockRows({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => StockCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            const Divider(height: 1, thickness: 1, color: AtomColors.line),
          children[i],
        ],
      ],
    ),
  );
}

/// The small square status tag (`.st`).
class StockTag extends StatelessWidget {
  const StockTag({super.key, required this.label, required this.tone});

  final String label;
  final AtomTone tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    constraints: const BoxConstraints(minHeight: 20),
    decoration: BoxDecoration(color: tone.bg, borderRadius: AtomRadius.brTag),
    child: Text(label, style: AtomText.tag.copyWith(color: tone.fg)),
  );
}

AtomTone stateTone(String state) => switch (state) {
  'out' => AtomTone.rose,
  'low' => AtomTone.amber,
  _ => AtomTone.green,
};

/// The figure's colour for a level.
Color stateInk(String state) => switch (state) {
  'out' => AtomColors.rose,
  'low' => AtomColors.amberInk,
  _ => AtomColors.ink,
};

/// The level bar (`.lvl`): available, then held.
class StockLevelBar extends StatelessWidget {
  const StockLevelBar({
    super.key,
    required this.available,
    required this.held,
    required this.state,
    required this.semanticLabel,
  });

  final double available;
  final double held;
  final String state;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    child: ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 6,
          color: AtomColors.surface,
          child: LayoutBuilder(
            builder: (context, box) => Row(
              children: [
                Container(
                  width: box.maxWidth * available,
                  color: state == 'in' ? AtomColors.green : AtomColors.amber,
                ),
                Container(width: box.maxWidth * held, color: AtomColors.pipe2),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// `.line` rows with the line between them (`.line + .line`).
class StockLines extends StatelessWidget {
  const StockLines({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0)
          const Divider(height: 1, thickness: 1, color: AtomColors.line),
        children[i],
      ],
    ],
  );
}

/// The white flow bar with the line under it, as the stock forms draw it.
class StockFormBar extends StatelessWidget {
  const StockFormBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AtomColors.paper,
      border: Border(bottom: BorderSide(color: AtomColors.line)),
    ),
    child: AtomFlowBar(leading: AtomFlowLeading.close, title: title),
  );
}

/// The board's borderless Cancel (`.btn-outline` with a transparent
/// border and fill): 50 high, ink text.
class StockCancelButton extends StatelessWidget {
  const StockCancelButton({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AtomPressable(
    onTap: onTap ?? () => Navigator.of(context).maybePop(),
    semanticLabel: label,
    scaleOnPress: false,
    builder: (context, pressed) => Container(
      constraints: const BoxConstraints(minHeight: 50),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: pressed ? AtomColors.head : null,
        borderRadius: AtomRadius.brControl,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AtomText.button.copyWith(color: AtomColors.ink),
      ),
    ),
  );
}

/// A label and a value on one line (`.line`).
class StockLine extends StatelessWidget {
  const StockLine({super.key, required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AtomText.secondary),
        const SizedBox(width: 12),
        Expanded(
          child: Align(alignment: AlignmentDirectional.centerEnd, child: value),
        ),
      ],
    ),
  );
}

/// A bold value for [StockLine].
Widget stockValue(String text) => Text(
  text,
  textAlign: TextAlign.end,
  style: AtomText.body.copyWith(
    fontWeight: FontWeight.w600,
    color: AtomColors.ink,
  ),
);

/// A round tinted icon (`.ico`).
class StockIcon extends StatelessWidget {
  const StockIcon({
    super.key,
    required this.icon,
    this.tone = AtomTone.blue,
    this.size = 36,
  });

  final IconData icon;
  final AtomTone tone;
  final double size;

  @override
  Widget build(BuildContext context) =>
      AtomIconTile(icon: icon, tone: tone, size: size);
}

/// A "Choose…" box that opens a select sheet: the canvas's `.input.sel`
/// with a second line.
class StockPickBox extends StatelessWidget {
  const StockPickBox({
    super.key,
    required this.label,
    required this.text,
    required this.onTap,
    this.subtitle,
    this.placeholder,
  });

  final String label;
  final String? text;
  final String? subtitle;

  /// Shown while nothing is chosen; "Choose" when null.
  final String? placeholder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final placeholder =
        this.placeholder ?? AppLocalizations.of(context).commonChoose;
    return AtomField(
      label: label,
      child: AtomPressable(
        onTap: onTap,
        semanticLabel: '$label: ${text ?? placeholder}',
        scaleOnPress: false,
        builder: (context, pressed) => Container(
          constraints: const BoxConstraints(minHeight: AtomSize.control),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: pressed ? AtomColors.surface : AtomColors.paper,
            borderRadius: AtomRadius.brControl,
            border: Border.all(color: AtomColors.line2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text ?? placeholder,
                      style: AtomText.input.copyWith(
                        color: text == null
                            ? AtomColors.placeholder
                            : AtomColors.ink,
                      ),
                    ),
                    if (subtitle != null && text != null)
                      Text(subtitle!, style: AtomText.small),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronDown,
                size: AtomIcon.row,
                color: AtomColors.chevron,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tinted round button for the home's action grid (`.acts4 a`).
class StockActionTile extends StatelessWidget {
  const StockActionTile({
    super.key,
    required this.icon,
    required this.tone,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final AtomTone tone;
  final String label;

  /// Null greys it out (stock read-only).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onTap == null ? 0.45 : 1,
    child: AtomPressable(
      onTap: onTap,
      semanticLabel: label,
      builder: (context, pressed) => Container(
        // Fills its grid cell (`.acts4`: four equal columns).
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: pressed ? AtomColors.surface : AtomColors.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AtomColors.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AtomIconTile(icon: icon, tone: tone, size: 36),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AtomText.small.copyWith(
                fontWeight: FontWeight.w600,
                color: AtomColors.ink,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A day box that opens the past-day sheet ("Today, 13 Nov").
class StockDayBox extends StatelessWidget {
  const StockDayBox({
    super.key,
    required this.label,
    required this.day,
    required this.onChanged,
  });

  final String label;
  final DateTime day;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = DateTime(day.year, day.month, day.day) == today;
    final text = isToday
        ? AppLocalizations.of(context).stockTodayDay(_short(day))
        : _short(day);
    return StockPickBox(
      label: label,
      text: text,
      onTap: () async {
        final picked = await showPastDaySheet(
          context,
          selected: day,
          today: today,
          title: label,
        );
        if (picked != null) onChanged(picked);
      },
    );
  }

  static String _short(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}

/// A filter chip that opens a choice (`.fchip`).
class StockFilterChip extends StatelessWidget {
  const StockFilterChip({
    super.key,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) => AtomPressable(
    onTap: onTap,
    semanticLabel: label,
    scaleOnPress: false,
    focusRadius: AtomRadius.brControl,
    builder: (context, pressed) => Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? AtomColors.primarySoft
            : (pressed ? AtomColors.surface : AtomColors.paper),
        borderRadius: AtomRadius.brControl,
        border: Border.all(
          color: active ? AtomColors.primaryLine : AtomColors.line2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AtomText.smallButton.copyWith(
                color: active ? AtomColors.primary : AtomColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            LucideIcons.chevronDown,
            size: 14,
            color: active ? AtomColors.primary : AtomColors.muted,
          ),
        ],
      ),
    ),
  );
}

/// Pads a screen's content at the gutter.
const stockGutter = EdgeInsets.symmetric(horizontal: AtomSpace.gutter);

/// Skeleton cards while a screen loads; scrolls rather than overflow on a
/// short phone.
class StockLoading extends StatelessWidget {
  const StockLoading({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.all(16),
    child: AtomLoadingCard(count: count),
  );
}

/// Two fields side by side, or one under the other when there's no room.
class StockTwoUp extends StatelessWidget {
  const StockTwoUp({super.key, required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
      if (box.maxWidth < 280 || scale > 1.3) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [first, second],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Expanded(child: first),
          Expanded(child: second),
        ],
      );
    },
  );
}

/// A route shown as a v2 bottom sheet (the grab, the dim, back closes it),
/// e.g. Adjust stock (9.7).
class StockSheetPage<T> extends Page<T> {
  const StockSheetPage({required this.child, super.key});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => ModalBottomSheetRoute<T>(
    settings: this,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AtomColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final keyboard = MediaQuery.viewInsetsOf(context).bottom;
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AtomColors.line2,
                    borderRadius: AtomRadius.brPill,
                  ),
                ),
              ),
              Flexible(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      );
    },
  );
}
