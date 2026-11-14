import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Product photos, the brand logo and banner: picked on the phone and
/// compressed to a JPEG under the server's limit, as v1 did
/// (`lib/core/images.dart`), then handed over as a file for the multipart
/// upload.

/// Products, gallery and banner: 4 MB. The logo: 2 MB.
const imageMaxBytes = 4 * 1024 * 1024;
const logoMaxBytes = 2 * 1024 * 1024;

/// The photo can't be brought under the limit.
class ImageTooLarge implements Exception {
  const ImageTooLarge();
}

final _picker = ImagePicker();

/// One photo, compressed under [maxBytes]; null when nothing was picked.
/// Throws [ImageTooLarge] when it can't be made small enough.
Future<File?> pickPhoto({
  ImageSource source = ImageSource.gallery,
  int maxBytes = imageMaxBytes,
}) async {
  final file = await _picker.pickImage(
    source: source,
    requestFullMetadata: false,
  );
  if (file == null) return null;
  final out = await _compress(file, maxBytes);
  if (out == null) throw const ImageTooLarge();
  return out;
}

/// Up to [limit] photos, each compressed; ones that can't be made small
/// enough are left out.
Future<List<File>> pickPhotos({
  required int limit,
  int maxBytes = imageMaxBytes,
}) async {
  if (limit <= 0) return const [];
  final files = limit == 1
      ? [?await _picker.pickImage(source: ImageSource.gallery)]
      : await _picker.pickMultiImage(limit: limit, requestFullMetadata: false);
  final out = <File>[];
  for (final f in files.take(limit)) {
    if (await _compress(f, maxBytes) case final file?) out.add(file);
  }
  return out;
}

Future<File?> _compress(XFile file, int maxBytes) async {
  final dir = await getTemporaryDirectory();
  final stamp = DateTime.now().microsecondsSinceEpoch;
  final base = p.basenameWithoutExtension(file.name);
  var dimension = 2048;
  var quality = 85;
  for (var attempt = 0; attempt < 6; attempt++) {
    final target = p.join(dir.path, '$base-$stamp-$attempt.jpg');
    try {
      final out = await FlutterImageCompress.compressAndGetFile(
        file.path,
        target,
        minWidth: dimension,
        minHeight: dimension,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      if (out == null) break;
      final f = File(out.path);
      if (await f.length() <= maxBytes) return f;
    } catch (_) {
      break;
    }
    quality = (quality - 12).clamp(40, 100);
    dimension = (dimension * 0.8).round();
  }
  // Compression unavailable (an unusual format): the original if it fits.
  final original = File(file.path);
  return await original.length() <= maxBytes ? original : null;
}
