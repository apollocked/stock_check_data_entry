import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/item.dart';
import '../controllers/inventory_controllers.dart';
import '../providers/repository_providers.dart';
import 'new_item_form_screen.dart';
import 'stock_action_sheet.dart';

class InventoryTab extends ConsumerStatefulWidget {
  const InventoryTab({super.key});

  @override
  ConsumerState<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends ConsumerState<InventoryTab> {
  String _searchQuery = '';

  Future<void> _editItem(Item item) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ItemFormScreen(existingItem: item)),
    );
    if (updated == true) ref.invalidate(itemsProvider);
  }

  Future<void> _confirmDelete(Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('"${item.name}" will be removed permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(inventoryRepositoryProvider).deleteItem(item);
      ref.invalidate(itemsProvider);
      if (mounted) _showSnackBar('Deleted "${item.name}".');
    } catch (e) {
      _showSnackBar('$e', isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
          duration: const Duration(seconds: 5),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search items...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
          ),
        ),
        Expanded(
          child: itemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Failed to load items:\n$error',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => ref.invalidate(itemsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (items) {
              final filtered = _searchQuery.isEmpty
                  ? items
                  : items
                        .where(
                          (i) =>
                              i.name.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ) ||
                              (i.barcode?.contains(_searchQuery) ?? false),
                        )
                        .toList();
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(itemsProvider);
                  await ref.read(itemsProvider.future);
                },
                child: filtered.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 120),
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 56,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'No items yet.\nTap + to add the first item.'
                                  : 'No items match "$_searchQuery".',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return _ItemCard(
                            item: item,
                            onTap: () =>
                                showStockActionSheet(context, item: item),
                            onEdit: () => _editItem(item),
                            onDelete: () => _confirmDelete(item),
                          );
                        },
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  bool get _isLow => item.quantity <= 5 && item.quantity > 0;
  bool get _isOut => item.quantity <= 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.imageUrl != null
                    ? Image.network(
                        item.imageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 56,
                          height: 56,
                          color: cs.surfaceContainerHighest,
                          child: Icon(Icons.broken_image, color: cs.outline),
                        ),
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        color: cs.surfaceContainerHighest,
                        child: Icon(
                          Icons.image_not_supported,
                          color: cs.outline,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (item.description != null &&
                        item.description!.isNotEmpty)
                      Text(
                        item.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (item.barcode != null)
                      Text(
                        item.barcode!,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: cs.outline),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.price == null ? '-' : item.price!.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _isOut
                          ? cs.errorContainer
                          : _isLow
                          ? cs.tertiaryContainer
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'In stock: ${item.quantity}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _isOut
                            ? cs.onErrorContainer
                            : _isLow
                            ? cs.onTertiaryContainer
                            : cs.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                tooltip: 'Actions',
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text('Delete'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
