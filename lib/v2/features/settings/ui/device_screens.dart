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

/// "84 MB", "2.4 MB", "0 MB".
String megabytes(int bytes) {
  final mb = bytes / (1024 * 1024);
  if (mb == 0) return '0 MB';
  return mb >= 10 ? '${mb.round()} MB' : '${mb.toStringAsFixed(1)} MB';
}

/// Storage (19.8): what the app keeps on this phone (only the cache: there
/// is no offline copy without the Offline add-on) and Clear cache.
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
                      size,
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
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: (bytes ?? 0) > 0 ? 1 : 0,
                      heightFactor: 1,
                      child: const ColoredBox(color: AtomColors.amber),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(l.dpDdCacheKey, style: AtomText.small),
              ],
            ),
          ),
        ),
        AtomSectionLabel(l.dpDdDetails),
        AtomRowGroup(
          children: [
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
        SetTiny(l.dpDdStorageNote),
      ],
    );
  }
}
