import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_icons.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/images.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/models/product.dart';
import '../../data/repositories/catalogue_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import 'inventory_logic.dart' show plural;
import 'product_detail_logic.dart';
import 'product_detail_screen.dart';
import 'product_form_logic.dart';

/// Add (id == null) or edit a product (DESIGN.md §4.10): one scrolling page
/// in four sections (Photos, Basics, Price & stock, Description), a bar that
/// says what's still missing, and a "Sent for review" screen after adding.
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.id});

  final int? id;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

/// The edit form's starting values, to count what changed.
class _Snapshot {
  _Snapshot(this.values);
  final Map<String, Object?> values;
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _title = TextEditingController();
  final _pageTitle = TextEditingController();
  final _price = TextEditingController();
  final _advance = TextEditingController();

  final _photosKey = GlobalKey();
  final _basicsKey = GlobalKey();
  final _priceKey = GlobalKey();
  final _descKey = GlobalKey();

  ProductFormOptions? _options;
  ProductDetail? _existing;
  String? _loadError;

  int? _categoryId;
  int? _brandId;
  PickedImage? _picture;
  final List<PickedImage> _newGallery = [];
  List<GalleryImage> _gallery = [];
  final Set<int> _removedGallery = {};
  List<String> _features = [];
  String _longHtml = '';
  List<DescPart> _initialParts = [];
  int _editorKey = 0;
  final Set<int> _colors = {};
  final Map<int, TextEditingController> _memories = {};
  final Map<int, TextEditingController> _sizes = {};
  _Snapshot? _start;

  bool _saving = false;
  bool _showErrors = false;
  bool _infoDismissed = false;
  ApiException? _error;
  ProductDetail? _created;

  bool get _isEdit => widget.id != null;
  CatalogueRepository get _repo => ref.read(catalogueRepositoryProvider);

  @override
  void initState() {
    super.initState();
    for (final c in [_title, _pageTitle, _price, _advance]) {
      c.addListener(_refresh);
    }
    _load();
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final c in [_title, _pageTitle, _price, _advance, ..._memories.values, ..._sizes.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final options = await ref.read(productFormOptionsProvider.future);
      ProductDetail? p;
      if (_isEdit) p = await _repo.product(widget.id!);
      if (!mounted) return;
      setState(() {
        _options = options;
        _existing = p;
        if (p != null) {
          final s = p.summary;
          _title.text = s.title;
          _pageTitle.text = p.detailPageTitle ?? '';
          _price.text = _thousands(s.price);
          _advance.text = _thousands(s.minAdvancePrice);
          _features = keyFeatures(p.short);
          _initialParts = htmlToParts(p.long);
          _longHtml = partsToHtml(_initialParts);
          _categoryId = p.categoryId ?? s.category?.id;
          _brandId = p.brandId ?? s.displayBrand?.id;
          _gallery = List.of(p.gallery);
          _colors.addAll(p.colors);
          for (final m in p.memories) {
            _memories[m.id] = TextEditingController(text: '${m.price}')..addListener(_refresh);
          }
          for (final z in p.sizes) {
            _sizes[z.id] = TextEditingController(text: '${z.price}')..addListener(_refresh);
          }
          _start = _snapshot();
        } else {
          _resetNew(options);
        }
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    }
  }

  /// A blank Add form; own brand prefilled (it comes first in the list).
  void _resetNew(ProductFormOptions options) {
    for (final c in [_title, _pageTitle, _price, _advance]) {
      c.text = '';
    }
    _categoryId = null;
    final ownId = ref.read(signedInProvider)?.brand.id;
    _brandId = options.brands.any((b) => b.id == ownId) ? ownId : options.brands.firstOrNull?.id;
    _picture = null;
    _newGallery.clear();
    _features = [];
    _initialParts = [];
    _longHtml = '';
    _editorKey++;
    _colors.clear();
    for (final c in [..._memories.values, ..._sizes.values]) {
      c.dispose();
    }
    _memories.clear();
    _sizes.clear();
    _showErrors = false;
    _error = null;
  }

  Map<String, Object?> _values() => {
        'title': _title.text.trim(),
        'detail': _pageTitle.text.trim(),
        'category': _categoryId,
        'brand': _brandId,
        'price': parseRupees(_price.text),
        'advance': parseRupees(_advance.text),
        'features': featuresToShort(_features),
        'long': _longHtml,
        'variants': [
          (_colors.toList()..sort()).join(','),
          _prices(_memories).toString(),
          _prices(_sizes).toString(),
        ].join('|'),
      };

  _Snapshot _snapshot() => _Snapshot(_values());

  /// Changed fields, counting a new main photo and gallery edits as one each.
  int get _changeCount {
    final start = _start;
    if (start == null) return 0;
    final now = _values();
    var n = now.entries.where((e) => start.values[e.key] != e.value).length;
    if (_picture != null) n++;
    if (_newGallery.isNotEmpty || _removedGallery.isNotEmpty) n++;
    return n;
  }

  bool get _dirty => _isEdit
      ? _changeCount > 0
      : _picture != null || _title.text.isNotEmpty || _price.text.isNotEmpty || _features.isNotEmpty || _newGallery.isNotEmpty;

  bool get _hasMainPhoto => _picture != null || (_existing?.summary.picture != null);

  List<FormGap> get _gaps => formGaps(
        hasMainPhoto: _hasMainPhoto,
        title: _title.text,
        categoryId: _categoryId,
        brandId: _brandId,
        price: parseRupees(_price.text),
        advance: parseRupees(_advance.text),
        features: _features,
      );

  ({bool photos, bool basics, bool price, bool desc}) get _sections {
    final g = _gaps.toSet();
    return (
      photos: !g.contains(FormGap.mainPhoto),
      basics: !g.any({FormGap.title, FormGap.category, FormGap.brand}.contains),
      price: !g.any({FormGap.price, FormGap.advance, FormGap.advanceTooHigh}.contains),
      desc: !g.any({FormGap.features, FormGap.tooManyFeatures}.contains),
    );
  }

  List<FormBrand> get _brandsForCategory {
    final all = _options?.brands ?? const <FormBrand>[];
    if (_categoryId == null) return all;
    final filtered = all.where((b) => b.categoryIds.isEmpty || b.categoryIds.contains(_categoryId)).toList();
    return filtered.isEmpty ? all : filtered;
  }

  bool _gated(List<int> categories) => _categoryId != null && categories.contains(_categoryId);

  int get _galleryMax => ref.read(configProvider).value?.galleryMax ?? 8;
  int get _galleryCount => _gallery.where((g) => !_removedGallery.contains(g.id)).length + _newGallery.length;

  Future<void> _pickMain(ImageSource source) async {
    try {
      final img = await pickImage(source: source);
      if (img != null && mounted) setState(() => _picture = img);
    } on ImageTooLarge catch (e) {
      if (mounted) showToast(context, '${e.message} That one is ${e.size}.');
    } catch (_) {
      if (mounted) showToast(context, "Couldn't use that photo. Try another one.");
    }
  }

  Future<void> _pickGallery() async {
    final room = _galleryMax - _galleryCount;
    if (room <= 0) {
      showToast(context, 'Up to $_galleryMax extra photos.');
      return;
    }
    try {
      final imgs = await pickImages(limit: room);
      if (mounted) setState(() => _newGallery.addAll(imgs.take(room)));
    } catch (_) {
      if (mounted) showToast(context, "Couldn't use those photos.");
    }
  }

  Map<int, int> _prices(Map<int, TextEditingController> m) =>
      {for (final e in m.entries) e.key: int.tryParse(e.value.text.trim()) ?? 0};

  void _scrollToFirstError() {
    final g = _gaps.toSet();
    final key = g.contains(FormGap.mainPhoto)
        ? _photosKey
        : g.any({FormGap.title, FormGap.category, FormGap.brand}.contains)
            ? _basicsKey
            : g.any({FormGap.price, FormGap.advance, FormGap.advanceTooHigh}.contains)
                ? _priceKey
                : _descKey;
    final ctx = key.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), alignment: 0.02);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final opts = _options!;
    final variantsOk = [_memories, _sizes].every((m) => m.values.every((c) => (int.tryParse(c.text.trim()) ?? 0) > 0));
    if (_gaps.isNotEmpty || !variantsOk) {
      setState(() => _showErrors = true);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFirstError());
      if (!variantsOk) showToast(context, 'Add a price for every option you picked.');
      return;
    }

