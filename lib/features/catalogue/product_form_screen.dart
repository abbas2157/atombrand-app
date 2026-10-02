import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/images.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/models/product.dart';
import '../../data/repositories/catalogue_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import 'product_detail_screen.dart';

/// Create (id == null) or edit a product (§2.1, §8.4).
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.id});

  final int? id;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _pageTitle = TextEditingController();
  final _price = TextEditingController();
  final _advance = TextEditingController();
  final _short = TextEditingController();
  final _long = TextEditingController();

  ProductFormOptions? _options;
  ProductDetail? _existing;
  String? _loadError;

  int? _categoryId;
  int? _brandId;
  PickedImage? _picture;
  final List<PickedImage> _newGallery = [];
  List<GalleryImage> _gallery = [];
  final Set<int> _colors = {};
  final Map<int, TextEditingController> _memories = {};
  final Map<int, TextEditingController> _sizes = {};

  bool _saving = false;
  ApiException? _error;

  bool get _isEdit => widget.id != null;
  CatalogueRepository get _repo => ref.read(catalogueRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_title, _pageTitle, _price, _advance, _short, _long, ..._memories.values, ..._sizes.values]) {
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
          _price.text = '${s.price}';
          _advance.text = '${s.minAdvancePrice}';
          _short.text = p.short ?? '';
          _long.text = p.long ?? '';
          _categoryId = p.categoryId ?? s.category?.id;
          _brandId = p.brandId ?? s.displayBrand?.id;
          _gallery = List.of(p.gallery);
          _colors.addAll(p.colors);
          for (final m in p.memories) {
            _memories[m.id] = TextEditingController(text: '${m.price}');
          }
          for (final z in p.sizes) {
            _sizes[z.id] = TextEditingController(text: '${z.price}');
          }
        } else {
          // Own brand comes first in the list.
          final ownId = ref.read(signedInProvider)?.brand.id;
          _brandId = options.brands.any((b) => b.id == ownId) ? ownId : options.brands.firstOrNull?.id;
        }
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    }
  }

  List<FormBrand> get _brandsForCategory {
    final all = _options?.brands ?? const <FormBrand>[];
    if (_categoryId == null) return all;
    final filtered = all.where((b) => b.categoryIds.isEmpty || b.categoryIds.contains(_categoryId)).toList();
    return filtered.isEmpty ? all : filtered;
  }

  bool _gated(List<int> categories) => _categoryId != null && categories.contains(_categoryId);

  Future<void> _pickMain(ImageSource source) async {
    try {
      final img = await pickImage(source: source);
      if (img != null && mounted) setState(() => _picture = img);
    } catch (_) {
      if (mounted) showToast(context, "Couldn't use that image. Try another one.");
    }
  }

  Future<void> _pickGallery() async {
    final max = ref.read(configProvider).value?.galleryMax ?? 8;
    final room = max - _newGallery.length;
    if (room <= 0) {
      showToast(context, 'Up to $max new images per save.');
      return;
    }
    try {
      final imgs = await pickImages(limit: room);
      if (mounted) setState(() => _newGallery.addAll(imgs.take(room)));
    } catch (_) {
      if (mounted) showToast(context, "Couldn't use those images.");
    }
  }

  Future<void> _deleteGalleryImage(GalleryImage g) async {
    final ok = await confirm(context, title: 'Remove image?', message: 'This removes it from the gallery now.', confirmLabel: 'Remove', destructive: true);
    if (!ok) return;
    try {
      await _repo.deleteGalleryImage(widget.id!, g.id);
      if (mounted) setState(() => _gallery.removeWhere((x) => x.id == g.id));
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Map<int, int> _prices(Map<int, TextEditingController> m) =>
      {for (final e in m.entries) e.key: int.tryParse(e.value.text.trim()) ?? 0};

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      showToast(context, 'Please fix the highlighted fields.');
      return;
    }
    if (!_isEdit && _picture == null) {
      showToast(context, 'Add a main picture.');
      return;
    }
    final status = _existing?.summary.status;
    if (status == 'Published') {
      final ok = await confirm(
        context,
        title: 'Send for review?',
        message: 'Saving sends this product back to AtomShop for review. It will be hidden until approved.',
        confirmLabel: 'Save & send',
      );
      if (!ok) return;
    }

    final opts = _options!;
    final input = ProductInput(
      title: _title.text.trim(),
      detailPageTitle: _pageTitle.text.trim(),
      categoryId: _categoryId!,
      brandId: _brandId!,
      price: int.parse(_price.text.trim()),
      minAdvancePrice: int.parse(_advance.text.trim()),
      short: _short.text.trim(),
      long: _long.text.trim(),
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
        await _repo.update(widget.id!, input);
      } else {
        await _repo.create(input);
      }
      if (!mounted) return;
      showToast(
        context,
        _isEdit
            ? (status == 'Published' ? 'Saved and sent for review.' : 'Product saved.')
            : 'Product added. AtomShop will review it before it goes live.',
      );
      context.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
      if (e.fieldErrors.isEmpty) {
        showApiError(context, e);
      } else {
        showToast(context, 'Please fix the highlighted fields.');
        _form.currentState!.validate();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _serverError(String field) => _error?.fieldError(field);

  @override
  Widget build(BuildContext context) {
    final ready = _options != null && (!_isEdit || _existing != null);
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit product' : 'Add product')),
      body: !ready
          ? (_loadError != null ? ErrorView(message: _loadError!, onRetry: _load) : const Center(child: CircularProgressIndicator()))
          : _buildForm(),
      bottomNavigationBar: !ready
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: BusyButton(label: _isEdit ? 'Save changes' : 'Submit for review', busy: _saving, onPressed: _save),
              ),
            ),
    );
  }

  Widget _buildForm() {
    final t = Theme.of(context).textTheme;
    final opts = _options!;
    final status = _existing?.summary.status;
    const gap = SizedBox(height: 14);
    final brands = _brandsForCategory;
    final digits = [FilteringTextInputFormatter.digitsOnly];

    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (status == 'Published')
            const InfoBanner('Saving sends this product back to AtomShop for review. It will be hidden until approved.')
          else if (status == 'Out of Stock')
            const InfoBanner('This product stays out of stock after saving. Change availability from Inventory.')
          else if (!_isEdit)
            const InfoBanner('New products go to AtomShop for review before they appear on the site.'),
          const SectionTitle('Basics'),
          TextFormField(
            controller: _title,
            maxLength: 255,
            decoration: InputDecoration(labelText: 'Title', errorText: _serverError('title')),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required.' : null,
          ),
          gap,
          TextFormField(
            controller: _pageTitle,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'Detail page title (optional)',
              helperText: 'Longer title shown on the product page',
              errorText: _serverError('detail_page_title'),
            ),
          ),
          gap,
          DropdownButtonFormField<int>(
            initialValue: _categoryId,
            isExpanded: true,
            decoration: InputDecoration(labelText: 'Category', errorText: _serverError('category_id')),
            items: [for (final c in opts.categories) DropdownMenuItem(value: c.id, child: Text(c.title))],
            onChanged: (v) => setState(() {
              _categoryId = v;
              final allowed = _brandsForCategory;
              if (!allowed.any((b) => b.id == _brandId)) _brandId = allowed.firstOrNull?.id;
            }),
            validator: (v) => v == null ? 'Choose a category.' : null,
          ),
          gap,
          DropdownButtonFormField<int>(
            key: ValueKey('brand-$_categoryId'),
            initialValue: brands.any((b) => b.id == _brandId) ? _brandId : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Show under brand',
              helperText: 'Usually your own brand',
              errorText: _serverError('brand_id'),
            ),
            items: [for (final b in brands) DropdownMenuItem(value: b.id, child: Text(b.title))],
            onChanged: (v) => setState(() => _brandId = v),
            validator: (v) => v == null ? 'Choose a brand.' : null,
          ),
          const SectionTitle('Price'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  inputFormatters: digits,
                  decoration: InputDecoration(labelText: 'Price', prefixText: 'Rs. ', errorText: _serverError('price')),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    return (n == null || n < 1) ? 'Enter a price.' : null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _advance,
                  keyboardType: TextInputType.number,
                  inputFormatters: digits,
                  decoration: InputDecoration(
                    labelText: 'Min. advance',
                    prefixText: 'Rs. ',
                    errorText: _serverError('min_advance_price'),
                  ),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null || n < 0) return 'Enter an amount.';
                    final price = int.tryParse(_price.text.trim());
                    if (price != null && n > price) return "Can't exceed the price.";
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SectionTitle('Description'),
          TextFormField(
            controller: _short,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(labelText: 'Short description', errorText: _serverError('short')),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Short description is required.' : null,
          ),
          gap,
          TextFormField(
            controller: _long,
            minLines: 4,
            maxLines: 12,
            decoration: InputDecoration(
              labelText: 'Full description (optional)',
              helperText: 'HTML is allowed',
              alignLabelWithHint: true,
              errorText: _serverError('long'),
            ),
          ),
          const SectionTitle('Images'),
          Text('Main picture${_isEdit ? '' : ' (required)'}', style: t.labelMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.control),
                child: _picture != null
                    ? Image.memory(_picture!.bytes, width: 96, height: 96, fit: BoxFit.cover)
                    : NetThumb(_existing?.summary.picture, size: 96, radius: AppRadius.control, icon: Icons.add_photo_alternate_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _pickMain(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(_picture == null && _existing?.summary.picture == null ? 'Choose picture' : 'Replace'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _pickMain(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Take photo'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_serverError('picture') != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_serverError('picture')!, style: t.bodySmall?.copyWith(color: AppColors.dangerFg)),
            ),
          const SizedBox(height: 16),
          Text('Gallery', style: t.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in _gallery)
                _GalleryThumb(
                  child: NetThumb(g.url, size: 80, radius: AppRadius.control),
                  onRemove: () => _deleteGalleryImage(g),
                ),
              for (final (i, g) in _newGallery.indexed)
                _GalleryThumb(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    child: Image.memory(g.bytes, width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  onRemove: () => setState(() => _newGallery.removeAt(i)),
                ),
              SizedBox(
                width: 80,
                height: 80,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: _pickGallery,
                  child: const Icon(Icons.add_photo_alternate_outlined, semanticLabel: 'Add gallery images'),
                ),
              ),
            ],
          ),
          if (_serverError('gallery_images') != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_serverError('gallery_images')!, style: t.bodySmall?.copyWith(color: AppColors.dangerFg)),
            ),
          if (_gated(opts.colorCategories) && opts.colors.isNotEmpty) ...[
            const SectionTitle('Colours'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in opts.colors)
                  FilterChip(
                    label: Text(c.label),
                    selected: _colors.contains(c.id),
                    onSelected: (v) => setState(() => v ? _colors.add(c.id) : _colors.remove(c.id)),
                  ),
              ],
            ),
          ],
          if (_gated(opts.memoryCategories) && opts.memories.isNotEmpty) ...[
            const SectionTitle('Storage options'),
            _PricedVariants(options: opts.memories, selected: _memories, onChanged: () => setState(() {})),
          ],
          if (_gated(opts.sizeCategories) && opts.sizes.isNotEmpty) ...[
            const SectionTitle('Screen sizes'),
            _PricedVariants(options: opts.sizes, selected: _sizes, onChanged: () => setState(() {})),
          ],
        ],
      ),
    );
  }
}

class _GalleryThumb extends StatelessWidget {
  const _GalleryThumb({required this.child, required this.onRemove});

  final Widget child;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -10,
          right: -10,
          child: IconButton(
            tooltip: 'Remove image',
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(backgroundColor: AppColors.surface, side: const BorderSide(color: AppColors.line)),
            iconSize: 16,
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
          ),
        ),
      ],
    );
  }
}

/// Checkbox + per-variant price rows (memory / size).
class _PricedVariants extends StatelessWidget {
  const _PricedVariants({required this.options, required this.selected, required this.onChanged});

  final List<VariantOption> options;
  final Map<int, TextEditingController> selected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          for (final o in options)
            Row(
              children: [
                Checkbox(
                  value: selected.containsKey(o.id),
                  onChanged: (v) {
                    if (v == true) {
                      selected[o.id] = TextEditingController();
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
                          child: TextFormField(
                            controller: selected[o.id],
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(isDense: true, prefixText: 'Rs. ', hintText: 'Price'),
                            validator: (v) => (int.tryParse(v?.trim() ?? '') ?? 0) < 1 ? 'Price?' : null,
                          ),
                        )
                      : null,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
