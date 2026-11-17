import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';

import '../access/app_update.dart' show versionBelow;
import 'update_policy.dart';

/// What the phone's store can say and do about updates.
abstract interface class StoreUpdates {
  /// What the store has for this phone. Null when it can't be asked
  /// (installed outside Google Play, no network, not supported).
  Future<StoreInfo?> info(InstalledApp installed, UpdatePolicy policy);

  /// Android: Google Play's own full-screen update. False when it could
  /// not start or the seller backed out.
  Future<bool> immediate();

  /// Android: Google Play asks once, then downloads while the seller
  /// works. False when declined or not possible.
  Future<bool> startFlexible();

  /// Android: installs a downloaded flexible update. In the background the
  /// install is silent; in the foreground Play shows a short restart.
  Future<void> completeFlexible();

  /// Android: the flexible download's progress.
  Stream<InstallStatus> get installStatus;
}

/// Google Play In-App Updates (`in_app_update`).
class PlayStoreUpdates implements StoreUpdates {
  const PlayStoreUpdates();

  @override
  Future<StoreInfo?> info(InstalledApp installed, UpdatePolicy policy) async {
    try {
      final i = await InAppUpdate.checkForUpdate();
      return StoreInfo(
        updateAvailable:
            i.updateAvailability == UpdateAvailability.updateAvailable ||
            i.updateAvailability ==
                UpdateAvailability.developerTriggeredUpdateInProgress,
        priority: i.updatePriority,
        stalenessDays: i.clientVersionStalenessDays,
        flexibleAllowed: i.flexibleUpdateAllowed,
        immediateAllowed: i.immediateUpdateAllowed,
        downloaded: i.installStatus == InstallStatus.downloaded,
        immediateInProgress:
            i.updateAvailability ==
            UpdateAvailability.developerTriggeredUpdateInProgress,
        availableBuild: i.availableVersionCode,
      );
    } on PlatformException catch (e) {
      // ERROR_API_NOT_AVAILABLE: not installed by Google Play (a shared
      // APK, a test build), or no Play Store on this phone.
      debugPrint('[update] Google Play cannot be asked: ${e.code}');
      return null;
    } catch (e) {
      debugPrint('[update] Google Play cannot be asked: $e');
      return null;
    }
  }

  @override
  Future<bool> immediate() async {
    try {
      return await InAppUpdate.performImmediateUpdate() ==
          AppUpdateResult.success;
    } catch (e) {
      debugPrint('[update] immediate update did not start: $e');
      return false;
    }
  }

  @override
  Future<bool> startFlexible() async {
    try {
      return await InAppUpdate.startFlexibleUpdate() == AppUpdateResult.success;
    } catch (e) {
      debugPrint('[update] download did not start: $e');
      return false;
    }
  }

  @override
  Future<void> completeFlexible() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      debugPrint('[update] could not install the download: $e');
    }
  }

  @override
  Stream<InstallStatus> get installStatus => InAppUpdate.installUpdateListener
      .handleError((Object e) => debugPrint('[update] status: $e'));
}

/// iOS: Apple has no in-app update API. The App Store's lookup says which
/// version it has, so the app never says "update" before Apple's listing
/// has it — the lookup is known to lag hours behind a release. It is a
/// public endpoint with unpublished rate limits: asked only when the
/// server says something newer exists, and the answer is kept for a day
/// (`UpdatesController`).
class AppStoreUpdates implements StoreUpdates {
  AppStoreUpdates({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ),
          );

  final Dio _dio;

  @override
  Future<StoreInfo?> info(InstalledApp installed, UpdatePolicy policy) async {
    final id = policy.appStoreId;
    if (id == null) return null;
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        'https://itunes.apple.com/lookup',
        queryParameters: {
          'id': id,
          'country': policy.storeCountry,
          // Apple caches the answer; a fresh query string asks again.
          't': DateTime.now().millisecondsSinceEpoch ~/ 60000,
        },
        options: Options(responseType: ResponseType.json),
      );
      final results = r.data?['results'];
      if (results is! List || results.isEmpty) return null;
      final version = (results.first as Map)['version'] as String?;
      if (version == null) return null;
      return lookupInfo(installed, version);
    } catch (e) {
      debugPrint('[update] App Store cannot be asked: $e');
      return null;
    }
  }

  /// What a lookup answer means for [installed].
  static StoreInfo lookupInfo(InstalledApp installed, String storeVersion) =>
      StoreInfo(
        updateAvailable: versionBelow(installed.version, storeVersion),
        storeVersion: storeVersion,
      );

  @override
  Future<bool> immediate() async => false;

  @override
  Future<bool> startFlexible() async => false;

  @override
  Future<void> completeFlexible() async {}

  @override
  Stream<InstallStatus> get installStatus => const Stream.empty();
}

/// Anything else (tests, web): the store is never asked.
class NoStoreUpdates implements StoreUpdates {
  const NoStoreUpdates();

  @override
  Future<StoreInfo?> info(InstalledApp installed, UpdatePolicy policy) async =>
      null;

  @override
  Future<bool> immediate() async => false;

  @override
  Future<bool> startFlexible() async => false;

  @override
  Future<void> completeFlexible() async {}

  @override
  Stream<InstallStatus> get installStatus => const Stream.empty();
}

/// The store for this phone.
StoreUpdates storeUpdatesForPlatform() {
  if (kIsWeb) return const NoStoreUpdates();
  if (Platform.isAndroid) return const PlayStoreUpdates();
  if (Platform.isIOS) return AppStoreUpdates();
  return const NoStoreUpdates();
}