    final input = ProductInput(
      title: _title.text.trim(),
      detailPageTitle: _pageTitle.text.trim(),
      categoryId: _categoryId!,
      brandId: _brandId!,
      price: parseRupees(_price.text)!,
      minAdvancePrice: parseRupees(_advance.text)!,
      short: featuresToShort(_features),
      long: _longHtml,
      picture: _picture,
      gallery: _newGallery,
      // Variants for other categories are ignored server-side; don't send them.
      colors: _gated(opts.colorCategories) ? _colors.toList() : const [],
      memories: _gated(opts.memoryCategories) ? _prices(_memories) : const {},
      sizes: _gated(opts.sizeCategories) ? _prices(_sizes) : const {},
    );

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_isEdit) {
        final wasLive = _existing?.summary.isLive ?? false;
        await _repo.update(widget.id!, input);
        for (final id in _removedGallery) {
          await _repo.deleteGalleryImage(widget.id!, id);
        }
        if (!mounted) return;
        showToast(context, wasLive ? 'Saved and sent for review.' : 'Changes saved.');
        context.pop(true);
      } else {
        final created = await _repo.create(input);
        if (mounted) setState(() => _created = created);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _showErrors = true;
      });
      if (e.fieldErrors.isEmpty) {
        showApiError(context, e);
      } else {
        showToast(context, 'Please fix the fields marked in red.');
      }
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
        content: Text(_isEdit
            ? 'You have $n unsaved ${n == 1 ? 'change' : 'changes'}. If you leave now, they\'ll be lost.'
            : "This product hasn't been submitted. If you leave now, what you've entered will be lost."),
        actionsOverflowDirection: VerticalDirection.up,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Discard', style: TextStyle(color: AppPalette.of(ctx).danger))),
          FilledButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep editing')),
        ],
      ),
    );
    return ok ?? false;
  }

  String? _serverError(String field) => _error?.fieldError(field);

  @override
  Widget build(BuildContext context) {
    final created = _created;
    if (created != null) {
      return _SubmittedView(
        product: created,
        onView: () {
          final router = GoRouter.of(context);
          router.pop(true);
          router.push('/products/${created.summary.id}');
        },
        onAddAnother: () => setState(() {
          _created = null;
          _resetNew(_options!);
        }),
        onClose: () => context.pop(true),
      );
    }

    final ready = _options != null && (!_isEdit || _existing != null);
    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) context.pop(false);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'Edit product' : 'Add product')),
        body: !ready
            ? (_loadError != null ? ErrorView(message: _loadError!, onRetry: _load) : const Center(child: CircularProgressIndicator()))
            : Column(
                children: [
                  if (!_isEdit) _ProgressStrip(_sections),
                  Expanded(child: _buildForm()),
                  _bottomBar(),
                ],
              ),
      ),
    );
  }

  Widget _bottomBar() {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final gaps = _gaps;
    final changes = _changeCount;
    final (String line, Color color, IconData? icon) = _isEdit
        ? changes == 0
            ? ('No changes yet', pal.muted, null)
            : gaps.isNotEmpty
                ? (missingLine(gaps, verb: 'save'), pal.danger, AppIcons.error)
                : (
                    _existing!.summary.isLive
                        ? '${plural(changes, 'change')} · sends it for review again'
                        : plural(changes, 'change'),
                    pal.positive.fg,
                    AppIcons.check,
                  )
        : gaps.isNotEmpty
            ? (missingLine(gaps), _showErrors ? pal.danger : pal.muted, _showErrors ? AppIcons.error : null)
            : ('Ready · AtomShop reviews it in 1–2 days', pal.positive.fg, AppIcons.check);
    final label = _isEdit ? (changes > 0 ? 'Save changes ($changes)' : 'Save changes') : 'Submit for review';
    // Add: the button looks disabled until complete but still explains what's
    // missing when tapped. Edit: really disabled until something changed.
    final looksDisabled = _isEdit ? changes == 0 : gaps.isNotEmpty;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: pal.card,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: pal.isDark ? 0.4 : 0.08), blurRadius: 20, offset: const Offset(0, -6))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    if (icon != null) ...[Icon(icon, size: 16, color: color), const SizedBox(width: 6)],
                    Expanded(
                      child: Text(line, style: t.bodySmall?.copyWith(fontSize: 13, color: color, fontWeight: icon == null ? FontWeight.w400 : FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _saving || (_isEdit && changes == 0) ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: looksDisabled && !_isEdit ? pal.primary.withValues(alpha: 0.45) : null,
                ),
                child: _saving
                    ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: pal.onPrimary))
                    : Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final opts = _options!;
    final status = _existing?.summary.status;
    final s = _sections;
    final gaps = _showErrors ? _gaps.toSet() : <FormGap>{};
    final brands = _brandsForCategory;
    final price = parseRupees(_price.text);
    final category = opts.categories.where((c) => c.id == _categoryId).firstOrNull;
    final brand = brands.where((b) => b.id == _brandId).firstOrNull;
    final hasOptions = (_gated(opts.colorCategories) && opts.colors.isNotEmpty) ||
        (_gated(opts.memoryCategories) && opts.memories.isNotEmpty) ||
        (_gated(opts.sizeCategories) && opts.sizes.isNotEmpty);
    String? err(FormGap g, String message) => gaps.contains(g) ? message : null;

    Widget banner;
    if (_isEdit && status == 'Published') {
      banner = _Banner(
        tone: pal.warning,
        icon: AppIcons.warning,
        text: 'This product is live. Saving changes sends it back to AtomShop for review, and it\'s hidden from buyers until approved (usually 1–2 days).',
      );
    } else if (_isEdit && status == 'Out of Stock') {
      banner = _Banner(
        tone: pal.info,
        icon: AppIcons.info,
        text: 'Saving sends this product for review again. Stock stays as it is; change it from the product page or Inventory.',
      );
    } else if (!_isEdit && _showErrors && _gaps.isNotEmpty) {
      final n = _gaps.length;
      banner = _Banner(
        tone: pal.negative,
        icon: AppIcons.error,
        text: '$n ${n == 1 ? 'thing' : 'things'} to fix before you can submit. They\'re marked in red below.',
      );
    } else if (!_isEdit && !_infoDismissed) {
      banner = _Banner(
        tone: pal.info,
        icon: AppIcons.info,
        text: 'New products are reviewed by AtomShop before going live, usually within 1–2 days.',
        onDismiss: () => setState(() => _infoDismissed = true),
      );
    } else {
      banner = const SizedBox.shrink();
    }

    final mainError = err(FormGap.mainPhoto, 'Add a main photo. Products without one can\'t be listed.') ?? _serverError('picture');
    final existingMain = _existing?.summary.picture;
    final visibleGallery = _gallery.where((g) => !_removedGallery.contains(g.id)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        banner,
        if (banner is! SizedBox) const SizedBox(height: 12),

        // 1 · Photos
        _Section(
          key: _photosKey,
          number: 1,
          title: 'Photos',
          done: s.photos,
          trailing: '${(_hasMainPhoto ? 1 : 0) + _galleryCount}/${_galleryMax + 1}',
          children: [
            _MainPhoto(
              picked: _picture,
              existingUrl: existingMain,
              error: mainError != null,
              onAdd: () => _pickMain(ImageSource.gallery),
              onReplace: () => _pickMain(ImageSource.gallery),
              onRemove: _picture != null ? () => setState(() => _picture = null) : null,
            ),
            if (mainError != null) _ErrorLine(mainError),
            if (!_hasMainPhoto)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickMain(ImageSource.gallery),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48), padding: const EdgeInsets.symmetric(horizontal: 8)),
                      icon: const Icon(AppIcons.gallery, size: 20),
                      label: const Text('Gallery'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickMain(ImageSource.camera),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48), padding: const EdgeInsets.symmetric(horizontal: 8)),
                      icon: const Icon(AppIcons.camera, size: 20),
                      label: const Text('Take photo'),
                    ),
                  ),
                ],
              )
            else ...[
              Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'More photos ', style: TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: '(optional, up to $_galleryMax)', style: TextStyle(color: pal.muted)),
                ]),
                style: t.bodySmall?.copyWith(fontSize: 13, color: pal.text),
              ),
              SizedBox(
                height: 92,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.only(top: 10, right: 4),
                  children: [
                    for (final g in visibleGallery)
                      _Thumb(
                        image: NetThumb(g.url, size: 76, radius: 12),
                        onRemove: () => setState(() => _removedGallery.add(g.id)),
                      ),
                    for (final (i, g) in _newGallery.indexed)
                      _Thumb(
                        image: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(g.bytes, width: 76, height: 76, fit: BoxFit.cover)),
                        onRemove: () => setState(() => _newGallery.removeAt(i)),
                        isNew: true,
                      ),
                    if (_galleryCount < _galleryMax) _AddThumb(onTap: _pickGallery),
                  ],
                ),
              ),
              if (_serverError('gallery_images') != null) _ErrorLine(_serverError('gallery_images')!),
            ],
            _Tip('Use a clear photo on a white background, at least 800×800 px.'),
          ],
        ),
        const SizedBox(height: 12),

        // 2 · Basics
        _Section(
          key: _basicsKey,
          number: 2,
          title: 'Basics',
          done: s.basics,
          children: [
            TextField(
              controller: _title,
              maxLength: 255,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                label: const _Label('Title', required: true),
                hintText: 'e.g. OXY 43" Smart LED TV 4318L',
                helperText: 'Brand, size and model work best',
                errorText: err(FormGap.title, 'Add a title buyers will search for') ?? _serverError('title'),
              ),
            ),
            TextField(
              controller: _pageTitle,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                label: const _Label('Detail page title', optional: true),
                helperText: 'Longer title shown on the product page',
                counterText: '',
                errorText: _serverError('detail_page_title'),
              ),
            ),
            _PickerField(
              label: const _Label('Category', required: true),
              value: category?.title,
              placeholder: 'Choose a category',
              error: err(FormGap.category, 'Choose a category') ?? _serverError('category_id'),
              onTap: () async {
                final picked = await _pickFromSheet(
                  title: 'Category',
                  items: [for (final c in opts.categories) (c.id, c.title)],
                  selected: _categoryId,
                  searchHint: 'Search categories',
                );
                if (picked == null) return;
                setState(() {
                  _categoryId = picked;
                  final allowed = _brandsForCategory;
                  if (!allowed.any((b) => b.id == _brandId)) _brandId = allowed.firstOrNull?.id;
                });
              },
            ),
            _PickerField(
              label: const _Label('Show under brand', required: true),
              value: brand?.title,
              placeholder: 'Choose a brand',
              helper: 'Usually your own brand',
              error: err(FormGap.brand, 'Choose a brand') ?? _serverError('brand_id'),
              onTap: () async {
                final picked = await _pickFromSheet(
                  title: 'Show under brand',
                  items: [for (final b in brands) (b.id, b.title)],
                  selected: _brandId,
                  searchHint: 'Search brands',
                );
                if (picked != null) setState(() => _brandId = picked);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 3 · Price & stock
        _Section(
          key: _priceKey,
          number: 3,
          title: 'Price & stock',
          done: s.price,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_RupeesFormatter()],
                    textInputAction: TextInputAction.next,
                    style: TextStyle(fontFeatures: tabularFigures),
                    decoration: InputDecoration(
                      label: const _Label('Price', required: true),
                      prefixIcon: const _RsPrefix(),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      hintText: '0',
                      helperText: _isEdit && _existing!.summary.price != price ? 'Was ${money(_existing!.summary.price)}' : ' ',
                      errorText: err(FormGap.price, 'Enter the price') ?? _serverError('price'),
                      errorMaxLines: 3,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _advance,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_RupeesFormatter()],
                    style: TextStyle(fontFeatures: tabularFigures),
                    decoration: InputDecoration(
                      label: const _Label('Min. advance', required: true),
                      prefixIcon: const _RsPrefix(),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      hintText: '0',
                      helperText: 'Paid upfront',
                      // Shown as soon as it's wrong, not only after Submit.
                      errorText: _gaps.contains(FormGap.advanceTooHigh)
                          ? "Advance can't be more than the price"
                          : err(FormGap.advance, 'Enter the minimum advance') ?? _serverError('min_advance_price'),
                      errorMaxLines: 3,
                    ),
                  ),
                ),
              ],
            ),
            if (hasOptions)
              _OptionsPanel(
                options: opts,
                gated: _gated,
                colors: _colors,
                memories: _memories,
                sizes: _sizes,
                showErrors: _showErrors,
                onChanged: () => setState(() {}),
                onNewController: (c) => c.addListener(_refresh),
              ),
            _NoteRow(
              icon: AppIcons.package,
              text: _isEdit
                  ? (_existing!.summary.canManageStock || _existing!.summary.isLive || _existing!.summary.isOutOfStock
                      ? 'Stock is changed from the product page or Inventory.'
                      : 'Stock can be set once AtomShop approves this product.')
                  : 'Opening stock can be set as soon as AtomShop approves the product.',
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 4 · Description
        _Section(
          key: _descKey,
          number: 4,
          title: 'Description',
          done: s.desc,
          children: [
            _FeatureInput(
              features: _features,
              error: gaps.contains(FormGap.features)
                  ? 'Add at least one key feature'
                  : _gaps.contains(FormGap.tooManyFeatures)
                      ? 'Too long. Keep key features under $maxFeatureChars characters in total.'
                      : _serverError('short'),
              onChanged: (f) => setState(() => _features = f),
            ),
            _DescriptionEditor(
              key: ValueKey(_editorKey),
              initial: _initialParts,
              onChanged: (html) => setState(() => _longHtml = html),
            ),
            if (_serverError('long') != null) _ErrorLine(_serverError('long')!),
          ],
        ),
      ],
    );
  }

  Future<int?> _pickFromSheet({
    required String title,
    required List<(int, String)> items,
    required int? selected,
    required String searchHint,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SearchSheet(title: title, items: items, selected: selected, searchHint: searchHint),
    );
  }
}

