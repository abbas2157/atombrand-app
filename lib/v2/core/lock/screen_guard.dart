import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_storage_methods.dart';

/// Block screenshots (19.2, "On this phone"): on by default. While it is on,
/// screens with customers' CNIC photos and documents can't be captured or
/// shown in the recent-apps preview (Android FLAG_SECURE).
final blockScreenshotsProvider = NotifierProvider<BlockScreenshots, bool>(
  BlockScreenshots.new,
);

class BlockScreenshots extends Notifier<bool> {
  static const _key = 'v2_block_screenshots';

  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    try {
      final v = await LocalStorageMethods.instance.readData(_key);
      if (v == 'off') state = false;
    } catch (_) {}
  }

  Future<void> set(bool on) async {
    state = on;
    try {
      await LocalStorageMethods.instance.writeData(_key, on ? 'on' : 'off');
    } catch (_) {}
  }
}

/// Wraps a screen that shows CNIC photos or documents: while it is open
/// (and Block screenshots is on) the window is secure.
class ScreenGuard extends ConsumerStatefulWidget {
  const ScreenGuard({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<ScreenGuard> createState() => _ScreenGuardState();
}

class _ScreenGuardState extends ConsumerState<ScreenGuard> {
  bool _held = false;

  void _hold(bool on) {
    if (on == _held) return;
    _held = on;
    _SecureWindow.change(on ? 1 : -1);
  }

  @override
  void initState() {
    super.initState();
    _hold(ref.read(blockScreenshotsProvider));
  }

  @override
  void dispose() {
    _hold(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(blockScreenshotsProvider, (_, on) => _hold(on));
    return widget.child;
  }
}

/// Counts the guarded screens open; the window is secure while any is.
abstract final class _SecureWindow {
  static const _channel = MethodChannel('atombrand/secure');
  static int _open = 0;

  static void change(int by) {
    final was = _open > 0;
    _open = (_open + by).clamp(0, 1 << 20);
    final now = _open > 0;
    if (was == now || !Platform.isAndroid) return;
    _channel.invokeMethod<void>('set', now).catchError((_) {});
  }
}
