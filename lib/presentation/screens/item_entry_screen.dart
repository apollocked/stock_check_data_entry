import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/error/app_exception.dart';
import '../controllers/inventory_controllers.dart';
import 'barcode_scan_screen.dart';

class ItemEntryScreen extends ConsumerStatefulWidget {
  const ItemEntryScreen({super.key});

  @override
  ConsumerState<ItemEntryScreen> createState() => _ItemEntryScreenState();
}

class _ItemEntryScreenState extends ConsumerState<ItemEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _descriptionController = TextEditingController();

  XFile? _pickedImage;
  bool _submitting = false;
  bool _creatingBranch = false;

  ImagePicker get _picker => ImagePicker();

  bool get _scannerAvailable =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
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

  Future<void> _scanBarcode() async {
    final code =
        await Navigator.of(context).push<String>(BarcodeScanScreen.route());
    if (code != null && code.isNotEmpty) {
      _barcodeController.text = code;
    }
  }

  Future<void> _showAddBranchDialog() async {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New branch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Branch name *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationController,
              decoration:
                  const InputDecoration(labelText: 'Location (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final name = nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Branch name is required.', isError: true);
      return;
    }

    setState(() => _creatingBranch = true);
    try {
      final created = await ref
          .read(branchesProvider.notifier)
          .create(name: name, location: locationController.text);
      ref.read(selectedBranchIdProvider.notifier).select(created.id);
      _showSnackBar('Branch "$name" created.');
    } catch (e) {
      _showSnackBar('$e', isError: true);
    } finally {
      if (mounted) setState(() => _creatingBranch = false);
    }
  }

  Future<void> _submit() async {
    final branchId = ref.read(selectedBranchIdProvider);
    if (branchId == null) {
      _showSnackBar('Select or create a branch first.', isError: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final repo = ref.read(inventoryRepositoryProvider);
    try {
      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await repo.uploadItemImage(_pickedImage!);
      }
      await repo.insertItem(
        branchId: branchId,
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        imageUrl: imageUrl,
      );
      ref.invalidate(itemsProvider);
      _resetForm();
      if (!mounted) return;
      _showSnackBar('Item saved successfully.');
    } on AppException catch (e) {
      _showSnackBar(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _priceController.clear();
    _barcodeController.clear();
    _descriptionController.clear();
    setState(() => _pickedImage = null);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchesProvider);
    final selectedBranchId = ref.watch(selectedBranchIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add item')),
      body: AbsorbPointer(
        absorbing: _submitting,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              branchesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Row(
                  children: [
                    Expanded(child: Text('Failed to load branches: $error')),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => ref.invalidate(branchesProvider),
                    ),
                  ],
                ),
                data: (branches) => Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: selectedBranchId,
                        decoration: const InputDecoration(
                          labelText: 'Branch',
                          prefixIcon: Icon(Icons.storefront),
                        ),
                        hint: const Text('Select branch'),
                        items: [
                          for (final branch in branches)
                            DropdownMenuItem(
                              value: branch.id,
                              child: Text(branch.name),
                            ),
                        ],
                        onChanged: (value) => ref
                            .read(selectedBranchIdProvider.notifier)
                            .select(value),
                        validator: (value) =>
                            value == null ? 'Branch is required' : null,
                      ),
                    ),
                    IconButton(
                      tooltip: 'New branch',
                      icon: _creatingBranch
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_business),
                      onPressed: _creatingBranch ? null : _showAddBranchDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Item name *',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Name is required'
                        : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Price *',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  final parsed =
                      double.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed < 0) {
                    return 'Enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _barcodeController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Barcode',
                  prefixIcon: const Icon(Icons.qr_code_2),
                  suffixIcon: _scannerAvailable
                      ? IconButton(
                          tooltip: 'Scan barcode',
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: _scanBarcode,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              _ImagePickerCard(
                image: _pickedImage,
                onPickGallery: () => _pickImage(ImageSource.gallery),
                onPickCamera: !_scannerAvailable
                    ? null
                    : () => _pickImage(ImageSource.camera),
                onClear: _pickedImage == null
                    ? null
                    : () => setState(() => _pickedImage = null),
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
                    : const Icon(Icons.save_outlined),
                label: Text(_submitting ? 'Saving...' : 'Save item'),
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
  final VoidCallback onPickGallery;
  final VoidCallback? onPickCamera;
  final VoidCallback? onClear;

  const _ImagePickerCard({
    required this.image,
    required this.onPickGallery,
    this.onPickCamera,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
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
            child: image == null
                ? Icon(Icons.image_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline)
                : Ink.image(
                    image: FileImage(File(image!.path)),
                    fit: BoxFit.cover,
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
