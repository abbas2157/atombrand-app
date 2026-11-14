import 'package:flutter/foundation.dart';

/// Release builds print nothing.
///
/// `debugPrint` writes to the device log in every build. In release that
/// is work for nothing on every sync, and the log holds what it should
/// not: the push token, push contents, sync details. Debug and profile
/// builds keep it, for finding problems on a phone.
///
/// Each isolate has its own `debugPrint`: called in `main`, in the
/// background sync's entry point, and in the push handler.
void quietLogsInRelease() {
  if (kReleaseMode) debugPrint = (String? message, {int? wrapWidth}) {};
}
