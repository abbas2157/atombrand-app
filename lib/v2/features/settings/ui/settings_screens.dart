import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/ids.dart';
import '../../../core/lock/quick_sign_in.dart';
import '../../../core/net/network_status.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../auth/ui/auth_parts.dart' show quickPrompt;
import '../../menu/ui/menu_screen.dart' show confirmSignOut;
import '../../notifications/ui/notifications_screens.dart'
    show NotificationSettingsScreen;
import '../../../core/prefs/atom_language.dart'
    show atomLanguageProvider, atomLanguages;
import '../data/settings_repository.dart';
import '../data/settings_rules.dart';
import '../../account/data/shop_settings.dart' show shopSettingsProvider;
import '../../../core/session/session.dart' show BrandPermission, BrandSession;
import 'security_screens.dart' show SecurityScreen;
import 'settings_parts.dart';
import 'device_screens.dart'
    show
        cacheBytesProvider,
        megabytes,
        notificationsAllowedProvider,
        offlineBytesProvider;
import '../../account/ui/daily_summary_screen.dart' show dailySummaryProvider;

export 'settings_parts.dart' show SettingsPane, settingsLeading;

/// Brand Partner on Google Play.
final playStoreUri = Uri.parse(
  'https://play.google.com/store/apps/details?id=pk.atomshop.atombrand_app',
);

/// A page with a back arrow, the title and a scrolling body.
class _Page extends StatelessWidget {
  const _Page({required this.title, required this.children, this.bottom});

  final String title;
  final List<Widget> children;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtomFlowBar(leading: settingsLeading(context), title: title),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: children,
            ),
          ),
          if (bottom != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              child: bottom,
            ),
        ],
      ),
    );
  }
}

/// Opens the privacy policy (18.4), kept on the phone.
void openPrivacyPolicy(BuildContext context) => context.push(V2Routes.privacy);

/// The settings pages that open on the right of Settings on a wide tablet
/// (19.19). The rest (shop settings, permissions, storage, help,
/// feedback, closing the account) still open as their own page.
enum _Pane { profile, security, devices, notifications, language, data }

