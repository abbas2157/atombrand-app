import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../data/models/json.dart';
import 'common.dart';

/// Loads a paginated endpoint page by page (§7.3). Filters live in the
/// screen; the fetcher closure reads them, so call [refresh] after changing one.
class PagedController<T> extends ChangeNotifier {
  PagedController(this._fetch);

  final Future<Paged<T>> Function(int page) _fetch;

  List<T> items = [];
  Paged<T>? firstPage;
  Pagination? _pagination;
  bool loading = false;
  bool loadingMore = false;
  String? error;
  int _generation = 0;
  bool _disposed = false;

  bool get hasMore => _pagination?.hasMore ?? false;
  bool get isEmpty => !loading && error == null && items.isEmpty;

  Future<void> refresh({bool showSpinner = true}) async {
    final gen = ++_generation;
    loading = showSpinner || items.isEmpty;
    error = null;
    _notify();
    try {
      final page = await _fetch(1);
      if (gen != _generation) return;
      items = List.of(page.items);
      firstPage = page;
      _pagination = page.pagination;
    } on ApiException catch (e) {
      if (gen != _generation) return;
      error = e.message;
    } finally {
      if (gen == _generation) {
        loading = false;
        _notify();
      }
    }
  }

  Future<void> loadMore() async {
    if (loading || loadingMore || !hasMore) return;
    final gen = _generation;
    loadingMore = true;
    _notify();
    try {
      final page = await _fetch(_pagination!.currentPage + 1);
      if (gen != _generation) return;
      items = [...items, ...page.items];
      _pagination = page.pagination;
    } on ApiException {
      // Keep what we have; the next scroll retries.
    } finally {
      if (gen == _generation) {
        loadingMore = false;
        _notify();
      }
    }
  }

  /// Replace one item in place (after an edit) without reloading.
  void replaceWhere(bool Function(T) test, T Function(T) update) {
    items = [for (final i in items) test(i) ? update(i) : i];
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Pull-to-refresh list with infinite scroll.
class PagedListView<T> extends StatefulWidget {
  const PagedListView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    required this.empty,
    this.header,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 96),
    this.separator = 12,
    this.onRefresh,
  });

  final PagedController<T> controller;
  final Widget Function(BuildContext, T) itemBuilder;
  final Widget empty;
  final Widget? header;
  final EdgeInsets padding;
  final double separator;

  /// Replaces the default pull-to-refresh (which reloads page 1).
  final Future<void> Function()? onRefresh;

  @override
  State<PagedListView<T>> createState() => _PagedListViewState<T>();
}

class _PagedListViewState<T> extends State<PagedListView<T>> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) widget.controller.loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        final header = widget.header;
        Widget body;
        if (c.loading && c.items.isEmpty) {
          body = const Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (c.error != null && c.items.isEmpty) {
          body = ErrorView(message: c.error!, onRetry: c.refresh);
        } else if (c.items.isEmpty) {
          body = widget.empty;
        } else {
          body = const SizedBox.shrink();
        }
        final showItems = c.items.isNotEmpty;
        return RefreshIndicator(
          onRefresh: widget.onRefresh ?? () => c.refresh(showSpinner: false),
          child: ListView.separated(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: widget.padding,
            itemCount: (header != null ? 1 : 0) + (showItems ? c.items.length + 1 : 1),
            separatorBuilder: (_, _) => SizedBox(height: widget.separator),
            itemBuilder: (context, index) {
              if (header != null) {
                if (index == 0) return header;
                index -= 1;
              }
              if (!showItems) return body;
              if (index == c.items.length) {
                return c.loadingMore
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : const SizedBox.shrink();
              }
              return widget.itemBuilder(context, c.items[index]);
            },
          ),
        );
      },
    );
  }
}
