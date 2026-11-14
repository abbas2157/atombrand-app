import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'install_id.dart';

/// What `login` is told about this phone, so Devices & sessions
/// (19.3) can name it and the sync contract can tie the token to it:
/// `device_id` (§2, a uuid made once per install), `platform` (android,
/// ios), `device_name` ("Samsung SM-A556E") and `app_version`. The server
/// keeps 80 characters of the name.
///
/// `id` is the one that matters beyond naming: without it the phone is
/// never registered, and the server refuses it an offline copy.
typedef LoginDevice = ({
  String? id,
  String? platform,
  String? name,
  String? version,
});

/// The brand and the model as one name: "Samsung SM-A556E", "Google Pixel
/// 7". The brand is left out when the model already starts with it, and
/// either part may be missing.
@visibleForTesting
String? deviceLabel(String? brand, String? model) {
  final b = (brand ?? '').trim();
  final m = (model ?? '').trim();
  final shown = b.isEmpty ? '' : b[0].toUpperCase() + b.substring(1);
  if (m.isEmpty) return shown.isEmpty ? null : shown;
  if (shown.isEmpty || m.toLowerCase().startsWith(b.toLowerCase())) return m;
  return '$shown $m';
}

/// This phone, read once. A name we can't read sends nothing and the
/// server says "Brand Partner app"; the id is read on its own, because
/// losing the name only costs a label, and losing the id costs the
/// offline copy.
Future<LoginDevice> readLoginDevice() async {
  final id = await InstallId.read();
  final version = await _appVersion();
  if (kIsWeb) return (id: id, platform: 'web', name: null, version: version);
  try {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final a = await info.androidInfo;
      return (
        id: id,
        platform: 'android',
        name: deviceLabel(a.brand, a.model),
        version: version,
      );
    }
    if (Platform.isIOS) {
      final i = await info.iosInfo;
      return (
        id: id,
        platform: 'ios',
        name: deviceLabel('Apple', i.modelName),
        version: version,
      );
    }
  } catch (_) {
    // Unknown phone: no name.
  }
  return (id: id, platform: null, name: null, version: version);
}

/// The build's own version, for the Devices list (19.3).
Future<String?> _appVersion() async {
  try {
    return (await PackageInfo.fromPlatform()).version;
  } catch (_) {
    return null;
  }
}
