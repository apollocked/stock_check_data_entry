import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/item.dart';
import '../../../domain/entities/store.dart';
import '../../controllers/inventory_controllers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/common/busy_button.dart';
import '../../widgets/feedback/app_feedback.dart';
import '../../widgets/motion/entrance.dart';
import 'widgets/item_form_fields.dart';
import 'widgets/item_photo_picker.dart';

/// Add a new item (optionally from a scanned barcode) or edit one.
class ItemFormScreen extends ConsumerStatefulWidget {
  final String barcode;
  final Item? existingItem;

  const ItemFormScreen({super.key, this.barcode = '', this.existingItem});

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _c = ItemFormControllers();
  XFile? _picked;
  String? _imageUrl;
  bool _saving = false;
  bool _dirty = false;

  Item? get _item => widget.existingItem;

  @override
  void initState() {
    super.initState();
    final item = _item;
    _c.name.text = item?.name ?? '';
    _c.price.text = item?.price?.toStringAsFixed(2) ?? '';
    _c.barcode.text = item?.barcode ?? widget.barcode;
    _c.description.text = item?.description ?? '';
    _imageUrl = item?.imageUrl;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _picked = image;
          _dirty = true;
        });
      }
    } catch (_) {
      if (mounted) {
        showAppSnack(
          context,
          'Could not open the photo. Check camera and photo access.',
          kind: SnackKind.error,
        );
      }
    }
  }

  Future<void> _save(List<ItemField> fields) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    String? text(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final imageUrl = _picked != null
          ? await repo.uploadItemImage(_picked!)
          : _imageUrl;
      final price = parsePrice(_c.price.text)!;
      final item = _item;
      if (item != null) {
        await repo.updateItem(
          itemId: item.id,
          name: _c.name.text.trim(),
          price: price,
          description: text(_c.description),
          barcode: text(_c.barcode),
          imageUrl: imageUrl,
          customFields: _c.customValues(fields),
        );
      } else {
        final store = await ref.read(storeProvider.future);
        await repo.insertItem(
          storeId: store.id,
          name: _c.name.text.trim(),
          price: price,
          description: text(_c.description),
          barcode: text(_c.barcode),
          imageUrl: imageUrl,
          customFields: _c.customValues(fields),
        );
      }
      invalidateStock(ref);
      if (!mounted) return;
      showAppSnack(
        context,
        item != null ? 'Item updated' : 'Item added',
        kind: SnackKind.success,
      );
      context.pop(true);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await confirmAction(
      context,
      title: 'Discard changes?',
      message: 'What you entered will be lost.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (discard && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final fields =
        ref.watch(storeProvider).value?.enabledFields ?? defaultValueFields();
    final hasPhoto = fields.any((f) => f.id == 'image_url');

    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) => didPop ? null : _confirmDiscard(),
      child: Scaffold(
        appBar: AppBar(title: Text(_item != null ? 'Edit item' : 'New item')),
        body: Form(
          key: _formKey,
          onChanged: () {
            if (!_dirty) setState(() => _dirty = true);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.xxl),
            children: [
              if (hasPhoto)
                ItemPhotoPicker(
                  picked: _picked,
                  existingUrl: _imageUrl,
                  onPick: _pick,
                  onRemove: () => setState(() {
                    _picked = null;
                    _imageUrl = null;
                    _dirty = true;
                  }),
                ).entrance(),
              ItemFormFields(
                controllers: _c,
                fields: fields,
                initialCustom: (id) => '${_item?.customValue(id) ?? ''}',
              ).entrance(index: 1),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.lg),
          child: BusyButton(
            label: _item != null ? 'Save changes' : 'Add item',
            icon: Icons.check_rounded,
            busy: _saving,
            onPressed: () => _save(fields),
          ),
        ),
      ),
    );
  }
}
