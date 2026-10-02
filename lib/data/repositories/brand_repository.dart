import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/images.dart';
import '../models/account.dart';
import '../models/dashboard.dart';
import '../models/json.dart';

class BrandPageInput {
  BrandPageInput({
    required this.title,
    this.tagline,
    this.description,
    this.website,
    this.supportEmail,
    this.supportPhone,
    this.heroIntro,
    this.slides = const [],
    this.logo,
    this.banner,
  });

  final String title;
  final String? tagline;
  final String? description;
  final String? website;
  final String? supportEmail;
  final String? supportPhone;
  final String? heroIntro;
  final List<PageSlide> slides;
  final PickedImage? logo;
  final PickedImage? banner;

  FormData toFormData() {
    final form = FormData();
    void field(String k, String? v) => form.fields.add(MapEntry(k, v ?? ''));
    field('title', title);
    field('tagline', tagline);
    field('description', description);
    field('website', website);
    field('support_email', supportEmail);
    field('support_phone', supportPhone);
    field('hero_intro', heroIntro);
    // A slide with an empty heading is dropped by the server; skip it here too.
    var i = 0;
    for (final s in slides.where((s) => s.heading.trim().isNotEmpty)) {
      field('slides[$i][tag]', s.tag);
      field('slides[$i][heading]', s.heading);
      field('slides[$i][text]', s.text);
      i++;
    }
    if (logo != null) form.files.add(MapEntry('picture', logo!.toMultipart()));
    if (banner != null) form.files.add(MapEntry('banner', banner!.toMultipart()));
    return form;
  }
}

class BrandRepository {
  BrandRepository(this._api);
  final ApiClient _api;

  Future<BrandPage> page() async => BrandPage.fromJson((await _api.get('page')).map);

  Future<BrandPage> updatePage(BrandPageInput input) async =>
      BrandPage.fromJson((await _api.post('page/update', data: input.toFormData())).map);

  Future<(AppUser, Brand)> profile() async {
    final d = (await _api.get('profile')).map;
    return (AppUser.fromJson(asMap(d['user'])), Brand.fromJson(asMap(d['brand'])));
  }

  Future<AppUser> updateProfile({required String name, required String email, String? phone}) async {
    final res = await _api.post('profile/update', data: {'name': name, 'email': email, 'phone': phone ?? ''});
    return AppUser.fromJson(asMap(res.map['user']));
  }

  /// Signs out every other device.
  Future<String> changePassword(String current, String password, String confirmation) async {
    final res = await _api.post('profile/password', data: {
      'current_password': current,
      'password': password,
      'password_confirmation': confirmation,
    });
    return res.message;
  }
}

final brandRepositoryProvider = Provider((ref) => BrandRepository(ref.watch(apiClientProvider)));
