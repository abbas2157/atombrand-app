import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:atombrand_app/v2/core/services/fcm_service.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/db/copy_key.dart' show CopyKey;
import '../../../core/lock/app_lock.dart' show biometricsProvider;
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import 'settings_parts.dart';

// Permissions (18.7) and Storage & clear cache (18.8): about this phone, for
// everyone.

final notificationsAllowedProvider = FutureProvider.autoDispose<bool>(
  (ref) => FcmService.notificationsAllowed(),
);

/// Whether the camera is allowed (19.7); null where the phone can't say.
final _cameraAllowedProvider = FutureProvider.autoDispose<bool?>((ref) async {
  try {
    return await const MethodChannel('atombrand/settings')
        .invokeMethod<bool>('cameraAllowed');
  } on Object {
    return null;
  }
});

/// Whether the microphone is allowed (18.7); null where the phone can't say
/// or it was never asked for.
final _micAllowedProvider = FutureProvider.autoDispose<bool?>((ref) async {
  try {
    return await const MethodChannel('atombrand/settings')
        .invokeMethod<bool>('micAllowed');
  } on Object {
    return null;
  }
});

/// Whether the phone has a fingerprint or face set up for quick unlock.
final _biometricsReadyProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.read(biometricsProvider).available(),
);

/// Opens this app's page in the phone's settings (19.7).
Future<void> openPhoneSettings() async {
  try {
    await const MethodChannel('atombrand/settings')
        .invokeMethod<void>('openAppSettings');
  } on Object {
    await launchUrl(Uri.parse('app-settings:'));
  }
}

/// Permissions (19.7): what the app may use on this phone. Each is asked
/// for only when first needed. Notifications can be turned on here; the
/// rest change in the phone's settings.
class PermissionsScreen extends ConsumerWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final notif = ref.watch(notificationsAllowedProvider).value;
    final bio = ref.watch(_biometricsReadyProvider).value;
    final camera = ref.watch(_cameraAllowedProvider).value;
    final mic = ref.watch(_micAllowedProvider).value;
    Widget row(
      IconData icon,
      String title,
      String sub,
      Widget trailing, {
      AtomTone tone = AtomTone.green,
    }) => SetItem(
      icon: icon,
      tone: tone,
      title: title,
      subtitle: sub,
      // What each permission is for reads in full beside its pill.
      subWraps: true,
      trailing: trailing,
    );
    return SetPage(
      title: l.permissionsTitle,
      children: [
        SetDesc(l.permissionsBody),
        AtomSectionLabel(l.dpDdOnThisPhone),
        AtomRowGroup(
          children: [
            row(
              LucideIcons.camera,
              l.permissionsCamera,
              l.dpDdCameraSub,
              camera == true
                  ? SetPill(l.permissionsAllowed)
                  : SetPill(l.permissionsWhenUsed, tone: AtomTone.grey),
              tone: camera == true ? AtomTone.green : AtomTone.grey,
            ),
            row(
              LucideIcons.bell,
              l.permissionsNotifications,
              l.permissionsNotificationsSub,
              notif == false
                  ? AtomButton.small(
                      label: l.permissionsTurnOn,
                      kind: AtomButtonKind.primary,
                      onPressed: () async {
                        await FcmService.requestPermission();
                        ref.invalidate(notificationsAllowedProvider);
                      },
                    )
                  : SetPill(l.permissionsAllowed),
              tone: notif == false ? AtomTone.rose : AtomTone.green,
            ),
            row(
              LucideIcons.image,
              l.permissionsPhotos,
              l.permissionsPhotosSub,
              SetPill(l.dpDdSelected),
            ),
            row(
              LucideIcons.fingerprint,
              l.bioTitle,
              l.dpDdBioSub,
              bio == true
                  ? SetPill(l.permissionsAllowed)
                  : SetPill(l.dpDdNotAsked, tone: AtomTone.grey),
              tone: bio == true ? AtomTone.green : AtomTone.grey,
            ),
            row(
              LucideIcons.mic,
              l.settingsMic,
              l.settingsMicSub,
              mic == true
                  ? SetPill(l.permissionsAllowed)
                  : SetPill(l.dpDdNotAsked, tone: AtomTone.grey),
              tone: mic == true ? AtomTone.green : AtomTone.grey,
            ),
          ],
        ),
        SetPad(
          top: 14,
          child: AtomButton(
            label: l.dpDdOpenPhoneSettings,
            kind: AtomButtonKind.outline,
            onPressed: openPhoneSettings,
          ),
        ),
        SetTiny(l.dpDdPermissionsNever),
      ],
    );
  }
}

/// The app's cache on this phone, in bytes.
Future<int> _cacheBytes() async {
  try {
    final dir = await getTemporaryDirectory();
    var total = 0;
    await for (final f in dir.list(recursive: true, followLinks: false)) {
      if (f is File) total += await f.length();
    }
    return total;
  } catch (_) {
    return 0;
  }
}

