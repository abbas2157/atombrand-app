import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/app_localizations.dart';
import '../../design/design.dart';
import '../atom_button.dart';
import '../atom_pressable.dart';
import '../atom_spinner.dart';
import '../atom_sheet.dart';
import 'atom_select_filter.dart';

/// Where a dropdown's options come from: a list in hand, or a loader.
typedef AtomOptionLoader<T> = Future<List<AtomOption<T>>> Function();

/// Opens the searchable dropdown for one choice (canvas 19.18).
///
/// Returns the chosen value, or null when the sheet is closed without a
/// choice.
Future<T?> showAtomSelect<T>(
  BuildContext context, {
  required String title,
  List<AtomOption<T>>? options,
  AtomOptionLoader<T>? load,
  T? selected,
  String? searchHint,
  String? mineLabel,
  String? othersLabel,
  bool offline = false,
  String? loadingLabel,
  String Function(String query)? noMatchText,
}) async {
  // Picking from a list ends typing: without this the field typed in last
  // takes focus back when the sheet closes and the keyboard pops up again.
  FocusManager.instance.primaryFocus?.unfocus();
  final result = await showAtomSheet<Set<T>>(
    context,
    expand: true,
    builder: (_) => AtomSelectSheet<T>(
      title: title,
      options: options,
      load: load,
      selected: {?selected},
      multi: false,
      searchHint: searchHint,
      mineLabel: mineLabel,
      othersLabel: othersLabel,
      offline: offline,
      loadingLabel: loadingLabel,
      noMatchText: noMatchText,
    ),
  );
  return result?.firstOrNull;
}

/// Opens the searchable dropdown for several choices.
///
/// Returns the chosen set, or null when the sheet is closed without Done.
Future<Set<T>?> showAtomMultiSelect<T>(
  BuildContext context, {
  required String title,
  List<AtomOption<T>>? options,
  AtomOptionLoader<T>? load,
  Set<T> selected = const {},
  String? searchHint,
  String? mineLabel,
  String? othersLabel,
  bool offline = false,
  String? loadingLabel,
  String Function(String query)? noMatchText,
}) {
  return showAtomSheet<Set<T>>(
    context,
    expand: true,
    builder: (_) => AtomSelectSheet<T>(
      title: title,
      options: options,
      load: load,
      selected: selected,
      multi: true,
      searchHint: searchHint,
      mineLabel: mineLabel,
      othersLabel: othersLabel,
      offline: offline,
      loadingLabel: loadingLabel,
      noMatchText: noMatchText,
    ),
  );
}

/// The one dropdown sheet every list choice in the app uses.
///
/// Search first and focused (the keyboard comes up with the sheet), matches
/// highlighted, the person's own items first, a tick on the choice. States:
/// loading, couldn't load (Try again), no match (Clear search), offline (a
/// note that the saved list is being searched), and pick-many with
/// "Done · N chosen". Even a short list gets the search box (owner rule).
class AtomSelectSheet<T> extends StatefulWidget {
  const AtomSelectSheet({
    super.key,
    required this.title,
    required this.multi,
    this.options,
    this.load,
    this.selected = const {},
    this.searchHint,
    this.mineLabel,
    this.othersLabel,
    this.offline = false,
    this.loadingLabel,
    this.noMatchText,
  }) : assert(
         (options == null) != (load == null),
         'Give either options or load.',
       );

  final String title;
  final bool multi;
  final List<AtomOption<T>>? options;
  final AtomOptionLoader<T>? load;
  final Set<T> selected;
  final String? searchHint;

  /// The header above the person's own items, e.g. "Your areas".
  final String? mineLabel;

  /// The header above the rest, e.g. "Other areas in Lahore". Left out when
  /// null and there are none of the person's own items.
  final String? othersLabel;
  final bool offline;

  /// "Loading areas…" while [load] runs; defaults to "Loading…".
  final String? loadingLabel;

  /// 'No area matches "mo"'; defaults to 'No match for "mo"'.
  final String Function(String query)? noMatchText;

  @override
  State<AtomSelectSheet<T>> createState() => _AtomSelectSheetState<T>();
}

