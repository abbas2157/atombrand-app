import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/images.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/models/dashboard.dart';
import '../../data/models/product.dart';
import '../../data/repositories/brand_repository.dart';
import '../../data/repositories/catalogue_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../catalogue/inventory_logic.dart' show plural;
import '../profile/more_logic.dart' show shortUrl;
import 'brand_page_logic.dart';

/// Brand page editor (DESIGN.md §4.12): a header that looks like the public
/// page (banner, overlapping logo, name, tagline), a completeness checklist,
/// the read-only public address, then About, Promo slides, Featured products
/// and Contact. Nothing is sent until "Save changes (N)". Slug, active status
/// and homepage placement are AtomShop's and never editable here.
class BrandPageScreen extends ConsumerStatefulWidget {
  const BrandPageScreen({super.key});

  @override
  ConsumerState<BrandPageScreen> createState() => _BrandPageScreenState();
}

class _BrandPageScreenState extends ConsumerState<BrandPageScreen> {
  final _title = TextEditingController();
  final _tagline = TextEditingController();
  final _story = TextEditingController();
  final _hero = TextEditingController();
  final _website = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  final _headerKey = GlobalKey();
  final _aboutKey = GlobalKey();

  BrandPage? _page;
  String? _loadError;
  PickedImage? _logo;
  PickedImage? _banner;
  String? _logoError;
  String? _bannerError;
  List<PageSlide> _slides = [];
  List<FeaturedProduct> _featured = [];
  bool _saving = false;
  bool _showErrors = false;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    for (final c in [_title, _tagline, _story, _hero, _website, _email, _phone]) {
      c.addListener(_refresh);
    }
    _load();
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final c in [_title, _tagline, _story, _hero, _website, _email, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(BrandPage p) {
    final b = p.brand;
    _title.text = b.title;
    _tagline.text = b.tagline ?? '';
    _story.text = b.description ?? '';
    _hero.text = p.heroIntro;
    _website.text = b.website ?? '';
    _email.text = b.supportEmail ?? '';
    _phone.text = b.supportPhone ?? '';
    _slides = p.slides.take(p.maxSlides).toList();
    _featured = List.of(p.featured);
    _logo = null;
    _banner = null;
    _logoError = null;
    _bannerError = null;
    _error = null;
    _showErrors = false;
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final p = await ref.read(brandRepositoryProvider).page();
      if (!mounted) return;
      setState(() {
        _page = p;
        _fill(p);
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    }
  }

  /// Changed parts, each counted once (a slide list or the featured set
  /// counts as one change).
  int get _changeCount {
    final p = _page;
    if (p == null) return 0;
    final b = p.brand;
    var n = 0;
    void cmp(String now, String? was) {
      if (now.trim() != (was ?? '').trim()) n++;
    }

    cmp(_title.text, b.title);
    cmp(_tagline.text, b.tagline);
    cmp(_story.text, b.description);
    cmp(_hero.text, p.heroIntro);
    cmp(_website.text, b.website);
    cmp(_email.text, b.supportEmail);
    cmp(_phone.text, b.supportPhone);
    if (_logo != null) n++;
    if (_banner != null) n++;
    if (!sameSlides(_slides, p.slides.take(p.maxSlides).toList())) n++;
    if (_featured.map((f) => f.id).join(',') != p.featured.map((f) => f.id).join(',')) n++;
    return n;
  }

  Future<void> _pick({required bool logo}) async {
    try {
      final img = await pickImage(source: ImageSource.gallery, maxBytes: logo ? kLogoMaxBytes : kImageMaxBytes);
      if (img == null || !mounted) return;
      setState(() {
        if (logo) {
          _logo = img;
          _logoError = null;
        } else {
          _banner = img;
          _bannerError = null;
        }
      });
    } on ImageTooLarge catch (e) {
      if (!mounted) return;
      final msg = '${e.message} ${e.name} is ${e.size}. Try saving it as JPG, or pick a smaller one.';
      setState(() => logo ? _logoError = msg : _bannerError = msg);
    } catch (_) {
      if (mounted) showToast(context, "Couldn't use that image. Try another one.");
    }
  }

  String? _validate() {
    if (_title.text.trim().isEmpty) return 'Add your brand name';
    final email = _email.text.trim();
    if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) return 'Check the email address';
    final web = normaliseUrl(_website.text);
    if (web.isNotEmpty && (Uri.tryParse(web)?.host ?? '').isEmpty) return 'Check the website address';
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final problem = _validate();
    if (problem != null) {
      setState(() => _showErrors = true);
      showToast(context, problem);
      return;
    }
    final p = _page!;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(brandRepositoryProvider);
      final saved = await repo.updatePage(
        BrandPageInput(
          title: _title.text.trim(),
          tagline: _tagline.text.trim(),
          description: _story.text.trim(),
          website: normaliseUrl(_website.text),
          supportEmail: _email.text.trim(),
          supportPhone: _phone.text.trim(),
          heroIntro: _hero.text.trim(),
          slides: _slides,
          logo: _logo,
          banner: _banner,
        ),
      );
      // Featured is a star on each product: switch the differences.
      final diff = featuredDiff(p.featured.map((f) => f.id).toList(), _featured.map((f) => f.id).toList());
      final catalogue = ref.read(catalogueRepositoryProvider);
      for (final id in [...diff.add, ...diff.remove]) {
        await catalogue.toggleFeatured(id);
      }
      final fresh = diff.add.isEmpty && diff.remove.isEmpty ? saved : await repo.page();
      if (!mounted) return;
      ref.read(sessionProvider.notifier).updateBrand(fresh.brand);
      setState(() {
        _page = fresh;
        _fill(fresh);
      });
      showToast(context, 'Brand page saved. Buyers see it now.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _showErrors = true;
      });
      showApiError(context, e.fieldErrors.isEmpty ? e : ApiException('Please fix the fields marked in red.'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmLeave() async {
    final n = _changeCount;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: Text("You have ${plural(n, 'unsaved change')}. If you leave now, they'll be lost."),
        actionsOverflowDirection: VerticalDirection.up,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Discard', style: TextStyle(color: AppPalette.of(ctx).danger)),
          ),
          FilledButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep editing')),
        ],
      ),
    );
    return ok ?? false;
  }

  String? _err(String f) => _error?.fieldError(f);

  void _scrollTo(String section) {
    final ctx = (section == 'header' ? _headerKey : _aboutKey).currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), alignment: 0.02);
  }

  Future<void> _editSlide(int? index) async {
    final p = _page!;
    final result = await showModalBottomSheet<_SlideResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _SlideSheet(slide: index == null ? const PageSlide() : _slides[index], index: index ?? _slides.length),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (result.delete) {
        if (index != null) _slides = [..._slides]..removeAt(index);
      } else if (index == null) {
        if (_slides.length < p.maxSlides) _slides = [..._slides, result.slide!];
      } else {
        _slides = [..._slides]..[index] = result.slide!;
      }
    });
  }

  Future<void> _pickFeatured() async {
    final picked = await showModalBottomSheet<List<ProductSummary>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProductPicker(already: _featured.map((f) => f.id).toSet(), room: maxFeatured - _featured.length),
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    setState(
      () => _featured = [..._featured, for (final p in picked) FeaturedProduct(p.id, p.title, p.status, p.picture)],
    );
  }

  void _openPreview() {
    final p = _page!;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _PreviewScreen(
          title: _title.text.trim(),
          tagline: _tagline.text.trim(),
          hero: _hero.text.trim(),
          story: _story.text.trim(),
          logo: _logo,
          logoUrl: p.brand.logo,
          banner: _banner,
          bannerUrl: p.brand.banner,
          slides: _slides,
          featured: _featured,
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          website: _website.text.trim(),
          saved: _changeCount == 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _page;
    final changes = _changeCount;
    return PopScope(
      canPop: changes == 0 || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Brand page'),
          actions: [
            if (p != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: _openPreview,
                  style: TextButton.styleFrom(foregroundColor: AppPalette.of(context).onHeader),
                  icon: const Icon(Icons.visibility_outlined, size: 20),
                  label: const Text('Preview'),
                ),
              ),
          ],
        ),
        body: p == null
            ? (_loadError != null
                  ? ErrorView(message: _loadError!, onRetry: _load)
                  : const Center(child: CircularProgressIndicator()))
            : Column(
                children: [
                  Expanded(child: _buildForm(p)),
                  _SaveBar(changes: changes, saving: _saving, onDiscard: () => setState(() => _fill(p)), onSave: _save),
                ],
              ),
      ),
    );
  }

  Widget _buildForm(BrandPage p) {
    final pal = AppPalette.of(context);
    final checklist = pageChecklist(
      hasLogo: _logo != null || (p.brand.logo ?? '').isNotEmpty,
      hasBanner: _banner != null || (p.brand.banner ?? '').isNotEmpty,
      tagline: _tagline.text,
      story: _story.text,
    );
    final nameError = _showErrors && _title.text.trim().isEmpty ? 'Add your brand name' : _err('title');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        _Completeness(checklist: checklist, onTap: _scrollTo),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: _headerKey,
          child: _HeaderEditor(
            banner: _banner,
            bannerUrl: p.brand.banner,
            logo: _logo,
            logoUrl: p.brand.logo,
            title: _title.text.trim().isEmpty ? 'Your brand' : _title.text.trim(),
            tagline: _tagline.text.trim(),
            bannerError: _bannerError ?? _err('banner'),
            onBanner: () => _pick(logo: false),
            onLogo: () => _pick(logo: true),
          ),
        ),
        if (_logoError != null || _err('picture') != null) ...[
          const SizedBox(height: 8),
          _ErrorLine(_logoError ?? _err('picture')!),
        ],
        if (p.brand.publicUrl != null) ...[const SizedBox(height: 12), _AddressCard(url: p.brand.publicUrl!)],
        const SizedBox(height: 12),
        KeyedSubtree(
          key: _aboutKey,
          child: _Section(
            title: 'About your brand',
            children: [
              TextField(
                controller: _title,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(label: const _Label('Brand name', required: true), errorText: nameError),
              ),
              TextField(
                controller: _tagline,
                maxLength: 80,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  label: const _Label('Tagline'),
                  hintText: 'e.g. Smart TVs and appliances built for Pakistani homes',
                  helperText: 'Shown under your name',
                  errorText: _err('tagline'),
                ),
              ),
              TextField(
                controller: _hero,
                maxLength: 300,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  label: const _Label('Intro line', optional: true),
                  helperText: 'A short welcome at the top of your page',
                  errorText: _err('hero_intro'),
                ),
              ),
              TextField(
                controller: _story,
                maxLength: 5000,
                minLines: 5,
                maxLines: 14,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  label: const _Label('Story'),
                  alignLabelWithHint: true,
                  hintText:
                      'When you started, what you make, why buyers trust you. A blank line starts a new paragraph.',
                  hintMaxLines: 3,
                  errorText: _err('description'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Promo slides',
          trailing: '${_slides.length}/${p.maxSlides}',
          children: [
            if (_slides.isEmpty)
              _EmptyTile(
                title: 'Add your first slide',
                body: 'Promote offers like "Eid Sale: 10% off Smart TVs".',
                onTap: () => _editSlide(null),
              )
            else ...[
              SizedBox(
                height: 128,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  children: [
                    for (final (i, s) in _slides.indexed) ...[
                      _SlideCard(slide: s, index: i, onTap: () => _editSlide(i)),
                      const SizedBox(width: 10),
                    ],
                    if (_slides.length < p.maxSlides)
                      _AddTile(label: 'Add slide', width: 120, onTap: () => _editSlide(null)),
                  ],
                ),
              ),
              Text(
                'Buyers see these as a carousel under your banner.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: pal.muted),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Featured products',
          trailing: '${_featured.length}/$maxFeatured',
          children: [
            Text(
              'These appear at the top of your brand page.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: pal.muted),
            ),
            if (_featured.isEmpty)
              _EmptyTile(
                title: 'Pick up to $maxFeatured products',
                body: p.publishedCount == 0
                    ? 'Products appear here once AtomShop approves them.'
                    : 'Your best sellers, shown first to every visitor.',
                onTap: p.publishedCount == 0 ? null : _pickFeatured,
              )
            else
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                clipBehavior: Clip.none,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.78,
                children: [
                  for (final (i, f) in _featured.indexed)
                    _FeaturedCard(
                      product: f,
                      position: i + 1,
                      onRemove: () => setState(() => _featured = [..._featured]..removeAt(i)),
                    ),
                  if (_featured.length < maxFeatured) _AddTile(label: 'Add product', onTap: _pickFeatured),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Contact',
          children: [
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                label: const _Label('Phone'),
                hintText: '03xx xxxxxxx',
                prefixIcon: const Icon(Icons.call_outlined),
                errorText: _err('support_phone'),
              ),
            ),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                label: const _Label('Email'),
                hintText: 'care@yourbrand.pk',
                prefixIcon: const Icon(Icons.mail_outline_rounded),
                errorText:
                    _err('support_email') ??
                    (_showErrors && _validate() == 'Check the email address'
                        ? 'Enter an email like care@yourbrand.pk'
                        : null),
              ),
            ),
            TextField(
              controller: _website,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                label: const _Label('Website', optional: true),
                hintText: 'yourbrand.pk',
                prefixIcon: const Icon(Icons.public_rounded),
                errorText:
                    _err('website') ??
                    (_showErrors && _validate() == 'Check the website address'
                        ? 'Enter a web address like yourbrand.pk'
                        : null),
              ),
            ),
            Text(
              'Buyers see these on your page to call or email you.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: pal.muted),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _Label extends StatelessWidget {
  const _Label(this.text, {this.required = false, this.optional = false});
  final String text;
  final bool required;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text),
          if (required)
            TextSpan(
              text: ' *',
              style: TextStyle(color: pal.danger),
            ),
          if (optional)
            TextSpan(
              text: ' (optional)',
              style: TextStyle(color: pal.muted, fontWeight: FontWeight.w400),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.trailing});
  final String title;
  final String? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: pal.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: t.titleSmall?.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: t.labelSmall?.copyWith(fontSize: 12, color: pal.muted, fontFeatures: tabularFigures),
                ),
            ],
          ),
          for (final c in children) ...[const SizedBox(height: 14), c],
        ],
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline_rounded, size: 16, color: pal.danger),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: pal.danger, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Completeness extends StatelessWidget {
  const _Completeness({required this.checklist, required this.onTap});
  final List<({String label, bool done, String section})> checklist;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final done = checklist.where((c) => c.done).length;
    final pct = (done * 100 / checklist.length).round();
    final complete = done == checklist.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: pal.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  complete ? 'Your page is complete' : 'Your page is $pct% complete',
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (complete)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: pal.positive.bg, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, size: 14, color: pal.positive.fg),
                      const SizedBox(width: 4),
                      Text(
                        'Page complete',
                        style: t.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: pal.positive.fg),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  '$done of ${checklist.length}',
                  style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: pal.primary),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: done / checklist.length,
              minHeight: 8,
              color: complete ? pal.success : pal.primary,
              backgroundColor: pal.primarySoft2,
            ),
          ),
          if (!complete) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in checklist)
                  c.done
                      ? Chip(
                          avatar: Icon(Icons.check_rounded, size: 16, color: pal.positive.fg),
                          label: Text(c.label),
                          labelStyle: t.labelMedium?.copyWith(color: pal.positive.fg, fontWeight: FontWeight.w600),
                          backgroundColor: pal.positive.bg,
                          side: BorderSide.none,
                        )
                      : ActionChip(
                          avatar: Icon(Icons.add_rounded, size: 16, color: pal.primary),
                          label: Text(c.label),
                          tooltip: 'Add ${c.label.toLowerCase()}',
                          labelStyle: t.labelMedium?.copyWith(color: pal.primary, fontWeight: FontWeight.w600),
                          side: BorderSide(color: pal.ring),
                          onPressed: () => onTap(c.section),
                        ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Banner with the round logo overlapping it, then name and tagline: the
/// public page's header, editable in place.
class _HeaderEditor extends StatelessWidget {
  const _HeaderEditor({
    required this.banner,
    required this.bannerUrl,
    required this.logo,
    required this.logoUrl,
    required this.title,
    required this.tagline,
    required this.bannerError,
    required this.onBanner,
    required this.onLogo,
  });

  final PickedImage? banner;
  final String? bannerUrl;
  final PickedImage? logo;
  final String? logoUrl;
  final String title;
  final String tagline;
  final String? bannerError;
  final VoidCallback onBanner;
  final VoidCallback onLogo;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final hasBanner = banner != null || (bannerUrl ?? '').isNotEmpty;
    final radius = BorderRadius.circular(AppRadius.card);
    final top = BorderRadius.vertical(top: Radius.circular(AppRadius.card));
    const logoSize = 80.0;

    final bannerArea = AspectRatio(
      aspectRatio: 16 / 6,
      child: hasBanner
          ? Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: top,
                  child: banner != null
                      ? Image.memory(banner!.bytes, fit: BoxFit.cover)
                      : NetThumb(bannerUrl, size: double.infinity, radius: 0),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: FilledButton.icon(
                    onPressed: onBanner,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.65),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(Icons.photo_camera_outlined, size: 16),
                    label: const Text('Change'),
                  ),
                ),
              ],
            )
          : Material(
              color: bannerError != null
                  ? Color.alphaBlend(pal.negative.bg.withValues(alpha: 0.5), pal.card)
                  : pal.surface,
              borderRadius: top,
              child: InkWell(
                borderRadius: top,
                onTap: onBanner,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: top,
                    border: bannerError != null ? Border.all(color: pal.danger, width: 2) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 30,
                        color: bannerError != null ? pal.danger : pal.muted,
                      ),
                      const SizedBox(height: 2),
                      Text('Add a banner', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Text('1600×600 px, up to 4 MB', style: t.bodySmall?.copyWith(color: pal.muted)),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(color: pal.card, borderRadius: radius, boxShadow: pal.cardShadow),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                button: true,
                label: hasBanner ? 'Change banner' : 'Add a banner, 1600 by 600 pixels, up to 4 MB',
                child: bannerArea,
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, logoSize / 2 + 10, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                        const SizedBox(height: 2),
                        Text(
                          tagline.isEmpty ? 'Your tagline shows here' : tagline,
                          style: t.bodyMedium?.copyWith(
                            color: tagline.isEmpty ? pal.muted.withValues(alpha: 0.7) : pal.muted,
                            fontStyle: tagline.isEmpty ? FontStyle.italic : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: -logoSize / 2,
                    child: Semantics(
                      button: true,
                      label: 'Change logo, square, up to 2 MB',
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: onLogo,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: pal.card, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: logo != null
                                  ? ClipOval(
                                      child: Image.memory(
                                        logo!.bytes,
                                        width: logoSize,
                                        height: logoSize,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : NetThumb(
                                      logoUrl,
                                      size: logoSize,
                                      radius: logoSize / 2,
                                      icon: Icons.add_a_photo_outlined,
                                    ),
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: pal.header,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: pal.card, width: 3),
                                ),
                                child: Icon(Icons.photo_camera_outlined, size: 15, color: pal.onHeader),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16 + logoSize + 18,
                    top: 8,
                    right: 16,
                    child: Text(
                      'Logo: square, up to 2 MB',
                      style: t.bodySmall?.copyWith(fontSize: 11.5, color: pal.muted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (bannerError != null) ...[const SizedBox(height: 8), _ErrorLine(bannerError!)],
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    Widget round(IconData icon, String tip, VoidCallback onTap) => IconButton.outlined(
      tooltip: tip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: pal.card,
        side: BorderSide(color: pal.border),
        minimumSize: const Size(44, 44),
      ),
      icon: Icon(icon, size: 18),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: pal.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 14, color: pal.muted),
              const SizedBox(width: 6),
              Text(
                'PUBLIC ADDRESS · READ ONLY',
                style: t.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: pal.muted,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: SelectableText(shortUrl(url), style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              ),
              round(Icons.copy_rounded, 'Copy link', () {
                Clipboard.setData(ClipboardData(text: url));
                showToast(context, 'Link copied');
              }),
              const SizedBox(width: 6),
              round(
                Icons.share_outlined,
                'Share link',
                () => SharePlus.instance.share(ShareParams(uri: Uri.parse(url))),
              ),
            ],
          ),
          Text(
            'The address and homepage placement are managed by AtomShop.',
            style: t.bodySmall?.copyWith(color: pal.muted),
          ),
        ],
      ),
    );
  }
}

