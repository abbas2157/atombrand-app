import 'package:atombrand_app/v2/features/catalogue/data/catalogue_logic.dart';
import 'package:atombrand_app/v2/features/catalogue/data/catalogue_models.dart';
import 'package:atombrand_app/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final l = lookupAppLocalizations(const Locale('en'));

ProductRow row(
  String status, {
  bool featured = false,
  int id = 1,
  int price = 1000,
  String title = 'A',
}) => ProductRow(
  id: id,
  title: title,
  status: status,
  price: price,
  featured: featured,
);

const options = FormOptions(
  categories: [
    NamedOption(1, 'Phones'),
    NamedOption(4, 'LED TVs'),
    NamedOption(9, 'ACs'),
  ],
  brands: [NamedOption(7, 'Zenvo')],
  colors: [NamedOption(1, 'Black'), NamedOption(2, 'Silver')],
  memories: [NamedOption(11, '128 GB'), NamedOption(12, '256 GB')],
  sizes: [NamedOption(21, '43"'), NamedOption(22, '55"')],
);

void main() {
  group('productActions', () {
    test('an editor without stock rights on a live product', () {
      expect(
        productActions(
          row(ProductStatus.published),
          canEdit: true,
          canStock: false,
          inventoryOn: false,
        ),
        [
          ProductAction.edit,
          ProductAction.feature,
          ProductAction.atompay,
          ProductAction.delete,
        ],
      );
    });

    test('without Inventory: mark out of stock or back in stock', () {
      expect(
        productActions(
          row(ProductStatus.published),
          canEdit: false,
          canStock: true,
          inventoryOn: false,
        ),
        [ProductAction.markOut],
      );
      expect(
        productActions(
          row(ProductStatus.outOfStock),
          canEdit: false,
          canStock: true,
          inventoryOn: false,
        ),
        [ProductAction.backIn],
      );
    });

    test('with Inventory: stock and serials, never the hand switch', () {
      final a = productActions(
        row(ProductStatus.outOfStock),
        canEdit: true,
        canStock: true,
        inventoryOn: true,
      );
      expect(a, contains(ProductAction.stock));
      expect(a, isNot(contains(ProductAction.backIn)));
      expect(a, isNot(contains(ProductAction.markOut)));
    });

    test('Order handler (see stock, no catalogue edit)', () {
      List<ProductAction> of(String s, {bool canStock = true}) =>
          productActions(
            row(s),
            canEdit: false,
            canStock: canStock,
            inventoryOn: true,
          );
      // Only Stock and serials, never edit, feature, AtomPay or delete.
      expect(of(ProductStatus.published), [ProductAction.stock]);
      // Nothing allowed: the list hides the More actions button.
      expect(of(ProductStatus.pending), isEmpty);
      expect(of(ProductStatus.published, canStock: false), isEmpty);
    });

    test('add-ons not known yet: no stock actions', () {
      final a = productActions(
        row(ProductStatus.published),
        canEdit: true,
        canStock: true,
        inventoryOn: null,
      );
      expect(a, isNot(contains(ProductAction.stock)));
      expect(a, isNot(contains(ProductAction.markOut)));
    });

    test('in review: no feature unless already featured; no stock', () {
      final pending = productActions(
        row(ProductStatus.pending),
        canEdit: true,
        canStock: true,
        inventoryOn: false,
      );
      expect(pending, isNot(contains(ProductAction.feature)));
      expect(pending, isNot(contains(ProductAction.markOut)));
      expect(
        productActions(
          row(ProductStatus.pending, featured: true),
          canEdit: true,
          canStock: false,
          inventoryOn: false,
        ),
        contains(ProductAction.feature),
      );
    });

    test('closed products cannot be edited; viewers get nothing', () {
      expect(
        productActions(
          row(ProductStatus.closed),
          canEdit: true,
          canStock: false,
          inventoryOn: false,
        ),
        isNot(contains(ProductAction.edit)),
      );
      expect(
        productActions(
          row(ProductStatus.published),
          canEdit: false,
          canStock: false,
          inventoryOn: true,
        ),
        isEmpty,
      );
    });
  });

  test('availabilityTag', () {
    expect(availabilityTag(null, l), isNull);
    expect(
      availabilityTag(const Availability(units: 0, level: 'out'), l)!.$2,
      TagTone.rose,
    );
    expect(availabilityTag(const Availability(units: 2, level: 'low'), l), (
      'Only 2 left',
      TagTone.amber,
    ));
    expect(availabilityTag(const Availability(units: 20), l), (
      '20 available',
      TagTone.green,
    ));
  });

  test('atompayMonthly rounds up so three payments cover the price', () {
    expect(atompayMonthly(189999), 63333);
    expect(atompayMonthly(100000), 33334);
    expect(atompayMonthly(0), 0);
    expect(atompayMonthly(90), 30);
  });

  test('formModeFor and the button', () {
    expect(ctaLabel(formModeFor(null), l), 'Send for review');
    expect(ctaLabel(formModeFor('Published'), l), 'Save and send for review');
    expect(ctaLabel(formModeFor('On hold'), l), 'Fix and send again');
    expect(ctaLabel(formModeFor('Out of Stock'), l), 'Save changes');
    expect(ctaLabel(formModeFor('Pending'), l), 'Save changes');
    expect(goesForReview(FormMode.outOfStock), isFalse);
    expect(goesForReview(FormMode.live), isTrue);
    expect(goesForReview(FormMode.hold), isTrue);
  });

  group('form', () {
    ProductDraft full() => ProductDraft(
      title: 'Zenvo TV',
      categoryId: 4,
      brandId: 7,
      price: 189999,
      minAdvance: 40000,
      short: 'Smart TV',
      hasPicture: true,
    );

    test('a full draft has no gaps', () {
      expect(productGaps(full(), options), isEmpty);
      expect(missingLine([], l), isNull);
    });

    test('gaps in form order, with the advance above the price', () {
      final d = ProductDraft(price: 100, minAdvance: 200);
      expect(productGaps(d, options), [
        FormGap.picture,
        FormGap.title,
        FormGap.category,
        FormGap.brand,
        FormGap.advanceTooHigh,
        FormGap.short,
      ]);
      expect(
        missingLine([FormGap.picture, FormGap.price], l),
        'Add a feature image and a price to send',
      );
      expect(
        missingLine([FormGap.picture, FormGap.title, FormGap.price], l),
        'Add a feature image, a title and a price to send',
      );
    });

    test('an empty advance is a gap; 0 is an answer', () {
      expect(productGaps(full()..minAdvance = null, options), [
        FormGap.advance,
      ]);
      expect(productGaps(full()..minAdvance = 0, options), isEmpty);
    });

    test('a priced variant needs an option and a price', () {
      final d = full()..priced = [VariantDraft(id: 21)];
      expect(productGaps(d, options), [FormGap.variants]);
      d.priced.first.price = 119999;
      expect(productGaps(d, options), isEmpty);
    });

    test('variants of another category are not checked', () {
      final d = full()
        ..categoryId = 9
        ..priced = [VariantDraft()];
      expect(productGaps(d, options), isEmpty);
    });

    test('short description limit', () {
      expect(productGaps(full()..short = 'x' * 501, options), [
        FormGap.shortTooLong,
      ]);
    });

    test('variants follow the category', () {
      expect(pricedVariantFor(1, options), PricedVariant.storage);
      expect(pricedVariantFor(4, options), PricedVariant.size);
      expect(pricedVariantFor(9, options), PricedVariant.none);
      expect(pricedVariantFor(null, options), PricedVariant.none);
      expect(coloursFor(1, options), isTrue);
      expect(coloursFor(4, options), isFalse);
    });

    test('fields: TV sizes with their prices, AtomPay only when asked', () {
      final d = full()
        ..colors = {1}
        ..atompay = true
        ..priced = [
          VariantDraft(id: 21, price: 119999),
          VariantDraft(id: 22, price: 189999),
          VariantDraft(),
        ];
      final f = productFields(d, options, sendAtompay: false);
      expect(f['sizes[name][]'], [21, 22]);
      expect(f['sizes[price_21]'], 119999);
      expect(f['sizes[price_22]'], 189999);
      expect(f.containsKey('memories[name][]'), isFalse);
      // TVs take no colours.
      expect(f.containsKey('colors[]'), isFalse);
      expect(f.containsKey('atompay_eligible'), isFalse);
      expect(f['min_advance_price'], 40000);
      final g = productFields(d..categoryId = 1, options, sendAtompay: true);
      expect(g['memories[name][]'], [21, 22]);
      expect(g['colors[]'], [1]);
      expect(g['atompay_eligible'], 1);
    });

    test('usedVariantIds leaves out the row being picked', () {
      final a = VariantDraft(id: 1);
      final b = VariantDraft(id: 2);
      expect(usedVariantIds([a, b, VariantDraft()], except: a), {2});
    });
  });

  group('descriptions', () {
    test('html to plain lines and back', () {
      const html =
          '<p>Screen: 55&quot; 4K</p><ul><li>Netflix</li><li>YouTube &amp; more</li></ul>';
      final plain = htmlToPlain(html);
      expect(plain, 'Screen: 55" 4K\n• Netflix\n• YouTube & more');
      expect(
        plainToHtml(plain),
        '<p>Screen: 55" 4K</p><ul><li>Netflix</li><li>YouTube &amp; more</li></ul>',
      );
    });

    test('plain text stays as it is', () {
      expect(htmlToPlain('Just text'), 'Just text');
      expect(htmlToPlain(null), '');
      expect(plainToHtml('- a\n\nb'), '<ul><li>a</li></ul><p>b</p>');
    });
  });

  group('brand page', () {
    test('normaliseWebsite', () {
      expect(normaliseWebsite(''), '');
      expect(normaliseWebsite('zenvo.pk'), 'https://zenvo.pk');
      expect(normaliseWebsite('http://zenvo.pk/x'), 'http://zenvo.pk/x');
      expect(normaliseWebsite('zenvo'), isNull);
    });

    test('validEmail', () {
      expect(validEmail(''), isTrue);
      expect(validEmail('care@zenvo.pk'), isTrue);
      expect(validEmail('care@zenvo'), isFalse);
    });

    test('shortAddress', () {
      expect(
        shortAddress('https://atomshop.pk/brand/zenvo'),
        'atomshop.pk/brand/zenvo',
      );
    });

    test('pageFields sends the slides by index', () {
      final f = pageFields(
        title: ' Zenvo ',
        tagline: '',
        intro: 'Hi',
        about: '',
        website: 'https://zenvo.pk',
        email: '',
        phone: '',
        slides: const [PageSlide(tag: 'New', heading: 'TVs', text: 'x')],
      );
      expect(f['title'], 'Zenvo');
      expect(f['hero_intro'], 'Hi');
      expect(f['slides[0][heading]'], 'TVs');
      expect(f.containsKey('slides[1][heading]'), isFalse);
    });

    test('page parsing', () {
      final p = BrandPageData.fromJson({
        'brand': {
          'title': 'Zenvo',
          'public_url': 'https://atomshop.pk/brand/zenvo',
          'website': 'https://zenvo.pk',
        },
        'content': {
          'hero_intro': 'Hi',
          'slides': [
            {'tag': 'New', 'heading': 'TVs', 'text': ''},
          ],
        },
        'max_slides': 2,
        'featured': [
          {'id': 5, 'title': 'AC', 'status': 'Published'},
        ],
        'featured_count': 7,
        'published_count': 16,
      });
      expect(p.title, 'Zenvo');
      expect(p.slides.single.heading, 'TVs');
      expect(p.featured.single.id, 5);
      expect(p.featuredShown, 5);
      expect(p.featuredCount, 7);
      expect(p.publishedCount, 16);
    });
  });

  group('list', () {
    test('sortProducts', () {
      final rows = [
        row('Published', id: 1, price: 300, title: 'b'),
        row('Published', id: 3, price: 100, title: 'C'),
        row('Published', id: 2, price: 200, title: 'a'),
      ];
      List<int> ids(ProductSort s) =>
          sortProducts(rows, s).map((r) => r.id).toList();
      expect(ids(ProductSort.newest), [3, 2, 1]);
      expect(ids(ProductSort.oldest), [1, 2, 3]);
      expect(ids(ProductSort.priceLow), [3, 2, 1]);
      expect(ids(ProductSort.priceHigh), [1, 2, 3]);
      expect(ids(ProductSort.name), [2, 1, 3]);
    });

    test('pageFromCopy filters and counts on the phone', () {
      final all = [
        const ProductRow(
          id: 1,
          title: 'Zenvo AC',
          status: 'Published',
          prNumber: 'PR-1',
        ),
        const ProductRow(
          id: 2,
          title: 'Zenvo TV',
          status: 'Pending',
          prNumber: 'PR-2',
        ),
        const ProductRow(
          id: 3,
          title: 'Fryer',
          status: 'Published',
          prNumber: 'PR-3',
        ),
      ];
      final p = pageFromCopy(all, search: 'zenvo', status: 'Published');
      expect(p.rows.map((r) => r.id), [1]);
      expect(p.countOf('Published'), 2);
      expect(p.total, 3);
      expect(p.fromCopy, isTrue);
      expect(pageFromCopy(all, search: 'pr-3').rows.single.id, 3);
    });

    test('row parsing and code line', () {
      final r = ProductRow.fromJson({
        'id': '5',
        'pr_number': 'PR-5',
        'title': 'OXY',
        'price': '60000',
        'status': 'On hold',
        'status_note': 'Fix the photo',
        'brand_featured': 1,
        'atompay_brand_wide': true,
        'category': {'id': 4, 'title': 'LED TVs'},
        'variants': {'summary': 'One version'},
        'available': {'units': 4, 'warehouses': 2, 'level': 'low'},
      });
      expect(r.id, 5);
      expect(r.price, 60000);
      expect(r.featured, isTrue);
      expect(r.atompayOn, isTrue);
      expect(r.holdWhy, 'Fix the photo');
      expect(r.statusLabel(l), 'On hold');
      expect(variantsTag(r), isNull);
      expect(productCodeLine(r, l), 'PR-5 · LED TVs');
      expect(r.available!.units, 4);
      expect(
        productCodeLine(
          const ProductRow(id: 1, title: 'x', status: 'Pending'),
          l,
        ),
        'New',
      );
      // A status change drops the server's words for the old one.
      expect(
        r.copyWith(status: ProductStatus.published).statusLabel(l),
        'Live',
      );
    });

    test('form options parse the variant gates and size units', () {
      final o = FormOptions.fromJson({
        'sizes': [
          {'id': 1, 'title': '55', 'unit': '"'},
        ],
        'brands': [
          {
            'id': 7,
            'title': 'Zenvo',
            'category_ids': [4, '9'],
          },
        ],
        'variant_categories': {
          'colors': [1],
          'memories': [2],
          'sizes': [4],
        },
      });
      expect(o.sizes.single.title, '55"');
      expect(o.brands.single.categoryIds, [4, 9]);
      expect(o.colorCategories, [1]);
      expect(o.memoryCategories, [2]);
    });
  });
}