/// Settings (19.1): one row per screen, owner-only rows hidden for agents,
/// add-on rows only with the add-on. Offline, the rows that need Atomshop
/// stay in place, greyed, saying "Needs internet".
///
/// On a wide tablet (19.19) the list sits on the left, titles only, and the
/// most used pages open on the right, Profile first.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  _Pane _picked = _Pane.profile;

  /// Whether the page on the right has unsaved changes. Its own
  /// [AtomUnsavedGuard] reports here; Back from the list goes through that
  /// guard already, as both are on the same route.
  final _unsaved = AtomUnsavedTracker();

  /// Opens [pane] on the right, first asking "Leave without saving?" when
  /// the page there has unsaved changes.
  Future<void> _pick(_Pane pane) async {
    if (pane == _picked) return;
    if (!await confirmDropUnsaved(context, _unsaved) || !mounted) return;
    setState(() => _picked = pane);
  }

  Widget _page(_Pane pane) => switch (pane) {
    _Pane.profile => const ProfileScreen(),
    _Pane.security => const SecurityScreen(),
    _Pane.devices => const DevicesScreen(),
    _Pane.notifications => const NotificationSettingsScreen(),
    _Pane.language => const LanguageScreen(),
    _Pane.data => const DataScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final split = atomTwoPane(context);
    final list = _list(context, split);
    if (!split) return list;
    return Scaffold(
      body: AtomSplitView(
        list: list,
        detail: AtomUnsavedScope(
          tracker: _unsaved,
          child: SettingsPane(
            child: AtomReadableWidth(
              child: KeyedSubtree(
                key: ValueKey(_picked),
                child: _page(_picked),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, bool split) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider.notifier).current;
    final owner = session?.who.isOwner ?? false;
    final access = ref.watch(accessProvider);
    final online = ref.watch(onlineProvider).value ?? true;
    final offline = online ? null : l.dpDdNeedsInternet;
    final profile = ref.watch(myProfileProvider).value;
    final devices = ref.watch(devicesProvider);
    final cacheOnly = ref.watch(cacheBytesProvider).value;
    final copyBytes = access.has(Addon.offline)
        ? ref.watch(offlineBytesProvider).value
        : 0;
    final cache = cacheOnly == null || copyBytes == null
        ? null
        : cacheOnly + copyBytes;
    final notifOff = ref.watch(notificationsAllowedProvider).value == false;
    final terms = access.terms;
    final role = owner ? l.menuRoleOwner : (session?.who.roleName ?? '');
    final business = profile?.brandName ?? session?.brandName ?? '';

    /// Opens [pane] on the right on a wide tablet, else pushes [route].
    VoidCallback open(_Pane pane, String route) =>
        split ? () => _pick(pane) : () => context.push(route);

    VoidCallback push(String route) =>
        () => context.push(route);

    /// One row. On the tablet's list only the title shows (19.19).
    Widget row({
      required IconData icon,
      required String title,
      AtomTone tone = AtomTone.grey,
      String? sub,
      String? value,
      int? badge,
      VoidCallback? onTap,
      _Pane? pane,
      bool needsInternet = false,
      bool loading = false,
      String? error,
      bool danger = false,
      bool chevron = true,
    }) => SetItem(
      icon: icon,
      tone: tone,
      title: title,
      subtitle: split ? null : sub,
      value: split ? null : value,
      badge: split ? null : badge,
      loading: !split && loading,
      error: split ? null : error,
      disabledReason: needsInternet ? offline : null,
      danger: danger,
      chevron: chevron && !split,
      selected: split && pane != null && _picked == pane,
      minHeight: split ? 52 : AtomSize.row,
      onTap: onTap,
    );

    final shop = owner ? ref.watch(shopSettingsProvider).value : null;
    final daily = owner ? ref.watch(dailySummaryProvider).value : null;
    final account = shop?.account;
    final inventory = access.stateOf(Addon.inventory);
    final groups = <(String, String?, List<Widget>)>[
      (
        l.settingsMyProfile,
        null,
        [
          row(
            icon: LucideIcons.user,
            tone: AtomTone.blue,
            title: l.settingsProfile,
            sub: owner ? l.settingsProfileSubOwner : l.settingsProfileSubAgent,
            pane: _Pane.profile,
            onTap: open(_Pane.profile, V2Routes.profile),
          ),
          row(
            icon: LucideIcons.keyRound,
            tone: AtomTone.blue,
            title: owner ? l.settingsPasswordRow : l.menuMyPassword,
            sub: owner
                ? l.settingsPasswordSubOwner
                : l.settingsPasswordSubAgent,
            needsInternet: true,
            onTap: push(V2Routes.settingsStep('password')),
          ),
          row(
            icon: LucideIcons.lock,
            tone: AtomTone.blue,
            title: l.securityTitle,
            sub: l.settingsSecuritySub,
            pane: _Pane.security,
            onTap: open(_Pane.security, V2Routes.settingsStep('security')),
          ),
          row(
            icon: LucideIcons.smartphone,
            tone: AtomTone.blue,
            title: l.devicesTitle,
            sub: devices.isLoading
                ? l.dpDdDevicesLoading
                : owner && devices.value != null
                ? l.emuP4DevicesSummary(
                    math.max(0, devices.value!.mine.length - 1),
                  )
                : l.devicesSub,
            value: devices.value == null
                ? null
                : '${devices.value!.mine.length}',
            loading: devices.isLoading,
            error: devices.hasError && !devices.isLoading
                ? l.dpDdDevicesError
                : null,
            needsInternet: true,
            pane: _Pane.devices,
            onTap: devices.hasError
                ? () => ref.invalidate(devicesProvider)
                : open(_Pane.devices, V2Routes.settingsStep('devices')),
          ),
        ],
      ),
      if (owner)
        (
          l.menuShopSettings,
          l.settingsShopNoteEvery,
          [
            row(
              icon: LucideIcons.store,
              tone: AtomTone.green,
              title: l.settingsPayTitle,
              sub: shop == null
                  ? l.settingsPaySub
                  : [
                      if (shop.settings.payCod) l.settingsPayCod,
                      if (shop.settings.payBank) l.settingsPayBank,
                      if (shop.settings.payWallet) l.settingsPayWallet,
                    ].join(', '),
              onTap: push(V2Routes.shopSettings),
            ),
            row(
              icon: LucideIcons.calendar,
              tone: AtomTone.green,
              title: l.settingsOrdersTitle,
              sub: shop == null
                  ? l.settingsOrdersSub
                  : l.settingsOrdersSubSet(
                      shop.settings.confirmHours,
                      shop.settings.idleMinutes,
                    ),
              onTap: push(V2Routes.shopSettings),
            ),
            row(
              icon: LucideIcons.fileText,
              tone: AtomTone.green,
              title: l.settingsReceipts,
              sub: l.settingsReceiptsSub,
              onTap: push(V2Routes.shopSettings),
            ),
            row(
              icon: AtomBrandIcons.whatsapp,
              tone: AtomTone.green,
              title: l.settingsDaily,
              sub: l.settingsDailySub,
              value: switch (daily) {
                null => null,
                final d => d.on ? l.settingsOn : l.dpDcOff,
              },
              onTap: push(V2Routes.dailySummary),
            ),
            if (session?.who.can(BrandPermission.pageEdit) ?? false)
              row(
                icon: LucideIcons.globe,
                tone: AtomTone.green,
                title: l.menuBrandPage,
                sub:
                    profile?.brandUrl?.replaceFirst(
                      RegExp(r'^https?://(www\.)?'),
                      '',
                    ) ??
                    l.menuBrandPageSub,
                value: switch (profile?.brandStatus) {
                  null => null,
                  'active' => l.settingsPageLive,
                  _ => l.settingsPageNotLive,
                },
                onTap: push(V2Routes.brandPage),
              ),
          ],
        ),
      if (owner)
        (
          l.settingsBrandAccount,
          l.settingsBrandAccountNote,
          [
            row(
              icon: LucideIcons.shield,
              tone: AtomTone.blue,
              title: l.settingsStatus,
              sub: [
                account?.status == 'active'
                    ? l.settingsStatusActivePartner
                    : _statusLabel(l, account?.status),
                if (account?.partnerSince != null)
                  l.settingsPartnerSince(AtomDates.day(account!.partnerSince!)),
              ].join(' · '),
              value: _statusLabel(l, account?.status),
              chevron: false,
            ),
            row(
              icon: LucideIcons.store,
              tone: AtomTone.blue,
              title: l.settingsAccountType,
              sub: account == null
                  ? null
                  : account.multi
                  ? l.settingsMultiOutlet(
                      account.outletsUsed,
                      account.outletLimit,
                    )
                  : l.settingsSingleOutlet,
              onTap: account?.multi ?? false ? push(V2Routes.outlets) : null,
              chevron: account?.multi ?? false,
            ),
            if (account != null)
              row(
                icon: LucideIcons.calendar,
                tone: AtomTone.blue,
                title: l.settingsAtompayWhole,
                sub: account.atompayWholeBrand
                    ? l.settingsAtompayWholeOn
                    : l.settingsAtompayWholeOff,
                value: account.atompayWholeBrand ? l.settingsOn : l.dpDcOff,
                chevron: false,
              ),
            if (inventory != AddonState.off)
              row(
                icon: LucideIcons.package,
                tone: AtomTone.blue,
                title: l.menuInventory,
                sub: [
                  ?account?.inventoryLabel,
                  if (account?.inventoryDaysLeft case final d?
                      when inventory == AddonState.trial)
                    l.settingsDaysLeft(d),
                ].join(' · '),
                onTap: push(V2Routes.plan),
              ),
            row(
              icon: AtomBrandIcons.whatsapp,
              tone: AtomTone.blue,
              title: l.helpTalk,
              sub: l.settingsTalkSub,
              needsInternet: true,
              onTap: push(V2Routes.support),
            ),
          ],
        ),
      (
        l.settingsApp,
        null,
        [
          row(
            icon: LucideIcons.bell,
            tone: AtomTone.amber,
            title: l.noticesTitle,
            sub: l.settingsNoticesSub,
            pane: _Pane.notifications,
            onTap: open(_Pane.notifications, V2Routes.notificationSettings),
          ),
          row(
            icon: LucideIcons.languages,
            tone: AtomTone.amber,
            title: l.languageTitle,
            sub: access.has(Addon.askAtom)
                ? l.settingsLanguageSubAtom
                : l.settingsApp,
            value: 'English',
            pane: _Pane.language,
            onTap: open(_Pane.language, V2Routes.settingsStep('language')),
          ),
          row(
            icon: LucideIcons.keyRound,
            tone: AtomTone.amber,
            title: l.permissionsTitle,
            sub: notifOff ? l.dpDdPermissionsOff : l.permissionsSub,
            badge: notifOff ? 1 : null,
            onTap: push(V2Routes.settingsStep('permissions')),
          ),
          row(
            icon: LucideIcons.save,
            tone: AtomTone.amber,
            title: l.storageTitle,
            sub: access.has(Addon.offline)
                ? l.settingsStorageSubOffline
                : l.dpDdStorageSub,
            value: cache == null ? null : megabytes(cache),
            onTap: push(V2Routes.settingsStep('storage')),
          ),
        ],
      ),
      (
        l.settingsPrivacy,
        null,
        [
          row(
            icon: LucideIcons.database,
            tone: AtomTone.purple,
            title: l.dpDdDataUse,
            sub: l.settingsDataSub,
            pane: _Pane.data,
            onTap: open(_Pane.data, V2Routes.settingsStep('data')),
          ),
          if (owner)
            row(
              icon: LucideIcons.download,
              tone: AtomTone.purple,
              title: l.dpDdExport,
              sub: l.settingsExportSub,
              needsInternet: true,
              onTap: open(_Pane.data, V2Routes.settingsStep('data')),
            ),
          row(
            icon: LucideIcons.shield,
            tone: AtomTone.purple,
            title: l.dpDdPrivacy,
            sub: l.settingsPrivacySub,
            onTap: () => openPrivacyPolicy(context),
          ),
          row(
            icon: LucideIcons.file,
            tone: AtomTone.purple,
            title: l.dpDdTerms,
            sub: terms?.version == null
                ? null
                : l.dpDdTermsSub(terms!.version!),
            onTap: push(V2Routes.termsRead),
          ),
        ],
      ),
      (
        l.settingsHelp,
        null,
        [
          row(
            icon: LucideIcons.circleHelp,
            title: l.menuHelp,
            sub: access.has(Addon.askAtom)
                ? l.settingsHelpSubAtom
                : l.settingsHelpSub,
            onTap: push(V2Routes.help),
          ),
          row(
            icon: LucideIcons.send,
            title: l.feedbackTitle,
            sub: l.feedbackSub,
            needsInternet: true,
            onTap: push(V2Routes.settingsStep('feedback')),
          ),
          row(
            icon: LucideIcons.star,
            title: l.rateTitle,
            sub: l.rateSub,
            needsInternet: true,
            onTap: push(V2Routes.rateApp),
          ),
        ],
      ),
    ];

    final children = <Widget>[
      if (!split)
        _ProfileCard(
          name: session?.name ?? '',
          initials: session?.initials ?? '',
          pictureUrl: profile?.pictureUrl,
          role: role,
          shopLine: [
            business,
            l.settingsBrandPartner,
          ].where((s) => s.isNotEmpty).join(' · '),
          onTap: open(_Pane.profile, V2Routes.profile),
        ),
      for (final (name, desc, rows) in groups) ...[
        AtomSectionLabel(name),
        if (desc != null && !split)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: Text(desc, style: AtomText.secondary.copyWith(height: 1.45)),
          ),
        AtomRowGroup(children: rows),
      ],
      if (!split) ...[AtomSectionLabel(l.settingsAbout), const _About()],
      AtomSectionLabel(l.settingsSignOutGroup),
      AtomRowGroup(
        children: [
          row(
            icon: LucideIcons.logIn,
            title: l.menuSignOut,
            sub: l.settingsSignOutSub,
            danger: true,
            chevron: false,
            onTap: () => confirmSignOut(context, ref),
          ),
          if (owner)
            row(
              icon: LucideIcons.trash,
              title: l.settingsDeleteTitle,
              sub: l.settingsDeleteRowSub,
              danger: true,
              needsInternet: true,
              onTap: push(V2Routes.settingsStep('close-account')),
            ),
        ],
      ),
      if (!online) SetTiny(l.dpDdOfflineFoot, top: 12, center: true),
    ];

    if (split) {
      // The tablet's list (19.19): white, the title without a Back arrow,
      // groups 12 in, rows 52 tall with only their titles.
      return ColoredBox(
        color: AtomColors.paper,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            0,
            MediaQuery.paddingOf(context).top,
            0,
            16,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 4),
              child: Semantics(
                header: true,
                child: Text(l.settingsTitle, style: AtomText.pageTitle),
              ),
            ),
            ...children,
          ],
        ),
      );
    }
    return SetPage(title: l.settingsTitle, children: children);
  }
}

