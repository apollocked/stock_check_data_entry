import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_messages.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/item.dart';
import '../../controllers/inventory_controllers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/item_image.dart';
import '../new_item_form_screen.dart';
import '../stock_action_sheet.dart';

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
      _showSnackBar(friendlyError(e), isError: true);
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SearchBar(
            leading: const Icon(Icons.search),
            hintText: 'Search items or barcode...',
            elevation: const WidgetStatePropertyAll(0),
            backgroundColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.surface,
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    'Failed to load items:\n${friendlyError(error)}',
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
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
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

  (Color, String, Color) _stockBadge(StatusColors sc) {
    final qty = item.quantity;
    if (qty < 0) {
      return (sc.danger, 'Minus: $qty', sc.danger);
    }
    if (qty == 0) {
      return (sc.neutral, 'Zero stock', sc.neutral);
    }
    if (qty <= 5) {
      return (sc.warning, 'Low: $qty', sc.warning);
    }
    return (sc.success, '$qty in stock', sc.success);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (pillBg, pillText, pillFg) = _stockBadge(context.status);

    return Card(
      clipBehavior: Clip.antiAlias,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withAlpha(60)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ItemImage(url: item.imageUrl, size: 60, radius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (item.barcode != null)
                      Text(
                        item.barcode!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.outline,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: pillBg.withAlpha(40),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        pillText,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: pillFg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.price == null ? '-' : item.price!.toStringAsFixed(2),
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800, color: cs.primary),
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
                itemBuilder: (context) => [
                  const PopupMenuItem(
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
                      leading: Icon(
                        Icons.delete_outline,
                        color: context.status.danger,
                      ),
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
