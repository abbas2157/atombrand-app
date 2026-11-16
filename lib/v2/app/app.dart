import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atombrand_app/v2/core/services/fcm_service.dart';

import '../../l10n/app_localizations.dart';
import '../core/access/access_controller.dart';
import '../core/lock/app_lock.dart';
import '../core/net/network_status.dart';
import '../core/update/updates_controller.dart';
import '../features/auth/ui/unlock_screens.dart';
import '../features/notifications/data/notifications_repository.dart';
import '../features/notifications/ui/notifications_screens.dart';
import '../features/sync/data/sync_providers.dart';
import '../features/sync/data/sync_scheduler.dart';
import '../features/sync/ui/offline_gate.dart';
import 'routes.dart';
import '../design/design.dart';
import 'router.dart';
import '../core/api/atom_server.dart';
import 'splash_hold.dart';
import 'status_strip.dart';

/// The v2 app.
///
/// Text is not capped: v2 is designed for 200% (v1 capped it at 1.5×).
class BrandPartnerApp extends ConsumerWidget {
  const BrandPartnerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Brand Partner',
      debugShowCheckedModeBanner: false,
      theme: AtomTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: router,
      restorationScopeId: 'app',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        // Dark status-bar icons unless a screen says otherwise: a screen
        // with no app bar (Sign in, the offline-gate screens) otherwise
        // keeps the light icons of the navy screen before it, white on
        // white. Navy screens set their own light region over this.
        final app = AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: StatusStrip(
            router: router,
            child: _RefreshOnResume(child: child!),
          ),
        );
        // A build against a local server says so in the corner, so a
        // tester never mistakes it for the real shop's data.
        return _PhonesStayUpright(
          child: AtomServer.isLocal
              ? Banner(
                  message: 'LOCAL',
                  location: BannerLocation.topEnd,
                  child: app,
                )
              : app,
        );
      },
    );
  }
}

/// A phone stays upright; a tablet turns freely.
///
/// The way-in screens are drawn for a tall screen: on a phone laid on its
/// side the tour's art fills the window and pushes its heading out of
/// sight. A tablet keeps both ways round, where the rail (15.1) and the
/// side-by-side layouts (`AtomSize.splitBreakpoint`) are the point.
///
/// `shortestSide` is the same whichever way the screen is held, so this
/// settles once and never fights the turn it just asked for.
class _PhonesStayUpright extends StatefulWidget {
  const _PhonesStayUpright({required this.child});
  final Widget child;

  @override
  State<_PhonesStayUpright> createState() => _PhonesStayUprightState();
}

class _PhonesStayUprightState extends State<_PhonesStayUpright> {
  bool? _phone;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final phone =
        MediaQuery.sizeOf(context).shortestSide < AtomSize.tabletBreakpoint;
    if (phone == _phone) return;
    _phone = phone;
    SystemChrome.setPreferredOrientations(
      phone ? const [DeviceOrientation.portraitUp] : DeviceOrientation.values,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Add-ons and the billing state are read again whenever the app comes back
/// to the front, so a plan paid on the web shows at once. Push taps open
/// their screen, and a push while the app is open drops in as a banner
/// (16.6).
class _RefreshOnResume extends ConsumerStatefulWidget {
  const _RefreshOnResume({required this.child});
  final Widget child;

  @override
  ConsumerState<_RefreshOnResume> createState() => _RefreshOnResumeState();
}

class _RefreshOnResumeState extends ConsumerState<_RefreshOnResume> {
  late final AppLifecycleListener _listener;
  ({String title, String body, Map<String, dynamic> data})? _banner;

  @override
  void initState() {
    super.initState();
    // Listening starts the sync triggers: the app opening, the connection
    // coming back, and the timer while it is open. Listened, not read:
    // Riverpod 3 pauses a provider no one listens to, and the scheduler's
    // own listens with it, so the network stream stopped after its first
    // answer and a payment saved offline waited for the next resume (seen
    // on a OnePlus, 9 Nov).
    ref.listenManual(syncSchedulerProvider, (_, _) {});
    // And these open the two photo folders. They have to be started
    // here rather than left to the first sync: a phone opened in a
    // basement never gets that far, and then a payment photographed
    // there would be queued without its photo, and a customer's face
    // already on the phone would not be found.
    ref
      ..read(outboxFilesProvider)
      ..read(copyPhotosProvider);
    _listener = AppLifecycleListener(
      onPause: () {
        ref.read(appLockProvider.notifier).paused();
        ref.read(syncSchedulerProvider).paused();
        // A downloaded update installs a little after the seller leaves
        // from a main tab, never from a form and never mid-sync.
        final path = ref
            .read(routerProvider)
            .routerDelegate
            .currentConfiguration
            .uri
            .path;
        ref
            .read(updatesProvider.notifier)
            .paused(
              onTab: V2Routes.tabs.contains(path),
              busy: () => ref.read(syncStatusProvider).running,
            );
      },
      onResume: () {
        ref.read(appLockProvider.notifier).resumed();
        ref.read(updatesProvider.notifier).resumed();
        ref.read(syncSchedulerProvider).resumed();
        // The radio may have come and gone while the app was away, and a
        // phone that missed the event would otherwise stay on "No
        // internet" until something else happened to ask.
        ref.invalidate(onlineProvider);
        ref.read(accessProvider.notifier)
          ..checkVersion()
          ..refreshIfStale();
      },
    );
    FcmService.onOpen = _open;
    // Atomshop says to check for an update now: ask the server again, and
    // let the gate follow.
    FcmService.onAppUpdate = () async {
      await ref.read(updatesProvider.notifier).check(force: true);
      await ref.read(accessProvider.notifier).checkVersion();
    };
    FcmService.onForeground = (title, body, data) {
      if (!mounted) return;
      ref.invalidate(noticesProvider);
      setState(() => _banner = (title: title, body: body, data: data));
    };
  }

  /// A push's screen, or Notifications when it has none of its own.
  void _open(Map<String, dynamic> data) {
    final router = ref.read(routerProvider);
    final t = noticeTarget(data);
    if (t == null) {
      router.push(V2Routes.notifications);
    } else if (t.tab) {
      router.go(t.path);
    } else {
      router.push(t.path);
    }
  }

  @override
  void dispose() {
    _listener.dispose();
    FcmService.onOpen = null;
    FcmService.onForeground = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = _banner;
    // Locked, unless the person chose to sign in with the password: then
    // Sign in shows (guards) and the lock waits behind it.
    final splash = ref.watch(splashHoldProvider);
    final locked =
        !splash &&
        ref.watch(appLockProvider.select((s) => s.locked && !s.passwordMode));
    // Inside the lock, not outside it: a phone that has been on its own
    // too long (11.6) or whose add-on has ended (11.7) still asks for
    // the PIN first.
    final app = OfflineGate(child: widget.child);
    if (b == null && !locked) return app;
    return Stack(
      children: [
        // Behind the lock, the app isn't read out by a screen reader.
        ExcludeSemantics(excluding: locked, child: app),
        if (locked) const Positioned.fill(child: UnlockGate()),
        if (b != null && !locked)
          Align(
            alignment: Alignment.topCenter,
            child: InAppBanner(
              key: ObjectKey(b),
              title: b.title,
              body: b.body,
              data: b.data,
              onOpen: () {
                setState(() => _banner = null);
                _open(b.data);
              },
              onClose: () => setState(() => _banner = null),
            ),
          ),
      ],
    );
  }
}