/// The navy card at the top of Settings: who is signed in, their role, the
/// shop and its Atomshop code. Opens Profile.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.initials,
    required this.role,
    required this.shopLine,
    required this.onTap,
    this.pictureUrl,
  });

  final String name;
  final String initials;

  /// Their photo when the server has one (owner: photos, not initials).
  final String? pictureUrl;
  final String role;
  final String shopLine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final line = AtomText.secondary.copyWith(color: AtomColors.navText);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AtomPressable(
        onTap: onTap,
        semanticLabel: l.settingsProfileCard(name),
        builder: (_, _) => Container(
          padding: const EdgeInsets.all(AtomSpace.inset),
          decoration: const BoxDecoration(
            color: AtomColors.nav,
            borderRadius: AtomRadius.brCard,
          ),
          child: ExcludeSemantics(
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AtomColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AtomColors.navLine, width: 3),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: Text(
                          initials,
                          style: AtomText.heading.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (pictureUrl != null && pictureUrl!.isNotEmpty)
                        AtomPhoto(
                          pictureUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AtomText.listTitle.copyWith(
                          color: Colors.white,
                          fontSize: 17,
                        ),
                      ),
                      if (role.isNotEmpty) Text(role, style: line),
                      if (shopLine.isNotEmpty) Text(shopLine, style: line),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(
                  LucideIcons.chevronRight,
                  size: AtomIcon.setRow,
                  color: AtomColors.navMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// About (19.1): the mark, the app's name and version, Atomshop's byline and
/// Our ecosystem.
class _About extends StatelessWidget {
  const _About();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AtomSpace.gutter),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: AtomDecor.card,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F101828),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
                BoxShadow(color: AtomColors.line, spreadRadius: 1),
              ],
            ),
            child: Image.asset(
              'assets/brand/mark.png',
              width: 50,
              height: 50,
              semanticLabel: l.appName,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.appName,
            textAlign: TextAlign.center,
            style: AtomText.listTitle.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.dpDdVersion(appVersion),
            textAlign: TextAlign.center,
            style: AtomText.secondary,
          ),
          const SizedBox(height: 12),
          Image.asset(
            'assets/brand/atomshop_logo.png',
            height: 26,
            semanticLabel: l.dpDdByline,
          ),
          const SizedBox(height: 8),
          // An inline link on the board (`.about a`, 14): laid out at its
          // line's height, so the card keeps the board's 8 above and 18
          // below it.
          SizedBox(
            height: 22,
            child: OverflowBox(
              maxHeight: 48,
              child: AtomLink(
                label: l.dpDdEcosystem,
                alignment: AlignmentDirectional.center,
                onTap: () => context.push(V2Routes.ecosystem),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Your profile (16.1). The owner changes their name and mobile; the email
/// is how they sign in, so it shows greyed (and goes back unchanged, as
/// `profile/update` needs it). A team member's mobile is their sign-in
/// name: only the owner changes it on Team, and their name too until the
/// server has a call for it, so their profile is read-only here.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  MyProfile? _loaded;
  bool _saving = false;
  String? _error;

  /// The server's refusals, shown on their fields (`422`).
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _fill(MyProfile p, BrandSession? session, bool owner) {
    if (_loaded != null) return;
    _loaded = p;
    _name.text = p.name;
    _email.text = p.email ?? '';
    final phone = owner ? p.phone : (session?.phone ?? p.phone);
    _phone.text = phone == null ? '' : AtomIds.formatMobile(phone);
  }

  /// Why Save is off, or null.
  String? _missing() =>
      profileProblem(AppLocalizations.of(context), _name.text, _phone.text);

  bool _dirty(MyProfile p, {required bool owner}) {
    final phone = _phone.text.trim();
    if (!owner) return _name.text.trim() != p.name;
    return _name.text.trim() != p.name ||
        (AtomIds.normaliseMobile(phone) ?? phone) != (p.phone ?? '');
  }

  void _edited(String field) => setState(() {
    if (_fieldErrors.containsKey(field)) {
      _fieldErrors = {..._fieldErrors}..remove(field);
    }
  });

  Future<void> _save(MyProfile p, {required bool owner}) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _error = null;
      _fieldErrors = const {};
    });
    final name = _name.text.trim();
    final phone = _phone.text.trim().isEmpty
        ? null
        : AtomIds.normaliseMobile(_phone.text);
    final repo = ref.read(settingsRepositoryProvider);
    final r = owner
        ? await repo.updateProfile(
            name: name,
            email: p.email ?? '',
            phone: phone,
          )
        : await repo.updateMyName(name);
    if (!mounted) return;
    switch (r) {
      case ApiOk():
        _loaded = owner
            ? p.copyWith(name: name, phone: phone ?? '')
            : p.copyWith(name: name);
        ref.invalidate(myProfileProvider);
        showAtomToast(context, kind: AtomToastKind.ok, message: l.profileSaved);
        if (SettingsPane.of(context)) {
          setState(() => _saving = false);
        } else {
          Navigator.of(context).pop();
        }
      case ApiErr(:final failure):
        const shown = {'name', 'phone'};
        final onFields = {
          for (final e in failure.fieldErrors.entries)
            if (shown.contains(e.key)) e.key: e.value,
        };
        setState(() {
          _saving = false;
          _fieldErrors = onFields;
          _error = onFields.isNotEmpty
              ? null
              : failure.fieldErrors.values.firstOrNull ??
                    sayFailure(l, failure);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider.notifier).current;
    final owner = session?.who.isOwner ?? false;
    final online = ref.watch(onlineProvider).value ?? true;
    final profile = ref.watch(myProfileProvider);
    final p = profile.value;
    if (p != null) _fill(p, session, owner);
    final base = _loaded;
    // Team members change their own name; the owner also the mobile (16.1).
    final missing = base == null
        ? null
        : owner
        ? _missing()
        : profileProblem(l, _name.text, '');
    final changed = base != null && _dirty(base, owner: owner);
    final pane = SettingsPane.of(context);
    final brand = p?.brandName ?? session?.brandName ?? '';

    final Widget? save;
    if (base == null) {
      save = null;
    } else if (!online) {
      save = AtomButton(label: l.dpDdNeedsInternet, onPressed: null);
    } else {
      save = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            AtomNote(kind: AtomNoteKind.problem, message: _error!),
            const SizedBox(height: 10),
          ],
          if (changed && missing != null) AtomButtonReason(reason: missing),
          AtomButton(
            label: l.commonSave,
            saving: _saving,
            onPressed: changed && missing == null
                ? () => _save(base, owner: owner)
                : null,
          ),
        ],
      );
    }

    final body = profile.when(
      loading: () => const <Widget>[AtomLoadingRows(count: 3)],
      error: (e, _) => [
        AtomErrorState(
          message: e is ApiFailure ? sayFailure(l, e) : null,
          onRetry: () => ref.invalidate(myProfileProvider),
        ),
      ],
      data: (p) => [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Column(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: p.pictureUrl != null
                      ? AtomPhoto(
                          p.pictureUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _BigInitials(session?.initials ?? ''),
                        )
                      : _BigInitials(session?.initials ?? ''),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                [
                  owner ? l.menuRoleOwner : (session?.who.roleName ?? ''),
                  brand,
                ].where((s) => s.isNotEmpty).join(' · '),
                style: AtomText.small.copyWith(color: AtomColors.faint),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AtomTextField(
                boxHeight: 48,
                label: l.customerName,
                controller: _name,
                hint: _fieldErrors['name'] == null ? l.profileNameHint : null,
                error: _fieldErrors['name'],
                textInputAction: TextInputAction.next,
                onChanged: (_) => _edited('name'),
              ),
              const SizedBox(height: 12),
              if (owner) ...[
                AtomTextField(
                  boxHeight: 48,
                  label: l.profileEmail,
                  labelNote: l.dpDdSignInWithIt,
                  controller: _email,
                  enabled: false,
                ),
                const SizedBox(height: 12),
                AtomTextField(
                  boxHeight: 48,
                  label: l.customerMobile,
                  controller: _phone,
                  error: _fieldErrors['phone'],
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                  ],
                  onChanged: (_) => _edited('phone'),
                ),
              ] else
                AtomTextField(
                  boxHeight: 48,
                  label: l.customerMobile,
                  labelNote: l.dpDdSignInWithIt,
                  controller: _phone,
                  enabled: false,
                  hint: l.dpDdOwnerChangesPhone,
                ),
              const SizedBox(height: 12),
              _PasswordCard(onTap: () => openPasswordScreen(context, ref)),
            ],
          ),
        ),
      ],
    );

    return AtomUnsavedGuard(
      dirty: changed && !_saving,
      child: Scaffold(
        backgroundColor: pane ? AtomColors.surface : AtomColors.paper,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!pane)
              AtomFlowBar(
                leading: AtomFlowLeading.close,
                title: l.profileTitle,
              ),
            Expanded(
              child: ListView(
                padding: pane
                    ? EdgeInsets.fromLTRB(
                        16,
                        22 + MediaQuery.paddingOf(context).top,
                        16,
                        24,
                      )
                    : const EdgeInsets.only(bottom: 24),
                children: [
                  if (pane)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Semantics(
                        header: true,
                        child: Text(l.profileTitle, style: AtomText.pageTitle),
                      ),
                    ),
                  ...body,
                ],
              ),
            ),
            if (save != null) SetBottomBar(child: save),
          ],
        ),
      ),
    );
  }
}

