import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/router.dart' show routerProvider;
import '../../../app/routes.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/format/dates.dart';
import '../../../core/net/network_status.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/sync_engine.dart';
import '../data/sync_providers.dart';
import 'sync_parts.dart';

/// The offline states that stand in front of the whole app:
///
/// - **Account on hold (3.5)**: `sync/check` said `wipe`. The copy and
///   this person's unsent changes are gone and the session has ended; the
///   server's reason stays on screen until they carry on. Any brand.
/// - **Offline add-on ended (10.10)**: the outbox is sent, then the copy is
///   deleted and the phone works online only.
/// - **Offline limit reached (3.4)**: the phone has been on its own past
///   `offline.until` (30 days, or the plan's paid-until). Nothing is lost.
/// - **No internet (10.9)**: a brand without the add-on has no copy and no
///   outbox, so with no signal it can only wait. The screen under stays
///   mounted, so what was being typed is still there when the signal
///   comes back.
///
/// Without the Offline add-on the PIN and fingerprint only unlock an online
/// session, the Sync centre is hidden (`routeRules`), and only 3.5 and 10.9
/// can show.
class OfflineGate extends ConsumerWidget {
  const OfflineGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(accountHoldProvider) case final reason?) {
      return _Hold(reason: reason);
    }
    final access = ref.watch(accessProvider);
    final signedIn = ref.watch(sessionProvider) is SignedIn;
    if (!access.has(Addon.offline)) {
      // Add-ons not known yet: nothing to decide on.
      if (!signedIn || access.addons == null) return child;
      final online = ref.watch(onlineProvider).value ?? true;
      if (online) return child;
      return Stack(
        children: [
          ExcludeSemantics(child: child),
          const Positioned.fill(child: _NoInternet()),
        ],
      );
    }
    final status = ref.watch(syncStatusProvider);
    if (status.stop == SyncStop.offlineEnded) {
      // Check it: the attention screens show through until nothing needs
      // the person, then this screen comes back to delete the copy.
      if (ref.watch(_peekProvider) && status.attention > 0) return child;
      return const _Ended();
    }
    if (pastTheWindow(status, DateTime.now())) return const _Limit();
    return child;
  }

  /// The phone has been on its own longer than the add-on allows. Only
  /// once the phone has been told (`offline_until` from `sync/check`), so a
  /// phone that has never synced is not held here.
  @visibleForTesting
  static bool pastTheWindow(SyncStatus s, DateTime now) {
    if (!s.loaded) return false;
    final until = s.offlineUntil;
    if (until == null) return false;
    return now.isAfter(until);
  }
}

/// The full-screen layout these share: centred icon, title, body, then
/// the buttons at the bottom.
class _Screen extends StatelessWidget {
  const _Screen({
    required this.content,
    required this.buttons,
    this.top,
    this.centre = true,
  });

  final List<Widget> content;
  final List<Widget> buttons;
  final Widget? top;
  final bool centre;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AtomColors.paper,
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?top,
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: Column(
                    mainAxisAlignment: centre
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    crossAxisAlignment: centre
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      if (!centre) const SizedBox(height: 30),
                      ...content,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: buttons,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _bigIcon(IconData icon, AtomTone tone) => Container(
  width: 76,
  height: 76,
  decoration: BoxDecoration(
    color: tone.bg,
    borderRadius: const BorderRadius.all(Radius.circular(AtomRadius.sheet)),
  ),
  child: Icon(icon, size: 34, color: tone.fg),
);

Widget _title(String text, {bool centre = true}) => Padding(
  padding: const EdgeInsets.only(top: 14),
  child: Semantics(
    header: true,
    child: Text(
      text,
      textAlign: centre ? TextAlign.center : TextAlign.start,
      style: AtomText.successTitle,
    ),
  ),
);

Widget _body(String text, {bool centre = true}) => Padding(
  padding: const EdgeInsets.only(top: 12),
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 320),
    child: Text(
      text,
      textAlign: centre ? TextAlign.center : TextAlign.start,
      style: AtomText.body.copyWith(fontSize: 15, color: AtomColors.muted),
    ),
  ),
);

/// 3.5 Account on hold: this phone was signed out by the server.
class _Hold extends ConsumerWidget {
  const _Hold({required this.reason});

