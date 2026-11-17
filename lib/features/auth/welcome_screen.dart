import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_icons.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../../widgets/feedback.dart';
import 'auth_illustrations.dart';
import 'auth_scaffold.dart';
import 'partner_content.dart';

/// Logo, product illustration, the partner pitch with marketplace numbers,
/// and the ways in (DESIGN.md §3.3). Copy: atomshop.pk/brand-partners.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final notice = session is SignedOut ? session.notice : null;

    return AuthTheme(
      child: Builder(
        builder: (context) {
          final p = AppPalette.of(context);
          final heroHeight = (MediaQuery.sizeOf(context).height * 0.3).clamp(170.0, 260.0);
          return Scaffold(
            backgroundColor: p.bg,
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                        sliver: SliverFillRemaining(
                          hasScrollBody: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(
                                height: 48,
                                child: Align(alignment: Alignment.centerLeft, child: BrandLogo.inline(height: 30)),
                              ),
                              const SizedBox(height: 16),
                              ProductsIllustration(height: heroHeight),
                              const SizedBox(height: 24),
                              Text(PartnerContent.headline, style: authTitleStyle(context)),
                              const SizedBox(height: 8),
                              Text(PartnerContent.pitch, style: authSubtitleStyle(context)),
                              const SizedBox(height: 20),
                              const _StatsStrip(),
                              const Spacer(),
                              const SizedBox(height: 24),
                              if (notice != null) ...[
                                AuthBanner(notice, icon: AppIcons.lock),
                                const SizedBox(height: 12),
                              ],
                              AuthButton(label: 'Sign In', onPressed: () => context.push('/sign-in')),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () => context.push('/apply'),
                                child: const Text('Become a partner'),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'By continuing, you agree to our',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(fontSize: 13, color: p.muted),
                                  ),
                                  TextButton(
                                    onPressed: () => openExternal(context, PartnerContent.termsUrl),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      textStyle: Theme.of(context).textTheme.labelMedium
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    child: const Text('Terms & Privacy Policy'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// AtomShop's marketplace numbers in three soft tiles.
class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, s) in PartnerContent.stats.take(3).indexed) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(AuthTheme.radius)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.value,
                      style: t.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: p.primary,
                        fontFeatures: tabularFigures,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(s.label, style: t.bodySmall?.copyWith(color: p.muted, height: 1.3)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
