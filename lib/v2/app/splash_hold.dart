import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long the splash (1.1, 1.2) stays on a cold start.
///
/// Android 12 and later draw only the icon on the system splash, so the
/// board's splash (name, tagline, "by Atomshop.pk", the shop for a
/// returning person) is the Flutter one. Reading the session takes a few
/// milliseconds, so without a hold it would never be seen.
const splashHold = Duration(milliseconds: 1500);

/// True while the splash is held after a cold start. Widget tests don't
/// hold it (they start where they need to be).
final splashHoldProvider = NotifierProvider<SplashHold, bool>(SplashHold.new);

class SplashHold extends Notifier<bool> {
  @override
  bool build() {
    if (_inTest) return false;
    // Counted from the first frame, so a slow start (a debug build, an old
    // phone) still shows the splash for the whole hold.
    Timer? timer;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      timer = Timer(splashHold, () => state = false);
    });
    ref.onDispose(() => timer?.cancel());
    return true;
  }

  static bool get _inTest =>
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
}
