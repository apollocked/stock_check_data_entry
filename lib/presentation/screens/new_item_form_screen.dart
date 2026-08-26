import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/error/app_exception.dart';
import '../../domain/entities/branch.dart';
import '../../domain/entities/item.dart';
import '../providers/repository_providers.dart';

class ItemFormScreen extends ConsumerStatefulWidget {
  final int branchId;
  final String barcode;
  final Item? existingItem;
  final List<BranchField> branchFields;

  const ItemFormScreen({
    super.key,
    required this.branchId,
    required this.barcode,
    this.existingItem,
    this.branchFields = const [],
  });

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;

  final Map<String, TextEditingController> _customControllers = {};

  XFile? _pickedImage;
  String? _existingImageUrl;
  bool _submitting = false;

  bool get _isEditMode => widget.existingItem != null;

  List<BranchField> get _enabledFields =>
      widget.branchFields.where((f) => f.enabled).toList();

  bool _hasField(String id) => _enabledFields.any((f) => f.id == id);

  ImagePicker get _picker => ImagePicker();

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameController = TextEditingController(text: item?.name ?? '');
    _priceController = TextEditingController(
      text: item?.price == null ? '' : item!.price!.toStringAsFixed(2),
    );
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _existingImageUrl = item?.imageUrl;

    for (final f in _enabledFields) {
      if (!const {
        'name',
        'price',
        'description',
        'barcode',
        'image_url',
      }.contains(f.id)) {
        _customControllers[f.id] = TextEditingController(
          text: item?.customValue(f.id)?.toString() ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    for (final c in _customControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (image != null) setState(() => _pickedImage = image);
    } catch (e) {
      _showSnackBar('Could not pick image: $e', isError: true);
    }
  }

  Map<String, dynamic> _collectCustomFields() {
    final result = <String, dynamic>{};
    for (final f in _enabledFields) {
      if (const {
        'name',
        'price',
        'description',
        'barcode',
        'image_url',
      }.contains(f.id)) {
        continue;
      }
      final ctrl = _customControllers[f.id];
      if (ctrl != null && ctrl.text.trim().isNotEmpty) {
        final val = ctrl.text.trim();
        result[f.id] = f.type == 'number' ? (num.tryParse(val) ?? val) : val;
      }
    }
    return result;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isEditMode && _hasField('image_url') && _pickedImage == null) {
      _showSnackBar('Please add a photo of the item', isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = ref.read(inventoryRepositoryProvider);

      String? imageUrl = _existingImageUrl;
      if (_pickedImage != null) {
        _showSnackBar('Uploading image...');
        imageUrl = await repo.uploadItemImage(
          _pickedImage!,
          barcode: widget.barcode,
        );
      }

      final custom = _collectCustomFields();

      if (_isEditMode) {
        await repo.updateItem(
          itemId: widget.existingItem!.id,
          name: _nameController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          description:
              _hasField('description') &&
                  _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          imageUrl: imageUrl,
          customFields: custom,
        );
      } else {
        await repo.insertItem(
          branchId: widget.branchId,
          name: _nameController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          description:
              _hasField('description') &&
                  _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          barcode: widget.barcode.isEmpty ? null : widget.barcode,
          imageUrl: imageUrl,
          customFields: custom,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditMode ? 'Item updated' : 'Item saved')),
        );
        Navigator.of(context).pop(true);
      }
    } on AppException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      _showSnackBar('Unexpected error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit item' : 'New item')),
      body: AbsorbPointer(
        absorbing: _submitting,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_hasField('barcode')) ...[
                TextFormField(
                  initialValue: widget.barcode,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Barcode',
                    prefixIcon: Icon(Icons.qr_code_2),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_hasField('name'))
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Item name *',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
              const SizedBox(height: 16),
              if (_hasField('price'))
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Price *',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (v) {
                    final p = double.tryParse(v?.trim() ?? '');
                    if (p == null || p < 0) return 'Enter a valid price';
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              if (_hasField('description'))
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                  ),
                ),
              // Custom fields
              for (final f in _enabledFields)
                if (!const {
                  'name',
                  'price',
                  'description',
                  'barcode',
                  'image_url',
                }.contains(f.id)) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customControllers[f.id],
                    keyboardType: f.type == 'number'
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: f.label,
                      prefixIcon: Icon(
                        f.type == 'number' ? Icons.numbers : Icons.edit_note,
                      ),
                    ),
                  ),
                ],
              const SizedBox(height: 8),
              if (_hasField('image_url'))
                _ImagePickerCard(
                  image: _pickedImage,
                  existingImageUrl: _isEditMode ? _existingImageUrl : null,
                  onPickGallery: () => _pickImage(ImageSource.gallery),
                  onPickCamera:
                      !kIsWeb && (Platform.isAndroid || Platform.isIOS)
                      ? () => _pickImage(ImageSource.camera)
                      : null,
                  onClear: _pickedImage == null && _existingImageUrl == null
                      ? null
                      : () => setState(() {
                          _pickedImage = null;
                          _existingImageUrl = null;
                        }),
                ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_isEditMode ? Icons.update : Icons.save_outlined),
                label: Text(
                  _submitting
                      ? 'Saving...'
                      : _isEditMode
                      ? 'Update item'
                      : 'Save item',
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  final XFile? image;
  final String? existingImageUrl;
  final VoidCallback onPickGallery;
  final VoidCallback? onPickCamera;
  final VoidCallback? onClear;

  const _ImagePickerCard({
    required this.image,
    this.existingImageUrl,
    required this.onPickGallery,
    this.onPickCamera,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null || existingImageUrl != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: image != null
                ? Ink.image(
                    image: FileImage(File(image!.path)),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 180,
                  )
                : existingImageUrl != null
                ? Image.network(
                    existingImageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 180,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.broken_image,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  )
                : Icon(
                    Icons.add_a_photo_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: onPickGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
                TextButton.icon(
                  onPressed: onPickCamera,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Camera'),
                ),
                if (hasImage)
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
