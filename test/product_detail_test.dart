import 'package:atombrand_app/data/models/product.dart';
import 'package:atombrand_app/features/catalogue/product_detail_logic.dart';
import 'package:flutter_test/flutter_test.dart';

ProductDetail _d(String status, {String? reason}) =>
    ProductDetail.fromJson({'id': 1, 'title': 'Microwave', 'status': status, 'rejection_reason': ?reason});

void main() {
  test('key features: one per comma, line or bullet; numbers keep their commas', () {
    expect(
      keyFeatures('Cavity volume 20 litres, Glass turntable,Defrost function ,  35-minute timer, AC 230V/50Hz, 700W.'),
      ['Cavity volume 20 litres', 'Glass turntable', 'Defrost function', '35-minute timer', 'AC 230V/50Hz', '700W'],
    );
    expect(keyFeatures('Up to 1,000 hours\n• smart remote'), ['Up to 1,000 hours', 'Smart remote']);
    expect(keyFeatures('<ul><li>Wi-Fi</li><li>HDR10 &amp; HLG</li></ul>'), ['Wi-Fi', 'HDR10 & HLG']);
    expect(keyFeatures(null), isEmpty);
    expect(keyFeatures(' , ,'), isEmpty);
    expect(
      keyFeatures('Google Assistant, (43 & Above Voice Control, Air Mouse, BT Function), Audio output(Headphone, Line out)'),
      ['Google Assistant', '(43 & Above Voice Control, Air Mouse, BT Function)', 'Audio output(Headphone, Line out)'],
    );
    expect(keyFeatures('Wifi (dual band, 1GB RAM, 2*HDMI'), ['Wifi (dual band', '1GB RAM', '2*HDMI']);
  });

  test('description: headings, paragraphs and bullets, never tags', () {
    final b = descriptionBlocks(
      '<h3>Cook fast</h3><p>Two <strong>simple</strong> dials.<br>Bell when done.</p><p>Features:</p><ul><li>20 L</li><li>700&nbsp;W</li></ul>',
    );
    expect(b.map((x) => x.kind).toList(), [
      DescKind.heading, DescKind.paragraph, DescKind.paragraph, DescKind.heading, DescKind.bullet, DescKind.bullet,
    ]);
    expect(b.map((x) => x.text).toList(), ['Cook fast', 'Two simple dials.', 'Bell when done.', 'Features', '20 L', '700 W']);
    expect(descriptionBlocks('Plain text only'), [(kind: DescKind.paragraph, text: 'Plain text only')]);
    expect(descriptionBlocks('  '), isEmpty);
    // A comma-list paragraph becomes bullets; real sentences stay a paragraph.
    expect(descriptionBlocks('<p>Full Screen, Boom Box, Wifi, 1GB RAM</p>').map((x) => x.kind).toSet(), {DescKind.bullet});
    expect(descriptionBlocks('<p>Bright, sharp picture. Easy, quick setup, and more, for less.</p>').single.kind, DescKind.paragraph);
  });

  test('banner follows the status; a rejection reason means Rejected', () {
    expect(bannerOf(_d('Published')), ProductBanner.live);
    expect(bannerOf(_d('Out of Stock')), ProductBanner.outOfStock);
    expect(bannerOf(_d('Pending')), ProductBanner.review);
    expect(bannerOf(_d('Closed')), ProductBanner.closed);
    expect(bannerOf(_d('On hold')), ProductBanner.onHold);
    expect(bannerOf(_d('Pending', reason: 'Image too blurry')), ProductBanner.rejected);
    expect(bannerOf(_d('Rejected')), ProductBanner.rejected);
  });
}