class _EmptyTile extends StatelessWidget {
  const _EmptyTile({required this.title, required this.body, required this.onTap});
  final String title;
  final String body;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Material(
      color: pal.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: pal.border, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: pal.primarySoft2, borderRadius: BorderRadius.circular(12)),
                child: Icon(onTap == null ? Icons.hourglass_empty_rounded : Icons.add_rounded, color: pal.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(body, style: t.bodySmall?.copyWith(color: pal.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.label, required this.onTap, this.width});
  final String label;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    return SizedBox(
      width: width,
      child: Material(
        color: pal.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: pal.border, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: pal.primary),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: pal.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _slideColors = [
  [Color(0xFF10122B), Color(0xFF34407A)],
  [Color(0xFF4136C9), Color(0xFF7B6FF0)],
  [Color(0xFFB42318), Color(0xFFE8354A)],
];

/// A text slide as buyers see it in the carousel.
class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.index, this.big = false});
  final PageSlide slide;
  final int index;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = _slideColors[index % _slideColors.length];
    return Container(
      padding: EdgeInsets.all(big ? 16 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(colors: c, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (slide.tag.isNotEmpty)
            Text(
              slide.tag.toUpperCase(),
              style: t.labelSmall?.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: Colors.white70,
              ),
            ),
          Text(
            slide.heading.isEmpty ? 'Headline' : slide.heading,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: (big ? t.titleLarge : t.titleSmall)?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          if (slide.text.isNotEmpty)
            Text(
              slide.text,
              maxLines: big ? 3 : 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
            ),
        ],
      ),
    );
  }
}

