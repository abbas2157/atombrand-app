// The dropdown filter decides what every list choice in v2 shows, so its
// rules are pinned here: the person's own items first, starts-with before
// contains, case and spacing ignored, keywords matched without a highlight.

import 'package:atombrand_app/v2/widgets/select/atom_select_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const areas = [
    AtomOption(value: 1, label: 'Allama Iqbal Town'),
    AtomOption(value: 2, label: 'Model Town', mine: true),
    AtomOption(value: 3, label: 'Gulberg', mine: true),
    AtomOption(value: 4, label: 'Mozang'),
    AtomOption(value: 5, label: 'Samanabad'),
    AtomOption(value: 6, label: 'Garden Town', mine: true),
    AtomOption(value: 7, label: 'Cantt', keywords: ['Cantonment']),
  ];

  List<String> labels(List<AtomOptionMatch<int>> ms) =>
      ms.map((m) => m.option.label).toList();

  test('an empty query keeps every option, own items first', () {
    final g = filterAtomOptions(areas, '');
    expect(labels(g.mine), ['Model Town', 'Gulberg', 'Garden Town']);
    expect(labels(g.others), [
      'Allama Iqbal Town',
      'Mozang',
      'Samanabad',
      'Cantt',
    ]);
    expect(g.mine.every((m) => !m.hasHighlight), isTrue);
  });

  test('matches anywhere in the label, ignoring case', () {
    final g = filterAtomOptions(areas, 'TOWN');
    expect(labels(g.mine), ['Model Town', 'Garden Town']);
    expect(labels(g.others), ['Allama Iqbal Town']);
  });

  test('labels that start with the query come first', () {
    final g = filterAtomOptions(areas, 'mo');
    // "Model Town" is the person's own; "Mozang" starts with "mo".
    expect(labels(g.mine), ['Model Town']);
    expect(labels(g.others), ['Mozang']);

    final a = filterAtomOptions(areas, 'a');
    // Allama and the rest all contain "a"; only Allama starts with it.
    expect(a.others.first.option.label, 'Allama Iqbal Town');
  });

  test('the highlight covers the first match', () {
    final m = filterAtomOptions(areas, 'town').mine.first;
    expect(m.option.label.substring(m.matchStart, m.matchEnd), 'Town');
  });

  test('spaces at the ends and repeated inside are ignored', () {
    final g = filterAtomOptions(areas, '  model   town ');
    expect(labels(g.mine), ['Model Town']);
  });

  test('a keyword matches without a highlight', () {
    final g = filterAtomOptions(areas, 'canton');
    expect(labels(g.others), ['Cantt']);
    expect(g.others.single.hasHighlight, isFalse);
  });

  test('no match gives empty groups', () {
    final g = filterAtomOptions(areas, 'zzz');
    expect(g.isEmpty, isTrue);
    expect(g.length, 0);
  });
}