  final String reason;

  static const _wa = 'https://wa.me/923331214955';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return _Screen(
      content: [
        _bigIcon(LucideIcons.shieldAlert, AtomTone.rose),
        const SizedBox(height: 12),
        AtomPill(label: l.syncHoldTag, tone: AtomTone.rose),
        _title(l.syncHoldTitle),
        _body(reason.isEmpty ? l.syncHoldBody : reason),
        const SizedBox(height: 18),
        AtomNote(kind: AtomNoteKind.success, message: l.syncHoldSafe),
      ],
      buttons: [
        AtomButton(
          label: l.syncHoldWhatsApp,
          kind: AtomButtonKind.whatsapp,
          onPressed: () =>
              launchUrl(Uri.parse(_wa), mode: LaunchMode.externalApplication),
        ),
        const SizedBox(height: 10),
        AtomButton(
          label: l.syncHoldSignIn,
          kind: AtomButtonKind.outline,
          onPressed: () {
            ref.read(accountHoldProvider.notifier).clear();
            ref.read(routerProvider).go(V2Routes.signIn);
          },
        ),
      ],
    );
  }
}

/// 10.9 No internet, for a brand without the Offline add-on.
/// The phone's Wi-Fi settings (Android, `MainActivity`'s
/// `atombrand/settings` channel).
Future<void> _openWifiSettings() async {
  try {
    await const MethodChannel('atombrand/settings')
        .invokeMethod<void>('openWifiSettings');
  } catch (_) {
    // Not on this build: the phone's own settings are a swipe away.
  }
}

class _NoInternet extends ConsumerStatefulWidget {
  const _NoInternet();

  @override
  ConsumerState<_NoInternet> createState() => _NoInternetState();
}

class _NoInternetState extends ConsumerState<_NoInternet> {
  bool _busy = false;

  Future<void> _try() async {
    setState(() => _busy = true);
    await ref.read(networkStatusProvider).check();
    ref.invalidate(onlineProvider);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Screen(
      content: [
        _bigIcon(LucideIcons.wifiOff, AtomTone.grey),
        _title(l.noInternetTitle),
        _body(l.syncNoInternetBody),
        const SizedBox(height: 18),
        AtomNote(kind: AtomNoteKind.info, message: l.syncNoInternetDraft),
      ],
      buttons: [
        AtomButton(label: l.commonTryAgain, saving: _busy, onPressed: _try),
        if (!kIsWeb && Platform.isAndroid) ...[
          const SizedBox(height: 10),
          AtomButton(
            label: l.syncOpenWifi,
            kind: AtomButtonKind.outline,
            onPressed: _openWifiSettings,
          ),
        ],
        const SizedBox(height: 8),
        Text(
          l.noInternetAuto,
          textAlign: TextAlign.center,
          style: AtomText.small.copyWith(color: AtomColors.faint),
        ),
      ],
    );
  }
}

/// 10.10 Offline add-on ended: send, then delete the copy.
class _Ended extends ConsumerWidget {
  const _Ended();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final status = ref.watch(syncStatusProvider);
    final sending = status.running;
    final waiting = status.waiting;
    final sent = waiting == 0 && status.attention == 0;
    return _Screen(
      centre: false,
      content: [
        _bigIcon(LucideIcons.cloudOff, AtomTone.amber),
        _title(l.syncEndedTitle, centre: false),
        _body(l.syncEndedBodyFull, centre: false),
        const SizedBox(height: 16),
        SyncCard(
          children: [
            SyncStepRow(
              state: waiting == 0
                  ? SyncStepState.done
                  : sending
                  ? SyncStepState.running
                  : SyncStepState.waiting,
              label: l.syncEndedSend(
                waiting == 0 ? status.progress.sent : waiting,
              ),
              trailing: waiting == 0
                  ? l.syncStepDone
                  : sending
                  ? l.syncEndedSendingTag
                  : l.syncStepNext,
            ),
            if (status.photos > 0)
              SyncStepRow(
                state: sending ? SyncStepState.running : SyncStepState.waiting,
                label: l.syncEndedPhotos(status.photos),
                trailing: sending ? l.syncEndedSendingTag : l.syncStepNext,
              ),
            SyncStepRow(
              state: sent ? SyncStepState.done : SyncStepState.waiting,
              label: l.syncEndedDelete,
              trailing: sent ? l.syncStepDone : l.syncStepNext,
            ),
          ],
        ),
        if (status.attention > 0) ...[
          const SizedBox(height: 14),
          AtomNote(
            kind: AtomNoteKind.warning,
            message: l.syncEndedAttention(status.attention),
          ),
          const SizedBox(height: 8),
          AtomButton.small(
            label: l.syncCheckIt,
            // Above the router's navigator: pushed through the router.
            onPressed: () {
              ref.read(_peekProvider.notifier).state = true;
              ref.read(routerProvider).push(V2Routes.syncAttention);
            },
          ),
        ],
      ],
      buttons: [
        AtomButton(
          label: sent ? l.syncContinueOnline : l.syncNow,
          saving: sending,
          onPressed: sent
              ? () => ref.read(syncStatusProvider.notifier).carryOn()
              : () => ref.read(syncStatusProvider.notifier).syncNow(),
        ),
      ],
    );
  }
}