/// The 88 initials circle for a profile without a photo.
class _BigInitials extends StatelessWidget {
  const _BigInitials(this.initials);
  final String initials;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    color: AtomColors.primary,
    child: Text(initials, style: AtomText.amount.copyWith(color: Colors.white)),
  );
}

/// "Change password" as a card on Your profile (17.1).
class _PasswordCard extends StatelessWidget {
  const _PasswordCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AtomPressable(
      onTap: onTap,
      scaleOnPress: false,
      semanticLabel: '${l.passwordTitle}, ${l.dpDdPasswordSub}',
      builder: (_, pressed) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: pressed ? AtomColors.surface : AtomColors.paper,
          borderRadius: AtomRadius.brCard,
          border: Border.all(color: AtomColors.line),
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              const AtomIconTile(icon: LucideIcons.lock, tone: AtomTone.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.passwordTitle, style: AtomText.listTitle),
                    Text(l.dpDdPasswordSub, style: AtomText.secondary),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                LucideIcons.chevronRight,
                size: AtomIcon.setRow,
                color: AtomColors.chevron,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens Change password, for the owner and agents alike.
Future<void> openPasswordScreen(BuildContext context, WidgetRef ref) =>
    context.push(V2Routes.settingsStep('password'));

/// Change password. The owner types the current one (`profile/password`);
/// the server then signs out every other phone. A team member chooses a
/// new one (`me/password`).
class PasswordScreen extends ConsumerStatefulWidget {
  const PasswordScreen({super.key});

  @override
  ConsumerState<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends ConsumerState<PasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _again = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final c in [_current, _next, _again]) {
      c.addListener(_changed);
    }
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    for (final c in [_current, _next, _again]) {
      c.dispose();
    }
    super.dispose();
  }

