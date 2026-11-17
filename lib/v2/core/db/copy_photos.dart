import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The photos that come down with the phone's copy: product pictures,
/// payment proofs, receipts and other photos the copy points at.
///
/// A file is kept under the same address the screens ask for
/// (`AtomServer.fileUrl`), so a screen holding a photo's address can find
/// the downloaded one without knowing anything about sync. The address is
/// hashed to a filename: it is a URL, and URLs are not filenames.
///
/// App storage, never the gallery: these are the brand's photos, and they
/// go when the copy goes.
class CopyPhotos {
  const CopyPhotos(this.root);

  /// `<app documents>/copy-photos`, or a temporary folder in a test.
  final Directory root;

  /// The one the screens read. Null until [start] has run, which is on
  /// purpose: a screen asks and is answered "not here" rather than
  /// waiting on the disk while it builds. Tests set it directly.
  static CopyPhotos? current;

  static Future<CopyPhotos> start() async {
    final dir = await getApplicationDocumentsDirectory();
    return current = CopyPhotos(Directory(p.join(dir.path, 'copy-photos')));
  }

  /// The file this address would be kept in, whether or not it is there.
  File fileFor(String url) {
    final name = sha256.convert(utf8.encode(url)).toString().substring(0, 40);
    final dot = url.lastIndexOf('.');
    final ext = dot > 0 && url.length - dot <= 5
        ? url.substring(dot).toLowerCase()
        : '.img';
    return File(p.join(root.path, '$name$ext'));
  }

  /// The downloaded photo at this address, or null.
  ///
  /// Synchronous on purpose: an image is asked for while a list is
  /// scrolling, and a Future there would flash the fallback first.
  static File? localFor(String? url) {
    if (url == null || url.isEmpty) return null;
    final store = current;
    if (store == null) return null;
    final f = store.fileFor(url);
    return f.existsSync() ? f : null;
  }

  Future<bool> has(String url) => fileFor(url).exists();

  /// How long a photo the server said it does not have is left alone.
  /// A photo taken again is a new file with a new address, so this only
  /// spares asking for the same missing one on every sync.
  static const missingFor = Duration(days: 7);

  File _missingMark(String url) => File('${fileFor(url).path}.missing');

  /// The server answered "not found" for it within [missingFor].
  Future<bool> knownMissing(String url, {DateTime? now}) async {
    try {
      final mark = _missingMark(url);
      if (!await mark.exists()) return false;
      final at = await mark.lastModified();
      return (now ?? DateTime.now()).difference(at) < missingFor;
    } on FileSystemException {
      return false;
    }
  }

  /// Remembers that the server does not have it (see [knownMissing]).
  Future<void> markMissing(String url) async {
    try {
      final mark = _missingMark(url);
      await mark.parent.create(recursive: true);
      await mark.writeAsBytes(const [], flush: true);
    } on FileSystemException {
      // Asked for again next time: no worse than before.
    }
  }

  /// Writes one downloaded photo. A failure is not fatal: the screen
  /// falls back to the address, and the next sync tries again.
  Future<bool> put(String url, List<int> bytes) async {
    if (bytes.isEmpty) return false;
    try {
      final f = fileFor(url);
      await f.parent.create(recursive: true);
      await f.writeAsBytes(bytes, flush: true);
      return true;
    } on FileSystemException {
      return false;
    }
  }

  /// Every downloaded photo, gone (a wipe, the add-on ending, signing
  /// out). A photo does not outlive the copy it came with.
  Future<void> forgetAll() async {
    try {
      if (await root.exists()) await root.delete(recursive: true);
    } on FileSystemException {
      // The key goes too, so what is left on disk cannot be read.
    }
  }
}
