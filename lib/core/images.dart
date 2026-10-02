import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

/// An image picked on device, already compressed under the upload limit.
class PickedImage {
  const PickedImage(this.bytes, this.filename);
  final Uint8List bytes;
  final String filename;

  MultipartFile toMultipart() => MultipartFile.fromBytes(bytes, filename: filename);
}

const kImageMaxBytes = 4 * 1024 * 1024; // products, banner, delivery proof
const kLogoMaxBytes = 2 * 1024 * 1024; // brand logo

final _picker = ImagePicker();

/// Picks one image and compresses it to JPEG under [maxBytes] (§10.4).
Future<PickedImage?> pickImage({
  ImageSource source = ImageSource.gallery,
  int maxBytes = kImageMaxBytes,
}) async {
  final file = await _picker.pickImage(source: source, requestFullMetadata: false);
  if (file == null) return null;
  return _compress(file, maxBytes);
}

/// Picks up to [limit] gallery images, each compressed under [maxBytes].
Future<List<PickedImage>> pickImages({int limit = 8, int maxBytes = kImageMaxBytes}) async {
  final files = await _picker.pickMultiImage(limit: limit, requestFullMetadata: false);
  final out = <PickedImage>[];
  for (final f in files.take(limit)) {
    final img = await _compress(f, maxBytes);
    if (img != null) out.add(img);
  }
  return out;
}

Future<PickedImage?> _compress(XFile file, int maxBytes) async {
  final name = _jpgName(file.name);
  var dimension = 2048;
  var quality = 85;
  Uint8List? bytes;
  for (var attempt = 0; attempt < 6; attempt++) {
    bytes = await FlutterImageCompress.compressWithFile(
      file.path,
      minWidth: dimension,
      minHeight: dimension,
      quality: quality,
      format: CompressFormat.jpeg,
    );
    if (bytes == null) break;
    if (bytes.lengthInBytes <= maxBytes) return PickedImage(bytes, name);
    quality = (quality - 12).clamp(40, 100);
    dimension = (dimension * 0.8).round();
  }
  // Compression unavailable (e.g. unsupported format): fall back to the
  // original if it already fits, otherwise give up.
  final original = await file.readAsBytes();
  return original.lengthInBytes <= maxBytes ? PickedImage(original, file.name) : null;
}

String _jpgName(String name) {
  final dot = name.lastIndexOf('.');
  return '${dot > 0 ? name.substring(0, dot) : name}.jpg';
}
