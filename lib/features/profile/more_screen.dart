import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';

/// More tab: Brand page editor · Profile · Change password · Support · Sign out.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final s = ref.watch(signedInProvider);
    final config = ref.watch(configProvider).value;

    Widget tile(IconData icon, String title, VoidCallback onTap, {String? subtitle, Color? color}) => ListTile(
          leading: Icon(icon, color: color ?? AppColors.primary),
          title: Text(title, style: t.bodyLarge?.copyWith(color: color)),
          subtitle: subtitle == null ? null : Text(subtitle, style: t.bodySmall),
          trailing: color == null ? const Icon(Icons.chevron_right_rounded, color: AppColors.muted) : null,
          onTap: onTap,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Row(
              children: [
                NetThumb(s?.brand.logo, size: 56, radius: 28, icon: Icons.storefront_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s?.brand.title ?? '', style: t.titleMedium),
                      Text(s?.user.name ?? '', style: t.bodySmall),
                      if (s?.user.email != null) Text(s!.user.email!, style: t.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                tile(Icons.web_rounded, 'Brand page', () => context.push('/brand-page'),
                    subtitle: 'Logo, banner, story and promo slides'),
                if (s?.brand.publicUrl != null)
                  tile(Icons.open_in_new_rounded, 'View public page', () => openExternal(context, s!.brand.publicUrl)),
                tile(Icons.person_outline_rounded, 'Profile', () => context.push('/profile')),
                tile(Icons.lock_reset_rounded, 'Change password', () => context.push('/change-password')),
              ],
            ),
          ),
          const SectionTitle('Support'),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                if (config?.supportWhatsapp != null)
                  tile(Icons.chat_outlined, 'WhatsApp AtomShop', () => openExternal(context, config!.supportWhatsapp)),
                if (config?.supportPhone != null)
                  tile(Icons.call_outlined, 'Call ${config!.supportPhone}', () => callPhone(context, config.supportPhone)),
                if (config?.supportEmail != null)
                  tile(Icons.mail_outline_rounded, config!.supportEmail!, () => openExternal(context, 'mailto:${config.supportEmail}')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: tile(Icons.logout_rounded, 'Sign out', () async {
              final ok = await confirm(context, title: 'Sign out?', message: 'You will need to sign in again on this device.', confirmLabel: 'Sign out');
              if (ok) await ref.read(sessionProvider.notifier).signOut();
            }, color: AppColors.dangerFg),
          ),
        ],
      ),
    );
  }
}
