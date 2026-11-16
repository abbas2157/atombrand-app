import '../../../../l10n/app_localizations.dart';
import 'catalogue_models.dart';

/// The Catalogue feature's rules, kept apart from the widgets so they can be
/// tested: which actions a product offers, availability tags, the AtomPay
/// instalment, the form's gaps and payload, the brand page's payload.

// ── Products (8.1) ─────────────────────────────────────────────────────────

/// The ⋯ sheet's actions, in board order.
enum ProductAction { edit, stock, feature, atompay, markOut, backIn, delete }

/// What the person may do with [p]. Hidden, never shown locked:
/// - Edit, Feature, AtomPay and Delete need `catalogue.edit`; a closed
///   product can't be edited. Feature is for live products (or to take a
///   featured one off).
/// - Stock and serials needs the Inventory add-on and `stock.view`, for a
///   live product.
/// - Without the add-on, Mark out of stock / Back in stock (`POST
///   inventory/{id}`) needs `stock.view` too, and a live product.
List<ProductAction> productActions(
  ProductRow p, {
  required bool canEdit,
  required bool canStock,
  required bool? inventoryOn,
}) => [
  if (canEdit && p.status != ProductStatus.closed) ProductAction.edit,
  if (inventoryOn == true && canStock && p.isLive) ProductAction.stock,
  if (canEdit && (p.isLive || p.featured)) ProductAction.feature,
  if (canEdit) ProductAction.atompay,
  if (inventoryOn == false && canStock && p.status == ProductStatus.published)
    ProductAction.markOut,
  if (inventoryOn == false && canStock && p.status == ProductStatus.outOfStock)
    ProductAction.backIn,
  if (canEdit) ProductAction.delete,
];

enum TagTone { green, amber, rose }

/// The availability tag on a row: "20 available", "Only 2 left", "None
/// available". Null without the Inventory add-on or units.
(String, TagTone)? availabilityTag(Availability? a, AppLocalizations l) {
  if (a == null) return null;
  if (a.units <= 0 || a.level == 'out') {
    return (l.catNoneAvailable, TagTone.rose);
  }
  if (a.level == 'low') return (l.catOnlyLeft(a.units), TagTone.amber);
  return (l.catAvailableUnits(a.units), TagTone.green);
}

/// "PR-10421 · Air conditioners"; "New" for a product without a number
/// or a first submission still in review.
String productCodeLine(ProductRow p, AppLocalizations l) => [
  p.isNew || p.prNumber == null ? l.catNewCode : p.prNumber!,
  ?p.categoryTitle,
].join(' · ');

/// The variants tag, or null for a product with one version.
String? variantsTag(ProductRow p) {
  final s = p.variantsSummary;
  if (s == null || s.isEmpty || s == 'One version') return null;
  return s;
}

/// How Products is sorted. The server lists newest first; the others sort
/// the rows loaded so far.
enum ProductSort {
  newest('newest'),
  oldest(null),
  priceLow('price_asc'),
  priceHigh('price_desc'),
  name('name'),

  /// Fewest available first; offered only with the Inventory add-on.
  stock('stock');

  const ProductSort(this.serverKey);

  /// `GET products?sort=` (`newest`, `name`, `price_asc`, `price_desc`), so
  /// every page comes in this order; null for an order only the phone
  /// applies (oldest first).
  final String? serverKey;
}

String sortLabel(ProductSort s, AppLocalizations l) => switch (s) {
  ProductSort.newest => l.catSortNewest,
  ProductSort.oldest => l.catSortOldest,
  ProductSort.priceLow => l.catSortPriceLow,
  ProductSort.priceHigh => l.catSortPriceHigh,
  ProductSort.name => l.catSortName,
  ProductSort.stock => l.catSortStock,
};

