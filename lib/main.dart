import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'v2/app/app.dart';
import 'v2/core/api/api_retry.dart';
import 'v2/core/api/atom_server.dart';
import 'v2/core/db/photo_cache.dart';
import 'v2/core/quiet_logs.dart';
import 'v2/core/services/fcm_service.dart';
import 'v2/core/update/update_policy.dart';
import 'v2/features/sync/data/background_sync.dart';

/// Brand Partner (v2, lib/v2). The v1 app under lib/ (app.dart, core/,
/// data/, features/, widgets/) is kept for reference while v2 is built and
/// is not started or imported by v2.
///
/// Only Firebase core is awaited before the first frame; push starts after
/// it, without the permission prompt: the app explains why first (15.8)
/// and asks itself.
void main() async {
  if (kReleaseMode && AtomServer.isLocal) {
    throw StateError(
      'A release build must use atomshop.pk; drop --dart-define=ATOM_SERVER.',
    );
  }
  WidgetsFlutterBinding.ensureInitialized();
  quietLogsInRelease();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  try {
    // From google-services.json / GoogleService-Info.plist (docs/RELEASE.md);
    // without them push is off and the app carries on.
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[v2] Firebase did not start: $e');
  }

  // This build's platform and number, sent with every request.
  await InstalledApp.load();

  // Photos seen online, kept on the phone: a few ms.
  await PhotoCache.start();

  // Server reads that fail with a definite answer (404, 403…) aren't tried
  // again; see apiRetry.
  runApp(const ProviderScope(retry: apiRetry, child: BrandPartnerApp()));

  unawaited(() async {
    // Sync with the app closed (WorkManager), for the Offline add-on.
    await BackgroundSync.initialise();
    try {
      await FcmService.initialize(requestPermission: false);
    } catch (e) {
      debugPrint('[v2] FcmService.initialize() threw: $e');
    }
  }());
}