class _AtomSelectSheetState<T> extends State<AtomSelectSheet<T>> {
  final _query = TextEditingController();
  late final Set<T> _chosen = {...widget.selected};
  List<AtomOption<T>>? _options;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _options = widget.options;
    if (_options == null) _load();
    _query.addListener(() => setState(() {}));
  }

  Future<void> _load() async {
    setState(() {
      _options = null;
      _loadError = null;
    });
    try {
      final options = await widget.load!();
      if (mounted) setState(() => _options = options);
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _tap(T value) {
    if (!widget.multi) {
      Navigator.of(context).pop(<T>{value});
      return;
    }
    setState(() {
      _chosen.contains(value) ? _chosen.remove(value) : _chosen.add(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtomSheetHeader(title: widget.title),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AtomSpace.gutter,
            10,
            AtomSpace.gutter,
            AtomSpace.s2,
          ),
          child: _SearchBox(
            controller: _query,
            hint: widget.searchHint ?? l.selectSearchHint,
          ),
        ),
        Expanded(child: _body(l)),
        if (widget.offline)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AtomSpace.gutter,
              0,
              AtomSpace.gutter,
              AtomSpace.s2,
            ),
            child: Text(l.selectOfflineNote, style: AtomText.small),
          ),
        if (widget.multi)
          _MultiFoot(
            count: _chosen.length,
            onClear: _chosen.isEmpty ? null : () => setState(_chosen.clear),
            onDone: () => Navigator.of(context).pop(_chosen),
          ),
      ],
    );
  }

  Widget _body(AppLocalizations l) {
    if (_loadError != null) {
      return _Centre(
        children: [
          Text(
            l.selectCouldNotLoad,
            style: AtomText.listTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AtomSpace.s3),
          AtomButton.small(label: l.commonTryAgain, onPressed: _load),
        ],
      );
    }
    final options = _options;
    if (options == null) {
      return _Centre(
        children: [
          const AtomSpinner(),
          const SizedBox(height: 10),
          Text(
            widget.loadingLabel ?? l.commonLoading,
            style: AtomText.body.copyWith(color: AtomColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    final groups = filterAtomOptions(options, _query.text);
    if (groups.isEmpty) {
      return _Centre(
        children: [
          Text(
            widget.noMatchText?.call(_query.text.trim()) ??
                l.selectNoMatch(_query.text.trim()),
            style: AtomText.listTitle.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            l.selectNoMatchHint,
            style: AtomText.body.copyWith(color: AtomColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          AtomButton.small(label: l.selectClearSearch, onPressed: _query.clear),
        ],
      );
    }

    final showOthersHeader =
        widget.othersLabel != null &&
        (groups.mine.isNotEmpty || widget.mineLabel == null);
    final children = <Widget>[
      if (groups.mine.isNotEmpty && widget.mineLabel != null)
        _GroupHeader(widget.mineLabel!),
      for (final m in groups.mine) _row(m),
      if (groups.others.isNotEmpty && showOthersHeader)
        _GroupHeader(widget.othersLabel!),
      for (final m in groups.others) _row(m),
    ];

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AtomSpace.s2),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: children,
      ),
    );
  }

  Widget _row(AtomOptionMatch<T> m) {
    final value = m.option.value;
    return AtomOptionRow(
      match: m,
      selected: _chosen.contains(value),
      multi: widget.multi,
      onTap: () => _tap(value),
    );
  }
}

class _SearchBox extends StatefulWidget {
  const _SearchBox({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hasText = widget.controller.text.isNotEmpty;
    return Container(
      constraints: const BoxConstraints(minHeight: AtomSize.sheetSearch),
      padding: const EdgeInsets.only(left: AtomSpace.inset),
      decoration: BoxDecoration(
        color: AtomColors.paper,
        borderRadius: AtomRadius.brControl,
        border: Border.all(
          color: _focus.hasFocus ? AtomColors.primary : AtomColors.line2,
        ),
        boxShadow: _focus.hasFocus
            ? const [BoxShadow(color: AtomColors.primarySoft, spreadRadius: 3)]
            : null,
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.search,
            size: AtomIcon.row,
            color: AtomColors.faint,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              autofocus: true,
              textInputAction: TextInputAction.search,
              style: AtomText.input,
              decoration: InputDecoration(
                hintText: widget.hint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          if (hasText)
            AtomPressable(
              onTap: widget.controller.clear,
              semanticLabel: l.selectClearSearch,
              builder: (_, _) =>
                  const Icon(LucideIcons.x, size: 18, color: AtomColors.faint),
            ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AtomSpace.gutter, 12, 16, 4),
        child: Text(
          text.toUpperCase(),
          style: AtomText.section.copyWith(
            color: AtomColors.muted,
            letterSpacing: 0.72,
          ),
        ),
      ),
    );
  }
}

/// One option in the sheet: the label with its match in bold on a soft
/// highlight, an optional second line, and a tick (one choice) or a
/// checkbox (several).
class AtomOptionRow extends StatelessWidget {
  const AtomOptionRow({
    super.key,
    required this.match,
    required this.selected,
    required this.multi,
    required this.onTap,
  });

  final AtomOptionMatch<Object?> match;
  final bool selected;
  final bool multi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final o = match.option;
    return AtomPressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: o.subtitle == null ? o.label : '${o.label}, ${o.subtitle}',
      scaleOnPress: false,
      focusRadius: BorderRadius.zero,
      builder: (context, pressed) => Container(
        constraints: const BoxConstraints(minHeight: AtomSize.optionRow),
        padding: const EdgeInsets.symmetric(
          horizontal: AtomSpace.gutter,
          vertical: AtomSpace.s2,
        ),
        decoration: BoxDecoration(
          color: pressed ? AtomColors.surface : AtomColors.paper,
          border: const Border(bottom: BorderSide(color: AtomColors.surface)),
        ),
        child: Row(
          children: [
            if (multi) ...[
              _Check(on: selected),
              const SizedBox(width: AtomSpace.s3),
            ],
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(_labelSpan(o.label, chosen: selected && !multi)),
                    if (o.subtitle != null)
                      Text(o.subtitle!, style: AtomText.secondary),
                  ],
                ),
              ),
            ),
            if (!multi && selected) ...[
              const SizedBox(width: AtomSpace.s3),
              const Icon(
                LucideIcons.check,
                size: AtomIcon.row,
                color: AtomColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  TextSpan _labelSpan(String label, {required bool chosen}) {
    final base = chosen
        ? AtomText.input.copyWith(
            color: AtomColors.primary,
            fontWeight: FontWeight.w600,
          )
        : AtomText.input;
    if (!match.hasHighlight) return TextSpan(text: label, style: base);
    return TextSpan(
      style: base,
      children: [
        TextSpan(text: label.substring(0, match.matchStart)),
        TextSpan(
          text: label.substring(match.matchStart, match.matchEnd),
          style: const TextStyle(backgroundColor: AtomColors.amberSoft),
        ),
        TextSpan(text: label.substring(match.matchEnd)),
      ],
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: on ? AtomColors.primary : AtomColors.paper,
        borderRadius: AtomRadius.brTag,
        border: Border.all(
          color: on ? AtomColors.primary : AtomColors.line2,
          width: 2,
        ),
      ),
      child: on
          ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}

class _MultiFoot extends StatelessWidget {
  const _MultiFoot({
    required this.count,
    required this.onClear,
    required this.onDone,
  });

  final int count;
  final VoidCallback? onClear;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AtomSpace.gutter,
        AtomSpace.s3,
        AtomSpace.gutter,
        26,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AtomColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AtomButton(
              label: l.commonClear,
              kind: AtomButtonKind.outline,
              compact: true,
              onPressed: onClear,
            ),
          ),
          const SizedBox(width: AtomSpace.s3),
          Expanded(
            flex: 2,
            child: AtomButton(
              label: l.selectDoneChosen(count),
              compact: true,
              onPressed: onDone,
            ),
          ),
        ],
      ),
    );
  }
}

class _Centre extends StatelessWidget {
  const _Centre({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AtomSpace.s6,
        vertical: 28,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
