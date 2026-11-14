import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/money.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/catalogue_images.dart';
import '../data/catalogue_logic.dart';
import '../data/catalogue_models.dart';
import '../data/catalogue_repository.dart';
import 'catalogue_parts.dart';

/// Add or edit a product (8.2). New, Edit a live product and On hold modes
/// (plus In review and Out of stock edits); a section jump bar; photos
/// first (feature image and up to 8 more), details, price with the minimum
/// advance and AtomPay ("Customer pays 3 × …"), the category's variants,
/// the description; the fixed Send for review.
///
/// [id] null adds a product. Someone without `catalogue.edit` sees the
/// product read-only.
class ProductFormScreen extends ConsumerWidget {
  const ProductFormScreen({super.key, this.id});

  final int? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final options = ref.watch(formOptionsProvider);
    final detail = id == null ? null : ref.watch(productDetailProvider(id!));
    final failure = options.error ?? detail?.error;
    if (failure != null) {
      return _Shell(
        title: id == null ? l.catAddProduct : l.catEditTitle,
        child: AtomErrorState(
          message: failure is ApiFailure
              ? (failure.kind == ApiFailureKind.notFound
                    ? l.catProductNotFound
                    : sayFailure(AppLocalizations.of(context), failure))
              : null,
          onRetry: () {
            ref.invalidate(formOptionsProvider);
            if (id != null) ref.invalidate(productDetailProvider(id!));
          },
        ),
      );
    }
    final o = options.value;
    final d = detail?.value;
    if (o == null || (id != null && d == null)) {
      return _Shell(
        title: id == null ? l.catAddProduct : l.catEditTitle,
        child: const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: AtomLoadingCard(count: 5),
        ),
      );
    }
    final canEdit =
        ref
            .watch(sessionProvider.notifier)
            .current
            ?.who
            .can(BrandPermission.catalogueEdit) ??
        false;
    return _ProductForm(
      key: ValueKey(id),
      detail: d,
      options: o,
      canEdit: canEdit,
    );
  }
}

/// The bar and a body, while the form loads or can't.
class _Shell extends StatelessWidget {
  const _Shell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AtomColors.surface,
    body: Column(
      children: [
        Container(
          color: AtomColors.paper,
          child: AtomFlowBar(leading: AtomFlowLeading.close, title: title),
        ),
        Expanded(child: child),
      ],
    ),
  );
}

/// A storage or size row: the draft and its price box.
class _PricedRow {
  _PricedRow(this.draft)
    : price = TextEditingController(
        text: draft.price > 0 ? groupDigits(draft.price) : '',
      );

  final VariantDraft draft;
  final TextEditingController price;
}

enum _Section { photos, details, price, variants, description }

class _ProductForm extends ConsumerStatefulWidget {
  const _ProductForm({
    super.key,
    required this.detail,
    required this.options,
    required this.canEdit,
  });

  final ProductDetail? detail;
  final FormOptions options;
  final bool canEdit;

