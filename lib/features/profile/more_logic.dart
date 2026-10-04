import '../../data/models/account.dart';
import '../brand_page/brand_page_logic.dart';

/// Shown in the More footer. Keep in step with `version:` in pubspec.yaml
/// (a test checks it).
const appVersion = '1.0.0';

/// The store chip on the profile card, from `brand.status`.
enum StoreState { live, review, suspended, unknown }

StoreState storeStateOf(String? status) => switch (status?.toLowerCase().trim()) {
      'active' || 'live' || 'approved' || 'published' => StoreState.live,
      'pending' || 'review' || 'in review' || 'under review' => StoreState.review,
      'suspended' || 'blocked' || 'inactive' || 'disabled' => StoreState.suspended,
      _ => StoreState.unknown,
    };

/// What a full brand page has; the same checklist as the editor.
List<({String label, bool done})> brandPageChecklist(Brand b) =>
    [for (final c in brandChecklist(b)) (label: c.label, done: c.done)];

/// "Add a banner and story to build buyer trust."
String nudgeLine(List<String> missing) {
  final words = missing.map((m) => m.toLowerCase()).toList();
  final list = words.length == 1 ? words.first : '${words.sublist(0, words.length - 1).join(', ')} and ${words.last}';
  final article = RegExp(r'^[aeiou]').hasMatch(list) ? 'an' : 'a';
  return 'Add $article $list to build buyer trust.';
}

/// "+923302277522" → "+92 330 227 7522"; other shapes are left as they are.
String formatPkPhone(String phone) {
  final d = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  final m = RegExp(r'^(?:\+92|0092|0)(3\d{2})(\d{3})(\d{4})$').firstMatch(d);
  if (m == null) return phone;
  return '+92 ${m[1]} ${m[2]} ${m[3]}';
}

/// "https://atomshop.pk/brand/oxy" → "atomshop.pk/brand/oxy".
String shortUrl(String url) => url.replaceFirst(RegExp(r'^https?://(www\.)?'), '').replaceFirst(RegExp(r'/$'), '');

/// "Tagline, banner and story missing".
String missingLine(List<String> missing) {
  final w = [for (final (i, m) in missing.indexed) i == 0 ? m : m.toLowerCase()];
  final list = w.length == 1 ? w.first : '${w.sublist(0, w.length - 1).join(', ')} and ${w.last}';
  return '$list missing';
}
