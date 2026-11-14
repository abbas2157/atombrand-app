import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/dates.dart';
import '../../../core/net/network_status.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/billing_models.dart';
import '../data/billing_repository.dart';
import '../data/plan_logic.dart';

/// What each add-on does (12.7), in the canvas's words.
List<String> addonFeatures(AppLocalizations l, Addon? a) => switch (a) {
  Addon.inventory => [
    l.acctFeatInventory1,
    l.acctFeatInventory2,
    l.acctFeatInventory3,
  ],
  Addon.team => [l.acctFeatTeam1, l.acctFeatTeam2, l.acctFeatTeam3],
  Addon.askAtom => [l.acctFeatAskAtom1, l.acctFeatAskAtom2, l.acctFeatAskAtom3],
  Addon.alerts => [l.acctFeatAlerts1, l.acctFeatAlerts2, l.acctFeatAlerts3],
  Addon.offline => [l.acctFeatOffline1, l.acctFeatOffline2, l.acctFeatOffline3],
  _ => const <String>[],
};

/// Switch an add-on on (12.7), as a sheet over Plan & billing: what it
/// does, then the one thing that can happen now (try free, switch on and
/// pay, switch off, or keep it on).
class AddonSwitchSheet extends ConsumerStatefulWidget {
  const AddonSwitchSheet({super.key, required this.addonKey});
  final String addonKey;

  @override
  ConsumerState<AddonSwitchSheet> createState() => _AddonSwitchSheetState();
}

class _AddonSwitchSheetState extends ConsumerState<AddonSwitchSheet> {
  bool _saving = false;

  Future<void> _switch(BillingAddon a, bool on) async {
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    final r = await ref.read(billingRepositoryProvider).switchAddon(a.key, on);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (r) {
      case ApiOk(:final value):
        ref.invalidate(billingProvider);
        unawaited(ref.read(accessProvider.notifier).refresh());
        final router = GoRouter.of(context);
        final bill = value.invoice;
        // The toast first: this sheet's context is gone once it closes.
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: switch (value.status) {
            'trial' => l.acctAddonTrialStarted(a.name),
            'off' => l.acctAddonIsOff(a.name),
            _ when !on => l.acctAddonStopsAtEnd(a.name),
            _ when bill != null && bill.open => l.acctBillReady(bill.number),
            _ => l.acctAddonIsOn(a.name),
          },
        );
        Navigator.of(context).maybePop();
        if (bill != null && bill.open && bill.due > 0) {
          router.push(V2Routes.paidOf(bill: bill.number));
        }
      case ApiErr(:final failure):
        showAtomToast(
          context,
          kind: AtomToastKind.bad,
          message:
              failure.fieldErrors.values.firstOrNull ?? sayFailure(l, failure),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(billingProvider);
    final online = ref.watch(onlineProvider).value ?? true;
    final bottom = 16 + MediaQuery.paddingOf(context).bottom;
    return data.when(
      skipLoadingOnRefresh: true,
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: AtomLoadingRows(count: 3),
      ),
      error: (e, _) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
        child: AtomErrorState(
          message: e is ApiFailure ? sayFailure(l, e) : null,
          onRetry: () => ref.invalidate(billingProvider),
        ),
      ),
      data: (p) {
        final a = p.addons.where((x) => x.key == widget.addonKey).firstOrNull;
        if (a == null) {
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, bottom),
            child: AtomMessageState(
              icon: LucideIcons.package,
              title: l.acctAddonNotSold,
              art: false,
            ),
          );
        }
        final choice = addonChoice(a);
        final legacy = a.state == AddonState.legacy;
        final feats = addonFeatures(l, a.addon);
        final trialDays = a.trialDays ?? p.item(a.key)?.trialDays ?? 15;
        final (title, sub, cta) = switch (choice) {
          AddonChoice.tryFree => (
            l.acctAddonTryTitle(trialDays),
            l.acctAddonTrySub,
            l.acctAddonTryCta,
          ),
          AddonChoice.payNow => (
            l.acctAddonPayTitle,
            l.acctAddonPaySub,
            l.acctSwitchOn,
          ),
          AddonChoice.keepOn => (
            l.acctAddonKeepOn,
            a.endsOn == null
                ? l.acctAddonCarriesOn
                : l.acctAddonWasStopping(AtomDates.short(a.endsOn!)),
            l.acctAddonKeepOn,
          ),
          AddonChoice.switchOff => (
            l.acctAddonOffTitle,
            a.state == AddonState.trial
                ? l.acctAddonOffTrial
                : legacy
                ? l.acctAddonOffLegacy
                : a.endsOn == null
                ? l.acctAddonOffPeriodEnd
                : l.acctAddonOffUntil(AtomDates.short(a.endsOn!)),
            l.acctSwitchOff,
          ),
        };
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(a.name, style: AtomText.heading),
              ),
              if (a.description != null) ...[
                const SizedBox(height: 4),
                Text(a.description!, style: AtomText.secondary),
              ],
              const SizedBox(height: 12),
              for (final f in feats)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        LucideIcons.check,
                        size: AtomIcon.inline,
                        color: AtomColors.green,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(f, style: AtomText.body)),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              if (legacy) ...[
                AtomNote(
                  kind: AtomNoteKind.success,
                  title: l.acctAddonFreeUntilDot(
                    AtomDates.day(a.legacyUntil ?? DateTime(2026, 12, 31)),
                  ),
                  message: l.acctAddonAfterLegacy,
                ),
                const SizedBox(height: 12),
              ],
              if (a.state == AddonState.lapsed) ...[
                AtomNote(kind: AtomNoteKind.warning, message: l.acctAddonEnded),
                const SizedBox(height: 12),
              ],
              AtomOptionCard(
                title: title,
                subtitle: sub,
                selected: true,
                onTap: () {},
              ),
              const SizedBox(height: 14),
              if (!online) AtomButtonReason(reason: l.syncNeedsInternet),
              AtomButton(
                label: cta,
                kind: choice == AddonChoice.switchOff
                    ? AtomButtonKind.danger
                    : AtomButtonKind.primary,
                saving: _saving,
                onPressed: online
                    ? () => _switch(a, choice != AddonChoice.switchOff)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A route page that shows [child] as a bottom sheet over the page under
/// it, so 12.7 keeps its own address (`/menu/plan/addon/:key`).
class AccountSheetPage<T> extends Page<T> {
  const AccountSheetPage({super.key, required this.child});
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => ModalBottomSheetRoute<T>(
    settings: this,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AtomColors.paper,
    shape: const RoundedRectangleBorder(borderRadius: AtomRadius.brSheetTop),
    showDragHandle: true,
    builder: (_) => child,
  );
}
