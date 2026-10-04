import 'package:atombrand_app/data/models/account.dart';
import 'package:atombrand_app/data/models/dashboard.dart';
import 'package:atombrand_app/features/brand_page/brand_page_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('checklist: logo, banner, tagline, story; blanks do not count', () {
    final c = pageChecklist(hasLogo: true, hasBanner: false, tagline: '  ', story: 'Since 2014');
    expect([for (final x in c) if (x.done) x.label], ['Logo', 'Story']);
    expect(c.firstWhere((x) => x.label == 'Banner').section, 'header');
    const b = Brand(id: 1, title: 'OXY', logo: 'l.png', banner: 'b.png', tagline: 'TVs', description: 'Story');
    expect(brandChecklist(b).every((x) => x.done), isTrue);
  });

  test('featured diff says what to star and unstar', () {
    final d = featuredDiff([1, 2, 3], [2, 3, 7]);
    expect(d.add, [7]);
    expect(d.remove, [1]);
    expect(featuredDiff([1], [1]).add, isEmpty);
  });

  test('slides compare by content; websites get https://', () {
    expect(sameSlides([const PageSlide(heading: 'Eid')], [const PageSlide(heading: 'Eid')]), isTrue);
    expect(sameSlides([const PageSlide(heading: 'Eid')], [const PageSlide(heading: 'Eid', tag: 'x')]), isFalse);
    expect(normaliseUrl('oxy.pk'), 'https://oxy.pk');
    expect(normaliseUrl('http://oxy.pk'), 'http://oxy.pk');
    expect(normaliseUrl(' '), '');
  });
}
