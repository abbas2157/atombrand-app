import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../access/app_update.dart' show versionBelow;
import '../api/api_client.dart' show Json;

/// What `app/config` says about updates for this phone's platform
/// (`update.<android|ios>` in `GET config`, admin: App updates).
///
/// Builds, not version names, decide: names differ between the stores
/// (the App Store had 1.0 while Google Play had 2.x), and only build
/// numbers always go up.
@immutable
class UpdatePolicy {
  const UpdatePolicy({
    this.latestVersion,
    this.latestBuild,
    this.recommendedBuild,
    this.minBuild,
    this.minVersion,
    this.blockedBuilds = const {},
    this.notes,
    this.storeUrl,
    this.appStoreId,
    this.storeCountry = 'pk',
    this.checkHours = 6,
  });

  /// Shown to people ("2.1.0").
  final String? latestVersion;

  /// The newest build in the store.
  final int? latestBuild;

  /// Below this: a gentle "update available".
  final int? recommendedBuild;

  /// Below this: the update comes before anything else.
  final int? minBuild;

  /// The old name-based minimum, for a server that has no builds yet.
  final String? minVersion;

  /// Builds pulled for a bug: treated as too old.
  final Set<int> blockedBuilds;

  /// What's new in [latestBuild], one point per line.
  final String? notes;

  final String? storeUrl;

  /// iOS: the App Store's numeric id, to ask it what it really has.
  final String? appStoreId;
  final String storeCountry;

  /// How long this answer may be kept before asking again.
  final int checkHours;

  /// The policy for [platform] from `GET config`'s data
  /// (`update.<android|ios>`, admin: App updates → atombrand).
  static UpdatePolicy? fromConfig(Object? data, String platform) {
    final config = Json.map(data);
    final mine = Json.map(Json.map(config['update'])[platform]);
    if (mine.isEmpty) return null;
    return UpdatePolicy.fromJson(mine);
  }

  factory UpdatePolicy.fromJson(
    Map<String, dynamic> j, {
    String? legacyMinVersion,
  }) {
    int? positive(Object? v) {
      final n = Json.integer(v);
      return n != null && n > 0 ? n : null;
    }

    return UpdatePolicy(
      latestVersion: Json.str(j['latest_version']),
      latestBuild: positive(j['latest_build']),
      recommendedBuild: positive(j['recommended_build']),
      minBuild: positive(j['min_build']),
      minVersion: Json.str(j['min_version']) ?? legacyMinVersion,
      blockedBuilds: {
        for (final b in Json.list(j['blocked_builds'])) ?positive(b),
      },
      notes: Json.str(j['notes']),
      storeUrl: Json.str(j['store_url']),
      appStoreId: Json.str(j['app_store_id']),
      storeCountry: Json.str(j['store_country']) ?? 'pk',
      checkHours: (positive(j['check_hours']) ?? 6).clamp(1, 48),
    );
  }

  Map<String, dynamic> toJson() => {
    'latest_version': latestVersion,
    'latest_build': latestBuild,
    'recommended_build': recommendedBuild,
    'min_build': minBuild,
    'min_version': minVersion,
    'blocked_builds': blockedBuilds.toList(),
    'notes': notes,
    'store_url': storeUrl,
    'app_store_id': appStoreId,
    'store_country': storeCountry,
    'check_hours': checkHours,
  };

  /// The points of [notes], without list marks.
  List<String> get notePoints => [
    for (final line in (notes ?? '').split('\n'))
      if (line.replaceFirst(RegExp(r'^\s*[-*•]\s*'), '').trim() case final p
          when p.isNotEmpty)
        p,
  ];
}

/// This install.
@immutable
class InstalledApp {
  const InstalledApp({
    required this.version,
    required this.build,
    required this.platform,
    this.fromPlay = false,
  });

  final String version;

  /// 0 when unknown.
  final int build;

  /// `android` or `ios`.
  final String platform;

  /// Installed by Google Play: Play's own answer about updates counts.
  final bool fromPlay;