  /// The sign-in saved behind the fingerprint gets the new password (one
  /// system prompt); if that can't be done, the old one is erased.
  Future<void> _updateQuickSignIn(AppLocalizations l) async {
    final quick = ref.read(quickSignInProvider.notifier);
    final saved = ref.read(quickSignInProvider).profile;
    final session = ref.read(sessionProvider.notifier).current;
    if (saved == null || session == null || saved.userId != session.userId) {
      return;
    }
    final login = session.who.isOwner ? session.email : session.phone;
    if (login == null) return quick.erase();
    final r = await quick.save(
      saved,
      QuickSecret(login: login, password: _next.text),
      quickPrompt(l, save: true),
    );
    if (r is! QuickOk) await quick.erase();
  }

  Future<void> _save(bool owner) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(settingsRepositoryProvider);
    final r = owner
        ? await repo.changeOwnerPassword(
            current: _current.text,
            next: _next.text,
          )
        : await repo.changeMyPassword(_next.text);
    if (!mounted) return;
    switch (r) {
      case ApiOk():
        if (owner) ref.invalidate(devicesProvider);
        await _updateQuickSignIn(l);
        if (!mounted) return;
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: owner
              ? l.settingsPasswordChangedOwner
              : l.settingsPasswordSaved,
        );
        Navigator.of(context).pop();
      case ApiErr(:final failure):
        setState(() {
          _saving = false;
          _error =
              failure.fieldErrors.values.firstOrNull ?? sayFailure(l, failure);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final owner =
        ref.watch(sessionProvider.notifier).current?.who.isOwner ?? false;
    final online = ref.watch(onlineProvider).value ?? true;
    final missing = online
        ? passwordProblem(
            l,
            needsCurrent: owner,
            current: _current.text,
            next: _next.text,
            again: _again.text,
          )
        : l.dpDdNeedsInternet;
    return AtomUnsavedGuard(
      dirty: _next.text.isNotEmpty && !_saving,
      child: _Page(
        title: owner ? l.passwordTitle : l.menuMyPassword,
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              AtomNote(kind: AtomNoteKind.problem, message: _error!),
              const SizedBox(height: 10),
            ],
            if (missing != null) AtomButtonReason(reason: missing),
            AtomButton(
              label: l.passwordSave,
              saving: _saving,
              onPressed: missing == null ? () => _save(owner) : null,
            ),
          ],
        ),
        children: [
          if (owner) ...[
            AtomPasswordField(
              label: l.passwordCurrent,
              controller: _current,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
          ],
          AtomPasswordField(
            label: l.passwordNew,
            controller: _next,
            newPassword: true,
            showStrength: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AtomPasswordField(
            label: l.passwordAgain,
            controller: _again,
            newPassword: true,
          ),
          const SizedBox(height: 14),
          AtomNote(
            kind: AtomNoteKind.info,
            message: owner
                ? l.settingsPasswordNoteOwner
                : l.settingsPasswordNoteAgent,
          ),
        ],
      ),
    );
  }
}

