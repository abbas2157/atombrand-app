import 'dart:math';

/// A uuid (v4), for an action, a record made on the phone, and this
/// install's own id.
///
/// Version 4 and variant 1, the shape `Str::isUuid` takes: the server
/// refuses anything else, and a record made offline keeps this id when it
/// reaches the server (`Action::adoptUuid`).
String newUuid() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String hex(int from, int to) =>
      [for (var i = from; i < to; i++) b[i].toRadixString(16).padLeft(2, '0')]
          .join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}
