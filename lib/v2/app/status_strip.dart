import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../design/design.dart';

/// A solid strip behind the status bar once a page has scrolled, so the
/// page never runs under the clock (every board keeps its `.safe` area
/// solid).
///
/// One place for all 100-odd screens: it listens to the scrolling of the
/// page in front (not sheets or dialogs), takes its colour from the page's
/// own status-bar style when the scroll starts (light icons: navy, else
/// paper), and steps aside on every navigation until the new page scrolls.
class StatusStrip extends StatefulWidget {
  const StatusStrip({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  State<StatusStrip> createState() => _StatusStripState();
}

class _StatusStripState extends State<StatusStrip> {
  Color? _colour;
  bool _lightIcons = false;

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_reset);
  }

  @override
  void didUpdateWidget(StatusStrip old) {
    super.didUpdateWidget(old);
    if (old.router != widget.router) {
      old.router.routerDelegate.removeListener(_reset);
      widget.router.routerDelegate.addListener(_reset);
    }
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_reset);
    super.dispose();
  }

  void _reset() {
    if (_colour != null && mounted) setState(() => _colour = null);
  }

  /// The style the page asks for under the clock, found the way the
  /// framework finds it (RenderView: the annotated layer at the top).
  SystemUiOverlayStyle? _pageStyle() {
    final views = RendererBinding.instance.renderViews;
    if (views.isEmpty) return null;
    final view = views.first;
    // Read only, as RenderView does for SystemChrome; the root view is a
    // repaint boundary, so it always has its layer after the first frame.
    // ignore: invalid_use_of_protected_member
    final layer = view.layer;
    if (layer == null) return null;
    final bounds = view.paintBounds;
    final top = MediaQuery.paddingOf(context).top;
    return layer.find<SystemUiOverlayStyle>(Offset(bounds.center.dx, top / 2));
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final ctx = n.context;
    if (ctx == null) return false;
    // A sheet or dialog scrolling isn't the page under the clock.
    final route = ModalRoute.of(ctx);
    if (route is PopupRoute || (route != null && !route.isCurrent)) {
      return false;
    }
    final scrolled = n.metrics.pixels > n.metrics.minScrollExtent + 0.5;
    if (scrolled && _colour == null) {
      // The page's own style decides, read before the strip covers it.
      final light = _pageStyle()?.statusBarIconBrightness == Brightness.light;
      setState(() {
        _lightIcons = light;
        _colour = light ? AtomColors.nav : AtomColors.paper;
      });
    } else if (!scrolled && _colour != null && n.depth == 0) {
      setState(() => _colour = null);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          widget.child,
          if (_colour != null && top > 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: top,
              child: IgnorePointer(
                child: AnnotatedRegion<SystemUiOverlayStyle>(
                  value: _lightIcons
                      ? SystemUiOverlayStyle.light
                      : SystemUiOverlayStyle.dark,
                  child: ColoredBox(color: _colour!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