/// Language (19.14): the app (English; Urdu is being written) and, with
/// Ask Atom, the language Atom answers in, kept on this phone.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final atom = ref.watch(accessProvider).has(Addon.askAtom);
    final lang = ref.watch(atomLanguageProvider);
    String name(String code) => switch (code) {
      'en' => 'English',
      'roman-ur' => 'Roman Urdu',
      'ur' => 'اردو',
      _ => l.atomLangAuto,
    };
    return SetPage(
      title: l.languageTitle,
      children: [
        AtomSectionLabel(l.languageApp),
        AtomRowGroup(
          children: [
            SetItem(
              title: 'English',
              trailing: const AtomRadio(on: true),
              checked: true,
              onTap: () {},
            ),
            SetItem(
              title: 'اردو',
              subtitle: l.languageSoon,
              dim: true,
              trailing: const AtomRadio(on: false),
              checked: false,
            ),
          ],
        ),
        if (atom) ...[
          AtomSectionLabel(l.atomLangTitle),
          AtomRowGroup(
            children: [
              for (final code in atomLanguages)
                SetItem(
                  title: name(code),
                  subtitle: code == 'auto' ? l.atomLangAutoSub : null,
                  trailing: AtomRadio(on: lang == code),
                  checked: lang == code,
                  onTap: () =>
                      ref.read(atomLanguageProvider.notifier).choose(code),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// When a device was last used: "today 9:05 AM" or "1 Nov". Kept on one
/// line when the row's second line wraps.
String _lastUsed(AppLocalizations l, DateTime at) {
  final now = AtomDates.now();
  final today =
      at.year == now.year && at.month == now.month && at.day == now.day;
  final s = today
      ? l.dpDdToday(AtomDates.time(at))
      : at.year == now.year
      ? AtomDates.short(at)
      : AtomDates.day(at);
  return s.replaceAll(' ', ' ');
}

/// The icon for a device: a phone, else a screen.
IconData _deviceIcon(SignedInDevice d) => switch (d.platform) {
  'web' || 'windows' || 'macos' || 'linux' => LucideIcons.monitor,
  _ => LucideIcons.smartphone,
};

/// Devices & sessions (19.3): where you are signed in, and for an owner
/// with Team, a row to the team's phones. Signing a device out works at
/// once.
class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  Future<void> _out(
    BuildContext context,
    WidgetRef ref,
    Future<ApiResult<Object?>> Function() call,
  ) async {
    final l = AppLocalizations.of(context);
    final r = await call();
    if (!context.mounted) return;
    ref.invalidate(devicesProvider);
    showAtomToast(
      context,
      kind: r is ApiOk ? AtomToastKind.ok : AtomToastKind.bad,
      message: switch (r) {
        ApiOk() => l.devicesSignedOut,
        ApiErr(:final failure) => sayFailure(l, failure),
      },
    );
  }

  /// Sign out all other devices (18.3): asks first, keeps this phone.
  Future<void> _signOutOthers(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final yes = await showAtomConfirm(
      context,
      title: l.settingsSignOutOthersTitle,
      body: l.settingsSignOutOthersBody,
      confirmLabel: l.devicesSignOutOthers,
      destructive: true,
    );
    if (!yes || !context.mounted) return;
    final r = await ref.read(settingsRepositoryProvider).signOutOthers();
    if (!context.mounted) return;
    ref.invalidate(devicesProvider);
    showAtomToast(
      context,
      kind: r is ApiOk ? AtomToastKind.ok : AtomToastKind.bad,
      message: switch (r) {
        ApiOk(:final value) =>
          value > 0 ? l.settingsSignOutOthersDone : l.settingsSignOutOthersNone,
        ApiErr(:final failure) => sayFailure(l, failure),
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final repo = ref.read(settingsRepositoryProvider);
    final online = ref.watch(onlineProvider).value ?? true;

    Widget row(SignedInDevice d) {
      final at = d.lastUsedAt ?? d.signedInAt;
      return SetItem(
        icon: _deviceIcon(d),
        tone: d.thisDevice ? AtomTone.blue : AtomTone.grey,
        title: d.thisDevice ? l.devicesThisPhone(d.name) : d.name,
        // Wraps rather than cutting off "last used …": the board's lines
        // are short enough for one line, real device names often aren't.
        subWraps: true,
        subtitle: d.thisDevice
            ? l.devicesNow
            : at == null
            ? l.dpDdDeviceApp
            : l.dpDdDeviceLastUsed(l.dpDdDeviceApp, _lastUsed(l, at)),
        trailing: d.thisDevice
            ? SetPill(l.devicesThisOne)
            : AtomButton.small(
                label: l.menuSignOut,
                onPressed: online
                    ? () => _out(context, ref, () => repo.signOutDevice(d.id))
                    : null,
              ),
      );
    }

    return SetPage(
      title: l.devicesTitle,
      children: [
        ...ref
            .watch(devicesProvider)
            .when(
              loading: () => const [SetPad(child: AtomLoadingRows(count: 3))],
              error: (e, _) => [
                SetPad(
                  child: AtomErrorState(
                    message: e is ApiFailure ? sayFailure(l, e) : null,
                    onRetry: () => ref.invalidate(devicesProvider),
                  ),
                ),
              ],
              data: (d) => [
                AtomSectionLabel(l.devicesSignedIn),
                AtomRowGroup(children: [for (final x in d.mine) row(x)]),
                if (d.team.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  AtomRowGroup(
                    children: [
                      SetItem(
                        icon: LucideIcons.smartphone,
                        title: l.dpDdTeamPhones,
                        // One line with "…" as on the board; the names
                        // are all on the next page.
                        subtitle: [for (final (name, _) in d.team) name]
                            .join(', '),
                        chevron: true,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const _TeamDevicesScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                // Always there (18.3); with nowhere else signed in the
                // server says so.
                SetPad(
                  top: 14,
                  child: _DangerOutlineButton(
                    label: online
                        ? l.devicesSignOutOthers
                        : l.dpDdNeedsInternet,
                    onPressed: online
                        ? () => _signOutOthers(context, ref)
                        : null,
                  ),
                ),
                SetTiny(
                  ref.watch(accessProvider).has(Addon.offline)
                      ? l.settingsSessionsNote
                      : l.dpDdDevicesNote,
                ),
              ],
            ),
      ],
    );
  }
}

/// Your team's phones (from 19.3): where each agent is signed in.
class _TeamDevicesScreen extends ConsumerWidget {
  const _TeamDevicesScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final team = ref.watch(devicesProvider).value?.team ?? const [];
    return SetPage(
      title: l.dpDdTeamPhones,
      children: [
        for (final (name, devices) in team) ...[
          AtomSectionLabel(name),
          if (devices.isEmpty)
            SetDesc(
              l.devicesNone,
              margin: const EdgeInsets.fromLTRB(18, 0, 18, 0),
            )
          else
            AtomRowGroup(
              children: [
                for (final d in devices)
                  SetItem(
                    icon: _deviceIcon(d),
                    title: d.name,
                    subWraps: true,
                    subtitle: switch (d.lastUsedAt ?? d.signedInAt) {
                      final at? => l.dpDdDeviceLastUsed(
                        l.dpDdDeviceApp,
                        _lastUsed(l, at),
                      ),
                      null => l.dpDdDeviceApp,
                    },
                  ),
              ],
            ),
        ],
      ],
    );
  }
}

/// The rose outline button (`.btn-outline` in rose, 19.3).
class _DangerOutlineButton extends StatelessWidget {
  const _DangerOutlineButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final on = onPressed != null;
    return AtomPressable(
      onTap: onPressed,
      semanticLabel: label,
      builder: (_, pressed) => Container(
        constraints: const BoxConstraints(minHeight: AtomSize.control),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: !on
              ? AtomColors.disabledFill
              : pressed
              ? AtomColors.roseSoft
              : AtomColors.paper,
          borderRadius: AtomRadius.brControl,
          border: Border.all(
            color: on ? AtomColors.roseLine : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AtomText.button.copyWith(
            color: on ? AtomColors.rose : AtomColors.disabledText,
          ),
        ),
      ),
    );
  }
}

/// Send feedback (19.9): an idea, a problem or praise, with a screenshot
/// and the phone model if you like.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  FeedbackKind _kind = FeedbackKind.idea;
  final _message = TextEditingController();
  File? _shot;
  bool _withDevice = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    final r = await ref
        .read(settingsRepositoryProvider)
        .feedback(
          _kind,
          _message.text.trim(),
          screenshot: _shot,
          device: _withDevice
              ? '${Platform.operatingSystem} ${Platform.operatingSystemVersion}'
              : null,
        );
    if (!mounted) return;
    switch (r) {
      case ApiOk():
        showAtomToast(context, kind: AtomToastKind.ok, message: l.feedbackSent);
        Navigator.of(context).pop();
      case ApiErr(:final failure):
        setState(() {
          _saving = false;
          _error = failure.kind == ApiFailureKind.notFound
              ? l.settingsFeedbackOff
              : failure.fieldErrors.values.firstOrNull ??
                    sayFailure(l, failure);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final online = ref.watch(onlineProvider).value ?? true;
    final (label, hint) = switch (_kind) {
      FeedbackKind.idea => (l.feedbackIdeaLabel, l.feedbackIdeaHint),
      FeedbackKind.problem => (l.feedbackProblemLabel, l.feedbackProblemHint),
      FeedbackKind.praise => (l.feedbackPraiseLabel, l.feedbackPraiseHint),
    };
    final short = _message.text.trim().length < 5;
    return AtomUnsavedGuard(
      dirty: _message.text.isNotEmpty && !_saving,
      child: SetPage(
        title: l.feedbackTitle,
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              AtomNote(kind: AtomNoteKind.problem, message: _error!),
              const SizedBox(height: 10),
            ],
            if (short && online) AtomButtonReason(reason: l.feedbackWriteFirst),
            AtomButton(
              label: online ? l.feedbackSend : l.dpDdNeedsInternet,
              saving: _saving,
              onPressed: short || !online ? null : _send,
            ),
          ],
        ),
        children: [
          SetPad(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AtomSegmented<FeedbackKind>(
                  segments: [
                    AtomSegment(FeedbackKind.idea, l.feedbackIdea),
                    AtomSegment(FeedbackKind.problem, l.feedbackProblem),
                    AtomSegment(FeedbackKind.praise, l.feedbackPraise),
                  ],
                  selected: _kind,
                  onChanged: (k) => setState(() => _kind = k),
                ),
                const SizedBox(height: 12),
                SetTextArea(
                  label: label,
                  controller: _message,
                  placeholder: hint,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                SetCompactButton(
                  label: _shot == null
                      ? l.feedbackScreenshot
                      : l.feedbackScreenshotAdded,
                  icon: LucideIcons.image,
                  onPressed: () async {
                    final f = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1600,
                      imageQuality: 70,
                    );
                    if (f != null) setState(() => _shot = File(f.path));
                  },
                ),
                const SizedBox(height: 12),
                AtomPressable(
                  onTap: () => setState(() => _withDevice = !_withDevice),
                  scaleOnPress: false,
                  toggled: _withDevice,
                  semanticLabel: l.feedbackWithDevice,
                  builder: (_, _) => ExcludeSemantics(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: AtomSize.tapTarget,
                      ),
                      child: Row(
                        children: [
                          AtomCheckbox(on: _withDevice),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l.feedbackWithDevice,
                              style: AtomText.body.copyWith(
                                color: AtomColors.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rate Brand Partner (18.10): four or five stars go to Google Play; fewer
/// ask what to fix.
Future<void> showRateSheet(BuildContext context) {
  return showAtomSheet<void>(
    context,
    builder: (_) => const Padding(
      // `.sheet` gap 14: the logo sits 14 under the grab.
      padding: EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: RateSheetBody(),
    ),
  );
}

/// The rate sheet's content (18.10), also shown by the Rate route.
class RateSheetBody extends StatefulWidget {
  const RateSheetBody({super.key});

  @override
  State<RateSheetBody> createState() => _RateState();
}

class _RateState extends State<RateSheetBody> {
  int _stars = 5;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final high = _stars >= 4;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AtomColors.line),
            ),
            child: Image.asset(
              'assets/brand/mark.png',
              width: 50,
              height: 50,
              semanticLabel: l.appName,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l.rateQuestion,
          textAlign: TextAlign.center,
          style: AtomText.heading,
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          children: [
            for (var i = 1; i <= 5; i++)
              AtomPressable(
                onTap: () => setState(() => _stars = i),
                semanticLabel: l.rateStars(i),
                selected: i == _stars,
                focusRadius: AtomRadius.brControl,
                builder: (_, _) => Padding(
                  padding: const EdgeInsets.all(4),
                  child: _Star(on: i <= _stars),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          high ? l.rateHigh : l.rateLow,
          textAlign: TextAlign.center,
          style: AtomText.secondary.copyWith(height: 1.45),
        ),
        const SizedBox(height: 14),
        AtomButton(
          label: high ? l.rateOnPlay : l.feedbackTitle,
          onPressed: () {
            final router = GoRouter.of(context);
            Navigator.of(context).pop();
            if (high) {
              launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
            } else {
              router.push(V2Routes.settingsStep('feedback'));
            }
          },
        ),
        const SizedBox(height: 14),
        Center(
          child: AtomLink(
            label: l.rateNotNow,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

/// A filled 36 star, amber when on, grey when off (19.10).
class _Star extends StatelessWidget {
  const _Star({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size.square(36),
    painter: _StarPainter(on ? AtomColors.amber : AtomColors.line2),
  );
}

class _StarPainter extends CustomPainter {
  const _StarPainter(this.colour);
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    // The board's star, drawn on a 24 grid.
    const pts = [
      (12.0, 2.0),
      (15.0, 8.0),
      (21.0, 8.9),
      (16.5, 13.3),
      (17.5, 19.5),
      (12.0, 16.5),
      (6.5, 19.5),
      (7.5, 13.3),
      (3.0, 8.9),
      (9.0, 8.0),
    ];
    final k = size.width / 24;
    final path = Path()..moveTo(pts.first.$1 * k, pts.first.$2 * k);
    for (final (x, y) in pts.skip(1)) {
      path.lineTo(x * k, y * k);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = colour
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = colour
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * k
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.colour != colour;
}

/// How we use your data (19.6): what is kept and where, the Excel export
/// (owner; the link is emailed), the privacy policy and closing the account.
class DataScreen extends ConsumerStatefulWidget {
  const DataScreen({super.key});

  @override
  ConsumerState<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends ConsumerState<DataScreen> {
  bool _saving = false;
  String? _done;
  String? _error;

  Future<void> _export() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    final r = await ref.read(settingsRepositoryProvider).export();
    if (!mounted) return;
    setState(() {
      _saving = false;
      switch (r) {
        case ApiOk(:final value):
          _done = l.exportStarted(value);
        case ApiErr(:final failure):
          _error = failure.kind == ApiFailureKind.notFound
              ? l.settingsExportOff
              : sayFailure(l, failure);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final owner =
        ref.watch(sessionProvider.notifier).current?.who.isOwner ?? false;
    final atom = ref.watch(accessProvider).has(Addon.askAtom);
    final offline = ref.watch(accessProvider).has(Addon.offline);
    final online = ref.watch(onlineProvider).value ?? true;
    Widget kept(IconData icon, String title, String body) => SetItem(
      icon: icon,
      tone: AtomTone.purple,
      title: title,
      subtitle: body,
      subWraps: true,
    );
    return SetPage(
      title: l.dataTitle,
      children: [
        AtomSectionLabel(l.dataKept),
        AtomRowGroup(
          children: [
            kept(LucideIcons.file, l.dataShop, l.dataShopBody),
            kept(
              LucideIcons.smartphone,
              l.dataPhone,
              // With Offline working on, a copy does stay on the phone.
              offline ? l.dataPhoneOfflineBody : l.dataPhoneBody,
            ),
            kept(LucideIcons.camera, l.dataCamera, l.dpDdDataCameraBody),
            if (atom) kept(LucideIcons.mic, l.dpDdDataAtom, l.dpDdDataAtomBody),
            kept(LucideIcons.clock, l.dataUsage, l.dataUsageBody),
          ],
        ),
        if (owner) ...[
          AtomSectionLabel(l.dataExport),
          AtomRowGroup(
            children: [
              SetItem(
                icon: LucideIcons.download,
                tone: AtomTone.green,
                title: l.dpDdDownloadAll,
                subtitle: l.dpDdDownloadAllSub,
              ),
            ],
          ),
          SetPad(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_done != null)
                  AtomNote(kind: AtomNoteKind.success, message: _done!)
                else ...[
                  if (_error != null) ...[
                    AtomNote(kind: AtomNoteKind.problem, message: _error!),
                    const SizedBox(height: 10),
                  ],
                  AtomButton(
                    label: online ? l.dataExportButton : l.dpDdNeedsInternet,
                    saving: _saving,
                    onPressed: online ? _export : null,
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
                  child: Text(
                    l.dpDdExportNote,
                    style: AtomText.small.copyWith(color: AtomColors.faint),
                  ),
                ),
              ],
            ),
          ),
        ],
        AtomSectionLabel(l.dpDdMore),
        AtomRowGroup(
          children: [
            SetItem(
              icon: LucideIcons.file,
              title: l.dpDdPrivacy,
              chevron: true,
              onTap: () => openPrivacyPolicy(context),
            ),
            if (owner)
              SetItem(
                icon: LucideIcons.trash,
                title: l.settingsDeleteTitle,
                danger: true,
                chevron: true,
                onTap: () =>
                    context.push(V2Routes.settingsStep('close-account')),
              ),
          ],
        ),
      ],
    );
  }
}

/// Delete account (owner): what stops and what is kept, then the password
/// (`POST me/delete`, App Store 5.1.1(v) and Google Play). On success the
/// phone signs out and forgets the quick sign-in. A 409 (orders still in
/// progress) is shown as the server says it.
class CloseAccountScreen extends ConsumerStatefulWidget {
  const CloseAccountScreen({super.key});

  @override
  ConsumerState<CloseAccountScreen> createState() => _CloseAccountScreenState();
}

class _CloseAccountScreenState extends ConsumerState<CloseAccountScreen> {
  final _reason = TextEditingController();
  final _password = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _reason.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final sure = await showAtomConfirm(
      context,
      title: l.settingsDeleteConfirmTitle,
      body: l.settingsDeleteConfirmBody,
      confirmLabel: l.settingsDeleteMine,
      destructive: true,
    );
    if (!sure || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final r = await ref
        .read(settingsRepositoryProvider)
        .deleteAccount(
          password: _password.text,
          reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
        );
    if (!mounted) return;
    switch (r) {
      case ApiOk(:final message):
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: message ?? l.settingsDeleted,
        );
        await ref.read(quickSignInProvider.notifier).erase();
        await ref.read(sessionProvider.notifier).signOut();
      case ApiErr(:final failure):
        setState(() {
          _saving = false;
          _error =
              failure.fieldErrors['password'] ??
              failure.fieldErrors.values.firstOrNull ??
              sayFailure(l, failure);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final online = ref.watch(onlineProvider).value ?? true;
    final problem = deleteProblem(l, password: _password.text, online: online);
    Widget line(String label, String value) =>
        AtomInfoLine(label: label, value: value);
    return SetPage(
      title: l.settingsDeleteTitle,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (problem != null && online) AtomButtonReason(reason: problem),
          AtomButton(
            label: online ? l.settingsDeleteMine : l.dpDdNeedsInternet,
            kind: AtomButtonKind.danger,
            saving: _saving,
            onPressed: problem == null ? _delete : null,
          ),
        ],
      ),
      children: [
        SetPad(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AtomNote(
                kind: AtomNoteKind.problem,
                message: l.settingsDeleteWarn,
                bold: [l.settingsDeleteWarnBold],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                decoration: AtomDecor.card,
                child: Column(
                  children: [
                    line(l.settingsDeleteSignIn, l.acctCloseStops),
                    const Divider(height: 1, color: AtomColors.line),
                    line(l.settingsDeletePage, l.settingsDeleteTakenOff),
                    const Divider(height: 1, color: AtomColors.line),
                    line(l.settingsDeleteRecords, l.acctCloseKept),
                    const Divider(height: 1, color: AtomColors.line),
                    line(l.acctCloseBills, l.acctCloseStillDue),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.settingsDeleteWhyKept,
                style: AtomText.secondary.copyWith(height: 1.45),
              ),
              const SizedBox(height: 12),
              SetCompactButton(
                label: l.acctCloseExportFirst,
                onPressed: () => context.push(V2Routes.settingsStep('data')),
              ),
              const SizedBox(height: 12),
              AtomTextField(
                label: l.acctCloseReason,
                labelNote: l.customerOptional,
                controller: _reason,
                placeholder: l.acctCloseReasonHint,
              ),
              const SizedBox(height: 12),
              AtomPasswordField(
                label: l.acctClosePassword,
                controller: _password,
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                AtomNote(kind: AtomNoteKind.problem, message: _error!),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// "Active", "Inactive", "On hold" for the brand's status.
String _statusLabel(AppLocalizations l, String? status) => switch (status) {
  null => '',
  'active' => l.settingsStatusActive,
  'inactive' => l.settingsStatusInactive,
  final s => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1),
};
