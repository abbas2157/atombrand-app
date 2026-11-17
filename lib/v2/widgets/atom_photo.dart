import 'package:flutter/material.dart';

import '../core/db/copy_photos.dart';
import '../core/db/photo_cache.dart';
import '../core/lock/screen_guard.dart';

/// A photo from the server, which may already be on the phone.
///
/// A drop-in for `Image.network`. With the Offline add-on the sync
/// downloads the photos the copy's rows point at and keeps each one under
/// the address it came from, so this looks there first: a customer's
/// face, their CNIC and a product picture all show in a basement, and
/// nothing else in the app has to know that sync exists.
///
/// Without the add-on, or before a photo has come down, it is exactly
/// `Image.network` — including the [errorBuilder], which is what draws
/// the initials when there is no photo and no signal.
class AtomPhoto extends StatelessWidget {
  const AtomPhoto(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.errorBuilder,
    this.loadingBuilder,
    this.frameBuilder,
    this.cacheWidth,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final ImageErrorWidgetBuilder? errorBuilder;
  final ImageLoadingBuilder? loadingBuilder;

  /// Fades a photo in as it decodes, as the lists do.
  final ImageFrameBuilder? frameBuilder;

  /// Decoded no wider than this: a 1600px CNIC in a 48px row is a lot of
  /// memory to hold for nothing. Left out, it follows [width] when that is
  /// known ([decodeWidth]).
  final int? cacheWidth;

  /// How wide to decode: [cacheWidth] if given, else the box on screen in
  /// pixels. Twice that for [BoxFit.cover], which crops: a landscape photo
  /// in a square avatar is scaled by its height, so decoding to the box's
  /// width alone would blur it.
  static int? decodeWidth({
    required int? cacheWidth,
    required double? width,
    required double? height,
    required BoxFit? fit,
    required double pixelRatio,
  }) {
    if (cacheWidth != null) return cacheWidth;
    if (width == null || !width.isFinite || width <= 0) return null;
    final side = (height != null && height.isFinite && height > width)
        ? height
        : width;
    final factor = fit == BoxFit.cover ? 2.0 : 1.0;
    return (side * pixelRatio * factor).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final decode = decodeWidth(
      cacheWidth: cacheWidth,
      width: width,
      height: height,
      fit: fit,
      pixelRatio: MediaQuery.maybeDevicePixelRatioOf(context) ?? 3,
    );
    // Looked up as the widget builds, not awaited: an image is asked for
    // while a list is scrolling, and a Future here would flash the
    // initials before the photo every time.
    final here = CopyPhotos.localFor(url);
    if (here != null) {
      return Image.file(
        here,
        width: width,
        height: height,
        fit: fit,
        frameBuilder: frameBuilder,
        cacheWidth: decode,
        // A file that is there but unreadable falls back the same way a
        // failed download does.
        errorBuilder: errorBuilder,
      );
    }
    // Online: from the phone's photo cache when it was fetched before,
    // except a document's (inside a ScreenGuard), which is never kept.
    final cache = PhotoCache.current;
    if (cache != null &&
        context.findAncestorWidgetOfExactType<ScreenGuard>() == null) {
      return Image(
        image: ResizeImage.resizeIfNeeded(
          decode,
          null,
          CachedPhoto(url, cache),
        ),
        width: width,
        height: height,
        fit: fit,
        frameBuilder: frameBuilder,
        errorBuilder: errorBuilder,
        loadingBuilder: loadingBuilder,
      );
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      frameBuilder: frameBuilder,
      cacheWidth: decode,
      errorBuilder: errorBuilder,
      loadingBuilder: loadingBuilder,
    );
  }
}
