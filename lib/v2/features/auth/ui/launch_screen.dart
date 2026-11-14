import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/atom_brand.dart';

/// Splash: 1.1 on a first launch, 1.2 (a smaller tile and the shop under
/// the name) once a stored session is known. Shown while the session and
/// this phone's lock are read; the router moves on by itself.
///
/// 1.2's offline parts (the "Offline" pill, changes waiting to sync) belong
/// to the Offline add-on and are left out.
class LaunchScreen extends ConsumerWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final session = switch (ref.watch(sessionProvider)) {
      SignedIn(:final session) => session,
      _ => null,
    };
    final returning = session != null;
    final shop = session == null
        ? null
        : [
            if (session.brandName != null) session.brandName!,
            session.who.isOwner
                ? (session.outletName ?? l.auth2MainShop)
                : session.outletName,
          ].whereType<String>().join(' · ');
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AtomColors.nav,
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AtomBrandTile(
                        size: returning
                            ? AtomSize.splashTileReturning
                            : AtomSize.splashTile,
                        shadow: true,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        l.appName,
                        textAlign: TextAlign.center,
                        style: AtomText.amount.copyWith(
                          fontSize: returning ? 24 : 28,
                          color: Colors.white,
                          letterSpacing: returning ? -0.4 : -0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        returning && shop!.isNotEmpty ? shop : l.auth2Tagline,
                        textAlign: TextAlign.center,
                        style: AtomText.body.copyWith(
                          fontSize: 15,
                          color: AtomColors.navText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!returning)
              Padding(
                padding: EdgeInsets.only(bottom: 48 + bottom),
                child: Column(
                  children: [
                    const AtomStepsStripe(width: 96),
                    const SizedBox(height: 14),
                    _By(l: l),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "by **Atomshop.pk** · Pay in Steps".
class _By extends StatelessWidget {
  const _By({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    const brand = 'Atomshop.pk';
    final parts = l.auth2SplashBy('\u0000').split('\u0000');
    final base = AtomText.secondary.copyWith(color: AtomColors.navMuted);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: parts.first),
          const TextSpan(
            text: brand,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          if (parts.length > 1) TextSpan(text: parts[1]),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
