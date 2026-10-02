import 'json.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    this.uuid,
    this.email,
    this.phone,
    this.verified = false,
    this.lastLoginAt,
  });

  factory AppUser.fromJson(Json j) => AppUser(
        id: asInt(j['id']),
        uuid: asStr(j['uuid']),
        name: asStrOr(j['name']),
        email: asStr(j['email']),
        phone: asStr(j['phone']),
        verified: asBool(j['verified']),
        lastLoginAt: asStr(j['last_login_at']),
      );

  final int id;
  final String? uuid;
  final String name;
  final String? email;
  final String? phone;
  final bool verified;
  final String? lastLoginAt;
}

class Brand {
  const Brand({
    required this.id,
    required this.title,
    this.slug,
    this.status,
    this.tagline,
    this.logo,
    this.banner,
    this.publicUrl,
    this.supportEmail,
    this.supportPhone,
    this.description,
    this.website,
  });

  factory Brand.fromJson(Json j) => Brand(
        id: asInt(j['id']),
        title: asStrOr(j['title']),
        slug: asStr(j['slug']),
        status: asStr(j['status']),
        tagline: asStr(j['tagline']),
        logo: asStr(j['logo']),
        banner: asStr(j['banner']),
        publicUrl: asStr(j['public_url']),
        supportEmail: asStr(j['support_email']),
        supportPhone: asStr(j['support_phone']),
        description: asStr(j['description']),
        website: asStr(j['website']),
      );

  final int id;
  final String title;
  final String? slug;
  final String? status;
  final String? tagline;
  final String? logo;
  final String? banner;
  final String? publicUrl;
  final String? supportEmail;
  final String? supportPhone;
  final String? description;
  final String? website;
}

/// Successful `auth/login` body.
class AuthSession {
  const AuthSession({required this.token, required this.user, required this.brand});

  factory AuthSession.fromJson(Json j) => AuthSession(
        token: asStrOr(j['token']),
        user: AppUser.fromJson(asMap(j['user'])),
        brand: Brand.fromJson(asMap(j['brand'])),
      );

  final String token;
  final AppUser user;
  final Brand brand;
}

/// Where a code went: `auth/password/forgot` or `apply/otp/send`.
class VerificationChallenge {
  const VerificationChallenge({
    required this.channels,
    required this.destinations,
    required this.expiresIn,
    this.message,
    this.debugCode,
  });

  factory VerificationChallenge.fromJson(Json j, {String? message}) => VerificationChallenge(
        channels: asStrList(j['channels']),
        destinations: asMap(j['destinations']).map((k, v) => MapEntry(k, v.toString())),
        expiresIn: asInt(j['expires_in'], 600),
        message: message,
        debugCode: asStr(j['debug_code']),
      );

  final List<String> channels;
  final Map<String, String> destinations;
  final int expiresIn;
  final String? message;

  /// Only returned by local/testing servers (§10.1).
  final String? debugCode;
}

class AppConfig {
  const AppConfig({
    required this.supportPhone,
    required this.supportEmail,
    required this.supportWhatsapp,
    required this.otpLength,
    required this.applyPercentages,
    required this.productStatuses,
    required this.orderStatuses,
    required this.orderSettable,
    required this.bulkStatuses,
    required this.imageMaxKb,
    required this.galleryMax,
  });

  factory AppConfig.fromJson(Json j) {
    final support = asMap(j['support']);
    final statuses = asMap(j['statuses']);
    final uploads = asMap(j['uploads']);
    final percentages = j['apply'] is Map ? (j['apply'] as Map)['percentages'] : null;
    return AppConfig(
      supportPhone: asStr(support['phone']),
      supportEmail: asStr(support['email']),
      supportWhatsapp: asStr(support['whatsapp']),
      otpLength: asInt(asMap(j['otp'])['length'], 6),
      applyPercentages: percentages is List
          ? percentages.map((e) => int.tryParse(e.toString())).whereType<int>().toList()
          : List.generate(20, (i) => i + 1),
      productStatuses: asStrList(statuses['product']),
      orderStatuses: asStrList(statuses['order']),
      orderSettable: asStrList(statuses['order_settable']),
      bulkStatuses: asStrList(statuses['bulk_request']),
      imageMaxKb: asInt(uploads['image_max_kb'], 4096),
      galleryMax: asInt(uploads['gallery_max'], 8),
    );
  }

  static const fallback = AppConfig(
    supportPhone: '+923302277522',
    supportEmail: 'atomshoppk@gmail.com',
    supportWhatsapp: 'https://wa.me/923302277522',
    otpLength: 6,
    applyPercentages: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
    productStatuses: ['Published', 'Pending', 'Out of Stock', 'On hold', 'Closed'],
    orderStatuses: ['Pending', 'Varification', 'Processing', 'Delivered', 'Instalments', 'Completed', 'Cancelled'],
    orderSettable: ['Pending', 'Varification', 'Processing', 'Delivered', 'Completed', 'Cancelled'],
    bulkStatuses: ['New Lead', 'Contacted', 'Quoted', 'Won', 'Lost'],
    imageMaxKb: 4096,
    galleryMax: 8,
  );

  final String? supportPhone;
  final String? supportEmail;
  final String? supportWhatsapp;
  final int otpLength;
  final List<int> applyPercentages;
  final List<String> productStatuses;
  final List<String> orderStatuses;
  final List<String> orderSettable;
  final List<String> bulkStatuses;
  final int imageMaxKb;
  final int galleryMax;
}
