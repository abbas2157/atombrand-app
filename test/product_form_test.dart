import 'package:atombrand_app/features/catalogue/product_detail_logic.dart';
import 'package:atombrand_app/features/catalogue/product_form_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature chips: comma input splits, duplicates drop, and short round-trips', () {
    var f = addFeatures([], '20L capacity, Glass turntable');
    f = addFeatures(f, 'glass turntable');
    f = addFeatures(f, 'Voice (Assistant, Air Mouse)');
    expect(f, ['20L capacity', 'Glass turntable', 'Voice (Assistant, Air Mouse)']);
    expect(keyFeatures(featuresToShort(f)), f);
    expect(featureChars(['ab', 'cd']), 6);
  });

  test('description blocks round-trip through the HTML the API stores', () {
    final parts = [
      DescPart(DescKind.heading, 'Cook fast'),
      DescPart(DescKind.paragraph, 'Two dials & a bell.'),
      DescPart(DescKind.paragraph, 'Best seller', bold: true),
      DescPart(DescKind.bullet, '20 L'),
      DescPart(DescKind.bullet, '700 W'),
      DescPart(DescKind.paragraph, '   '),
    ];
    final html = partsToHtml(parts);
    expect(html, '<h3>Cook fast</h3><p>Two dials &amp; a bell.</p><p><strong>Best seller</strong></p><ul><li>20 L</li><li>700 W</li></ul>');
    final back = htmlToParts(html);
    expect(back.map((p) => (p.kind, p.text, p.bold)).toList(), [
      (DescKind.heading, 'Cook fast', false),
      (DescKind.paragraph, 'Two dials & a bell.', false),
      (DescKind.paragraph, 'Best seller', true),
      (DescKind.bullet, '20 L', false),
      (DescKind.bullet, '700 W', false),
    ]);
    expect(partsToHtml(back), html);
  });

  test('gaps say what is missing, in form order, in plain words', () {
    List<FormGap> gaps({bool photo = true, String title = 'TV', int? cat = 1, int? price = 72000, int? adv = 15000, List<String> f = const ['Wifi']}) =>
        formGaps(hasMainPhoto: photo, title: title, categoryId: cat, brandId: 7, price: price, advance: adv, features: f);
    expect(gaps(), isEmpty);
    expect(gaps(photo: false, price: null), [FormGap.mainPhoto, FormGap.price]);
    expect(missingLine(gaps(photo: false, price: null)), 'Add a main photo and a price to continue');
    expect(gaps(adv: 80000), [FormGap.advanceTooHigh]);
    expect(gaps(adv: 0), isEmpty);
    expect(gaps(title: '  ', cat: null, f: []), [FormGap.title, FormGap.category, FormGap.features]);
    expect(missingLine([FormGap.title, FormGap.category, FormGap.features], verb: 'save'), 'Add a title, a category and one key feature to save');
    expect(parseRupees('72,000'), 72000);
    expect(parseRupees(''), isNull);
  });
}
