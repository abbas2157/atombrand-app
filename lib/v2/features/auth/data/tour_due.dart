import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../help/data/help_repository.dart';

/// Whether the first-time tour (17.7) is still to show on this phone: the
/// last step on the way in. Null while it is read.
final tourDueProvider = NotifierProvider<TourDue, bool?>(TourDue.new);

class TourDue extends Notifier<bool?> {
  @override
  bool? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    bool show;
    try {
      show = await ref.read(tourMemoryProvider).shouldShow();
    } catch (_) {
      show = false;
    }
    // Done meanwhile (a test, a fast tap): keep that.
    state ??= show;
  }

  /// Skip or Start: never again on this phone.
  Future<void> done() async {
    state = false;
    await ref.read(tourMemoryProvider).markShown();
  }
}
