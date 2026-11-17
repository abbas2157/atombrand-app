import '../../data/models/account.dart';
import '../../data/models/dashboard.dart';

/// Most featured products the editor offers.
const maxFeatured = 6;

/// What a full brand page has; the editor's checklist and the More nudge
/// use the same four (promo slides always have the server's stock copy, so
/// they can't be "missing").
List<({String label, bool done, String section})> pageChecklist({
  required bool hasLogo,
  required bool hasBanner,
  required String tagline,
  required String story,
}) => [
      (label: 'Logo', done: hasLogo, section: 'header'),
      (label: 'Banner', done: hasBanner, section: 'header'),
      (label: 'Tagline', done: tagline.trim().isNotEmpty, section: 'about'),
      (label: 'Story', done: story.trim().isNotEmpty, section: 'about'),
    ];

/// Same checklist from a saved brand.
List<({String label, bool done, String section})> brandChecklist(Brand b) => pageChecklist(
      hasLogo: (b.logo ?? '').isNotEmpty,
      hasBanner: (b.banner ?? '').isNotEmpty,
      tagline: b.tagline ?? '',
      story: b.description ?? '',
    );

/// Featured ids to switch on and off to get from [saved] to [draft].
({List<int> add, List<int> remove}) featuredDiff(List<int> saved, List<int> draft) => (
      add: [for (final id in draft) if (!saved.contains(id)) id],
      remove: [for (final id in saved) if (!draft.contains(id)) id],
    );

bool sameSlides(List<PageSlide> a, List<PageSlide> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].tag != b[i].tag || a[i].heading != b[i].heading || a[i].text != b[i].text) return false;
  }
  return true;
}

/// "https://www.oxy.pk" stays; "oxy.pk" gets https:// so the API takes it.
String normaliseUrl(String s) {
  final t = s.trim();
  if (t.isEmpty || RegExp(r'^https?://', caseSensitive: false).hasMatch(t)) return t;
  return 'https://$t';
}
