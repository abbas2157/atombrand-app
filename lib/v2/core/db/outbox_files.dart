import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The photos a queued save carries, kept where the save can still find
/// them days later.
///
/// The camera and the picker hand back a file in the phone's cache, which
/// Android empties whenever it likes. A payment photographed in a basement
/// may not be sent for a week, so the file is copied into the app's own
/// storage the moment the save is queued, and deleted again when the
/// action leaves the outbox.
///
/// App storage, never the gallery or anywhere else on the phone
/// (`RULES.md` §1.4): these are payment proofs and delivery photos.
class OutboxFiles {
  const OutboxFiles(this.root);

  /// `<app documents>/outbox`, or a temporary folder in a test.
  final Directory root;

  static Future<OutboxFiles> open() async {
    final dir = await getApplicationDocumentsDirectory();
    return OutboxFiles(Directory(p.join(dir.path, 'outbox')));
  }

  Directory _of(String actionId) => Directory(p.join(root.path, actionId));

  /// Copies [files] in, and answers the field-to-path map the outbox row
  /// keeps. A file that cannot be copied is left out rather than failing
  /// the save: the seller's work matters more than the photo, and the
  /// server's own rules decide whether the photo was required.
  Future<Map<String, String>> keep(
    String actionId,
    Map<String, File> files,
  ) async {
    if (files.isEmpty) return const {};
    final dir = _of(actionId);
    final out = <String, String>{};
    for (final e in files.entries) {
      try {
        await dir.create(recursive: true);
        final name = '${e.key}${p.extension(e.value.path)}';
        final to = File(p.join(dir.path, name));
        await e.value.copy(to.path);
        out[e.key] = to.path;
      } on FileSystemException {
        continue;
      }
    }
    return out;
  }

  /// The files of [paths] as they are now. One that has gone missing is
  /// left out, so a half-cleaned folder still sends what is left.
  Map<String, File> read(Map<String, String> paths) {
    final out = <String, File>{};
    for (final e in paths.entries) {
      final f = File(e.value);
      if (f.existsSync()) out[e.key] = f;
    }
    return out;
  }

  /// The action has left the outbox: its photos go with it.
  Future<void> forget(String actionId) async {
    try {
      final dir = _of(actionId);
      if (await dir.exists()) await dir.delete(recursive: true);
    } on FileSystemException {
      // The next wipe takes it.
    }
  }

  /// Every queued photo, gone (a wipe, or signing out).
  Future<void> forgetAll() async {
    try {
      if (await root.exists()) await root.delete(recursive: true);
    } on FileSystemException {
      // Nothing more to do: the key goes too, so nothing is readable.
    }
  }
}
