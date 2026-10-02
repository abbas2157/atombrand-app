import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/images.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/models/dashboard.dart';
import '../../data/repositories/brand_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/status_badge.dart';
import '../auth/auth_scaffold.dart';

/// F10: public brand storefront editor (§2.5). Slug, active status and
/// homepage placement are admin-only and not shown as editable.
class BrandPageScreen extends ConsumerStatefulWidget {
  const BrandPageScreen({super.key});

  @override
  ConsumerState<BrandPageScreen> createState() => _BrandPageScreenState();
}

class _SlideCtrls {
  _SlideCtrls(PageSlide s)
      : tag = TextEditingController(text: s.tag),
        heading = TextEditingController(text: s.heading),
        text = TextEditingController(text: s.text);

  final TextEditingController tag;
  final TextEditingController heading;
  final TextEditingController text;

  PageSlide get value => PageSlide(tag: tag.text.trim(), heading: heading.text.trim(), text: text.text.trim());

  void dispose() {
    tag.dispose();
    heading.dispose();
    text.dispose();
  }
}

class _BrandPageScreenState extends ConsumerState<BrandPageScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _tagline = TextEditingController();
  final _description = TextEditingController();
  final _website = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _hero = TextEditingController();
  final List<_SlideCtrls> _slides = [];

  BrandPage? _page;
  String? _loadError;
  PickedImage? _logo;
  PickedImage? _banner;
  bool _saving = false;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_title, _tagline, _description, _website, _email, _phone, _hero]) {
      c.dispose();
    }
    for (final s in _slides) {
      s.dispose();
    }
    super.dispose();
  }

  void _fill(BrandPage p) {
    final b = p.brand;
    _title.text = b.title;
    _tagline.text = b.tagline ?? '';
    _description.text = b.description ?? '';
    _website.text = b.website ?? '';
    _email.text = b.supportEmail ?? '';
    _phone.text = b.supportPhone ?? '';
    _hero.text = p.heroIntro;
    for (final s in _slides) {
      s.dispose();
    }
    _slides
      ..clear()
      ..addAll(p.slides.take(p.maxSlides).map(_SlideCtrls.new));
    _logo = null;
    _banner = null;
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

  Future<void> _pick({required bool logo}) async {
    try {
      final img = await pickImage(source: ImageSource.gallery, maxBytes: logo ? kLogoMaxBytes : kImageMaxBytes);
      if (img == null || !mounted) return;
      setState(() => logo ? _logo = img : _banner = img);
    } catch (_) {
      if (mounted) showToast(context, "Couldn't use that image. Try another one.");
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final p = await ref.read(brandRepositoryProvider).updatePage(BrandPageInput(
            title: _title.text.trim(),
            tagline: _tagline.text.trim(),
            description: _description.text.trim(),
            website: _website.text.trim(),
            supportEmail: _email.text.trim(),
            supportPhone: _phone.text.trim(),
            heroIntro: _hero.text.trim(),
            slides: _slides.map((s) => s.value).toList(),
            logo: _logo,
            banner: _banner,
          ));
      if (!mounted) return;
      ref.read(sessionProvider.notifier).updateBrand(p.brand);
      setState(() {
        _page = p;
        _fill(p);
      });
      showToast(context, 'Brand page updated.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
      showApiError(context, e.fieldErrors.isEmpty ? e : ApiException('Please fix the highlighted fields.'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _err(String f) => _error?.fieldError(f);

  @override
  Widget build(BuildContext context) {
    final p = _page;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brand page'),
        actions: [
          if (p?.brand.publicUrl != null)
            IconButton(
              tooltip: 'Preview public page',
              icon: const Icon(Icons.open_in_new_rounded),
              onPressed: () => openExternal(context, p!.brand.publicUrl),
            ),
        ],
      ),
      body: p == null
          ? (_loadError != null ? ErrorView(message: _loadError!, onRetry: _load) : const Center(child: CircularProgressIndicator()))
          : _buildForm(p),
      bottomNavigationBar: p == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: BusyButton(label: 'Save brand page', busy: _saving, onPressed: _save),
              ),
            ),
    );
  }

  Widget _buildForm(BrandPage p) {
    final t = Theme.of(context).textTheme;
    const gap = SizedBox(height: 14);
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Banner + logo
          AspectRatio(
            aspectRatio: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: _banner != null
                      ? Image.memory(_banner!.bytes, fit: BoxFit.cover)
                      : (p.brand.banner != null
                          ? NetThumb(p.brand.banner, size: double.infinity, radius: 0, icon: Icons.panorama_outlined)
                          : Container(color: AppColors.primarySoft)),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _pick(logo: false),
                    icon: const Icon(Icons.panorama_outlined),
                    label: const Text('Banner'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => _pick(logo: true),
                child: Semantics(
                  button: true,
                  label: 'Change logo',
                  child: _logo != null
                      ? ClipOval(child: Image.memory(_logo!.bytes, width: 72, height: 72, fit: BoxFit.cover))
                      : NetThumb(p.brand.logo, size: 72, radius: 36, icon: Icons.add_a_photo_outlined),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton(onPressed: () => _pick(logo: true), child: const Text('Change logo')),
                    Text('Logo up to 2 MB, banner up to 4 MB.', style: t.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          for (final f in ['picture', 'banner'])
            if (_err(f) != null) Text(_err(f)!, style: t.bodySmall?.copyWith(color: AppColors.dangerFg)),
          const SizedBox(height: 8),
          if (p.brand.publicUrl != null) ...[
            InfoBanner('Public address: ${p.brand.publicUrl}\nThe address and homepage placement are managed by AtomShop.'),
          ],
          const SectionTitle('About your brand'),
          TextFormField(
            controller: _title,
            decoration: InputDecoration(labelText: 'Brand name', errorText: _err('title')),
            validator: (v) => requiredValidator(v, 'Brand name'),
          ),
          gap,
          TextFormField(
            controller: _tagline,
            decoration: InputDecoration(labelText: 'Tagline', errorText: _err('tagline')),
          ),
          gap,
          TextFormField(
            controller: _description,
            maxLength: 5000,
            minLines: 4,
            maxLines: 10,
            decoration: InputDecoration(labelText: 'Story / description', alignLabelWithHint: true, errorText: _err('description')),
          ),
          const SectionTitle('Contact'),
          TextFormField(
            controller: _website,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(labelText: 'Website', hintText: 'https://', errorText: _err('website')),
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return null;
              final u = Uri.tryParse(s);
              return (u == null || !u.hasScheme || u.host.isEmpty) ? 'Enter a full URL, starting with https://' : null;
            },
          ),
          gap,
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: 'Support email', errorText: _err('support_email')),
            validator: (v) => emailValidator(v, required: false),
          ),
          gap,
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: 'Support phone', errorText: _err('support_phone')),
          ),
          const SectionTitle('Hero'),
          TextFormField(
            controller: _hero,
            maxLength: 300,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(labelText: 'Intro line', alignLabelWithHint: true, errorText: _err('hero_intro')),
          ),
          SectionTitle(
            'Promo slides (${_slides.length}/${p.maxSlides})',
            trailing: _slides.length < p.maxSlides
                ? TextButton.icon(
                    onPressed: () => setState(() => _slides.add(_SlideCtrls(const PageSlide()))),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add slide'),
                  )
                : null,
          ),
          if (_slides.isEmpty) Text('No slides. Your page shows the banner only.', style: t.bodySmall),
          for (final (i, s) in _slides.indexed) ...[
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Slide ${i + 1}', style: t.titleMedium)),
                      IconButton(
                        tooltip: 'Remove slide ${i + 1}',
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () => setState(() => _slides.removeAt(i).dispose()),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: s.tag,
                    maxLength: 40,
                    decoration: InputDecoration(labelText: 'Tag', hintText: 'e.g. New arrival', errorText: _err('slides.$i.tag')),
                  ),
                  TextFormField(
                    controller: s.heading,
                    maxLength: 90,
                    decoration: InputDecoration(
                      labelText: 'Heading',
                      helperText: 'Slides without a heading are not saved',
                      errorText: _err('slides.$i.heading'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: s.text,
                    maxLength: 160,
                    minLines: 2,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: 'Text', errorText: _err('slides.$i.text')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          SectionTitle('Featured products (${p.featured.length})'),
          if (p.featured.isEmpty)
            Text(
              'Feature products from their detail screen (star icon). You have ${p.publishedCount} live products.',
              style: t.bodySmall,
            )
          else
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (final f in p.featured)
                    ListTile(
                      leading: NetThumb(f.picture, size: 40),
                      title: Text(f.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: StatusBadge.product(f.status),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
