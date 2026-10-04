import 'dart:io';

import 'package:atombrand_app/data/models/account.dart';
import 'package:atombrand_app/features/profile/more_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('footer version matches pubspec', () {
    final m = RegExp(r'^version:\s*([0-9.]+)', multiLine: true).firstMatch(File('pubspec.yaml').readAsStringSync());
    expect(appVersion, m!.group(1));
  });

  test('store chip follows brand.status', () {
    expect(storeStateOf('active'), StoreState.live);
    expect(storeStateOf('Pending'), StoreState.review);
    expect(storeStateOf('suspended'), StoreState.suspended);
    expect(storeStateOf(null), StoreState.unknown);
  });

  test('brand page checklist and nudge line', () {
    const b = Brand(id: 1, title: 'OXY', logo: 'x.png', tagline: 'Smart TVs');
    final c = brandPageChecklist(b);
    expect([for (final x in c) if (!x.done) x.label], ['Banner', 'Story']);
    expect(nudgeLine(['Banner', 'Story']), 'Add a banner and story to build buyer trust.');
    expect(nudgeLine(['Logo', 'Tagline', 'Banner']), 'Add a logo, tagline and banner to build buyer trust.');
    expect(missingLine(['Tagline', 'Banner', 'Story']), 'Tagline, banner and story missing');
  });

  test('phones and links read well', () {
    expect(formatPkPhone('+923302277522'), '+92 330 227 7522');
    expect(formatPkPhone('03302277522'), '+92 330 227 7522');
    expect(formatPkPhone('021 111 222'), '021 111 222');
    expect(shortUrl('https://atomshop.pk/brand/oxy/'), 'atomshop.pk/brand/oxy');
  });
}