/// 3.4 Offline limit reached: connect once to carry on.
class _Limit extends ConsumerWidget {
  const _Limit();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final status = ref.watch(syncStatusProvider);
    final paid = status.check?.paidUntil;
    final until = status.offlineUntil;
    final planEnded =
        paid != null &&
        until != null &&
        AtomDates.daysFrom(until, today: paid) == 0;
    final last = status.lastSyncAt;
    final days = status.check?.offline.days ?? 30;
    return _Screen(
      top: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Center(
          child: AtomPill(label: l.syncOffBar, tone: AtomTone.amber, dot: true),
        ),
      ),
      content: [
        _bigIcon(LucideIcons.cloudOff, AtomTone.amber),
        _title(
          planEnded
              ? l.syncPlanEndedTitle(AtomDates.short(paid))
              : l.syncLimitTitle,
        ),
        _body(planEnded ? l.syncPlanEndedBody : l.syncLimitDays(days)),
        const SizedBox(height: 22),
        SyncCard(
          children: [
            if (status.waiting > 0)
              _InfoRow(
                icon: LucideIcons.clock,
                tone: AtomTone.blue,
                title: l.syncOffBarChanges(status.waiting),
                sub: '',
              ),
            _InfoRow(
              icon: LucideIcons.shieldCheck,
              tone: AtomTone.green,
              title: l.syncSafeHere,
              sub: l.syncSafeHereSub,
            ),
            _InfoRow(
              icon: LucideIcons.history,
              tone: AtomTone.grey,
              title: last == null
                  ? l.syncNotSyncedYet
                  : l.syncLastSynced(
                      '${AtomDates.short(last)}, ${AtomDates.time(last)}',
                    ),
              sub: planEnded ? '' : l.syncLimitAgo(days, l.syncLimitWhy),
            ),
          ],
        ),
      ],
      buttons: [
        AtomButton(
          label: l.commonTryAgain,
          icon: LucideIcons.refreshCw,
          saving: status.running,
          onPressed: () => ref.read(syncStatusProvider.notifier).syncNow(),
        ),
        if (!kIsWeb && Platform.isAndroid) ...[
          const SizedBox(height: 10),
          AtomButton(
            label: l.syncOpenWifi,
            kind: AtomButtonKind.outline,
            onPressed: _openWifiSettings,
          ),
        ],
        const SizedBox(height: 8),
        Text(
          l.syncLookUpOnly,
          textAlign: TextAlign.center,
          style: AtomText.small.copyWith(color: AtomColors.faint),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.tone,
    required this.title,
    required this.sub,
  });

  final IconData icon;
  final AtomTone tone;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
      children: [
        AtomIconTile(icon: icon, tone: tone, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AtomText.listTitle),
              if (sub.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(sub, style: AtomText.secondary),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// 10.10's Check it: let Needs attention show through the gate.
final _peekProvider = NotifierProvider<_Peek, bool>(_Peek.new);

class _Peek extends Notifier<bool> {
  @override
  bool build() => false;

  @override
  set state(bool value) => super.state = value;
}
