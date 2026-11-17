import 'dart:async';

import 'package:atombrand_app/v2/core/db/copy_key.dart';

/// Runs before every test file under `test/`.
///
/// A host test has no Keystore. Without this, the copy's key waits on a
/// platform call that never answers under the test clock, and anything
/// behind it — unlocking with the PIN — never finishes.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  CopyKey.noKeystoreForTest();
  await testMain();
}
