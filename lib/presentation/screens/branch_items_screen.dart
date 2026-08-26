import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/branch.dart';
import '../../domain/entities/item.dart';
import '../controllers/inventory_controllers.dart';
import '../providers/repository_providers.dart';
import 'barcode_lookup_screen.dart';
import 'new_item_form_screen.dart';

class BranchItemsScreen extends ConsumerStatefulWidget {
  final int branchId;
  final String branchName;

  const BranchItemsScreen({
    super.key,
    required this.branchId,
    required this.branchName,
  });

  @override
  ConsumerState<BranchItemsScreen> createState() => _BranchItemsScreenState();
}

class _BranchItemsScreenState extends ConsumerState<BranchItemsScreen> {
  bool _exporting = false;
  String _searchQuery = '';

  Branch? _branch;

  @override
  void initState() {
    super.initState();
    _loadBranch();
  }

  void _loadBranch() {
    final branches = ref.read(branchesProvider).valueOrNull;
    if (branches != null) {
      _branch = branches.where((b) => b.id == widget.branchId).firstOrNull;
    }
  }

  List<BranchField> get _branchFields => _branch?.fields ?? const [];

  Future<void> _exportCsv(List<Item> items) async {
    setState(() => _exporting = true);
    try {
      if (items.isEmpty) {
        _showSnackBar('No items to export.');
        return;
      }
      final csvService = ref.read(csvExportServiceProvider);
      final file = await csvService.buildCsvFile(items, _branchFields);
      await csvService.share(file);
      if (mounted) {
        _showSnackBar('Exported ${items.length} items. Saved to: ${file.path}');
      }
    } catch (e) {
      _showSnackBar('Export failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
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

  Future<void> _editItem(Item item) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ItemFormScreen(
          branchId: widget.branchId,
          barcode: item.barcode ?? '',
          existingItem: item,
          branchFields: _branchFields,
        ),
      ),
    );
    if (updated == true) ref.invalidate(itemsProvider);
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
    final itemsAsync = ref.watch(itemsProvider(widget.branchId));

    // Re-check branch when branches reload
    ref.listen(branchesProvider, (_, next) {
      next.whenData((branches) {
        final b = branches.where((b) => b.id == widget.branchId).firstOrNull;
        if (b != null && b != _branch) setState(() => _branch = b);
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.branchName),
        actions: [
          if (_exporting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: 'Export CSV',
              icon: const Icon(Icons.ios_share),
              onPressed: itemsAsync.hasValue
                  ? () => _exportCsv(itemsAsync.value!)
                  : null,
            ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(itemsProvider),
          ),
        ],
      ),
      body: Column(
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
                                i.name
                                    .toLowerCase()
                                    .contains(_searchQuery.toLowerCase()) ||
                                (i.barcode?.contains(_searchQuery) ?? false),
                          )
                          .toList();
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(itemsProvider);
                    await ref.read(itemsProvider(widget.branchId).future);
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
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return _ItemCard(
                              item: item,
                              branchFields: _branchFields,
                              onTap: () => _editItem(item),
                              onDelete: () => _confirmDelete(item),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BarcodeLookupScreen(
                branchId: widget.branchId,
                branchName: widget.branchName,
                branchFields: _branchFields,
              ),
            ),
          );
          ref.invalidate(itemsProvider);
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Add item'),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Item item;
  final List<BranchField> branchFields;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.item,
    required this.branchFields,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Get optional field values for display
    final optionalFields = branchFields
        .where((f) =>
            f.enabled &&
            !const {'name', 'price', 'description', 'barcode', 'image_url'}
                .contains(f.id))
        .toList();

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
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
                    for (final f in optionalFields)
                      _customFieldChip(item, f, context),
                    if (item.barcode != null)
                      Text(
                        item.barcode!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.outline),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.price == null ? '-' : item.price!.toStringAsFixed(2),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customFieldChip(Item item, BranchField field, BuildContext context) {
    final val = item.customValue(field.id);
    if (val == null || val.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        '${field.label}: $val',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
      ),
    );
  }
}