String _thousands(int n) => count(n);

/// Keeps digits only and groups them: 72000 → 72,000.
class _RupeesFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final trimmed = digits.length > 9 ? digits.substring(0, 9) : digits;
    final text = count(int.parse(trimmed));
    // Keep the caret the same number of digits from the end.
    final digitsAfter = newValue.text.substring(newValue.selection.end.clamp(0, newValue.text.length)).replaceAll(RegExp(r'[^0-9]'), '').length;
    var pos = text.length, seen = 0;
    while (pos > 0 && seen < digitsAfter) {
      pos--;
      if (RegExp(r'[0-9]').hasMatch(text[pos])) seen++;
    }
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: pos));
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
      TextSpan(children: [
        TextSpan(text: text),
        if (required) TextSpan(text: ' *', style: TextStyle(color: pal.danger)),
        if (optional) TextSpan(text: ' (optional)', style: TextStyle(color: pal.muted, fontWeight: FontWeight.w400)),
      ]),
      semanticsLabel: '$text${required ? ', required' : ''}${optional ? ', optional' : ''}',
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip(this.s);
  final ({bool photos, bool basics, bool price, bool desc}) s;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final parts = [(s.photos, 'Photos'), (s.basics, 'Basics'), (s.price, 'Price'), (s.desc, 'Description')];
    final n = parts.where((p) => p.$1).length;
    final next = parts.where((p) => !p.$1).firstOrNull?.$2;
    return Semantics(
      label: '$n of 4 sections done${next == null ? ', ready to submit' : ', next: $next'}',
      excludeSemantics: true,
      child: Container(
        color: pal.card,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '$n of 4', style: TextStyle(fontWeight: FontWeight.w700, color: pal.text)),
                    const TextSpan(text: ' sections done'),
                  ]),
                  style: t.labelSmall?.copyWith(fontSize: 12, color: pal.muted),
                ),
                const Spacer(),
                Text(next == null ? 'Ready to submit' : 'Next: $next', style: t.labelSmall?.copyWith(fontSize: 12, color: next == null ? pal.positive.fg : pal.muted)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final (i, p) in parts.indexed) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 4,
                          decoration: BoxDecoration(color: p.$1 ? pal.primary : pal.border, borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          p.$2,
                          style: t.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: p.$1 ? pal.primary : pal.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.tone, required this.icon, required this.text, this.onDismiss});

  final Tone tone;
  final IconData icon;
  final String text;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.fromLTRB(14, 12, onDismiss == null ? 14 : 4, 12),
        decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(14)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: tone.fg),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: t.bodySmall?.copyWith(fontSize: 13, height: 1.45, color: pal.text))),
            if (onDismiss != null)
              IconButton(
                tooltip: 'Dismiss',
                visualDensity: VisualDensity.compact,
                onPressed: onDismiss,
                icon: Icon(AppIcons.close, size: 18, color: tone.fg),
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({super.key, required this.number, required this.title, required this.done, required this.children, this.trailing});

  final int number;
  final String title;
  final bool done;
  final String? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: pal.card, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: pal.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            label: '$title, section $number of 4${done ? ', done' : ''}',
            excludeSemantics: true,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(color: done ? pal.positive.bg : pal.primarySoft2, shape: BoxShape.circle),
                  child: Center(
                    child: done
                        ? Icon(AppIcons.check, size: 15, color: pal.positive.fg)
                        : Text('$number', style: t.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: pal.primary)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: t.titleSmall?.copyWith(fontSize: 16, fontWeight: FontWeight.w700))),
                if (trailing != null) Text(trailing!, style: t.labelSmall?.copyWith(fontSize: 12, color: pal.muted, fontFeatures: tabularFigures)),
              ],
            ),
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
      child: Transform.translate(
        offset: const Offset(0, -6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 1), child: Icon(AppIcons.error, size: 15, color: pal.danger)),
            const SizedBox(width: 6),
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: pal.danger, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(AppIcons.tip, size: 16, color: pal.muted),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: pal.muted))),
      ],
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: pal.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: pal.muted),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13, color: pal.muted))),
        ],
      ),
    );
  }
}