List<ProductRow> sortProducts(List<ProductRow> rows, ProductSort sort) {
  final out = List.of(rows);
  int newest(ProductRow a, ProductRow b) => b.id.compareTo(a.id);
  switch (sort) {
    case ProductSort.newest:
      out.sort(newest);
    case ProductSort.oldest:
      out.sort((a, b) => a.id.compareTo(b.id));
    case ProductSort.priceLow:
      out.sort((a, b) {
        final c = a.price.compareTo(b.price);
        return c != 0 ? c : newest(a, b);
      });
    case ProductSort.priceHigh:
      out.sort((a, b) {
        final c = b.price.compareTo(a.price);
        return c != 0 ? c : newest(a, b);
      });
    case ProductSort.name:
      out.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    case ProductSort.stock:
      out.sort((a, b) {
        final c = (a.available?.units ?? 1 << 30).compareTo(
          b.available?.units ?? 1 << 30,
        );
        return c != 0 ? c : newest(a, b);
      });
  }
  return out;
}

/// Products read from the offline copy: filtered and counted on the phone.
ProductsPage pageFromCopy(
  List<ProductRow> all, {
  required String search,
  String? status,
}) {
  final term = search.trim().toLowerCase();
  final counts = <String, int>{};
  for (final p in all) {
    counts[p.status] = (counts[p.status] ?? 0) + 1;
  }
  final rows = [
    for (final p in all)
      if ((status == null || p.status == status) &&
          (term.isEmpty ||
              p.title.toLowerCase().contains(term) ||
              (p.prNumber?.toLowerCase().contains(term) ?? false)))
        p,
  ]..sort((a, b) => b.id.compareTo(a.id));
  return ProductsPage(
    rows: rows,
    counts: counts,
    total: all.length,
    fromCopy: true,
  );
}

// ── Product form (8.2) ─────────────────────────────────────────────────────

/// AtomPay's monthly payment: three equal payments, rounded up so three of
/// them cover the price.
int atompayMonthly(int price) => price <= 0 ? 0 : (price + 2) ~/ 3;

/// The form's mode, from the product's status.
enum FormMode { add, live, hold, review, outOfStock, closed }

FormMode formModeFor(String? status) => switch (status) {
  null => FormMode.add,
  ProductStatus.published => FormMode.live,
  ProductStatus.onHold => FormMode.hold,
  ProductStatus.outOfStock => FormMode.outOfStock,
  ProductStatus.closed => FormMode.closed,
  _ => FormMode.review,
};

/// The fixed button's words.
String ctaLabel(FormMode mode, AppLocalizations l) => switch (mode) {
  FormMode.add => l.catSendForReview,
  FormMode.hold => l.catFixAndSend,
  FormMode.live => l.catSaveAndSend,
  FormMode.review || FormMode.outOfStock || FormMode.closed => l.catSaveChanges,
};

/// Saving sends the product (back) to Atomshop's review.
bool goesForReview(FormMode mode) =>
    mode == FormMode.add || mode == FormMode.live || mode == FormMode.hold;

/// Which priced variant the category takes: storage (phones, tablets) or
/// screen size (TVs). Variants sent for another category are ignored.
enum PricedVariant { none, storage, size }

PricedVariant pricedVariantFor(int? categoryId, FormOptions o) {
  if (categoryId == null) return PricedVariant.none;
  if (o.memoryCategories.contains(categoryId)) return PricedVariant.storage;
  if (o.sizeCategories.contains(categoryId)) return PricedVariant.size;
  return PricedVariant.none;
}

bool coloursFor(int? categoryId, FormOptions o) =>
    categoryId != null && o.colorCategories.contains(categoryId);

/// One storage or size row being edited: the option (null until chosen)
/// and its price.
class VariantDraft {
  VariantDraft({this.id, this.price = 0});

  int? id;
  int price;

  bool get complete => id != null && price > 0;
}

