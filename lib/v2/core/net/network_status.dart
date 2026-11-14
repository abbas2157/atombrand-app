import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the phone has a network (Wi-Fi, mobile data, …). It can't tell
/// that the server answers: a failed call still says "No internet" too.
abstract interface class NetworkStatus {
  Future<bool> check();
  Stream<bool> watch();
}

class DeviceNetworkStatus implements NetworkStatus {
  DeviceNetworkStatus();
  final _connectivity = Connectivity();

  static bool _online(List<ConnectivityResult> r) =>
      r.isNotEmpty && !r.every((c) => c == ConnectivityResult.none);

  @override
  Future<bool> check() async {
    try {
      return _online(await _connectivity.checkConnectivity());
    } catch (_) {
      // No plugin (tests, an odd platform): don't claim to be offline.
      return true;
    }
  }

  @override
  Stream<bool> watch() {
    try {
      return _connectivity.onConnectivityChanged
          .map(_online)
          .handleError((Object _) {});
    } catch (_) {
      return const Stream.empty();
    }
  }
}

final networkStatusProvider = Provider<NetworkStatus>(
  (ref) => DeviceNetworkStatus(),
);

/// The phone's network, as it changes. Sign in's "Online" / "No internet"
/// pill (2.1, 2.2) and the lock screens' "Online" pill watch this.
///
/// A "no network" event is only believed once a direct check agrees.
/// Some phones (seen on ColorOS) emit a stray `none` and then nothing
/// else, and the app would sit on "No internet" with a working radio:
/// refusing the first sign-in, reading the copy instead of asking the
/// server, and — worst — never draining the outbox, because the
/// scheduler sends when this says the signal came back.
///
/// Being wrong the other way is cheap: a call is tried and fails, and
/// the failure is what moves the app to the copy anyway.
final onlineProvider = StreamProvider<bool>((ref) async* {
  final net = ref.read(networkStatusProvider);
  var last = await net.check();
  yield last;
  await for (final said in net.watch()) {
    final now = said || await net.check();
    if (now != last) yield last = now;
  }
});
