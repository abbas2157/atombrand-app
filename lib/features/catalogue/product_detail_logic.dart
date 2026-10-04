import '../../data/models/product.dart';

/// Which banner explains the product's status (DESIGN.md §4.9).
enum ProductBanner { live, outOfStock, review, rejected, onHold, closed, other }

ProductBanner bannerOf(ProductDetail d) {
  if (d.isRejected) return ProductBanner.rejected;
  return switch (d.summary.status) {
    'Published' => ProductBanner.live,
    'Out of Stock' => ProductBanner.outOfStock,
    'Pending' => ProductBanner.review,
    'On hold' => ProductBanner.onHold,
    'Closed' => ProductBanner.closed,
    _ => ProductBanner.other,
  };
}

String _decode(String s) => s
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&rsquo;', '’')
    .replaceAll('&ndash;', '–');

String _clean(String s) => _decode(s).replaceAll(RegExp(r'\s+'), ' ').trim();

/// The short description as a list: one feature per line, bullet, `;` or
/// `,` (a comma between digits, as in "1,000", stays). Never a raw comma list.
List<String> keyFeatures(String? short) {
  if (short == null) return const [];
  final text = _decode(short)
      .replaceAll(RegExp(r'<br\s*/?>|</p>|</li>|</div>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '');
  final parts = _splitList(text);
  final out = <String>[];
  for (var p in parts) {
    p = p.replaceAll(RegExp(r'\s+'), ' ').trim().replaceAll(RegExp(r'^[-–*•.\s]+|[.\s]+$'), '');
    if (p.isEmpty) continue;
    out.add(p[0].toUpperCase() + p.substring(1));
  }
  return out;
}

enum DescKind { heading, paragraph, bullet }

typedef DescBlock = ({DescKind kind, String text});

/// The HTML `long` description as headings, paragraphs and bullets, so it
/// is shown formatted and never as tags.
List<DescBlock> descriptionBlocks(String? html) {
  if (html == null || html.trim().isEmpty) return const [];
  final blocks = <DescBlock>[];
  final buf = StringBuffer();
  var kind = DescKind.paragraph;

  void flush() {
    final text = _clean(buf.toString());
    buf.clear();
    if (text.isNotEmpty) blocks.add((kind: kind, text: text));
  }

  final token = RegExp(r'<\s*(/?)\s*([a-zA-Z0-9]+)[^>]*>|([^<]+)');
  for (final m in token.allMatches(html)) {
    final text = m.group(3);
    if (text != null) {
      buf.write(text);
      continue;
    }
    final closing = m.group(1) == '/';
    final tag = m.group(2)!.toLowerCase();
    if (tag == 'br') {
      flush();
    } else if (RegExp(r'^h[1-6]$').hasMatch(tag)) {
      flush();
      kind = closing ? DescKind.paragraph : DescKind.heading;
    } else if (tag == 'li') {
      flush();
      kind = closing ? DescKind.paragraph : DescKind.bullet;
    } else if (const {'p', 'div', 'ul', 'ol', 'tr', 'table', 'section'}.contains(tag)) {
      flush();
      if (!closing) kind = DescKind.paragraph;
    }
  }
  flush();

  // A short paragraph ending in ':' ("Features:") reads as a heading, and a
  // comma list becomes bullets.
  return [
    for (final b in blocks)
      if (b.kind == DescKind.paragraph && b.text.length <= 60 && b.text.endsWith(':'))
        (kind: DescKind.heading, text: b.text.substring(0, b.text.length - 1))
      else if (b.kind == DescKind.paragraph && isCommaList(b.text))
        for (final item in keyFeatures(b.text)) (kind: DescKind.bullet, text: item)
      else
        b,
  ];
}

/// Splits on lines, bullets, `;` and commas, but never inside brackets
/// ("Assistant (voice, air mouse)") or between digits ("1,000").
List<String> _splitList(String text, {bool brackets = true}) {
  final parts = <String>[];
  final buf = StringBuffer();
  var depth = 0;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (brackets && (c == '(' || c == '[')) depth++;
    if (brackets && (c == ')' || c == ']') && depth > 0) depth--;
    final between = i > 0 && i + 1 < text.length && _isDigit(text[i - 1]) && _isDigit(text[i + 1]);
    final hardBreak = c == '\n' || c == '•';
    final softBreak = c == ';' || c == '·' || (c == ',' && !between);
    final dash = (c == '-' || c == '–' || c == '*') && i > 0 && i + 1 < text.length && text[i - 1] == ' ' && text[i + 1] == ' ';
    if (hardBreak || ((softBreak || dash) && depth == 0)) {
      parts.add(buf.toString());
      buf.clear();
      if (hardBreak) depth = 0;
    } else {
      buf.write(c);
    }
  }
  parts.add(buf.toString());
  // An unclosed bracket would swallow the rest: split as if there were none.
  if (depth > 0) return _splitList(text, brackets: false);
  return parts;
}

bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

/// A paragraph that is really a comma list ("Wifi, 1GB RAM, 2*HDMI, …"),
/// with no sentences in it.
bool isCommaList(String text) {
  if (RegExp(r'[.!?]\s+[A-Z]').hasMatch(text)) return false;
  final items = keyFeatures(text);
  if (items.length < 4) return false;
  return items.every((s) => s.length <= 60);
}
