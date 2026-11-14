import 'package:flutter/foundation.dart';

/// One choice in a searchable dropdown.
@immutable
class AtomOption<T> {
  const AtomOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.mine = false,
    this.keywords = const [],
  });

  final T value;
  final String label;

  /// A second line under the label ("You serve this area").
  final String? subtitle;

  /// The person's own items ("Your areas") are listed first, in their own
  /// group.
  final bool mine;

  /// Extra words the search also matches but doesn't show, e.g. a brand
  /// code or the Urdu name of a city.
  final List<String> keywords;
}

/// An option as the sheet shows it, with the matched part of its label.
@immutable
class AtomOptionMatch<T> {
  const AtomOptionMatch(this.option, this.matchStart, this.matchEnd);

  final AtomOption<T> option;

  /// The matched range in [AtomOption.label], or -1 when nothing in the
  /// label matched (no query, or only a keyword matched).
  final int matchStart;
  final int matchEnd;

  bool get hasHighlight => matchStart >= 0;
}

/// The result of filtering: the person's own matches, then the rest.
@immutable
class AtomOptionGroups<T> {
  const AtomOptionGroups(this.mine, this.others);

  final List<AtomOptionMatch<T>> mine;
  final List<AtomOptionMatch<T>> others;

  bool get isEmpty => mine.isEmpty && others.isEmpty;
  int get length => mine.length + others.length;
}

/// Filters [options] by [query] and splits them into the person's own items
/// and the others.
///
/// - Matching is case-insensitive and ignores spaces at the ends of the
///   query and repeated spaces inside it.
/// - A label matches if it contains the query anywhere ("mo" finds
///   "Model Town" and "Mozang"). The first match is the one highlighted.
/// - Keywords match too, without a highlight.
/// - Labels that *start* with the query come before those that only contain
///   it; otherwise the given order is kept.
AtomOptionGroups<T> filterAtomOptions<T>(
  List<AtomOption<T>> options,
  String query,
) {
  final q = normaliseQuery(query);
  final mineStart = <AtomOptionMatch<T>>[];
  final mineRest = <AtomOptionMatch<T>>[];
  final otherStart = <AtomOptionMatch<T>>[];
  final otherRest = <AtomOptionMatch<T>>[];

  for (final o in options) {
    final AtomOptionMatch<T> m;
    var startsWith = false;
    if (q.isEmpty) {
      m = AtomOptionMatch(o, -1, -1);
    } else {
      final i = _fold(o.label).indexOf(q);
      if (i >= 0) {
        m = AtomOptionMatch(o, i, i + q.length);
        startsWith = i == 0;
      } else if (o.keywords.any((k) => _fold(k).contains(q))) {
        m = AtomOptionMatch(o, -1, -1);
      } else {
        continue;
      }
    }
    if (o.mine) {
      (startsWith ? mineStart : mineRest).add(m);
    } else {
      (startsWith ? otherStart : otherRest).add(m);
    }
  }

  return AtomOptionGroups(
    [...mineStart, ...mineRest],
    [...otherStart, ...otherRest],
  );
}

/// Lower case, trimmed, inner runs of spaces made single.
String normaliseQuery(String query) =>
    _fold(query).trim().replaceAll(RegExp(r'\s+'), ' ');

// Lower-casing keeps the string length the same for the scripts the app
// uses, so a match index in the folded label is an index in the label.
String _fold(String s) => s.toLowerCase();
