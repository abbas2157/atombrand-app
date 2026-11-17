import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../update/updates_controller.dart';

/// What `GET app/config` says about this app's version.
@immutable
class AppUpdate {
  const AppUpdate({required this.required, this.storeUrl});

  /// This version is below the server's minimum: only the Update screen.
  final bool required;

  /// The Play Store page, from the config; null uses the package's page.
  final String? storeUrl;
}

/// Whether this app must update before anything else (`app/config` →
/// `seller.update`, docs/trd/2026-11-09-seller-app-updates.md).
abstract interface class AppUpdateRepository {
  /// Null when it can't tell (offline, no version on the server): the app
  /// carries on.
  Future<AppUpdate?> check();
}

/// The update gate's answer from [UpdatesController], which also drives
/// the gentle banner, Google Play's downloads and What's new: one check
/// for all of them.
class ApiAppUpdateRepository implements AppUpdateRepository {
  const ApiAppUpdateRepository(this._ref);
  final Ref _ref;

  @override
  Future<AppUpdate?> check() async {
    final s = await _ref.read(updatesProvider.notifier).check();
    if (s.policy == null) return null;
    return AppUpdate(required: s.blocking, storeUrl: s.policy?.storeUrl);
  }
}

final appUpdateRepositoryProvider = Provider<AppUpdateRepository>(
  ApiAppUpdateRepository.new,
);

/// Whether [current] is an older version than [min] ("1.9.3" < "2.0.0").
/// Build suffixes ("+7", "-beta") are ignored; missing parts count as 0.
bool versionBelow(String current, String min) {
  List<int> parts(String v) => [
    for (final p in v.split(RegExp(r'[+-]')).first.trim().split('.'))
      int.tryParse(p) ?? 0,
  ];
  final a = parts(current);
  final b = parts(min);
  for (var i = 0; i < 3; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x < y;
  }
  return false;
}
