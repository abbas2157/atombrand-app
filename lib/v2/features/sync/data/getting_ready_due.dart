import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Getting ready (2.7) is due on the way in: set when this phone's PIN is
/// set (2.5) or the outlet is chosen (2.6), so the first offline copy
/// comes down before Home. The guards only act on it while the Offline
/// add-on is on (`wayInProvider`). In memory: a later cold start goes
/// straight Home and the copy carries on in the background.
final gettingReadyDueProvider = NotifierProvider<GettingReadyDue, bool>(
  GettingReadyDue.new,
);

class GettingReadyDue extends Notifier<bool> {
  @override
  bool build() => false;

  /// The PIN or the outlet was just set: show Getting ready next.
  void arm() => state = true;

  /// "Start working now", or the copy is done.
  void done() => state = false;
}