  @override
  ConsumerState<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<_ProductForm> {
  AppLocalizations get l => AppLocalizations.of(context);

  final _title = TextEditingController();
  final _detailTitle = TextEditingController();
  final _price = TextEditingController();
  final _advance = TextEditingController();
  final _short = TextEditingController();
  final _long = TextEditingController();

  int? _categoryId;
  int? _brandId;
  bool _atompay = false;
  final _colors = <int>{};
  final _priced = <_PricedRow>[];

  File? _picture;
  final _gallery = <GalleryImage>[];
  final _newGallery = <File>[];

  /// What the description boxes started with, to send the stored text back
  /// untouched when it wasn't edited.
  String _shortStart = '';
  String _longStart = '';

  bool _dirty = false;
  bool _saving = false;
  Map<String, String> _errors = const {};

  final _keys = {for (final s in _Section.values) s: GlobalKey()};

  ProductDetail? get _d => widget.detail;
  FormOptions get _o => widget.options;
  late final FormMode _mode = formModeFor(_d?.row.status);
  bool get _readOnly => !widget.canEdit || _mode == FormMode.closed;

  @override
  void initState() {
    super.initState();
    final d = _d;
    if (d != null) {
      _title.text = d.row.title;
      _detailTitle.text = d.detailTitle ?? '';
      _price.text = d.row.price > 0 ? groupDigits(d.row.price) : '';
      _advance.text = groupDigits(d.row.minAdvance);
      _shortStart = htmlToPlain(d.short);
      _longStart = htmlToPlain(d.long);
      _categoryId = d.categoryId ?? d.row.categoryId;
      _brandId = d.brandId;
      _atompay = d.row.atompay;
      _colors.addAll(d.colors);
      final priced = switch (pricedVariantFor(_categoryId, _o)) {
        PricedVariant.storage => d.memories,
        PricedVariant.size => d.sizes,
        PricedVariant.none => const <VariantPrice>[],
      };
      for (final v in priced) {
        _priced.add(_PricedRow(VariantDraft(id: v.id, price: v.price)));
      }
      _gallery.addAll(d.gallery);
    } else {
      // The partner's own brand is listed first.
      _brandId = _o.brands.firstOrNull?.id;
    }
    _short.text = _shortStart;
    _long.text = _longStart;
    for (final c in [_title, _detailTitle, _price, _advance, _short, _long]) {
      c.addListener(_touch);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _detailTitle,
      _price,
      _advance,
      _short,
      _long,
      for (final r in _priced) r.price,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _touch() {
    if (!mounted) return;
    setState(() => _dirty = true);
  }

  bool get _atompayBrandWide => _d?.row.atompayBrandWide ?? false;

  bool get _hasPicture =>
      _picture != null || (_d?.row.picture?.isNotEmpty ?? false);

  int get _galleryCount => _gallery.length + _newGallery.length;

  ProductDraft get _draft => ProductDraft(
    title: _title.text,
    detailTitle: _detailTitle.text,
    categoryId: _categoryId,
    brandId: _brandId,
    price: parseRupees(_price.text),
    minAdvance: _advance.text.trim().isEmpty
        ? null
        : parseRupees(_advance.text),
    atompay: _atompay,
    short: _short.text == _shortStart ? (_d?.short ?? '') : _short.text,
    long: _long.text == _longStart ? (_d?.long ?? '') : plainToHtml(_long.text),
    colors: _colors,
    priced: [for (final r in _priced) r.draft],
    hasPicture: _hasPicture,
  );

  bool _done(_Section s, ProductDraft d) {
    final gaps = productGaps(d, _o);
    return switch (s) {
      _Section.photos => !gaps.contains(FormGap.picture),
      _Section.details =>
        !gaps.contains(FormGap.title) &&
            !gaps.contains(FormGap.category) &&
            !gaps.contains(FormGap.brand),
      _Section.price =>
        !gaps.contains(FormGap.price) &&
            !gaps.contains(FormGap.advance) &&
            !gaps.contains(FormGap.advanceTooHigh),
      _Section.variants =>
        (_colors.isNotEmpty || _priced.isNotEmpty) &&
            !gaps.contains(FormGap.variants),
      _Section.description =>
        !gaps.contains(FormGap.short) && !gaps.contains(FormGap.shortTooLong),
    };
  }

  bool get _hasVariants =>
      coloursFor(_categoryId, _o) ||
      pricedVariantFor(_categoryId, _o) != PricedVariant.none;

  void _jump(_Section s) {
    final c = _keys[s]!.currentContext;
    if (c == null) return;
    Scrollable.ensureVisible(
      c,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // ── Photos ──────────────────────────────────────────────────────────────

  Future<void> _pickFeature() async {
    final l = AppLocalizations.of(context);
    final source = await askPhotoSource(context);
    if (source == null || !mounted) return;
    try {
      final f = await pickPhoto(source: source);
      if (f == null || !mounted) return;
      setState(() {
        _picture = f;
        _dirty = true;
        _errors = {..._errors}..remove('picture');
      });
    } on ImageTooLarge {
      if (mounted) {
        showAtomToast(
          context,
          kind: AtomToastKind.bad,
          message: l.catPhotoTooLarge,
        );
      }
    }
  }

  Future<void> _addGallery() async {
    final files = await pickPhotos(limit: maxGalleryPhotos - _galleryCount);
    if (files.isEmpty || !mounted) return;
    setState(() {
      _newGallery.addAll(files.take(maxGalleryPhotos - _galleryCount));
      _dirty = true;
    });
  }

  Future<void> _removeSaved(GalleryImage g) async {
    final l = AppLocalizations.of(context);
    final yes = await showAtomConfirm(
      context,
      title: l.catRemovePhotoTitle,
      body: l.catRemovePhotoBody,
      confirmLabel: l.catRemove,
      destructive: true,
    );
    if (!yes || !mounted) return;
    final r = await ref
        .read(catalogueRepositoryProvider)
        .deleteGalleryImage(_d!.row.id, g.id);
    if (!mounted) return;
    switch (r) {
      case ApiOk():
        setState(() => _gallery.remove(g));
        ref.invalidate(productDetailProvider(_d!.row.id));
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: l.catPhotoRemoved,
        );
      case ApiErr(:final failure):
        showAtomToast(
          context,
          kind: AtomToastKind.bad,
          message: sayFailure(AppLocalizations.of(context), failure),
        );
    }
  }

  // ── Details and variants ────────────────────────────────────────────────

  void _setCategory(int id) {
    if (id == _categoryId) return;
    final before = pricedVariantFor(_categoryId, _o);
    setState(() {
      _categoryId = id;
      _dirty = true;
      if (pricedVariantFor(id, _o) != before) {
        for (final r in _priced) {
          r.price.dispose();
        }
        _priced.clear();
      }
    });
  }

  Future<void> _pickVariant(_PricedRow row, PricedVariant kind) async {
    final l = AppLocalizations.of(context);
    final used = usedVariantIds([
      for (final r in _priced) r.draft,
    ], except: row.draft);
    final list = kind == PricedVariant.storage ? _o.memories : _o.sizes;
    final id = await showAtomSelect<int>(
      context,
      title: kind == PricedVariant.storage ? l.catStorage : l.catSize,
      selected: row.draft.id,
      options: [
        for (final o in list)
          if (!used.contains(o.id)) AtomOption(value: o.id, label: o.title),
      ],
    );
    if (id == null || !mounted) return;
    setState(() {
      row.draft.id = id;
      _dirty = true;
    });
  }

  void _addPriced() => setState(() {
    // A new row starts at the cash price, the usual base.
    final base = parseRupees(_price.text);
    _priced.add(_PricedRow(VariantDraft(price: _priced.isEmpty ? base : 0)));
    _dirty = true;
  });

  void _removePriced(_PricedRow row) => setState(() {
    _priced.remove(row);
    row.price.dispose();
    _dirty = true;
  });

  // ── Saving ──────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final draft = _draft;
    if (productGaps(draft, _o).isNotEmpty) return;
    if (_mode == FormMode.live) {
      final yes = await showAtomConfirm(
        context,
        title: l.catSendLiveTitle,
        body: l.catSendLiveBody,
        confirmLabel: l.catSend,
      );
      if (!yes || !mounted) return;
    }
    setState(() {
      _saving = true;
      _errors = const {};
    });
    final fields = productFields(
      draft,
      _o,
      sendAtompay:
          !_atompayBrandWide && (_d == null || _atompay != _d!.row.atompay),
    );
    final r = await ref
        .read(catalogueRepositoryProvider)
        .save(
          id: _d?.row.id,
          fields: fields,
          picture: _picture,
          gallery: _newGallery,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (r) {
      case ApiOk():
        invalidateCatalogue(ref);
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: goesForReview(_mode)
              ? l.catSentForReview
              : l.catChangesSaved,
        );
        setState(() => _dirty = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.pop();
        });
      case ApiErr(:final failure):
        if (failure.kind == ApiFailureKind.validation &&
            failure.fieldErrors.isNotEmpty) {
          setState(() => _errors = failure.fieldErrors);
          _jump(_firstErrorSection(failure.fieldErrors.keys));
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

  _Section _firstErrorSection(Iterable<String> keys) {
    _Section of(String k) {
      if (k.startsWith('picture') || k.startsWith('gallery')) {
        return _Section.photos;
      }
      if (k.startsWith('price') || k.startsWith('min_advance')) {
        return _Section.price;
      }
      if (k.startsWith('colors') ||
          k.startsWith('memories') ||
          k.startsWith('sizes')) {
        return _Section.variants;
      }
      if (k == 'short' || k == 'long') return _Section.description;
      return _Section.details;
    }

    final sections = keys.map(of).toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    return sections.first;
  }

  String? _err(String key) {
    for (final e in _errors.entries) {
      if (e.key == key || e.key.startsWith('$key.')) return e.value;
    }
    return null;
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final draft = _draft;
    final gaps = productGaps(draft, _o);
    final row = _d?.row;
    final brandName = ref.watch(sessionProvider.notifier).current?.brandName;
    final sections = [
      _Section.photos,
      _Section.details,
      _Section.price,
      if (_hasVariants) _Section.variants,
      _Section.description,
    ];

    final (String statusLabel, AtomTone statusColour) = row == null
        ? (l.catNotSentYet, AtomTone.grey)
        : (row.statusLabel(l), statusTone(row.status));

    return AtomUnsavedGuard(
      dirty: _dirty && !_readOnly,
      child: Scaffold(
        backgroundColor: AtomColors.surface,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: AtomColors.paper,
                border: Border(bottom: BorderSide(color: AtomColors.line)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AtomFlowBar(
                    leading: AtomFlowLeading.close,
                    title: row == null ? l.catAddProduct : l.catEditTitle,
                    subtitle: row == null
                        ? (brandName == null || brandName.isEmpty
                              ? l.catNewProduct
                              : l.catNewSubtitle(brandName))
                        : [?row.prNumber, row.title].join(' · '),
                    oneLine: true,
                    trailing: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12, left: 8),
                        child: StatusPill(
                          label: statusLabel,
                          tone: statusColour,
                        ),
                      ),
                    ],
                  ),
                  _JumpBar(
                    sections: sections,
                    done: (s) => _done(s, draft),
                    onTap: _jump,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AtomSize.formMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ?_modeNote(row),
                        for (final (i, s) in sections.indexed) ...[
                          const SizedBox(height: 12),
                          KeyedSubtree(
                            key: _keys[s],
                            child: _section(s, i + 1, draft),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!_readOnly)
              FormBottomBar(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AtomSize.formMaxWidth,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (missingLine(gaps, l) case final reason?)
                          AtomButtonReason(reason: reason),
                        AtomButton(
                          label: ctaLabel(_mode, l),
                          saving: _saving,
                          onPressed: gaps.isEmpty ? _save : null,
                        ),
                        if (goesForReview(_mode)) ...[
                          const SizedBox(height: 6),
                          Tiny(l.catReviewedBy, center: true),
                        ],
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

  Widget? _modeNote(ProductRow? row) {
    final l = AppLocalizations.of(context);
    if (!widget.canEdit && row != null) {
      return AtomNote(kind: AtomNoteKind.info, message: l.catNoteReadOnly);
    }
    return switch (_mode) {
      FormMode.add => AtomNote(kind: AtomNoteKind.info, message: l.catNoteNew),
      FormMode.live => AtomNote(
        kind: AtomNoteKind.info,
        message: l.catNoteLive,
      ),
      FormMode.hold => AtomNote(
        kind: AtomNoteKind.problem,
        message: l.catNoteHold(row?.holdWhy ?? l.catOnHoldManyBody),
        bold: [l.catNoteHoldLead],
      ),
      FormMode.review => AtomNote(
        kind: AtomNoteKind.info,
        message: l.catNoteReview,
      ),
      FormMode.outOfStock => AtomNote(
        kind: AtomNoteKind.warning,
        message: l.catNoteOutOfStock,
      ),
      FormMode.closed => AtomNote(
        kind: AtomNoteKind.problem,
        message: l.catNoteClosed,
      ),
    };
  }

  Widget _section(_Section s, int n, ProductDraft draft) => switch (s) {
    _Section.photos => FormCard(
      title: l.catSectionPhotos,
      number: n,
      done: _done(s, draft),
      children: [_featureImage(), _galleryGrid()],
    ),
    _Section.details => FormCard(
      title: l.catSectionDetails,
      number: n,
      done: _done(s, draft),
      children: _details(),
    ),
    _Section.price => FormCard(
      title: l.catSectionPrice,
      number: n,
      done: _done(s, draft),
      children: _priceFields(draft),
    ),
    _Section.variants => FormCard(
      title: l.catSectionVariants,
      number: n,
      done: _done(s, draft),
      trailing: Text(
        l.catOptionalTag,
        style: AtomText.small.copyWith(
          fontWeight: FontWeight.w600,
          color: AtomColors.faint,
        ),
      ),
      children: _variants(),
    ),
    _Section.description => FormCard(
      title: l.catSectionDescription,
      number: n,
      done: _done(s, draft),
      children: _description(),
    ),
  };

  Widget _featureImage() {
    final l = AppLocalizations.of(context);
    final url = _d?.row.picture;
    final held = _mode == FormMode.hold && _picture == null;
    final Widget image = _picture != null
        ? Image.file(_picture!, fit: BoxFit.contain)
        : url != null && url.isNotEmpty
        ? AtomPhoto(url, fit: BoxFit.contain)
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.imagePlus,
                size: 32,
                color: AtomColors.purpleInk,
              ),
              const SizedBox(height: 6),
              Text(
                l.catFeatureImageMissing,
                style: AtomText.small.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AtomColors.purpleInk,
                ),
              ),
            ],
          );
    final error = _err('picture');
    return AtomField(
      label: l.catFeatureImage,
      labelNote: l.catFeatureImageNote,
      labelNoteInline: true,
      error: error,
      child: Container(
        height: 180,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: held
              ? AtomColors.roseSoft
              : _hasPicture
              ? AtomColors.paper
              : AtomColors.purpleSoft,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(
            color: held || error != null
                ? AtomColors.roseLine
                : AtomColors.line,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(padding: const EdgeInsets.all(8), child: image),
            if (!_readOnly)
              Positioned(
                right: 10,
                bottom: 10,
                child: AtomButton.small(
                  label: _hasPicture ? l.catChange : l.catAddPhoto,
                  icon: LucideIcons.camera,
                  onPressed: _pickFeature,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _galleryGrid() {
    final l = AppLocalizations.of(context);
    final error = _err('gallery_images');
    final canAdd = !_readOnly && _galleryCount < maxGalleryPhotos;
    final tiles = <Widget>[
      for (final (i, g) in _gallery.indexed)
        _GalleryTile(
          label: l.catPhotoN(i + 2),
          removeLabel: l.catRemovePhotoN(i + 2),
          image: AtomPhoto(g.url, fit: BoxFit.cover),
          onRemove: _readOnly ? null : () => _removeSaved(g),
        ),
      for (final (i, f) in _newGallery.indexed)
        _GalleryTile(
          label: l.catPhotoN(_gallery.length + i + 2),
          removeLabel: l.catRemovePhotoN(_gallery.length + i + 2),
          image: Image.file(f, fit: BoxFit.cover),
          onRemove: () => setState(() => _newGallery.remove(f)),
        ),
      if (canAdd) _AddTile(onTap: _addGallery),
    ];
    return AtomField(
      label: l.catMorePhotos,
      labelNote: l.catPhotosOf(_galleryCount, maxGalleryPhotos),
      labelNoteInline: true,
      error: error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tiles.isNotEmpty)
            LayoutBuilder(
              builder: (context, box) {
                // Whole pixels, so four always fit on a row.
                final side = ((box.maxWidth - 3 * 8) / 4).floorToDouble();
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in tiles)
                      SizedBox(width: side, height: side, child: t),
                  ],
                );
              },
            ),
          const SizedBox(height: 8),
          Tiny(l.catPhotosTip),
        ],
      ),
    );
  }

  List<Widget> _details() {
    final l = AppLocalizations.of(context);
    final brands = _o.brands;
    final brandLabel = _o.nameOf(brands, _brandId);
    return [
      AtomTextField(
        label: l.catTitleLabel,
        controller: _title,
        enabled: !_readOnly,
        hint: l.catTitleHint,
        error: _err('title'),
        textInputAction: TextInputAction.next,
        inputFormatters: [LengthLimitingTextInputFormatter(255)],
      ),
      AtomSelectField<int>(
        label: l.catCategory,
        value: _categoryId,
        valueLabel: _o.nameOf(_o.categories, _categoryId),
        placeholder: l.commonChoose,
        sheetTitle: l.catCategory,
        searchHint: l.catCategorySearch,
        error: _err('category_id'),
        options: [
          for (final c in _o.categories)
            AtomOption(value: c.id, label: c.title),
        ],
        onChanged: _readOnly ? null : _setCategory,
      ),
      AtomSelectField<int>(
        label: l.catBrand,
        value: _brandId,
        valueLabel: brandLabel,
        placeholder: l.commonChoose,
        sheetTitle: l.catBrand,
        searchHint: l.catBrandSearch,
        mineLabel: l.catBrandsInCategory,
        othersLabel: l.catOtherBrands,
        error: _err('brand_id'),
        options: [
          for (final b in brands)
            AtomOption(
              value: b.id,
              label: b.title,
              mine: _categoryId != null && b.categoryIds.contains(_categoryId),
            ),
        ],
        // One brand to choose from: shown, not changeable (the board's
        // greyed Brand).
        onChanged: _readOnly || brands.length <= 1
            ? null
            : (id) => setState(() {
                _brandId = id;
                _dirty = true;
              }),
      ),
      AtomTextField(
        label: l.catDetailHeading,
        labelNote: l.catOptional,
        labelNoteInline: true,
        controller: _detailTitle,
        enabled: !_readOnly,
        placeholder: l.catDetailHeadingHint,
        error: _err('detail_page_title'),
        inputFormatters: [LengthLimitingTextInputFormatter(500)],
      ),
    ];
  }

  List<Widget> _priceFields(ProductDraft draft) {
    final l = AppLocalizations.of(context);
    final tooHigh =
        draft.minAdvance != null &&
        draft.price > 0 &&
        draft.minAdvance! > draft.price;
    final on = _atompay || _atompayBrandWide;
    final price = AtomTextField(
      label: l.catCashPrice,
      controller: _price,
      enabled: !_readOnly,
      prefix: const Text('Rs'),
      keyboardType: TextInputType.number,
      inputFormatters: const [RupeesInputFormatter()],
      error: _err('price'),
      textInputAction: TextInputAction.next,
    );
    final advance = AtomTextField(
      label: l.catMinAdvance,
      controller: _advance,
      enabled: !_readOnly,
      prefix: const Text('Rs'),
      keyboardType: TextInputType.number,
      inputFormatters: const [RupeesInputFormatter()],
      error: tooHigh ? l.catAdvanceTooHigh : _err('min_advance_price'),
    );
    final stacked = MediaQuery.textScalerOf(context).scale(10) > 13;
    return [
      if (stacked) ...[
        price,
        advance,
      ] else
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: price),
            const SizedBox(width: 10),
            Expanded(child: advance),
          ],
        ),
      if (!tooHigh) Text(l.catAdvanceHint, style: AtomText.small),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: on ? AtomColors.unreadRow : AtomColors.head,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(
            color: on ? AtomColors.primaryLine : AtomColors.line,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AtomIconTile(
              icon: LucideIcons.creditCard,
              tone: AtomTone.blue,
              size: 36,
            ),
            const SizedBox(width: AtomSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.catSellWithAtompay,
                    style: AtomText.listTitle.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _atompayBrandWide
                        ? l.catAtompayBrandWideNote
                        : l.catSellWithAtompayBody,
                    style: AtomText.secondary,
                  ),
                  if (on && draft.price > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      l.catCustomerPays(formatRs(atompayMonthly(draft.price))),
                      style: AtomText.secondary.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AtomColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AtomSpace.s2),
            AtomSwitch(
              value: on,
              semanticLabel: l.catAtompay,
              onChanged: _readOnly || _atompayBrandWide
                  ? null
                  : (v) => setState(() {
                      _atompay = v;
                      _dirty = true;
                    }),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _variants() {
    final l = AppLocalizations.of(context);
    final priced = pricedVariantFor(_categoryId, _o);
    final colours = coloursFor(_categoryId, _o);
    final pricedError =
        _err('memories') ?? _err('sizes') ?? _err('memories.name');
    return [
      if (colours) _colourPicker(),
      if (priced != PricedVariant.none)
        AtomField(
          label: priced == PricedVariant.storage
              ? l.catStorageLabel
              : l.catSizesLabel,
          error: pricedError,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final r in _priced) ...[
                _pricedRow(r, priced),
                const SizedBox(height: 8),
              ],
              if (!_readOnly && _priced.length < _optionsFor(priced).length)
                Align(
                  alignment: Alignment.centerLeft,
                  child: AtomButton.small(
                    label: priced == PricedVariant.storage
                        ? l.catAddStorage
                        : l.catAddSize,
                    icon: LucideIcons.plus,
                    onPressed: _addPriced,
                  ),
                ),
              const SizedBox(height: 8),
              Tiny(l.catVariantsTip),
            ],
          ),
        ),
    ];
  }

  List<NamedOption> _optionsFor(PricedVariant k) =>
      k == PricedVariant.storage ? _o.memories : _o.sizes;

  Widget _colourPicker() {
    final l = AppLocalizations.of(context);
    final all = _o.colors;
    final picked = [
      for (final c in all)
        if (_colors.contains(c.id)) c,
    ];
    void toggle(int id) => setState(() {
      _colors.contains(id) ? _colors.remove(id) : _colors.add(id);
      _dirty = true;
    });
    // A short list as the board's swatches; a long one through the
    // searchable dropdown, with the picked ones as swatches under it.
    final swatches = all.length <= 12;
    return AtomField(
      label: l.catColours,
      labelNote: l.catColoursPicked(_colors.length),
      labelNoteInline: true,
      error: _err('colors'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!swatches && !_readOnly) ...[
            AtomMultiSelectField<int>(
              label: l.catChooseColours,
              values: {..._colors},
              summary: picked.isEmpty
                  ? null
                  : picked.map((c) => c.title).join(', '),
              placeholder: l.commonChoose,
              sheetTitle: l.catColours,
              searchHint: l.catSearchColours,
              options: [
                for (final c in all) AtomOption(value: c.id, label: c.title),
              ],
              onChanged: (v) => setState(() {
                _colors
                  ..clear()
                  ..addAll(v);
                _dirty = true;
              }),
            ),
            if (picked.isNotEmpty) const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in swatches ? all : picked)
                _Swatch(
                  name: c.title,
                  on: _colors.contains(c.id),
                  onTap: _readOnly ? null : () => toggle(c.id),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pricedRow(_PricedRow r, PricedVariant kind) {
    final l = AppLocalizations.of(context);
    final name = _o.nameOf(_optionsFor(kind), r.draft.id);
    final label = kind == PricedVariant.storage ? l.catStorage : l.catSize;
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: AtomSelectBox(
            text: name,
            placeholder: label,
            semanticLabel: label,
            onTap: _readOnly ? null : () => _pickVariant(r, kind),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RupeeBox(
            controller: r.price,
            enabled: !_readOnly,
            semanticLabel: l.catPriceForThis,
            onChanged: (v) => setState(() {
              r.draft.price = parseRupees(v);
              _dirty = true;
            }),
          ),
        ),
        if (!_readOnly) ...[
          const SizedBox(width: 8),
          AtomIconButton(
            icon: LucideIcons.x,
            label: l.catRemoveVariant(name ?? label),
            color: AtomColors.muted,
            onTap: () => _removePriced(r),
          ),
        ],
      ],
    );
  }

  List<Widget> _description() {
    final l = AppLocalizations.of(context);
    final n = _short.text.trim().length;
    final tooLong = n > maxShortChars;
    return [
      AtomTextField(
        label: l.catShortDescription,
        controller: _short,
        enabled: !_readOnly,
        minLines: 3,
        keyboardType: TextInputType.multiline,
        error: tooLong ? l.catShortTooLong : _err('short'),
        hint: l.catShortCount(n, maxShortChars),
      ),
      AtomTextField(
        label: l.catFullDescription,
        labelNote: l.catOptional,
        labelNoteInline: true,
        controller: _long,
        enabled: !_readOnly,
        minLines: 5,
        keyboardType: TextInputType.multiline,
        hint: l.catFullHint,
        error: _err('long'),
      ),
    ];
  }
}

/// The section jump bar (`.jump`): one chip per section, green with a tick
/// when it is complete; tapping scrolls to it.
class _JumpBar extends StatelessWidget {
  const _JumpBar({
    required this.sections,
    required this.done,
    required this.onTap,
  });

  final List<_Section> sections;
  final bool Function(_Section) done;
  final ValueChanged<_Section> onTap;

  static String _label(_Section s, AppLocalizations l) => switch (s) {
    _Section.photos => l.catJumpPhotos,
    _Section.details => l.catJumpDetails,
    _Section.price => l.catJumpPrice,
    _Section.variants => l.catJumpVariants,
    _Section.description => l.catJumpDescription,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      label: l.catSections,
      container: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: [
            for (final (i, s) in sections.indexed) ...[
              if (i > 0) const SizedBox(width: 6),
              _chip(s, done(s), l),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(_Section s, bool ok, AppLocalizations l) => AtomPressable(
    onTap: () => onTap(s),
    semanticLabel: _label(s, l),
    focusRadius: AtomRadius.brPill,
    builder: (context, pressed) => Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: ok
            ? AtomColors.greenSoft
            : pressed
            ? AtomColors.head
            : AtomColors.paper,
        borderRadius: AtomRadius.brPill,
        border: Border.all(color: ok ? AtomColors.greenLine : AtomColors.line2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ok) ...[
            const Icon(LucideIcons.check, size: 14, color: AtomColors.green),
            const SizedBox(width: 5),
          ],
          Text(
            _label(s, l),
            style: AtomText.small.copyWith(
              fontWeight: FontWeight.w600,
              color: ok ? AtomColors.green : AtomColors.text,
            ),
          ),
        ],
      ),
    ),
  );
}

/// A gallery photo with its X.
class _GalleryTile extends StatelessWidget {
  const _GalleryTile({
    required this.label,
    required this.removeLabel,
    required this.image,
    required this.onRemove,
  });

  final String label;
  final String removeLabel;
  final Widget image;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Semantics(
            label: label,
            image: true,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AtomColors.surface,
                borderRadius: AtomRadius.brControl,
                border: Border.all(color: AtomColors.line),
              ),
              child: image,
            ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: -6,
            right: -6,
            child: AtomPressable(
              onTap: onRemove,
              semanticLabel: removeLabel,
              focusRadius: AtomRadius.brPill,
              builder: (context, pressed) => Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AtomColors.ink,
                  shape: BoxShape.circle,
                  border: Border.all(color: AtomColors.paper, width: 2),
                ),
                child: const Icon(
                  LucideIcons.x,
                  size: 12,
                  color: AtomColors.paper,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The dashed Add tile at the end of the gallery.
class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AtomPressable(
      onTap: onTap,
      semanticLabel: '${l.catAdd} ${l.catMorePhotos.toLowerCase()}',
      builder: (context, pressed) => Container(
        decoration: BoxDecoration(
          color: pressed ? AtomColors.head : AtomColors.paper,
          borderRadius: AtomRadius.brControl,
          border: Border.all(color: AtomColors.line2, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.plus, size: 18, color: AtomColors.primary),
            const SizedBox(height: 2),
            Text(
              l.catAdd,
              style: AtomText.small.copyWith(
                fontWeight: FontWeight.w600,
                color: AtomColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A colour chip (`.swatch`): a dot in the colour and its name.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.on, required this.onTap});

  final String name;
  final bool on;
  final VoidCallback? onTap;

  /// The dot for the colour names the catalogue uses; grey otherwise.
  static Color dotFor(String name) {
    final n = name.toLowerCase();
    const known = <String, Color>{
      'black': Color(0xFF101828),
      'white': Color(0xFFFFFFFF),
      'silver': Color(0xFFC9CED6),
      'grey': Color(0xFF8A919E),
      'gray': Color(0xFF8A919E),
      'graphite': Color(0xFF4A5160),
      'blue': Color(0xFF2747C7),
      'navy': Color(0xFF0F1B35),
      'red': Color(0xFFC0323F),
      'green': Color(0xFF0F7552),
      'gold': Color(0xFFD4A84B),
      'golden': Color(0xFFD4A84B),
      'pink': Color(0xFFF2A7C3),
      'purple': Color(0xFF6941C6),
      'yellow': Color(0xFFF7C948),
      'orange': Color(0xFFF08A24),
      'brown': Color(0xFF7A4E2D),
      'beige': Color(0xFFE6D5B8),
    };
    for (final e in known.entries) {
      if (n.contains(e.key)) return e.value;
    }
    return const Color(0xFFD0D5DD);
  }

  @override
  Widget build(BuildContext context) => AtomPressable(
    onTap: onTap,
    toggled: on,
    semanticLabel: name,
    focusRadius: AtomRadius.brPill,
    builder: (context, pressed) => Container(
      height: 40,
      padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
      decoration: BoxDecoration(
        color: on
            ? AtomColors.unreadRow
            : pressed
            ? AtomColors.head
            : AtomColors.paper,
        borderRadius: AtomRadius.brPill,
        border: Border.all(
          color: on ? AtomColors.primary : AtomColors.line2,
          width: on ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: dotFor(name),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x26101828)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: AtomText.smallButton.copyWith(
              color: on ? AtomColors.primary : AtomColors.text,
            ),
          ),
        ],
      ),
    ),
  );
}

/// A rupee amount box without a label (a variant's price): "Rs" then the
/// digits with commas.
class _RupeeBox extends StatefulWidget {
  const _RupeeBox({
    required this.controller,
    required this.onChanged,
    required this.semanticLabel,
    this.enabled = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String semanticLabel;
  final bool enabled;

  @override
  State<_RupeeBox> createState() => _RupeeBoxState();
}

class _RupeeBoxState extends State<_RupeeBox> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 46),
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: atomInputBox(
      focused: _focus.hasFocus,
      error: false,
      disabled: !widget.enabled,
    ),
    child: Row(
      children: [
        Text('Rs', style: AtomText.listTitle.copyWith(color: AtomColors.muted)),
        const SizedBox(width: 6),
        Expanded(
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            inputFormatters: const [RupeesInputFormatter()],
            onChanged: widget.onChanged,
            style: AtomText.input.copyWith(fontSize: 15),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              filled: false,
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              semanticCounterText: '',
              hintText: widget.semanticLabel,
              hintStyle: AtomText.input.copyWith(
                fontSize: 13,
                color: AtomColors.placeholder,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
