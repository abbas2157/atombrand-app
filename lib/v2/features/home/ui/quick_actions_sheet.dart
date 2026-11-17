import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import 'home_parts.dart';

/// One quick action.
@immutable
class QuickAction {
  const QuickAction({
    required this.id,
    required this.title,
    required this.sub,
    required this.path,
    this.tab = false,
  });

  final String id;
  final String title;
  final String sub;
  final String path;

  /// Switches tabs rather than opening over them.
  final bool tab;
}

/// What the ＋ offers this person (5.6): only what the role allows, and
/// the add-on parts only when the add-on is on.
List<QuickAction> quickActionsFor(
  Who who,
  AccessState access,
  AppLocalizations l,
) => [
  if (who.can(BrandPermission.catalogueEdit))
    QuickAction(
      id: 'product',
      title: l.homeAddProduct,
      sub: l.homeAddProductSub,
      path: V2Routes.productNew,
    ),
  if (access.has(Addon.inventory) && who.can(BrandPermission.stockChange))
    QuickAction(
      id: 'stock',
      title: l.homeStockIn,
      sub: l.homeStockInSub,
      path: V2Routes.stockIn(),
    ),
  if (who.can(BrandPermission.ordersPayment))
    QuickAction(
      id: 'payment',
      title: l.homeRecordPayment,
      sub: l.homeRecordPaymentSub,
      path: V2Routes.orders,
      tab: true,
    ),
  if (who.can(BrandPermission.bulkQuote))
    QuickAction(
      id: 'quote',
      title: l.homeSendQuote,
      sub: l.homeSendQuoteSub,
      path: V2Routes.bulkTab('website'),
      tab: true,
    ),
  if (who.can(BrandPermission.atompayView))
    QuickAction(
      id: 'handover',
      title: l.homeHandOver,
      sub: l.homeHandOverSub,
      path: V2Routes.atompayOrders,
      tab: true,
    ),
  if (access.has(Addon.askAtom))
    QuickAction(
      id: 'ask',
      title: l.homeAskAtom,
      sub: l.homeAskAtomSub,
      path: V2Routes.askAtom,
    ),
];

/// Quick actions (5.6), the sheet behind the ＋.
class QuickActionsSheet extends ConsumerWidget {
  const QuickActionsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    ref.watch(sessionProvider);
    final who =
        ref.watch(sessionProvider.notifier).current?.who ?? const Who.owner();
    final actions = quickActionsFor(who, ref.watch(accessProvider), l);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(l.homeWhatToDo, style: AtomText.heading),
                    ),
                    const SizedBox(height: 2),
                    Text(l.homeOnlyYourRole, style: AtomText.secondary),
                  ],
                ),
              ),
              AtomPressable(
                onTap: () => Navigator.of(context).maybePop(),
                semanticLabel: l.commonClose,
                builder: (_, _) => const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    LucideIcons.x,
                    size: AtomIcon.bar,
                    color: AtomColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (actions.isEmpty)
            AtomNote(kind: AtomNoteKind.info, message: l.homeNothingForRole),
          for (final a in actions) ...[
            _Choice(action: a),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.action});
  final QuickAction action;

  @override
  Widget build(BuildContext context) {
    final a = action;
    final (IconData icon, AtomTone tone) = switch (a.id) {
      'product' => (LucideIcons.tag, AtomTone.blue),
      'stock' => (LucideIcons.package, AtomTone.green),
      'payment' => (LucideIcons.dollarSign, AtomTone.green),
      'quote' => (LucideIcons.fileText, AtomTone.amber),
      'handover' => (LucideIcons.creditCard, AtomTone.blue),
      _ => (LucideIcons.sparkle, AtomTone.blue),
    };
    return AtomPressable(
      onTap: () {
        // Close the sheet first, then go: a tab switch under an open
        // sheet would leave the sheet on top.
        final router = GoRouter.of(context);
        Navigator.of(context).pop();
        a.tab ? router.go(a.path) : router.push(a.path);
      },
      semanticLabel: '${a.title}, ${a.sub}',
      focusRadius: AtomRadius.brCard,
      builder: (_, pressed) => ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: pressed ? AtomColors.unreadRow : AtomColors.paper,
            borderRadius: AtomRadius.brCard,
            border: Border.all(
              color: pressed ? AtomColors.primaryLine : AtomColors.line,
            ),
          ),
          child: Row(
            children: [
              a.id == 'ask'
                  ? Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AtomRadius.brCard,
                        border: Border.all(color: AtomColors.line),
                      ),
                      child: const AtomAiMark(size: 30),
                    )
                  : Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tone.bg,
                        borderRadius: AtomRadius.brCard,
                      ),
                      child: Icon(icon, size: AtomIcon.row, color: tone.fg),
                    ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.title, style: AtomText.listTitle),
                    const SizedBox(height: 2),
                    Text(
                      a.sub,
                      style: AtomText.secondary.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A bottom sheet as a route page, so `context.push(V2Routes.quickActions)`
/// from the tab bar opens a sheet over the tabs.
class HomeSheetPage<T> extends Page<T> {
  const HomeSheetPage({super.key, required this.child});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => ModalBottomSheetRoute<T>(
    settings: this,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetGrab(),
          Flexible(child: SingleChildScrollView(child: child)),
        ],
      ),
    ),
  );
}