/// The cache's size, for Storage and its row on Settings.
final cacheBytesProvider = FutureProvider.autoDispose<int>(
  (ref) => _cacheBytes(),
);

/// The offline copy's size on this phone (Offline add-on): the encrypted
/// database with its journal files, and the photos kept beside it.
Future<int> _offlineBytes() async {
  var total = 0;
  try {
    final db = await CopyKey.file();
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      final f = File('${db.path}$suffix');
      if (await f.exists()) total += await f.length();
    }
    final photos = Directory(
      '${db.parent.path}${Platform.pathSeparator}copy-photos',
    );
    if (await photos.exists()) {
      await for (final f in photos.list(recursive: true, followLinks: false)) {
        if (f is File) total += await f.length();
      }
    }
  } catch (_) {}
  return total;
}

/// The offline copy's size, for Storage and its row on Settings.
final offlineBytesProvider = FutureProvider.autoDispose<int>(
  (ref) => _offlineBytes(),
);

/// "84 MB", "2.4 MB", "0 MB".
String megabytes(int bytes) {
  final mb = bytes / (1024 * 1024);
  if (mb == 0) return '0 MB';
  return mb >= 10 ? '${mb.round()} MB' : '${mb.toStringAsFixed(1)} MB';
}

/// Storage (18.8): what the app keeps on this phone (the offline copy with
/// the Offline add-on, and the cache) and Clear cache. Clearing never
/// touches the offline copy.
class StorageScreen extends ConsumerWidget {
  const StorageScreen({super.key});

  Future<void> _clear(BuildContext context, WidgetRef ref, int bytes) async {
    final l = AppLocalizations.of(context);
    final yes = await showAtomConfirm(
      context,
      title: l.dpDdClearTitle(megabytes(bytes)),
      body: l.storageClearBody,
      confirmLabel: l.storageClearButton,
      sideBySide: true,
    );
    if (!yes) return;
    try {
      final dir = await getTemporaryDirectory();
      await for (final f in dir.list(followLinks: false)) {
        await f.delete(recursive: true);
      }
    } catch (_) {}
    PaintingBinding.instance.imageCache.clear();
    ref.invalidate(cacheBytesProvider);
    if (context.mounted) {
      showAtomToast(
        context,
        kind: AtomToastKind.ok,
        message: l.dpDdCacheFreed(megabytes(bytes)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bytes = ref.watch(cacheBytesProvider).value;
    final size = bytes == null ? '…' : megabytes(bytes);
    final offlineOn = ref.watch(accessProvider).has(Addon.offline);
    final copy = offlineOn ? ref.watch(offlineBytesProvider).value : 0;
    final total = bytes == null || copy == null ? null : bytes + copy;
    // The bar's parts: blue for the offline copy, amber for the cache.
    final copyShare = total == null || total == 0 ? 0 : copy! / total;
    final cacheShare = total == null || total == 0 ? 0 : bytes! / total;
    return SetPage(
      title: l.storageTitle,
      children: [
        SetPad(
          top: 14,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: AtomDecor.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(l.dpDdUsed, style: AtomText.secondary),
                    ),
                    Text(
                      total == null ? '…' : megabytes(total),
                      style: AtomText.secondary.copyWith(
                        color: AtomColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: AtomRadius.brControl,
                  child: Container(
                    height: 8,
                    color: AtomColors.surface,
                    // Stretch: a childless ColoredBox takes its smallest
                    // size, so without it the parts are 0 tall.
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (copyShare > 0)
                          Expanded(
                            flex: (copyShare * 1000).round().clamp(1, 1000),
                            child: const ColoredBox(color: AtomColors.primary),
                          ),
                        if (cacheShare > 0)
                          Expanded(
                            flex: (cacheShare * 1000).round().clamp(1, 1000),
                            child: const ColoredBox(color: AtomColors.amber),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 2,
                  children: [
                    if (offlineOn)
                      Text(l.settingsBlueKey, style: AtomText.small),
                    Text(l.dpDdCacheKey, style: AtomText.small),
                  ],
                ),
              ],
            ),
          ),
        ),
        AtomSectionLabel(l.dpDdDetails),
        AtomRowGroup(
          children: [
            if (offlineOn)
              SetItem(
                icon: LucideIcons.database,
                tone: AtomTone.blue,
                title: l.settingsOfflineCopy,
                subtitle: l.settingsOfflineCopySub,
                subWraps: true,
                value: copy == null ? '…' : megabytes(copy),
              ),
            SetItem(
              icon: LucideIcons.image,
              tone: AtomTone.amber,
              title: l.storageCache,
              subtitle: l.dpDdCacheSub,
              value: size,
            ),
          ],
        ),
        SetPad(
          top: 14,
          child: AtomButton(
            label: l.storageClear,
            kind: AtomButtonKind.outline,
            onPressed: bytes == null || bytes == 0
                ? null
                : () => _clear(context, ref, bytes),
          ),
        ),
        SetTiny(offlineOn ? l.settingsOfflineCopyNote : l.dpDdStorageNote),
      ],
    );
  }
}
