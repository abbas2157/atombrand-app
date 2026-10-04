import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/app_icons.dart';

import '../../core/formatters.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/models/account.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../auth/partner_content.dart';
import '../dashboard/dashboard_screen.dart';
import 'more_logic.dart';

/// More (DESIGN.md §4.11): the brand card with its store status and a few
/// numbers, a nudge while the brand page is incomplete, then grouped rows:
/// Your store, Account, Help & support, and Sign out (always confirmed).
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final s = ref.watch(signedInProvider);
    final config = ref.watch(configProvider).value;
    if (s == null) return const SizedBox.shrink();
    final brand = s.brand;
    final checklist = brandPageChecklist(brand);
    final missing = [for (final c in checklist) if (!c.done) c.label];
    final publicUrl = brand.publicUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
          await ref.read(sessionProvider.notifier).refreshBadge();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          children: [
            _ProfileCard(user: s.user, brand: brand, onEdit: () => context.push('/profile')),
            if (missing.isNotEmpty) ...[
              const SizedBox(height: 12),
              _BrandPageNudge(checklist: checklist, missing: missing, onComplete: () => context.push('/brand-page')),
            ],
            const _SectionLabel('Your store'),
            _Group([
              _Row(
                icon: AppIcons.brandPage,
                title: 'Brand page',
                subtitle: missing.isEmpty ? 'Logo, banner, story and promo slides' : missingLine(missing),
                onTap: () => context.push('/brand-page'),
              ),
              if (publicUrl != null) ...[
                _Row(
                  icon: AppIcons.globe,
                  title: 'View public page',
                  subtitle: shortUrl(publicUrl),
                  external: true,
                  onTap: () => openExternal(context, publicUrl),
                ),
                _Row(
                  icon: AppIcons.share,
                  title: 'Share store link',
                  subtitle: 'Send your store to buyers on WhatsApp',
                  onTap: () => SharePlus.instance.share(ShareParams(
                    text: 'Shop ${brand.title} on AtomShop, with instalments available: $publicUrl',
                    subject: '${brand.title} on AtomShop',
                  )),
                ),
              ],
            ]),
            const _SectionLabel('Account'),
            _Group([
              _Row(
                icon: AppIcons.user,
                title: 'Profile',
                subtitle: 'Name, phone, business details',
                onTap: () => context.push('/profile'),
              ),
              _Row(icon: AppIcons.lock, title: 'Change password', onTap: () => context.push('/change-password')),
              const _Row(
                icon: AppIcons.bank,
                title: 'Bank & payouts',
                subtitle: 'Where AtomShop sends your payments',
                soon: true,
              ),
              const _Row(icon: AppIcons.users, title: 'Team members', subtitle: 'Give staff access', soon: true),
            ]),
            const _SectionLabel('Help & support'),
            _Group([
              _Row(
                icon: AppIcons.support,
                title: 'Contact AtomShop',
                subtitle: 'WhatsApp, call or email',
                onTap: () => showContactSheet(context, config ?? AppConfig.fallback),
              ),
              _Row(
                icon: AppIcons.document,
                title: 'Seller policies and terms',
                external: true,
                onTap: () => openExternal(context, PartnerContent.termsUrl),
              ),
            ]),
            const SizedBox(height: 20),
            _Group([
              _Row(
                icon: AppIcons.logout,
                title: 'Sign out',
                danger: true,
                onTap: () => _confirmSignOut(context, ref, s),
              ),
            ]),
            const SizedBox(height: 14),
            Text(
              'Atombrand · v$appVersion',
              textAlign: TextAlign.center,
              style: t.bodySmall?.copyWith(color: pal.muted),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref, SignedIn s) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) {
        final pal = AppPalette.of(ctx);
        final t = Theme.of(ctx).textTheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _Logo(s.brand, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sign out of ${s.brand.title}?', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                          if (s.user.email != null) Text(s.user.email!, style: t.bodySmall?.copyWith(color: pal.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "You'll need your email and password to sign in again. New-order alerts stop on this phone until you do.",
                  style: t.bodyMedium?.copyWith(color: pal.muted, height: 1.5),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          backgroundColor: pal.danger,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(AppIcons.logout, size: 20),
                        label: const Text('Sign out'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (ok == true) await ref.read(sessionProvider.notifier).signOut();
  }
}

/// WhatsApp, call or email AtomShop, as large options.
Future<void> showContactSheet(BuildContext context, AppConfig config) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (ctx) {
      final pal = AppPalette.of(ctx);
      final t = Theme.of(ctx).textTheme;
      Widget option({required IconData icon, required Tone tone, required String title, required String subtitle, String? tag, required VoidCallback onTap}) =>
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: pal.card,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: pal.divider, width: 1.5)),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.pop(ctx);
                  onTap();
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 72),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(14)),
                          child: Icon(icon, color: tone.fg),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                              Text(subtitle, style: t.bodySmall?.copyWith(color: pal.muted, fontFeatures: tabularFigures)),
                            ],
                          ),
                        ),
                        if (tag != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: pal.positive.bg, borderRadius: BorderRadius.circular(11)),
                            child: Text(tag, style: t.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: pal.positive.fg)),
                          )
                        else
                          Icon(AppIcons.externalLink, size: 18, color: pal.muted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Contact AtomShop', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('We help with orders, payments, listings and your brand page.', style: t.bodyMedium?.copyWith(color: pal.muted)),
              const SizedBox(height: 16),
              if (config.supportWhatsapp != null)
                option(
                  icon: AppIcons.chat,
                  tone: pal.positive,
                  title: 'WhatsApp',
                  subtitle: 'Usually replies within 1 hour',
                  tag: 'Fastest',
                  onTap: () => openExternal(context, config.supportWhatsapp),
                ),
              if (config.supportPhone != null)
                option(
                  icon: AppIcons.phone,
                  tone: pal.indigo,
                  title: 'Call',
                  subtitle: formatPkPhone(config.supportPhone!),
                  onTap: () => callPhone(context, config.supportPhone),
                ),
              if (config.supportEmail != null)
                option(
                  icon: AppIcons.email,
                  tone: pal.warning,
                  title: 'Email',
                  subtitle: config.supportEmail!,
                  onTap: () => openExternal(context, 'mailto:${config.supportEmail}'),
                ),
              Text('Mon–Sat, 10am–7pm', style: t.bodySmall?.copyWith(color: pal.muted)),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------

class _Logo extends StatelessWidget {
  const _Logo(this.brand, {this.size = 64});
  final Brand brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: pal.divider, width: 1.5)),
      child: NetThumb(brand.logo, size: size, radius: size / 2, icon: AppIcons.store),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({required this.user, required this.brand, required this.onEdit});

  final AppUser user;
  final Brand brand;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final dash = ref.watch(dashboardProvider);
    final state = storeStateOf(brand.status);
    final (String? label, Tone? tone) = switch (state) {
      StoreState.live => ('Store live', pal.positive),
      StoreState.review => ('Under review', pal.warning),
      StoreState.suspended => ('Suspended', pal.negative),
      StoreState.unknown => (null, null),
    };
    final d = dash.value;
    Widget stat(String value, String label) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Text(value, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontFeatures: tabularFigures)),
                Text(label, style: t.bodySmall?.copyWith(color: pal.muted), textAlign: TextAlign.center),
              ],
            ),
          ),
        );
    Widget divider() => SizedBox(height: 32, child: VerticalDivider(width: 1, color: pal.divider));

    return Container(
      decoration: BoxDecoration(color: pal.card, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: pal.cardShadow),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 4, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Logo(brand),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(brand.title, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(color: pal.muted)),
                      if (user.email != null)
                        Text(user.email!, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(color: pal.muted)),
                      if (label != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: tone!.bg, borderRadius: BorderRadius.circular(13)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 7, height: 7, decoration: BoxDecoration(color: tone.fg, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text(label, style: t.labelSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: tone.fg)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton(onPressed: onEdit, child: const Text('Edit')),
              ],
            ),
          ),
          // Numbers come from the dashboard; the strip hides if it fails.
          if (!dash.hasError)
            DecoratedBox(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: pal.divider))),
              child: Row(
                children: [
                  stat(d == null ? '–' : count(d.catalogueTotal), 'Products'),
                  divider(),
                  stat(d == null ? '–' : count(d.ordersLast30), 'Orders, 30 days'),
                  divider(),
                  stat(d == null ? '–' : count(d.cataloguePublished), 'Live'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BrandPageNudge extends StatelessWidget {
  const _BrandPageNudge({required this.checklist, required this.missing, required this.onComplete});

  final List<({String label, bool done})> checklist;
  final List<String> missing;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final done = checklist.where((c) => c.done).length;
    final pct = (done * 100 / checklist.length).round();
    final tone = Tone(pal.accentInk, Color.alphaBlend(pal.accent.withValues(alpha: 0.10), pal.card));
    return Semantics(
      container: true,
      label: 'Your brand page is $pct% complete. ${nudgeLine(missing)}',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tone.bg,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: pal.accent.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Row(
                children: [
                  Expanded(child: Text('Your brand page is $pct% complete', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                  Text('$done of ${checklist.length}', style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: tone.fg)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: done / checklist.length,
                minHeight: 8,
                color: pal.accent,
                backgroundColor: pal.accent.withValues(alpha: 0.18),
              ),
            ),
            const SizedBox(height: 10),
            ExcludeSemantics(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in checklist)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: pal.card,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: c.done ? pal.positive.bg : pal.accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(c.done ? AppIcons.check : AppIcons.add, size: 14, color: c.done ? pal.positive.fg : tone.fg),
                          const SizedBox(width: 4),
                          Text(c.label, style: t.labelSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: c.done ? pal.positive.fg : tone.fg)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ExcludeSemantics(child: Text(nudgeLine(missing), style: t.bodySmall?.copyWith(fontSize: 13, color: pal.text))),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onComplete,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              child: const Text('Complete now'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Semantics(
          header: true,
          child: Text(
            text.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppPalette.of(context).muted,
                ),
          ),
        ),
      );
}

class _Group extends StatelessWidget {
  const _Group(this.rows);
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: pal.card, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: pal.cardShadow),
      child: Column(
        children: [
          for (final (i, r) in rows.indexed) ...[
            if (i > 0) Divider(height: 1, indent: 60, color: pal.divider),
            r,
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.external = false,
    this.soon = false,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  /// Opens outside the app: an external-link icon instead of a chevron.
  final bool external;
  final bool soon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final color = danger ? pal.danger : pal.primary;
    final enabled = onTap != null && !soon;
    final Widget? trailing = danger
        ? null
        : soon
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: pal.neutral.bg, borderRadius: BorderRadius.circular(11)),
                child: Text('Soon', style: t.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: pal.neutral.fg)),
              )
            : Icon(external ? AppIcons.externalLink : AppIcons.chevronRight, size: external ? 18 : 22, color: pal.muted);
    return Semantics(
      button: enabled,
      enabled: enabled,
      label: [title, ?subtitle, if (external) 'opens outside the app', if (soon) 'coming soon'].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
            child: Row(
              mainAxisAlignment: danger ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Opacity(opacity: soon ? 0.5 : 1, child: Icon(icon, size: 24, color: color)),
                SizedBox(width: danger ? 10 : 20),
                if (danger)
                  Text(title, style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: color))
                else
                  Expanded(
                    child: Opacity(
                      opacity: soon ? 0.55 : 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                          if (subtitle != null) Text(subtitle!, style: t.bodySmall?.copyWith(color: pal.muted)),
                        ],
                      ),
                    ),
                  ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
