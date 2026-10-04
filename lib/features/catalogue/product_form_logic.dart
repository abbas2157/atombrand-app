import 'product_detail_logic.dart';

/// Most characters the API takes for `short` (the key features, joined).
const maxFeatureChars = 500;

/// Key-feature chips are stored as the comma list `short` has always been,
/// which [keyFeatures] reads back (brackets keep their commas).
String featuresToShort(List<String> features) => features.join(', ');

/// Chips from what the seller typed: "20L, 700W" becomes two chips, blanks
/// and duplicates are dropped.
List<String> addFeatures(List<String> current, String typed) {
  final out = List.of(current);
  final seen = {for (final f in current) f.toLowerCase()};
  for (final f in keyFeatures(typed)) {
    if (seen.add(f.toLowerCase())) out.add(f);
  }
  return out;
}

int featureChars(List<String> features) => featuresToShort(features).length;

/// One block of the full-description editor.
class DescPart {
  DescPart(this.kind, this.text, {this.bold = false});

  DescKind kind;
  String text;

  /// The whole paragraph in bold (the editor has no inline styling).
  bool bold;
}

String _escape(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

/// The editor's blocks as the HTML the API stores. The seller never sees it.
String partsToHtml(List<DescPart> parts) {
  final out = StringBuffer();
  var inList = false;
  for (final p in parts) {
    final text = p.text.trim();
    if (text.isEmpty) continue;
    if (p.kind != DescKind.bullet && inList) {
      out.write('</ul>');
      inList = false;
    }
    final body = p.bold ? '<strong>${_escape(text)}</strong>' : _escape(text);
    switch (p.kind) {
      case DescKind.heading:
        out.write('<h3>${_escape(text)}</h3>');
      case DescKind.paragraph:
        out.write('<p>$body</p>');
      case DescKind.bullet:
        if (!inList) out.write('<ul>');
        inList = true;
        out.write('<li>$body</li>');
    }
  }
  if (inList) out.write('</ul>');
  return out.toString();
}

/// Blocks to edit from the stored HTML. A paragraph wrapped in `<strong>`
/// comes back bold.
List<DescPart> htmlToParts(String? html) {
  final bold = RegExp(r'<p[^>]*>\s*<(strong|b)>([\s\S]*?)</\1>\s*</p>', caseSensitive: false);
  final boldTexts = {for (final m in bold.allMatches(html ?? '')) descriptionBlocks(m.group(2)).map((b) => b.text).join(' ')};
  return [
    for (final b in descriptionBlocks(html))
      DescPart(b.kind, b.text, bold: b.kind == DescKind.paragraph && boldTexts.contains(b.text)),
  ];
}

/// What still has to be filled in before the form can be sent, in the order
/// the form asks for it.
enum FormGap { mainPhoto, title, category, brand, price, advance, advanceTooHigh, features, tooManyFeatures }

String gapLabel(FormGap g) => switch (g) {
      FormGap.mainPhoto => 'a main photo',
      FormGap.title => 'a title',
      FormGap.category => 'a category',
      FormGap.brand => 'a brand',
      FormGap.price => 'a price',
      FormGap.advance => 'the minimum advance',
      FormGap.advanceTooHigh => 'a lower advance',
      FormGap.features => 'one key feature',
      FormGap.tooManyFeatures => 'shorter key features',
    };

/// "Add a main photo and a price to continue".
String missingLine(List<FormGap> gaps, {String verb = 'continue'}) {
  final labels = gaps.map(gapLabel).toList();
  final list = labels.length == 1 ? labels.first : '${labels.sublist(0, labels.length - 1).join(', ')} and ${labels.last}';
  return 'Add $list to $verb';
}

List<FormGap> formGaps({
  required bool hasMainPhoto,
  required String title,
  required int? categoryId,
  required int? brandId,
  required int? price,
  required int? advance,
  required List<String> features,
}) => [
      if (!hasMainPhoto) FormGap.mainPhoto,
      if (title.trim().isEmpty) FormGap.title,
      if (categoryId == null) FormGap.category,
      if (brandId == null) FormGap.brand,
      if (price == null || price < 1) FormGap.price,
      if (advance == null)
        FormGap.advance
      else if (price != null && price > 0 && advance > price)
        FormGap.advanceTooHigh,
      if (features.isEmpty) FormGap.features,
      if (featureChars(features) > maxFeatureChars) FormGap.tooManyFeatures,
    ];

/// "Rs. 72,000" typed as "72000": parse the digits only.
int? parseRupees(String s) {
  final d = s.replaceAll(RegExp(r'[^0-9]'), '');
  return d.isEmpty ? null : int.tryParse(d);
}
