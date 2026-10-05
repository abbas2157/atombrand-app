// Builds the square launcher-icon sources from the AB mark (DESIGN.md §1):
//   assets/brand/launcher_icon.png        mark on white (iOS, legacy Android)
//   assets/brand/launcher_foreground.png  mark on transparent, inside the
//                                         adaptive-icon safe zone (Android 8+)
// Then: dart run flutter_launcher_icons
//
// Run from the project root: dart run tool/make_launcher_icon.dart
import 'dart:io';

import 'package:image/image.dart' as img;

const _size = 1024;

void main() {
  final mark = img.decodePng(File('assets/brand/mark.png').readAsBytesSync())!;
  _write('assets/brand/launcher_icon.png', _place(mark, width: 0.64, white: true));
  // Adaptive icons crop to the centre 66%; keep the mark well inside it.
  _write('assets/brand/launcher_foreground.png', _place(mark, width: 0.50, white: false));
}

img.Image _place(img.Image mark, {required double width, required bool white}) {
  final canvas = img.Image(width: _size, height: _size, numChannels: 4);
  img.fill(canvas, color: white ? img.ColorRgba8(255, 255, 255, 255) : img.ColorRgba8(0, 0, 0, 0));
  final w = (_size * width).round();
  final scaled = img.copyResize(mark, width: w, interpolation: img.Interpolation.cubic);
  return img.compositeImage(canvas, scaled, dstX: (_size - scaled.width) ~/ 2, dstY: (_size - scaled.height) ~/ 2);
}

void _write(String path, img.Image image) {
  File(path).writeAsBytesSync(img.encodePng(image));
  stdout.writeln('wrote $path');
}
