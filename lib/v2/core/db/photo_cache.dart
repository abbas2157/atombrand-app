import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Photos shown online, kept on the phone so they are not downloaded again
/// every time the app opens: faces, products, team photos, the shop's
/// logo. For a seller without the Offline add-on, whose photos otherwise
/// lived only in memory and came down again after every restart.
///
/// Not for documents. A photo inside a `ScreenGuard` (payment proofs, documents,
/// guarantors' cards, receipts) is never written here: those stay with the
/// encrypted copy (`CopyPhotos`) or not at all (`RULES.md` §1.4). It is the
/// app's cache folder, so the system may clear it; it is cleared on sign
/// out, and kept under [maxBytes].
class PhotoCache {
  PhotoCache(this.root);

  /// `<app cache>/photos`, or a temporary folder in a test.
  final Directory root;

  /// The one `AtomPhoto` uses. Null until [start] has run (and in tests):
  /// photos then load as they always did.
  static PhotoCache? current;

  /// Oldest photos go first above this.
  static const maxBytes = 80 * 1024 * 1024;

  static Future<PhotoCache?> start() async {
    try {
      final dir = await getApplicationCacheDirectory();
      final cache = PhotoCache(Directory(p.join(dir.path, 'photos')));
      current = cache;
      // Not awaited: the first screens need not wait for the tidy-up.
      cache.trim();
      return cache;
    } catch (e) {
      debugPrint('[photos] no cache folder: $e');
      return null;
    }
  }

  File fileFor(String url) {
    final name = sha256.convert(utf8.encode(url)).toString().substring(0, 40);
    return File(p.join(root.path, name));
  }

  /// Keeps the folder under [maxBytes], dropping the photos used least
  /// recently (a photo read from here is touched, see [CachedPhoto]).
  Future<void> trim() async {
    try {
      if (!await root.exists()) return;
      final files = <(File, int, DateTime)>[];
      var total = 0;
      await for (final e in root.list()) {
        if (e is! File) continue;
        final s = await e.stat();
        files.add((e, s.size, s.modified));
        total += s.size;
      }
      if (total <= maxBytes) return;
      files.sort((a, b) => a.$3.compareTo(b.$3));
      for (final (f, size, _) in files) {
        if (total <= maxBytes) break;
        try {
          await f.delete();
          total -= size;
        } on FileSystemException {
          // In use: next time.
        }
      }
    } on FileSystemException catch (e) {
      debugPrint('[photos] could not tidy the cache: $e');
    }
  }

  /// Signing out: another person may sign in on this phone next.
  Future<void> forgetAll() async {
    try {
      if (await root.exists()) await root.delete(recursive: true);
    } on FileSystemException catch (e) {
      debugPrint('[photos] could not clear the cache: $e');
    }
  }
}

/// A photo from the network, read from [PhotoCache] when it is there and
/// kept there when it is fetched. Otherwise as `NetworkImage`: a failure
/// reaches the image's `errorBuilder`.
@immutable
class CachedPhoto extends ImageProvider<CachedPhoto> {
  const CachedPhoto(this.url, this.cache);

  final String url;
  final PhotoCache cache;

  static final HttpClient _http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 20);

  @override
  Future<CachedPhoto> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<CachedPhoto>(this);

  @override
  ImageStreamCompleter loadImage(
    CachedPhoto key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _load(decode),
    scale: 1,
    debugLabel: url,
    informationCollector: () => [DiagnosticsProperty('URL', url)],
  );

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final file = cache.fileFor(url);
    Uint8List? bytes;
    try {
      if (await file.exists()) {
        bytes = await file.readAsBytes();
        // Recently used: [PhotoCache.trim] keeps it.
        file.setLastModified(DateTime.now()).ignore();
      }
    } on FileSystemException {
      bytes = null;
    }
    if (bytes == null || bytes.isEmpty) {
      final request = await _http.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw NetworkImageLoadException(
          statusCode: response.statusCode,
          uri: Uri.parse(url),
        );
      }
      bytes = await consolidateHttpClientResponseBytes(response);
      if (bytes.isEmpty) throw StateError('Empty photo: $url');
      try {
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes, flush: true);
      } on FileSystemException {
        // Shown anyway; fetched again next time.
      }
    }
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) => other is CachedPhoto && other.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => 'CachedPhoto("$url")';
}