  /// This install, once [load] has run (in `main`, and in a background
  /// run). Null in tests and before then: requests then go without the
  /// platform and build headers, as before.
  static InstalledApp? current;

  /// Reads this install's version, build and installer, once.
  static Future<InstalledApp?> load() async {
    if (current != null) return current;
    if (kIsWeb) return null;
    try {
      final info = await PackageInfo.fromPlatform();
      final platform = Platform.isIOS ? 'ios' : 'android';
      return current = InstalledApp(
        version: info.version,
        build: int.tryParse(info.buildNumber) ?? 0,
        platform: platform,
        fromPlay: info.installerStore == 'com.android.vending',
      );
    } catch (e) {
      debugPrint('[update] no app version: $e');
      return null;
    }
  }
}

/// What the store says. Null fields: it did not say.
@immutable
class StoreInfo {
  const StoreInfo({
    required this.updateAvailable,
    this.storeVersion,
    this.priority = 0,
    this.stalenessDays,
    this.flexibleAllowed = false,
    this.immediateAllowed = false,
    this.downloaded = false,
    this.immediateInProgress = false,
    this.availableBuild,
  });

  /// The store has something newer for this phone. False is a real
  /// "nothing newer here" (a staged rollout that has not reached it, or
  /// an App Store listing that has not caught up).
  final bool updateAvailable;

  /// iOS: the App Store's version name.
  final String? storeVersion;

  /// Google Play's in-app update priority, 0 to 5.
  final int priority;
  final int? stalenessDays;
  final bool flexibleAllowed;
  final bool immediateAllowed;

  /// A flexible update has finished downloading and waits to install.
  final bool downloaded;

  /// An immediate update was started and left part-way (the app closed).
  final bool immediateInProgress;

  /// Android: the version code Play would install.
  final int? availableBuild;
}

/// How firmly to ask.
enum UpdateLevel {
  /// Nothing to say.
  none,

  /// A banner the seller can close.
  gentle,

  /// The update comes before anything else.
  required,

  /// This build was pulled for a bug: the same as [required], its own words.
  blocked,

  /// Required, but the store has nothing newer for this phone yet (a
  /// staged rollout, an App Store listing a few hours behind). Blocking
  /// would leave the seller with nothing to do, so the app works and says
  /// the update is on its way.
  comingSoon,
}

/// Decides how firmly to ask. Pure, so every rule is a test.
///
/// - A pulled build, or one below the minimum, must update — unless the
///   store answers for certain that it has nothing newer for this phone.
/// - Below the recommended build: a gentle banner, if the store (when it
///   can be asked) has the update.
/// - With no policy (offline, never fetched): nothing. Not knowing never
///   blocks.
UpdateLevel decideUpdate({
  required InstalledApp installed,
  required UpdatePolicy? policy,
  required StoreInfo? store,
}) {
  if (policy == null) return UpdateLevel.none;
  final build = installed.build;
  final known = build > 0;

  final pulled = known && policy.blockedBuilds.contains(build);
  final belowMin = known
      ? (policy.minBuild != null && build < policy.minBuild!)
      : (policy.minVersion != null &&
            versionBelow(installed.version, policy.minVersion!));

  // Only an answer that can be trusted says "nothing newer": Play for an
  // app Play installed, the App Store lookup on iOS.
  final storeSaysNothing =
      store != null &&
      !store.updateAvailable &&
      (installed.platform == 'ios' || installed.fromPlay);

  if (pulled || belowMin) {
    if (storeSaysNothing) return UpdateLevel.comingSoon;
    return pulled ? UpdateLevel.blocked : UpdateLevel.required;
  }

  final recommended = policy.recommendedBuild;
  if (known && recommended != null && build < recommended) {
    // iOS: only once the App Store really has it, so "Update" never opens
    // a page that still says "Open". Android: Play's answer when it gives
    // one; the server's otherwise (installed outside Play).
    if (store == null) {
      return installed.platform == 'ios'
          ? UpdateLevel.none
          : UpdateLevel.gentle;
    }
    return store.updateAvailable ? UpdateLevel.gentle : UpdateLevel.none;
  }
  return UpdateLevel.none;
}
