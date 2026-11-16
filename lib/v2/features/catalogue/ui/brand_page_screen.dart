import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/api/api_result.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/catalogue_images.dart';
import '../data/catalogue_logic.dart';
import '../data/catalogue_models.dart';
import '../data/catalogue_repository.dart';
import 'catalogue_parts.dart';

/// Brand page (8.3, `page.edit`): the page's address and counts, logo and
/// banner, the story, up to 2 promo slides, contact, the featured products
/// (featured from Products), View on atomshop.pk, Save. Saving is
/// immediate; Atomshop doesn't review it.
class BrandPageScreen extends ConsumerWidget {
  const BrandPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(brandPageProvider);
    return page.when(
      skipLoadingOnRefresh: true,
      loading: () => const _Frame(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: AtomLoadingCard(count: 6),
        ),
      ),
      error: (e, _) => _Frame(
        child: AtomErrorState(
          message: e is ApiFailure
              ? sayFailure(AppLocalizations.of(context), e)
              : null,
          error: e,
          onRetry: () => ref.invalidate(brandPageProvider),
        ),
      ),
      data: (data) => _BrandPageForm(key: ValueKey(data), data: data),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child, this.viewUrl});

  final Widget child;
  final String? viewUrl;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AtomColors.paper,
              border: Border(bottom: BorderSide(color: AtomColors.line)),
            ),
            child: AtomFlowBar(
              title: l.catBrandPageTitle,
              oneLine: true,
              trailing: [
                // At large text the label can't share the bar: the icon
                // alone, with its name for screen readers.
                if (viewUrl != null &&
                    MediaQuery.textScalerOf(context).scale(10) > 13 &&
                    MediaQuery.sizeOf(context).width < 400)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AtomIconButton(
                      icon: LucideIcons.externalLink,
                      label: l.catViewOnAtomshop,
                      onTap: () => launchUrl(
                        Uri.parse(viewUrl!),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  )
                else if (viewUrl != null)
                  Padding(
                    // 12 here and the bar's 4: the 16px gutter.
                    padding: const EdgeInsets.only(right: 12, left: 8),
                    child: AtomButton.small(
                      label: l.catViewOnAtomshop,
                      icon: LucideIcons.externalLink,
                      onPressed: () => launchUrl(
                        Uri.parse(viewUrl!),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// A slide's three boxes.
class _SlideBoxes {
  _SlideBoxes([PageSlide s = const PageSlide()])
    : tag = TextEditingController(text: s.tag),
      heading = TextEditingController(text: s.heading),
      text = TextEditingController(text: s.text);

  final TextEditingController tag;
  final TextEditingController heading;
  final TextEditingController text;

  PageSlide get value =>
      PageSlide(tag: tag.text, heading: heading.text, text: text.text);

  List<TextEditingController> get all => [tag, heading, text];
}

class _BrandPageForm extends ConsumerStatefulWidget {
  const _BrandPageForm({super.key, required this.data});

  final BrandPageData data;

  @override
  ConsumerState<_BrandPageForm> createState() => _BrandPageFormState();
}

class _BrandPageFormState extends ConsumerState<_BrandPageForm> {
  AppLocalizations get l => AppLocalizations.of(context);

  final _title = TextEditingController();
  final _tagline = TextEditingController();
  final _intro = TextEditingController();
  final _about = TextEditingController();
  final _website = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _slides = <_SlideBoxes>[];

  File? _logo;
  File? _banner;
  bool _dirty = false;
  bool _saving = false;
  bool _tried = false;
  Map<String, String> _errors = const {};

  BrandPageData get _d => widget.data;

  List<TextEditingController> get _boxes => [
    _title,
    _tagline,
    _intro,
    _about,
    _website,
    _email,
    _phone,
  ];

  @override
  void initState() {
    super.initState();
    _fill();
  }

  /// Puts the saved page into the boxes (start, and Discard changes).
  void _fill() {
    for (final c in _boxes) {
      c.removeListener(_touch);
    }
    for (final s in _slides) {
      for (final c in s.all) {
        c.dispose();
      }
    }
    _slides.clear();
    _title.text = _d.title;
    _tagline.text = _d.tagline ?? '';
    _intro.text = _d.heroIntro ?? '';
    _about.text = _d.description ?? '';
    _website.text = (_d.website ?? '').replaceFirst(
      RegExp(r'^https?://', caseSensitive: false),
      '',
    );
    _email.text = _d.supportEmail ?? '';
    _phone.text = _d.supportPhone ?? '';
    for (final s in _d.slides.take(_d.maxSlides)) {
      _addSlideBoxes(_SlideBoxes(s));
    }
    for (final c in _boxes) {
      c.addListener(_touch);
    }
    _logo = null;
    _banner = null;
    _dirty = false;
    _tried = false;
    _errors = const {};
  }

  void _addSlideBoxes(_SlideBoxes s) {
    for (final c in s.all) {
      c.addListener(_touch);
    }
    _slides.add(s);
  }

  @override
  void dispose() {
    for (final c in _boxes) {
      c.dispose();
    }
    for (final s in _slides) {
      for (final c in s.all) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _touch() {
    if (mounted) setState(() => _dirty = true);
  }

  String? get _websiteError =>
      normaliseWebsite(_website.text) == null ? l.catWebsiteError : null;
  String? get _emailError =>
      validEmail(_email.text) ? null : l.catSupportEmailError;
  String? get _titleError =>
      _title.text.trim().isEmpty ? l.catDisplayNameError : null;
  String? get _introError =>
      _intro.text.trim().length > maxIntroChars ? l.catIntroTooLong : null;

  bool get _valid =>
      _websiteError == null &&
      _emailError == null &&
      _titleError == null &&
      _introError == null;

  Future<void> _pick({required bool logo}) async {
    final l = AppLocalizations.of(context);
    final source = await askPhotoSource(context);
    if (source == null || !mounted) return;
    try {
      final f = await pickPhoto(
        source: source,
        maxBytes: logo ? logoMaxBytes : imageMaxBytes,
      );
      if (f == null || !mounted) return;
      setState(() {
        logo ? _logo = f : _banner = f;
        _dirty = true;
      });
    } on ImageTooLarge {
      if (mounted) {
        showAtomToast(
          context,
          kind: AtomToastKind.bad,
          message: logo ? l.catLogoTooLarge : l.catPhotoTooLarge,
        );
      }
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    if (!_valid) {
      setState(() => _tried = true);
      showAtomToast(context, kind: AtomToastKind.bad, message: l.catFixFields);
      return;
    }
    setState(() {
      _saving = true;
      _errors = const {};
    });
    final r = await ref
        .read(catalogueRepositoryProvider)
        .savePage(
          fields: pageFields(
            title: _title.text,
            tagline: _tagline.text,
            intro: _intro.text,
            about: _about.text,
            website: normaliseWebsite(_website.text) ?? '',
            email: _email.text,
            phone: _phone.text,
            slides: [for (final s in _slides) s.value],
          ),
          logo: _logo,
          banner: _banner,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (r) {
      case ApiOk():
        showAtomToast(context, kind: AtomToastKind.ok, message: l.catPageSaved);
        setState(() => _dirty = false);
        // The new page comes back; the form refills from it.
        ref.invalidate(brandPageProvider);
      case ApiErr(:final failure):
        if (failure.kind == ApiFailureKind.validation) {
          setState(() {
            _errors = failure.fieldErrors;
            _tried = true;
          });
        }
        showAtomToast(
          context,
          kind: AtomToastKind.bad,
          message: failure.kind == ApiFailureKind.validation
              ? (failure.message ?? l.catFixFields)
              : sayFailure(AppLocalizations.of(context), failure),
        );
    }
  }

  String? _err(String key) => _errors[key];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = _d;
    return AtomUnsavedGuard(
      dirty: _dirty,
      child: _Frame(
        viewUrl: d.publicUrl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AtomSize.formMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _pageCard(d),
                  const SizedBox(height: 12),
                  _imagesCard(d),
                  const SizedBox(height: 12),
                  _storyCard(),
                  const SizedBox(height: 12),
                  _slidesCard(d),
                  const SizedBox(height: 12),
                  _contactCard(),
                  const SizedBox(height: 12),
                  _featuredCard(d),
                  const SizedBox(height: 16),
                  AtomButton(
                    label: l.catSavePage,
                    saving: _saving,
                    onPressed: _dirty ? _save : null,
                  ),
                  const SizedBox(height: 10),
                  AtomButton(
                    label: l.catDiscardChanges,
                    kind: AtomButtonKind.outline,
                    onPressed: _dirty && !_saving
                        ? () => setState(_fill)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pageCard(BrandPageData d) => FormCard(
    title: l.catPage,
    children: [
      Column(
        children: [
          // `.line` has a line above each row.
          const Divider(height: 1, color: AtomColors.line),
          AtomInfoLine(
            label: l.catAddress,
            value: shortAddress(d.publicUrl).isEmpty
                ? '–'
                : shortAddress(d.publicUrl),
          ),
          const Divider(height: 1, color: AtomColors.line),
          AtomInfoLine(label: l.catLiveProducts, value: '${d.publishedCount}'),
          const Divider(height: 1, color: AtomColors.line),
          AtomInfoLine(
            label: l.catFeatured,
            value: l.catFeaturedOf(
              d.featuredCount.clamp(0, d.featuredShown),
              d.featuredShown,
            ),
          ),
        ],
      ),
      Text(l.catAddressFixed, style: AtomText.small),
    ],
  );

  Widget _imagesCard(BrandPageData d) {
    final l = AppLocalizations.of(context);
    final Widget banner = _banner != null
        ? Image.file(_banner!, fit: BoxFit.cover)
        : d.banner != null
        ? AtomPhoto(d.banner!, fit: BoxFit.cover)
        : const ColoredBox(color: AtomColors.nav);
    final Widget logo = _logo != null
        ? Image.file(_logo!, fit: BoxFit.cover)
        : d.logo != null
        ? AtomPhoto(d.logo!, fit: BoxFit.cover)
        : Center(
            child: Text(
              _initials(d.title),
              style: AtomText.heading.copyWith(color: AtomColors.primary),
            ),
          );
    final caption = _banner != null
        ? l.catNewBanner
        : _logo != null
        ? l.catNewLogo
        : d.banner == null
        ? l.catNoBanner
        : null;
    return FormCard(
      title: l.catLogoAndBanner,
      children: [
        Container(
          height: 120,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              banner,
              // The logo sits top-left on the banner (`.banner .lg`).
              Positioned(
                left: 14,
                top: 14,
                child: Container(
                  width: 56,
                  height: 56,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AtomColors.paper,
                    borderRadius: AtomRadius.brCard,
                    border: Border.all(color: AtomColors.paper, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: logo,
                ),
              ),
              if (caption != null)
                // `.banner .cap`: plain 12px light text, bottom right.
                Positioned(
                  left: 84,
                  right: 12,
                  bottom: 12,
                  child: Text(
                    caption,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtomText.small.copyWith(
                      color: AtomColors.navText,
                      shadows: d.banner != null || _banner != null
                          ? const [Shadow(blurRadius: 4)]
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: AtomButton(
                label: l.catChangeLogo,
                kind: AtomButtonKind.outline,
                compact: true,
                fontSize: 14,
                onPressed: () => _pick(logo: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AtomButton(
                label: l.catChangeBanner,
                kind: AtomButtonKind.outline,
                compact: true,
                fontSize: 14,
                onPressed: () => _pick(logo: false),
              ),
            ),
          ],
        ),
        if (_err('picture') ?? _err('banner') case final e?)
          AtomFieldError(e)
        else
          Text(l.catLogoBannerHint, style: AtomText.small),
      ],
    );
  }

  Widget _storyCard() => FormCard(
    title: l.catYourStory,
    children: [
      AtomTextField(
        label: l.catDisplayName,
        controller: _title,
        error: (_tried ? _titleError : null) ?? _err('title'),
        inputFormatters: [LengthLimitingTextInputFormatter(255)],
        textInputAction: TextInputAction.next,
      ),
      AtomTextField(
        label: l.catTagline,
        controller: _tagline,
        error: _err('tagline'),
        inputFormatters: [LengthLimitingTextInputFormatter(255)],
        textInputAction: TextInputAction.next,
      ),
      AtomTextField(
        label: l.catIntro,
        controller: _intro,
        minLines: 3,
        keyboardType: TextInputType.multiline,
        hint: '${l.catIntroHint} ${_intro.text.trim().length} / $maxIntroChars',
        error: _introError ?? _err('hero_intro'),
      ),
      AtomTextField(
        label: l.catAbout,
        controller: _about,
        minLines: 5,
        keyboardType: TextInputType.multiline,
        error: _err('description'),
        inputFormatters: [LengthLimitingTextInputFormatter(5000)],
      ),
    ],
  );

  Widget _slidesCard(BrandPageData d) => FormCard(
    title: l.catPromoBanner,
    trailing: Text(
      l.catUpToSlides(d.maxSlides),
      style: AtomText.small.copyWith(fontWeight: FontWeight.w600),
    ),
    children: [
      for (final (i, s) in _slides.indexed)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AtomColors.head,
            borderRadius: AtomRadius.brControl,
            border: Border.all(color: AtomColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.catSlideN(i + 1),
                      style: AtomText.fieldLabel.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _MiniButton(
                    label: l.catRemove,
                    onTap: () => setState(() {
                      _slides.removeAt(i);
                      for (final c in s.all) {
                        c.dispose();
                      }
                      _dirty = true;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AtomTextField(
                label: l.catSmallLabel,
                controller: s.tag,
                boxHeight: 44,
                error: _err('slides.$i.tag'),
                inputFormatters: [LengthLimitingTextInputFormatter(40)],
              ),
              const SizedBox(height: 10),
              AtomTextField(
                label: l.catHeadline,
                controller: s.heading,
                boxHeight: 44,
                error: _err('slides.$i.heading'),
                hint: s.heading.text.trim().isEmpty
                    ? l.catSlideNoHeadline
                    : null,
                inputFormatters: [LengthLimitingTextInputFormatter(90)],
              ),
              const SizedBox(height: 10),
              AtomTextField(
                label: l.catSupportingLine,
                controller: s.text,
                boxHeight: 44,
                error: _err('slides.$i.text'),
                inputFormatters: [LengthLimitingTextInputFormatter(160)],
              ),
            ],
          ),
        ),
      if (_slides.length < d.maxSlides)
        Align(
          alignment: Alignment.centerLeft,
          child: AtomButton.small(
            label: l.catAddSlide,
            icon: LucideIcons.plus,
            onPressed: () => setState(() {
              _addSlideBoxes(_SlideBoxes());
              _dirty = true;
            }),
          ),
        ),
    ],
  );

  Widget _contactCard() => FormCard(
    title: l.catContact,
    children: [
      AtomTextField(
        label: l.catWebsite,
        controller: _website,
        prefix: const Icon(LucideIcons.globe),
        keyboardType: TextInputType.url,
        error: (_tried ? _websiteError : null) ?? _err('website'),
        textInputAction: TextInputAction.next,
      ),
      AtomTextField(
        label: l.catSupportEmail,
        controller: _email,
        prefix: const Icon(LucideIcons.mail),
        keyboardType: TextInputType.emailAddress,
        error: (_tried ? _emailError : null) ?? _err('support_email'),
        textInputAction: TextInputAction.next,
      ),
      AtomTextField(
        label: l.catSupportPhone,
        controller: _phone,
        prefix: const Icon(LucideIcons.phone),
        keyboardType: TextInputType.phone,
        error: _err('support_phone'),
        inputFormatters: [LengthLimitingTextInputFormatter(30)],
      ),
    ],
  );

  Widget _featuredCard(BrandPageData d) {
    final l = AppLocalizations.of(context);
    final shown = d.featured.take(d.featuredShown).toList();
    final more = d.featuredCount - shown.length;
    return FormCard(
      title: l.catFeaturedOnPage,
      trailing: AtomTextLink(
        label: l.catChange,
        onTap: () => context.go(V2Routes.products),
      ),
      children: [
        if (shown.isEmpty)
          Text(
            l.catNoFeatured,
            style: AtomText.body.copyWith(color: AtomColors.muted),
          )
        else
          Column(
            children: [
              for (final (i, f) in shown.indexed) ...[
                if (i > 0) const Divider(height: 1, color: AtomColors.line),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      AtomThumb(url: f.picture, size: 40),
                      const SizedBox(width: AtomSpace.s3),
                      Expanded(
                        child: Text(
                          f.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AtomText.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AtomColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: AtomSpace.s2),
                      StatusPill(
                        label: ProductStatus.label(f.status, l),
                        tone: statusTone(f.status),
                      ),
                    ],
                  ),
                ),
              ],
              if (more > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l.catAndMore(more), style: AtomText.small),
                  ),
                ),
            ],
          ),
        Text(l.catFeaturedHint, style: AtomText.small),
      ],
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

/// The slide's Remove (`.mini` at 30 tall, 12px), with a 48 tap area.
class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AtomPressable(
    onTap: onTap,
    semanticLabel: label,
    builder: (context, pressed) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Center(
        widthFactor: 1,
        child: Container(
          constraints: const BoxConstraints(minHeight: 30),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: pressed ? AtomColors.head : AtomColors.paper,
            borderRadius: AtomRadius.brControl,
            border: Border.all(color: AtomColors.line2),
          ),
          child: Text(
            label,
            style: AtomText.small.copyWith(
              fontWeight: FontWeight.w600,
              color: AtomColors.ink,
            ),
          ),
        ),
      ),
    ),
  );
}
