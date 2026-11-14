import 'package:atombrand_app/l10n/app_localizations.dart';
import 'package:atombrand_app/v2/core/access/access.dart';
import 'package:atombrand_app/v2/core/access/access_controller.dart';
import 'package:atombrand_app/v2/core/session/session.dart';
import 'package:atombrand_app/v2/core/session/session_controller.dart';
import 'package:atombrand_app/v2/features/catalogue/data/catalogue_models.dart';
import 'package:atombrand_app/v2/features/catalogue/data/catalogue_repository.dart';
import 'package:atombrand_app/v2/features/catalogue/ui/brand_page_screen.dart';
import 'package:atombrand_app/v2/features/catalogue/ui/product_form_screen.dart';
import 'package:atombrand_app/v2/features/catalogue/ui/products_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Owner extends SessionController {
  @override
  SessionState build() => const SignedIn(
    BrandSession(
      token: 't',
      userId: 1,
      name: 'Owner',
      who: Who.owner(),
      brandName: 'Zenvo',
    ),
  );
}

class _Access extends AccessController {
  @override
  AccessState build() =>
      const AccessState(addonStates: {Addon.inventory: AddonState.off});
}

final _page = ProductsPage(
  rows: [
    ProductRow.fromJson({
      'id': 10421,
      'pr_number': 'PR-10421',
      'title': 'Zenvo Inverter AC 1.5 ton',
      'price': 149999,
      'status': 'Published',
      'brand_featured': true,
      'atompay_eligible': true,
      'category': {'id': 9, 'title': 'Air conditioners'},
      'variants': {'summary': '2 sizes'},
    }),
    ProductRow.fromJson({
      'id': 10433,
      'pr_number': 'PR-10433',
      'title': 'Zenvo Air Fryer 5 L',
      'price': 18499,
      'status': 'On hold',
      'status_note': 'Atomshop asked for a clearer feature image',
    }),
  ],
  counts: const {
    'Published': 16,
    'Pending': 3,
    'Out of Stock': 2,
    'On hold': 1,
  },
  total: 22,
);

const _options = FormOptions(
  categories: [NamedOption(4, 'LED TVs')],
  brands: [NamedOption(7, 'Zenvo')],
  sizes: [NamedOption(21, '43"'), NamedOption(22, '55"')],
);

Widget _app(Widget home) => ProviderScope(
  overrides: [
    sessionProvider.overrideWith(_Owner.new),
    accessProvider.overrideWith(_Access.new),
    productsProvider.overrideWith((ref, q) async => _page),
    formOptionsProvider.overrideWith((ref) async => _options),
    productDetailProvider.overrideWith(
      (ref, id) async => ProductDetail.fromJson({
        'id': id,
        'pr_number': 'PR-$id',
        'title': 'Zenvo 55" 4K Smart TV',
        'price': 189999,
        'min_advance_price': 40000,
        'status': 'Published',
        'category_id': 4,
        'brand_id': 7,
        'short': 'Smart TV',
        'sizes': [
          {'id': 21, 'price': 119999},
        ],
      }),
    ),
    brandPageProvider.overrideWith(
      (ref) async => BrandPageData.fromJson({
        'brand': {
          'title': 'Zenvo Appliances',
          'public_url': 'https://atomshop.pk/brand/zenvo',
        },
        'content': {
          'hero_intro': 'Hi',
          'slides': [
            {'tag': 'New', 'heading': 'TVs', 'text': ''},
          ],
        },
        'featured': [
          {'id': 5, 'title': 'Zenvo AC', 'status': 'Published'},
        ],
        'featured_count': 1,
        'published_count': 16,
      }),
    ),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

void main() {
  testWidgets('Products shows tiles, the hold callout and rows', (t) async {
    await t.pumpWidget(_app(const ProductsScreen()));
    await t.pumpAndSettle();
    expect(find.text('22 products · 16 live on atomshop.pk'), findsOneWidget);
    expect(find.text('Zenvo Air Fryer 5 L is on hold'), findsOneWidget);
    expect(find.text('Zenvo Inverter AC 1.5 ton'), findsOneWidget);
    expect(find.text('★ Featured'), findsOneWidget);
    expect(find.text('AtomPay on'), findsOneWidget);
    expect(find.text('Add product'), findsOneWidget);

    // The ⋯ sheet: without Inventory, a live product can be marked out.
    await t.tap(
      find.bySemanticsLabel('More actions for Zenvo Inverter AC 1.5 ton'),
    );
    await t.pumpAndSettle();
    expect(find.text('Mark out of stock'), findsOneWidget);
    expect(find.text('Stock and serials'), findsNothing);
    expect(find.text('Delete product'), findsOneWidget);
  });

  testWidgets('The form opens a live product with its TV sizes', (t) async {
    await t.pumpWidget(_app(const ProductFormScreen(id: 10388)));
    await t.pumpAndSettle();
    expect(find.text('Edit product'), findsOneWidget);
    expect(find.text('Screen sizes, each with its own price'), findsOneWidget);
    expect(find.text('Customer pays 3 × Rs 63,333'), findsNothing);
    expect(find.text('Save and send for review'), findsOneWidget);
  });

  testWidgets('A new product asks for what is missing', (t) async {
    await t.pumpWidget(_app(const ProductFormScreen()));
    await t.pumpAndSettle();
    expect(find.text('Add product'), findsOneWidget);
    expect(find.textContaining('Add a feature image'), findsWidgets);
  });

  testWidgets('Brand page shows the address, slide and featured', (t) async {
    await t.pumpWidget(_app(const BrandPageScreen()));
    await t.pumpAndSettle();
    expect(find.text('atomshop.pk/brand/zenvo'), findsOneWidget);
    expect(find.text('Slide 1'), findsOneWidget);
    expect(find.text('Zenvo AC'), findsOneWidget);
    expect(find.text('Save brand page'), findsOneWidget);
  });
}
