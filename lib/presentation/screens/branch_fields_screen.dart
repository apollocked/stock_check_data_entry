import 'package:flutter/material.dart';

import '../../domain/entities/branch.dart';

const List<Map<String, dynamic>> kAvailableFields = [
  {'id': 'name', 'label': 'Name', 'type': 'text', 'required': true},
  {'id': 'price', 'label': 'Price', 'type': 'number', 'required': true},
  {'id': 'description', 'label': 'Description', 'type': 'text', 'required': false},
  {'id': 'barcode', 'label': 'Barcode', 'type': 'text', 'required': false},
  {'id': 'image_url', 'label': 'Image', 'type': 'image', 'required': false},
  {'id': 'category', 'label': 'Category', 'type': 'text', 'required': false},
  {'id': 'supplier', 'label': 'Supplier', 'type': 'text', 'required': false},
  {'id': 'stock', 'label': 'Stock Quantity', 'type': 'number', 'required': false},
  {'id': 'expiry_date', 'label': 'Expiry Date', 'type': 'text', 'required': false},
];

class BranchFieldsScreen extends StatefulWidget {
  final String branchName;
  final String? location;
  final List<BranchField>? initialFields;

  const BranchFieldsScreen({
    super.key,
    required this.branchName,
    this.location,
    this.initialFields,
  });

  @override
  State<BranchFieldsScreen> createState() => _BranchFieldsScreenState();
}

class _BranchFieldsScreenState extends State<BranchFieldsScreen> {
  late final Map<String, bool> _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = {};
    for (final f in kAvailableFields) {
      final id = f['id'] as String;
      final req = f['required'] as bool;
      if (widget.initialFields != null) {
        final existing = widget.initialFields!
            .where((ef) => ef.id == id)
            .toList();
        _enabled[id] = existing.isNotEmpty
            ? existing.first.enabled
            : (req ? true : false);
      } else {
        _enabled[id] = req ? true : false;
      }
    }
  }

  List<BranchField> _buildFields() {
    return [
      for (final f in kAvailableFields)
        BranchField(
          id: f['id'] as String,
          label: f['label'] as String,
          type: f['type'] as String,
          enabled: _enabled[f['id'] as String] ?? false,
          required: f['required'] as bool,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fields: ${widget.branchName}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Select which fields to include for items in this branch.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Required fields are always enabled.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 16),
          for (final f in kAvailableFields) ...[
            _FieldTile(
              id: f['id'] as String,
              label: f['label'] as String,
              type: f['type'] as String,
              required: f['required'] as bool,
              enabled: _enabled[f['id'] as String] ?? false,
              onChanged: (val) {
                setState(() => _enabled[f['id'] as String] = val);
              },
            ),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () {
              Navigator.of(context).pop(_buildFields());
            },
            child: const Text('Create branch'),
          ),
        ],
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  final String id;
  final String label;
  final String type;
  final bool required;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _FieldTile({
    required this.id,
    required this.label,
    required this.type,
    required this.required,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typeLabel = type == 'image'
        ? '📷'
        : type == 'number'
            ? '#'
            : 'T';

    return Card(
      elevation: 0,
      color: enabled
          ? cs.primaryContainer.withAlpha(80)
          : cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(typeLabel, style: TextStyle(color: cs.outline)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleSmall),
                  if (required)
                    Text(
                      'Required',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.outline,
                          ),
                    ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              onChanged: required ? null : onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