/// Everything the form holds, for checking and sending.
class ProductDraft {
  ProductDraft({
    this.title = '',
    this.detailTitle = '',
    this.categoryId,
    this.brandId,
    this.price = 0,
    this.minAdvance,
    this.atompay = false,
    this.short = '',
    this.long = '',
    Set<int>? colors,
    List<VariantDraft>? priced,
    this.hasPicture = false,
  }) : colors = colors ?? {},
       priced = priced ?? [];

  String title;
  String detailTitle;
  int? categoryId;
  int? brandId;
  int price;

  /// Null while the box is empty (0 is a real answer: no advance).
  int? minAdvance;
  bool atompay;
  String short;

  /// The full description as HTML, ready to send.
  String long;
  Set<int> colors;
  List<VariantDraft> priced;
  bool hasPicture;
}

const maxShortChars = 500;
const maxGalleryPhotos = 8;

/// What still has to be filled in before the form can be sent, in the order
/// the form asks for it.
enum FormGap {
  picture,
  title,
  category,
  brand,
  price,
  advance,
  advanceTooHigh,
  variants,
  short,
  shortTooLong,
}

List<FormGap> productGaps(ProductDraft d, FormOptions o) => [
  if (!d.hasPicture) FormGap.picture,
  if (d.title.trim().isEmpty) FormGap.title,
  if (d.categoryId == null) FormGap.category,
  if (d.brandId == null) FormGap.brand,
  if (d.price < 1) FormGap.price,
  if (d.minAdvance == null)
    FormGap.advance
  else if (d.price > 0 && d.minAdvance! > d.price)
    FormGap.advanceTooHigh,
  if (pricedVariantFor(d.categoryId, o) != PricedVariant.none &&
      d.priced.any((v) => !v.complete))
    FormGap.variants,
  if (d.short.trim().isEmpty) FormGap.short,
  if (d.short.trim().length > maxShortChars) FormGap.shortTooLong,
];

String gapWords(FormGap g, AppLocalizations l) => switch (g) {
  FormGap.picture => l.catGapPicture,
  FormGap.title => l.catGapTitle,
  FormGap.category => l.catGapCategory,
  FormGap.brand => l.catGapBrand,
  FormGap.price => l.catGapPrice,
  FormGap.advance => l.catGapAdvance,
  FormGap.advanceTooHigh => l.catGapAdvanceHigh,
  FormGap.variants => l.catGapVariants,
  FormGap.short => l.catGapShort,
  FormGap.shortTooLong => l.catGapShortLong,
};

/// "Add a feature image and a price to send"; null with nothing missing.
String? missingLine(List<FormGap> gaps, AppLocalizations l) {
  if (gaps.isEmpty) return null;
  final words = [for (final g in gaps) gapWords(g, l)];
  final list = words.length == 1
      ? words.first
      : l.catListAnd(words.sublist(0, words.length - 1).join(', '), words.last);
  return l.catAddToSend(list);
}

/// The multipart fields of `POST products` / `products/{id}/update`.
///
/// Variants follow the admin form's shape: `colors[]`, `memories[name][]`
/// with `memories[price_{id}]`, `sizes[name][]` with `sizes[price_{id}]`.
/// Only the category's own variants are sent. [sendAtompay] false leaves
/// the product's AtomPay switch as it is.
Map<String, dynamic> productFields(
  ProductDraft d,
  FormOptions o, {
  required bool sendAtompay,
}) {
  final priced = pricedVariantFor(d.categoryId, o);
  final key = switch (priced) {
    PricedVariant.storage => 'memories',
    PricedVariant.size => 'sizes',
    PricedVariant.none => null,
  };
  final rows = [
    for (final v in d.priced)
      if (v.complete) v,
  ];
  return {
    'title': d.title.trim(),
    'detail_page_title': d.detailTitle.trim(),
    'category_id': d.categoryId,
    'brand_id': d.brandId,
    'price': d.price,
    'min_advance_price': d.minAdvance ?? 0,
    'short': d.short.trim(),
    'long': d.long,
    if (sendAtompay) 'atompay_eligible': d.atompay ? 1 : 0,
    if (coloursFor(d.categoryId, o) && d.colors.isNotEmpty)
      'colors[]': d.colors.toList(),
    if (key != null && rows.isNotEmpty) ...{
      '$key[name][]': [for (final v in rows) v.id],
      for (final v in rows) '$key[price_${v.id}]': v.price,
    },
  };
}

