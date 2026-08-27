import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/store.dart';
import '../controllers/inventory_controllers.dart';

class ItemFieldsScreen extends ConsumerStatefulWidget {
  const ItemFieldsScreen({super.key});

  @override
  ConsumerState<ItemFieldsScreen> createState() => _ItemFieldsScreenState();
}

class _ItemFieldsScreenState extends ConsumerState<ItemFieldsScreen> {
  bool _saving = false;

  Future<void> _save(List<ItemField> fields) async {
    setState(() => _saving = true);
    try {
      await ref.read(storeProvider.notifier).updateFields(fields);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Item fields saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeAsync = ref.watch(storeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Item fields')),
      body: storeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (store) {
          final fields = store.enabledFields;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'These are the item fields shown in the inventory and CSV export.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              for (final f in kStoreFieldOptions) ...[
                _FieldTile(field: f, enabled: _isEnabled(fields, f)),
                const SizedBox(height: 4),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: _saving
                    ? null
                    : () async {
                        final updated = [
                          for (final f in kStoreFieldOptions)
                            ItemField(
                              id: f['id'] as String,
                              label: f['label'] as String,
                              type: f['type'] as String,
                              enabled: _isEnabled(fields, f),
                              required: f['required'] as bool,
                            ),
                        ];
                        await _save(updated);
                      },
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving...' : 'Save fields'),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isEnabled(List<ItemField> enabled, Map<String, dynamic> option) {
    final id = option['id'] as String;
    final required = option['required'] as bool;
    final match = enabled.where((f) => f.id == id).toList();
    if (match.isNotEmpty) return match.first.enabled;
    return required;
  }
}

class _FieldTile extends StatefulWidget {
  final Map<String, dynamic> field;
  final bool enabled;

  const _FieldTile({required this.field, required this.enabled});

  @override
  State<_FieldTile> createState() => _FieldTileState();
}

class _FieldTileState extends State<_FieldTile> {
  late bool _checked = widget.enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = widget.field['label'] as String;
    final type = widget.field['type'] as String;
    final required = widget.field['required'] as bool;

    final typeLabel = switch (type) {
      'image' => 'img',
      'number' => '#',
      'text' => 'T',
      _ => 'T',
    };

    return Card(
      elevation: 0,
      color: _checked
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
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: cs.outline),
                    ),
                ],
              ),
            ),
            Switch(
              value: _checked,
              onChanged: required
                  ? null
                  : (val) => setState(() => _checked = val),
            ),
          ],
        ),
      ),
    );
  }
}