class _SlideCard extends StatelessWidget {
  const _SlideCard({required this.slide, required this.index, required this.onTap});
  final PageSlide slide;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    return Semantics(
      button: true,
      label: 'Edit slide ${index + 1}: ${slide.heading}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 224,
          child: Stack(
            children: [
              Positioned.fill(
                child: _SlideView(slide: slide, index: index),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: pal.card, shape: BoxShape.circle),
                  child: Icon(Icons.edit_outlined, size: 16, color: pal.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideResult {
  const _SlideResult.save(this.slide) : delete = false;
  const _SlideResult.delete() : slide = null, delete = true;
  final PageSlide? slide;
  final bool delete;
}

class _SlideSheet extends StatefulWidget {
  const _SlideSheet({required this.slide, required this.index});
  final PageSlide slide;
  final int index;

  @override
  State<_SlideSheet> createState() => _SlideSheetState();
}

class _SlideSheetState extends State<_SlideSheet> {
  late final _tag = TextEditingController(text: widget.slide.tag);
  late final _heading = TextEditingController(text: widget.slide.heading);
  late final _text = TextEditingController(text: widget.slide.text);
  bool _tried = false;

  bool get _isNew => widget.slide.heading.isEmpty;

  @override
  void initState() {
    super.initState();
    for (final c in [_tag, _heading, _text]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_tag, _heading, _text]) {
      c.dispose();
    }
    super.dispose();
  }

  PageSlide get _value => PageSlide(tag: _tag.text.trim(), heading: _heading.text.trim(), text: _text.text.trim());

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pal = AppPalette.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isNew ? 'New slide' : 'Edit slide ${widget.index + 1}',
                style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: _SlideView(slide: _value, index: widget.index, big: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tag,
                maxLength: 40,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(label: _Label('Label', optional: true), hintText: 'e.g. Eid offer'),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _heading,
                maxLength: 90,
                autofocus: _isNew,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  label: const _Label('Headline', required: true),
                  hintText: 'e.g. Eid Sale: 10% off Smart TVs',
                  errorText: _tried && _heading.text.trim().isEmpty ? 'Add a headline' : null,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _text,
                maxLength: 160,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  label: _Label('Text', optional: true),
                  hintText: 'One line with the details',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (!_isNew) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, const _SlideResult.delete()),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52), foregroundColor: pal.danger),
                        child: const Text('Delete slide'),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (_heading.text.trim().isEmpty) {
                          setState(() => _tried = true);
                          return;
                        }
                        Navigator.pop(context, _SlideResult.save(_value));
                      },
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                      child: Text(_isNew ? 'Add slide' : 'Done'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Changes go live when you save the brand page.',
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(color: pal.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.product, required this.position, required this.onRemove});
  final FeaturedProduct product;
  final int position;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final live = product.status == 'Published';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: pal.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: pal.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: NetThumb(product.picture, size: 60, radius: 8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.labelSmall?.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.3),
              ),
              if (!live)
                Text(
                  'Not live',
                  style: t.labelSmall?.copyWith(fontSize: 11, color: pal.negative.fg, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: pal.header.withValues(alpha: 0.8), shape: BoxShape.circle),
            child: Center(
              child: Text(
                '$position',
                style: t.labelSmall?.copyWith(color: pal.onHeader, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        Positioned(
          top: -12,
          right: -12,
          child: SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              tooltip: 'Remove ${product.title}',
              padding: EdgeInsets.zero,
              onPressed: onRemove,
              icon: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: pal.header,
                  shape: BoxShape.circle,
                  border: Border.all(color: pal.card, width: 2),
                ),
                child: Icon(Icons.close_rounded, size: 14, color: pal.onHeader),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Live products to feature, with search; returns the ones ticked.
class _ProductPicker extends ConsumerStatefulWidget {
  const _ProductPicker({required this.already, required this.room});
  final Set<int> already;
  final int room;

  @override
  ConsumerState<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends ConsumerState<_ProductPicker> {
  final _picked = <ProductSummary>[];
  List<ProductSummary>? _items;
  String _q = '';
  Timer? _debounce;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _error = null);
    try {
      final res = await ref.read(catalogueRepositoryProvider).products(q: _q.trim(), status: 'Published');
      if (mounted) setState(() => _items = res.items);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final items = (_items ?? const <ProductSummary>[]).where((p) => !widget.already.contains(p.id)).toList();
    final full = _picked.length >= widget.room;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text('Feature products', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Pick up to ${widget.room} more. Only live products can be featured.',
                style: t.bodySmall?.copyWith(color: pal.muted),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                onChanged: (v) {
                  _q = v;
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 350), _fetch);
                },
                decoration: const InputDecoration(
                  hintText: 'Search by name or PR number',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: _items == null
                  ? (_error != null
                        ? ErrorView(message: "Couldn't load your products.", onRetry: _fetch)
                        : const Center(child: CircularProgressIndicator()))
                  : items.isEmpty
                  ? Center(
                      child: Text(
                        _q.trim().isEmpty
                            ? 'All your live products are already featured.'
                            : 'No live products match “${_q.trim()}”',
                        style: t.bodyMedium?.copyWith(color: pal.muted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final p = items[i];
                        final sel = _picked.any((x) => x.id == p.id);
                        return CheckboxListTile(
                          value: sel,
                          onChanged: !sel && full
                              ? null
                              : (v) => setState(
                                  () => v == true ? _picked.add(p) : _picked.removeWhere((x) => x.id == p.id),
                                ),
                          secondary: NetThumb(p.picture, size: 48, radius: 10),
                          title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            [?p.prNumber, money(p.price)].join(' · '),
                            style: t.bodySmall?.copyWith(fontFeatures: tabularFigures),
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  onPressed: _picked.isEmpty ? null : () => Navigator.pop(context, _picked),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: Text(_picked.isEmpty ? 'Pick products' : 'Add ${plural(_picked.length, 'product')}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.changes, required this.saving, required this.onDiscard, required this.onSave});
  final int changes;
  final bool saving;
  final VoidCallback onDiscard;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: pal.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: pal.isDark ? 0.4 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              if (changes > 0) ...[
                TextButton(
                  onPressed: saving ? null : onDiscard,
                  style: TextButton.styleFrom(foregroundColor: pal.muted, minimumSize: const Size(0, 52)),
                  child: const Text('Discard'),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: changes == 0 || saving ? null : onSave,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: saving
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: pal.onPrimary),
                        )
                      : Text(changes == 0 ? 'Save brand page' : 'Save changes ($changes)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The buyer view of the draft, before it's saved.
class _PreviewScreen extends StatelessWidget {
  const _PreviewScreen({
    required this.title,
    required this.tagline,
    required this.hero,
    required this.story,
    required this.logo,
    required this.logoUrl,
    required this.banner,
    required this.bannerUrl,
    required this.slides,
    required this.featured,
    required this.phone,
    required this.email,
    required this.website,
    required this.saved,
  });

  final String title;
  final String tagline;
  final String hero;
  final String story;
  final PickedImage? logo;
  final String? logoUrl;
  final PickedImage? banner;
  final String? bannerUrl;
  final List<PageSlide> slides;
  final List<FeaturedProduct> featured;
  final String phone;
  final String email;
  final String website;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    const logoSize = 84.0;
    final hasBanner = banner != null || (bannerUrl ?? '').isNotEmpty;
    final live = featured.where((f) => f.status == 'Published').toList();
    // A white page: dark status-bar icons (light ones in dark mode).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: pal.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: pal.card,
        body: Stack(
          children: [
            ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(height: MediaQuery.paddingOf(context).top),
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: pal.divider)),
                  ),
                  child: Row(
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'atomshop'),
                            TextSpan(
                              text: '.pk',
                              style: TextStyle(color: pal.accent),
                            ),
                          ],
                        ),
                        style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
                      ),
                    ],
                  ),
                ),
                AspectRatio(
                  aspectRatio: 16 / 6,
                  child: hasBanner
                      ? (banner != null
                            ? Image.memory(banner!.bytes, fit: BoxFit.cover)
                            : NetThumb(bannerUrl, size: double.infinity, radius: 0))
                      : Container(color: pal.surface),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -logoSize / 2),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: pal.card, width: 4),
                          ),
                          child: logo != null
                              ? ClipOval(
                                  child: Image.memory(
                                    logo!.bytes,
                                    width: logoSize,
                                    height: logoSize,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : NetThumb(logoUrl, size: logoSize, radius: logoSize / 2),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -logoSize / 2 + 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                            if (tagline.isNotEmpty) Text(tagline, style: t.bodyMedium?.copyWith(color: pal.muted)),
                            if (hero.isNotEmpty) ...[const SizedBox(height: 8), Text(hero, style: t.bodyMedium)],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (slides.isNotEmpty)
                  SizedBox(
                    height: 170,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: slides.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => SizedBox(
                        width: 300,
                        child: _SlideView(slide: slides[i], index: i, big: true),
                      ),
                    ),
                  ),
                if (live.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                    child: Text('Featured', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.95,
                    children: [
                      for (final f in live)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: pal.divider),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: Center(child: NetThumb(f.picture, size: 90, radius: 8))),
                              const SizedBox(height: 6),
                              Text(
                                f.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
                if (story.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
                    child: Text('About $title', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(story, style: t.bodyMedium?.copyWith(height: 1.55)),
                  ),
                ],
                if (phone.isNotEmpty || email.isNotEmpty || website.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                    child: Text('Contact $title', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (phone.isNotEmpty)
                          Chip(avatar: const Icon(Icons.call_outlined, size: 18), label: Text(phone)),
                        if (email.isNotEmpty)
                          Chip(avatar: const Icon(Icons.mail_outline_rounded, size: 18), label: Text(email)),
                        if (website.isNotEmpty)
                          Chip(avatar: const Icon(Icons.public_rounded, size: 18), label: Text(website)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.only(left: 14, right: 4),
                  height: 44,
                  decoration: BoxDecoration(
                    color: pal.header,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: saved ? pal.success : pal.accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        saved ? 'Preview' : 'Preview · Not yet saved',
                        style: t.labelLarge?.copyWith(color: pal.onHeader),
                      ),
                      IconButton(
                        tooltip: 'Close preview',
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: pal.onHeader, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
