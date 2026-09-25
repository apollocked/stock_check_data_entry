import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../domain/entities/store.dart';
import '../../../widgets/common/section_header.dart';

/// Text controllers for everything the item form edits.
class ItemFormControllers {
  final name = TextEditingController();
  final price = TextEditingController();
  final barcode = TextEditingController();
  final description = TextEditingController();
  final custom = <String, TextEditingController>{};

  TextEditingController customFor(String id, [String initial = '']) =>
      custom.putIfAbsent(id, () => TextEditingController(text: initial));

  /// Filled-in custom field values; numbers are stored as numbers.
  Map<String, dynamic> customValues(List<ItemField> fields) => {
    for (final f in fields)
      if (!kStandardFieldIds.contains(f.id) &&
          (custom[f.id]?.text.trim().isNotEmpty ?? false))
        f.id: f.type == 'number'
            ? num.tryParse(custom[f.id]!.text.trim()) ??
                  custom[f.id]!.text.trim()
            : custom[f.id]!.text.trim(),
  };

  void dispose() {
    for (final c in [name, price, barcode, description, ...custom.values]) {
      c.dispose();
    }
  }
}

/// The form inputs, shown or hidden by the store's enabled fields.
class ItemFormFields extends StatelessWidget {
  final ItemFormControllers controllers;
  final List<ItemField> fields;
  final String Function(String id) initialCustom;

  const ItemFormFields({
    super.key,
    required this.controllers,
    required this.fields,
    required this.initialCustom,
  });

  bool _has(String id) => fields.any((f) => f.id == id);

  @override
  Widget build(BuildContext context) {
    final c = controllers;
    final custom = fields.where((f) => !kStandardFieldIds.contains(f.id));
    const gap = SizedBox(height: Gap.md);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Basics'),
        TextFormField(
          controller: c.name,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 200,
          decoration: const InputDecoration(
            labelText: 'Item name',
            prefixIcon: Icon(Icons.inventory_2_outlined),
            counterText: '',
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Name is required' : null,
        ),
        gap,
        TextFormField(
          controller: c.price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
          ],
          decoration: const InputDecoration(
            labelText: 'Price',
            prefixIcon: Icon(Icons.sell_outlined),
          ),
          validator: (v) =>
              parsePrice(v) == null ? 'Enter a valid price' : null,
        ),
        if (_has('barcode')) ...[
          gap,
          TextFormField(
            controller: c.barcode,
            textInputAction: TextInputAction.next,
            maxLength: 128,
            decoration: const InputDecoration(
              labelText: 'Barcode (optional)',
              prefixIcon: Icon(Icons.qr_code_2_rounded),
              counterText: '',
            ),
          ),
        ],
        if (_has('description') || custom.isNotEmpty)
          const SectionHeader('More details'),
        if (_has('description'))
          TextFormField(
            controller: c.description,
            maxLines: 3,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
            ),
          ),
        for (final field in custom) ...[
          gap,
          TextFormField(
            controller: c.customFor(field.id, initialCustom(field.id)),
            maxLength: 200,
            keyboardType: field.type == 'number'
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: field.label,
              counterText: '',
              prefixIcon: Icon(
                field.type == 'number'
                    ? Icons.numbers_rounded
                    : Icons.notes_rounded,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Accepts "12", "12.5" or "12,50"; null when empty or invalid.
double? parsePrice(String? value) {
  final p = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
  return p == null || p < 0 ? null : p;
}