class _MainPhoto extends StatelessWidget {
  const _MainPhoto({
    required this.picked,
    required this.existingUrl,
    required this.error,
    required this.onAdd,
    required this.onReplace,
    required this.onRemove,
  });

  final PickedImage? picked;
  final String? existingUrl;
  final bool error;
  final VoidCallback onAdd;
  final VoidCallback onReplace;

  /// Only a newly picked photo can be removed (the API always needs one).
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(14);
    if (picked == null && existingUrl == null) {
      return Semantics(
        button: true,
        label: 'Add main photo, required',
        excludeSemantics: true,
        child: Material(
          color: error ? Color.alphaBlend(pal.negative.bg.withValues(alpha: 0.5), pal.card) : pal.surface,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onAdd,
            child: CustomPaint(
              painter: _DashedBorder(color: error ? pal.danger : pal.border, radius: 14),
              child: SizedBox(
                height: 188,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(AppIcons.imageAdd, size: 36, color: error ? pal.danger : pal.muted),
                    const SizedBox(height: 6),
                    Text('Add main photo', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      error ? 'Required · buyers see this first' : '(required)',
                      style: t.bodySmall?.copyWith(color: error ? pal.danger : pal.muted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Container(
      height: 200,
      decoration: BoxDecoration(color: Colors.white, borderRadius: radius, border: Border.all(color: pal.divider)),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 48),
              child: picked != null
                  ? Image.memory(picked!.bytes, fit: BoxFit.contain)
                  : NetThumb(existingUrl, size: 140, radius: 0),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: pal.header, borderRadius: BorderRadius.circular(12)),
              child: Text(picked != null && existingUrl != null ? 'New main photo' : 'Main photo', style: t.labelSmall?.copyWith(color: pal.onHeader, fontWeight: FontWeight.w700)),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Row(
              children: [
                _PillButton(label: 'Replace', onTap: onReplace),
                if (onRemove != null) ...[
                  const SizedBox(width: 6),
                  _PillButton(label: existingUrl != null ? 'Undo' : 'Remove', onTap: onRemove!, danger: existingUrl == null),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onTap, this.danger = false});
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        foregroundColor: danger ? pal.negative.fg : const Color(0xFF10122B),
        side: const BorderSide(color: Color(0xFFD9DCE6)),
        shape: const StadiumBorder(),
      ),
      child: Text(label),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(1));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 12) {
        canvas.drawPath(m.extractPath(d, d + 7), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.image, required this.onRemove, this.isNew = false});
  final Widget image;
  final VoidCallback onRemove;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isNew ? pal.primary : pal.divider, width: isNew ? 1.5 : 1),
            ),
            child: image,
          ),
          Positioned(
            top: -12,
            right: -12,
            child: SizedBox(
              width: 36,
              height: 36,
              child: IconButton(
                tooltip: 'Remove photo',
                padding: EdgeInsets.zero,
                onPressed: onRemove,
                icon: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(color: pal.header, shape: BoxShape.circle, border: Border.all(color: pal.card, width: 2)),
                  child: Icon(AppIcons.close, size: 14, color: pal.onHeader),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddThumb extends StatelessWidget {
  const _AddThumb({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    return SizedBox(
      width: 76,
      height: 76,
      child: Material(
        color: pal.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: CustomPaint(
            painter: _DashedBorder(color: pal.border, radius: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppIcons.add, color: pal.primary),
                Text('Add', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: pal.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A field that opens a picker: looks like the other outlined inputs.
class _PickerField extends StatelessWidget {
  const _PickerField({required this.label, required this.value, required this.placeholder, required this.onTap, this.helper, this.error});

  final Widget label;
  final String? value;
  final String placeholder;
  final String? helper;
  final String? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          label: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          helperText: helper,
          errorText: error,
          suffixIcon: const Icon(AppIcons.chevronDown),
        ),
        child: Text(value ?? placeholder, style: TextStyle(fontSize: 15, color: value == null ? pal.muted : pal.text)),
      ),
    );
  }
}

class _SearchSheet extends StatefulWidget {
  const _SearchSheet({required this.title, required this.items, required this.selected, required this.searchHint});

  final String title;
  final List<(int, String)> items;
  final int? selected;
  final String searchHint;

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final q = _q.trim().toLowerCase();
    final items = widget.items.where((i) => q.isEmpty || i.$2.toLowerCase().contains(q)).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(widget.title, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            ),
            if (widget.items.length > 6)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _q = v),
                  decoration: InputDecoration(hintText: widget.searchHint, prefixIcon: const Icon(AppIcons.search)),
                ),
              ),
            Expanded(
              child: items.isEmpty
                  ? Center(child: Text('Nothing matches “${_q.trim()}”', style: t.bodyMedium?.copyWith(color: pal.muted)))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final (id, label) = items[i];
                        final sel = id == widget.selected;
                        return ListTile(
                          minTileHeight: 52,
                          title: Text(label, style: t.bodyLarge?.copyWith(fontWeight: sel ? FontWeight.w700 : null, color: sel ? pal.primary : null)),
                          trailing: sel ? Icon(AppIcons.check, color: pal.primary) : null,
                          onTap: () => Navigator.pop(context, id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Colours, storage and sizes for categories that have them, folded away.
class _OptionsPanel extends StatefulWidget {
  const _OptionsPanel({
    required this.options,
    required this.gated,
    required this.colors,
    required this.memories,
    required this.sizes,
    required this.showErrors,
    required this.onChanged,
    required this.onNewController,
  });

  final ProductFormOptions options;
  final bool Function(List<int>) gated;
  final Set<int> colors;
  final Map<int, TextEditingController> memories;
  final Map<int, TextEditingController> sizes;
  final bool showErrors;
  final VoidCallback onChanged;
  final ValueChanged<TextEditingController> onNewController;

  @override
  State<_OptionsPanel> createState() => _OptionsPanelState();
}

class _OptionsPanelState extends State<_OptionsPanel> {
  late bool _open = widget.colors.isNotEmpty || widget.memories.isNotEmpty || widget.sizes.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final o = widget.options;
    final picked = widget.colors.length + widget.memories.length + widget.sizes.length;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: pal.border, width: 1.5), borderRadius: BorderRadius.circular(AppRadius.control)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.control),
            onTap: () => setState(() => _open = !_open),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(TextSpan(children: [
                            const TextSpan(text: 'Options', style: TextStyle(fontWeight: FontWeight.w600)),
                            TextSpan(text: ' (optional)', style: TextStyle(color: pal.muted)),
                          ])),
                          Text(
                            picked == 0 ? 'Colours, storage or sizes with their own price' : '$picked picked',
                            style: t.bodySmall?.copyWith(color: pal.muted),
                          ),
                        ],
                      ),
                    ),
                    Icon(_open ? AppIcons.chevronUp : AppIcons.chevronDown, color: pal.muted),
                  ],
                ),
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.gated(o.colorCategories) && o.colors.isNotEmpty) ...[
                    Text('Colours', style: t.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in o.colors)
                          FilterChip(
                            label: Text(c.label),
                            selected: widget.colors.contains(c.id),
                            onSelected: (v) {
                              v ? widget.colors.add(c.id) : widget.colors.remove(c.id);
                              widget.onChanged();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (widget.gated(o.memoryCategories) && o.memories.isNotEmpty) ...[
                    Text('Storage', style: t.labelLarge),
                    _PricedVariants(options: o.memories, selected: widget.memories, showErrors: widget.showErrors, onChanged: widget.onChanged, onNewController: widget.onNewController),
                    const SizedBox(height: 12),
                  ],
                  if (widget.gated(o.sizeCategories) && o.sizes.isNotEmpty) ...[
                    Text('Screen sizes', style: t.labelLarge),
                    _PricedVariants(options: o.sizes, selected: widget.sizes, showErrors: widget.showErrors, onChanged: widget.onChanged, onNewController: widget.onNewController),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Checkbox + per-variant price rows (memory / size).
class _PricedVariants extends StatelessWidget {
  const _PricedVariants({
    required this.options,
    required this.selected,
    required this.showErrors,
    required this.onChanged,
    required this.onNewController,
  });

  final List<VariantOption> options;
  final Map<int, TextEditingController> selected;
  final bool showErrors;
  final VoidCallback onChanged;
  final ValueChanged<TextEditingController> onNewController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final o in options)
          Row(
            children: [
              Checkbox(
                value: selected.containsKey(o.id),
                onChanged: (v) {
                  if (v == true) {
                    final c = TextEditingController();
                    onNewController(c);
                    selected[o.id] = c;
                  } else {
                    selected.remove(o.id)?.dispose();
                  }
                  onChanged();
                },
              ),
              Expanded(child: Text(o.label)),
              SizedBox(
                width: 140,
                child: selected.containsKey(o.id)
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: TextField(
                          controller: selected[o.id],
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            isDense: true,
                            prefixText: 'Rs. ',
                            hintText: 'Price',
                            errorText: showErrors && (int.tryParse(selected[o.id]!.text.trim()) ?? 0) < 1 ? 'Add a price' : null,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
      ],
    );
  }
}

/// Key features as chips: type one, press Enter (or a comma) to add it.
class _FeatureInput extends StatefulWidget {
  const _FeatureInput({required this.features, required this.onChanged, this.error});

  final List<String> features;
  final ValueChanged<List<String>> onChanged;
  final String? error;

  @override
  State<_FeatureInput> createState() => _FeatureInputState();
}

class _FeatureInputState extends State<_FeatureInput> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit() {
    if (_ctrl.text.trim().isEmpty) return;
    widget.onChanged(addFeatures(widget.features, _ctrl.text));
    _ctrl.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final chars = featureChars(widget.features);
    final error = widget.error;
    final borderColor = error != null ? pal.danger : (_focus.hasFocus ? pal.primary : pal.border);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _focus.requestFocus,
          child: InputDecorator(
            isFocused: _focus.hasFocus,
            decoration: InputDecoration(
              label: const _Label('Key features', required: true),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              contentPadding: const EdgeInsets.fromLTRB(12, 16, 8, 10),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.control), borderSide: BorderSide(color: borderColor, width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.control), borderSide: BorderSide(color: borderColor, width: 1.5)),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final (i, f) in widget.features.indexed)
                  InputChip(
                    label: Text(f),
                    labelStyle: t.labelLarge?.copyWith(color: pal.primary, fontWeight: FontWeight.w600),
                    backgroundColor: pal.primarySoft2,
                    side: BorderSide.none,
                    deleteIcon: Icon(AppIcons.close, size: 18, color: pal.primary),
                    deleteButtonTooltipMessage: 'Remove $f',
                    onDeleted: () => widget.onChanged([...widget.features]..removeAt(i)),
                  ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 160),
                  child: IntrinsicWidth(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      onChanged: (v) {
                        if (v.endsWith(',')) _commit();
                        setState(() {});
                      },
                      onSubmitted: (_) => _commit(),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        hintText: widget.features.isEmpty ? 'Type a feature, press Enter' : 'Add another',
                      ),
                    ),
                  ),
                ),
                if (_ctrl.text.trim().isNotEmpty)
                  FilledButton(
                    onPressed: _commit,
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 14)),
                    child: const Text('Add'),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  error ?? 'One feature per chip, e.g. "20L capacity"',
                  style: t.bodySmall?.copyWith(color: error != null ? pal.danger : pal.muted),
                ),
              ),
              Text(
                '$chars/$maxFeatureChars',
                style: t.bodySmall?.copyWith(color: chars > maxFeatureChars ? pal.danger : pal.muted, fontFeatures: tabularFigures),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A small block editor: each paragraph, heading or bullet is its own line,
/// styled as it will look. The toolbar changes the focused line. It saves as
/// HTML the seller never sees.
class _DescriptionEditor extends StatefulWidget {
  const _DescriptionEditor({super.key, required this.initial, required this.onChanged});

  final List<DescPart> initial;
  final ValueChanged<String> onChanged;

  @override
  State<_DescriptionEditor> createState() => _DescriptionEditorState();
}

class _Line {
  _Line(DescPart p)
      : part = p,
        ctrl = TextEditingController(text: p.text),
        focus = FocusNode();

  final DescPart part;
  final TextEditingController ctrl;
  final FocusNode focus;

  void dispose() {
    ctrl.dispose();
    focus.dispose();
  }
}

class _DescriptionEditorState extends State<_DescriptionEditor> {
  late final List<_Line> _lines = [
    for (final p in widget.initial) _Line(DescPart(p.kind, p.text, bold: p.bold)),
  ];
  int _current = 0;

  @override
  void initState() {
    super.initState();
    if (_lines.isEmpty) _lines.add(_Line(DescPart(DescKind.paragraph, '')));
    for (final l in _lines) {
      _wire(l);
    }
  }

  void _wire(_Line l) {
    l.focus.addListener(() {
      if (l.focus.hasFocus) setState(() => _current = _lines.indexOf(l));
    });
  }

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  void _emit() => widget.onChanged(partsToHtml([for (final l in _lines) l.part]));

  void _onChanged(_Line l, String text) {
    // Enter starts a new line of the same kind (a heading is followed by text).
    if (text.contains('\n')) {
      final pieces = text.split('\n');
      l.part.text = pieces.first;
      l.ctrl.value = TextEditingValue(text: pieces.first, selection: TextSelection.collapsed(offset: pieces.first.length));
      var at = _lines.indexOf(l);
      _Line? last;
      for (final rest in pieces.skip(1)) {
        final kind = l.part.kind == DescKind.heading ? DescKind.paragraph : l.part.kind;
        final n = _Line(DescPart(kind, rest));
        _wire(n);
        _lines.insert(++at, n);
        last = n;
      }
      setState(() {});
      if (last != null) WidgetsBinding.instance.addPostFrameCallback((_) => last!.focus.requestFocus());
    } else {
      l.part.text = text;
    }
    _emit();
  }

  void _setKind(DescKind kind) {
    final l = _lines[_current.clamp(0, _lines.length - 1)];
    setState(() {
      l.part.kind = l.part.kind == kind ? DescKind.paragraph : kind;
      if (l.part.kind == DescKind.heading) l.part.bold = false;
    });
    l.focus.requestFocus();
    _emit();
  }

  void _toggleBold() {
    final l = _lines[_current.clamp(0, _lines.length - 1)];
    setState(() {
      if (l.part.kind == DescKind.heading) l.part.kind = DescKind.paragraph;
      l.part.bold = !l.part.bold;
    });
    l.focus.requestFocus();
    _emit();
  }

  void _removeLine(int i) {
    if (_lines.length == 1) {
      _lines.first.ctrl.clear();
      _lines.first.part.text = '';
    } else {
      final l = _lines.removeAt(i);
      WidgetsBinding.instance.addPostFrameCallback((_) => l.dispose());
      _current = (i - 1).clamp(0, _lines.length - 1);
    }
    setState(() {});
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final cur = _lines[_current.clamp(0, _lines.length - 1)].part;
    final anyFocus = _lines.any((l) => l.focus.hasFocus);

    Widget tool(String tip, Widget icon, bool on, VoidCallback onTap) => Tooltip(
          message: tip,
          child: Semantics(
            button: true,
            toggled: on,
            label: tip,
            excludeSemantics: true,
            child: Material(
              color: on ? pal.primarySoft2 : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onTap,
                child: SizedBox(width: 48, height: 44, child: Center(child: IconTheme(data: IconThemeData(color: on ? pal.primary : pal.text, size: 22), child: icon))),
              ),
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(children: [
            const TextSpan(text: 'Full description', style: TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: ' (optional)', style: TextStyle(color: pal.muted)),
          ]),
          style: t.bodyMedium,
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: pal.field,
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(color: anyFocus ? pal.primary : pal.border, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: pal.divider))),
                child: Row(
                  children: [
                    tool('Bold', const Icon(AppIcons.bold), cur.bold, _toggleBold),
                    tool('Heading', const Icon(AppIcons.heading), cur.kind == DescKind.heading, () => _setKind(DescKind.heading)),
                    tool('Bullet list', const Icon(AppIcons.bulletList), cur.kind == DescKind.bullet, () => _setKind(DescKind.bullet)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                child: Column(
                  children: [
                    for (final (i, l) in _lines.indexed)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (l.part.kind == DescKind.bullet)
                            Padding(
                              padding: const EdgeInsets.only(top: 17, right: 10, left: 2),
                              child: Container(width: 6, height: 6, decoration: BoxDecoration(color: pal.text, shape: BoxShape.circle)),
                            ),
                          Expanded(
                            child: TextField(
                              controller: l.ctrl,
                              focusNode: l.focus,
                              minLines: 1,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              onChanged: (v) => _onChanged(l, v),
                              style: l.part.kind == DescKind.heading
                                  ? t.titleMedium?.copyWith(fontWeight: FontWeight.w700)
                                  : t.bodyMedium?.copyWith(height: 1.5, fontWeight: l.part.bold ? FontWeight.w700 : null),
                              decoration: InputDecoration(
                                isDense: true,
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                hintText: i == 0 && _lines.length == 1 ? 'Describe the product in your own words' : null,
                              ),
                            ),
                          ),
                          if (l.focus.hasFocus && (_lines.length > 1 || l.ctrl.text.isNotEmpty))
                            IconButton(
                              tooltip: 'Remove this line',
                              onPressed: () => _removeLine(i),
                              icon: Icon(AppIcons.close, size: 18, color: pal.muted),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: Text('Formatted for you, no code needed. Enter starts a new line.', style: t.bodySmall?.copyWith(color: pal.muted)),
        ),
      ],
    );
  }
}

/// "Sent for review" after adding a product.
class _SubmittedView extends StatelessWidget {
  const _SubmittedView({required this.product, required this.onView, required this.onAddAnother, required this.onClose});

  final ProductDetail product;
  final VoidCallback onView;
  final VoidCallback onAddAnother;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final p = product.summary;
    Widget step(Widget dot, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [dot, const SizedBox(width: 10), Expanded(child: Text(text, style: t.bodySmall?.copyWith(fontSize: 13, color: pal.text)))]),
        );
    Widget numDot(String n, Tone tone) => Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: tone.bg, shape: BoxShape.circle),
          child: Center(child: Text(n, style: t.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: tone.fg))),
        );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onClose();
      },
      child: Scaffold(
        backgroundColor: pal.card,
        appBar: AppBar(
          backgroundColor: pal.card,
          foregroundColor: pal.text,
          automaticallyImplyLeading: false,
          actions: [IconButton(tooltip: 'Close', onPressed: onClose, icon: const Icon(AppIcons.close))],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const _SuccessArt(),
              const SizedBox(height: 18),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text('Sent for review', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4)),
              ),
              const SizedBox(height: 8),
              Text(
                "We'll notify you when it's live. AtomShop usually reviews new products within 1–2 days.",
                textAlign: TextAlign.center,
                style: t.bodyMedium?.copyWith(color: pal.muted, height: 1.5),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: pal.divider), borderRadius: BorderRadius.circular(AppRadius.card)),
                child: Row(
                  children: [
                    NetThumb(p.picture, size: 56, radius: 10),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                          Text(
                            [money(p.price), ?p.prNumber].join(' · '),
                            style: t.bodySmall?.copyWith(color: pal.muted, fontFeatures: tabularFigures),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: pal.surface, borderRadius: BorderRadius.circular(AppRadius.card)),
                child: Column(
                  children: [
                    step(
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(color: pal.success, shape: BoxShape.circle),
                        child: Icon(AppIcons.check, size: 14, color: pal.onSuccess),
                      ),
                      'Submitted just now',
                    ),
                    step(numDot('2', pal.info), 'AtomShop checks the photos and details'),
                    step(numDot('3', pal.neutral), 'It goes live, and you can set its stock'),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddAnother,
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                    icon: const Icon(AppIcons.add),
                    label: const Text('Add another'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onView,
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                    child: const Text('View product'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessArt extends StatelessWidget {
  const _SuccessArt();

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    return ExcludeSemantics(
      child: SizedBox(
        width: 132,
        height: 132,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(decoration: BoxDecoration(color: pal.positive.bg, shape: BoxShape.circle)),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(color: pal.success, shape: BoxShape.circle),
              child: Icon(AppIcons.check, size: 52, color: pal.onSuccess),
            ),
            Positioned(left: 10, top: 22, child: _Dot(10, pal.accent)),
            Positioned(right: 12, top: 32, child: _Dot(8, pal.primary)),
            Positioned(right: 18, bottom: 22, child: _Dot(12, pal.warning.fg.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.size, this.color);
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

/// "Rs." always visible inside price fields, not only once focused.
class _RsPrefix extends StatelessWidget {
  const _RsPrefix();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 14, right: 4),
        child: Text('Rs.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppPalette.of(context).muted)),
      );
}
