import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import 'auth_scaffold.dart';
import 'google_sign_in_button.dart';
import 'partner_content.dart';
import 'partner_widgets.dart';

/// A short brand-partner landing page that scrolls, with the ways in pinned
/// at the bottom (DESIGN.md §3.1). Copy: atomshop.pk/brand-partners.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final session = ref.watch(sessionProvider);
    final notice = session is SignedOut ? session.notice : null;
    final config = ref.watch(configProvider).value;

    return AuthTheme(
      child: Scaffold(
        backgroundColor: AppColors.surface,
        bottomNavigationBar: _ActionPanel(notice: notice),
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                    children: [
                      const Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(top: -60, right: -84, child: _BrandSlashes()),
                          Center(child: BrandLogo.lockup(height: 112)),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        PartnerContent.headline,
                        textAlign: TextAlign.center,
                        style: authTitleStyle(t)?.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: 10),
                      Text(PartnerContent.pitch, textAlign: TextAlign.center, style: authSubtitleStyle(t)),
                      const SizedBox(height: 24),
                      const PartnerStatsCard(),
                      const SizedBox(height: 36),
                      const AuthSectionTitle('Why brands sell on AtomShop'),
                      for (final b in PartnerContent.benefits) BenefitRow(icon: b.icon, title: b.title, body: b.body),
                      const SizedBox(height: 18),
                      const AuthSectionTitle('How it works'),
                      const PartnerSteps(),
                      const SizedBox(height: 36),
                      const AuthSectionTitle('Brands already live'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final b in PartnerContent.liveBrands) SoftPill(b, icon: Icons.verified_rounded),
                        ],
                      ),
                      if (config?.supportWhatsapp != null || config?.supportEmail != null) ...[
                        const SizedBox(height: 36),
                        const AuthSectionTitle('Questions?'),
                        Text(
                          'Talk to the partnerships team. We reply within ${PartnerContent.replyTime}.',
                          style: t.bodyMedium?.copyWith(color: AppColors.muted, height: 1.45),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (config?.supportWhatsapp != null)
                              ActionChip(
                                avatar: const Icon(Icons.chat_rounded, size: 18, color: AppColors.successFg),
                                label: const Text('WhatsApp us'),
                                onPressed: () => openExternal(context, config!.supportWhatsapp),
                              ),
                            if (config?.supportEmail != null)
                              ActionChip(
                                avatar: const Icon(Icons.mail_outline_rounded, size: 18, color: AppColors.primary),
                                label: Text(config!.supportEmail!),
                                onPressed: () => openExternal(context, 'mailto:${config.supportEmail}'),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// White panel pinned to the bottom: Sign in, Google, Become a partner.
class _ActionPanel extends StatelessWidget {
  const _ActionPanel({this.notice});
  final String? notice;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (notice != null) ...[
                    InfoBanner(notice!, icon: Icons.lock_outline_rounded, color: AppColors.dangerFg),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(onPressed: () => context.push('/sign-in'), child: const Text('Sign in')),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(child: GoogleSignInButton(compact: true)),
                    ],
                  ),
                  const PartnerLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two faint diagonal strokes in the corner, echoing the A and B of the mark.
class _BrandSlashes extends StatelessWidget {
  const _BrandSlashes();

  @override
  Widget build(BuildContext context) =>
      const ExcludeSemantics(child: CustomPaint(size: Size(220, 200), painter: _SlashPainter()));
}

class _SlashPainter extends CustomPainter {
  const _SlashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    Path bar(double x, double w) => Path()
      ..moveTo(x, size.height)
      ..lineTo(x + w, size.height)
      ..lineTo(x + w + size.height * 0.58, 0)
      ..lineTo(x + size.height * 0.58, 0)
      ..close();
    canvas.drawPath(bar(20, 44), Paint()..color = AppColors.accent.withValues(alpha: 0.05));
    canvas.drawPath(bar(84, 30), Paint()..color = AppColors.primary.withValues(alpha: 0.08));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