/// Ids already used by other rows, so each option is picked once.
Set<int> usedVariantIds(List<VariantDraft> rows, {VariantDraft? except}) => {
  for (final r in rows)
    if (r != except && r.id != null) r.id!,
};

// ── Descriptions ───────────────────────────────────────────────────────────

String _decode(String s) => s
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&rsquo;', '’');

String _escape(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

/// The stored description as plain lines to edit: blocks on their own
/// lines, list items as "• item". Text without tags comes back as it is.
String htmlToPlain(String? html) {
  if (html == null) return '';
  if (!RegExp(r'<[a-zA-Z/][^>]*>').hasMatch(html)) return _decode(html).trim();
  final text = html
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n• ')
      .replaceAll(
        RegExp(
          r'<br\s*/?>|</?(p|div|ul|ol|h[1-6]|tr|table|section)[^>]*>',
          caseSensitive: false,
        ),
        '\n',
      )
      .replaceAll(RegExp(r'<[^>]+>'), '');
  return _decode(text)
      .split('\n')
      .map((l) => l.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
      .where((l) => l.isNotEmpty && l != '•')
      .join('\n');
}

/// Plain lines as the HTML the server stores: a line starting with •, - or
/// * is a bullet, the rest are paragraphs.
String plainToHtml(String text) {
  final out = StringBuffer();
  var inList = false;
  for (final raw in text.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final bullet = RegExp(r'^[•\-*]\s*').firstMatch(line);
    if (bullet != null) {
      if (!inList) out.write('<ul>');
      inList = true;
      out.write('<li>${_escape(line.substring(bullet.end))}</li>');
    } else {
      if (inList) out.write('</ul>');
      inList = false;
      out.write('<p>${_escape(line)}</p>');
    }
  }
  if (inList) out.write('</ul>');
  return out.toString();
}

// ── Brand page (8.3) ───────────────────────────────────────────────────────

const maxIntroChars = 300;

/// The website as the server's `url` rule wants it: "zenvo.pk" gains
/// https://. Empty stays empty; null when it can't be a web address.
String? normaliseWebsite(String typed) {
  final t = typed.trim();
  if (t.isEmpty) return '';
  final withScheme = RegExp(r'^https?://', caseSensitive: false).hasMatch(t)
      ? t
      : 'https://$t';
  final uri = Uri.tryParse(withScheme);
  if (uri == null || uri.host.isEmpty || !uri.host.contains('.')) return null;
  if (uri.host.contains(' ')) return null;
  return withScheme;
}

bool validEmail(String typed) {
  final t = typed.trim();
  return t.isEmpty || RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
}

/// "atomshop.pk/brand/zenvo" from the public address.
String shortAddress(String? url) =>
    (url ?? '').replaceFirst(RegExp(r'^https?://(www\.)?'), '');

/// The fields of `POST page/update` (the images go as files).
Map<String, dynamic> pageFields({
  required String title,
  required String tagline,
  required String intro,
  required String about,
  required String website,
  required String email,
  required String phone,
  required List<PageSlide> slides,
}) => {
  'title': title.trim(),
  'tagline': tagline.trim(),
  'hero_intro': intro.trim(),
  'description': about.trim(),
  'website': website,
  'support_email': email.trim(),
  'support_phone': phone.trim(),
  for (var i = 0; i < slides.length; i++) ...{
    'slides[$i][tag]': slides[i].tag.trim(),
    'slides[$i][heading]': slides[i].heading.trim(),
    'slides[$i][text]': slides[i].text.trim(),
  },
};
