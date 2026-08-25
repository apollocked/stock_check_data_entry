import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/item.dart';
import '../controllers/inventory_controllers.dart';
import '../providers/repository_providers.dart';

class ManagerExportScreen extends ConsumerStatefulWidget {
  const ManagerExportScreen({super.key});

  @override
  ConsumerState<ManagerExportScreen> createState() =>
      _ManagerExportScreenState();
}

class _ManagerExportScreenState extends ConsumerState<ManagerExportScreen> {
  int? _branchFilter;
  bool _exporting = false;

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final items = await ref.read(itemsProvider(_branchFilter).future);
      if (!mounted) return;
      if (items.isEmpty) {
        _showSnackBar('No items to export.');
        return;
      }
      final csvService = ref.read(csvExportServiceProvider);
      final file = await csvService.buildCsvFile(items);
      await csvService.share(file);
      if (!mounted) return;
      _showSnackBar('Exported ${items.length} items. Saved to: ${file.path}');
    } catch (e) {
      _showSnackBar('Export failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
          duration: const Duration(seconds: 6),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchesProvider);
    final itemsAsync = ref.watch(itemsProvider(_branchFilter));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: branchesAsync.maybeWhen(
                      data: (branches) => DropdownButtonFormField<int?>(
                        initialValue: _branchFilter,
                        decoration: const InputDecoration(
                          labelText: 'Filter by branch',
                          prefixIcon: Icon(Icons.filter_alt_outlined),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('All branches'),
                          ),
                          for (final branch in branches)
                            DropdownMenuItem<int?>(
                              value: branch.id,
                              child: Text(branch.name),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _branchFilter = value),
                      ),
                      orElse: () => const LinearProgressIndicator(),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    icon: const Icon(Icons.refresh),
                    onPressed: () => ref.invalidate(itemsProvider),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _exporting ? null : _exportCsv,
                  icon: _exporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share),
                  label: Text(_exporting ? 'Preparing CSV...' : 'Export CSV'),
                ),
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
                data: (items) => RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(itemsProvider);
                    await ref.read(itemsProvider(_branchFilter).future);
                  },
                  child: items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Icon(Icons.inventory_outlined, size: 56),
                            SizedBox(height: 12),
                            Center(child: Text('No items yet.')),
                          ],
                        )
                      : ListView.separated(
                          itemCount: items.length + 1,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            if (index == items.length) {
                              return Padding(
                                padding: const EdgeInsets.all(12),
                                child: Center(
                                  child: Text(
                                    '${items.length} item(s)',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                        ),
                                  ),
                                ),
                              );
                            }
                            final item = items[index];
                            return ListTile(
                              leading: item.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item.imageUrl!,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            const Icon(Icons.broken_image),
                                      ),
                                    )
                                  : CircleAvatar(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      child: const Icon(
                                        Icons.image_not_supported,
                                      ),
                                    ),
                              title: Text(item.name),
                              subtitle: Text(
                                '${item.branchName ?? 'Unknown branch'}'
                                '${item.barcode == null ? '' : '  •  ${item.barcode}'}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.price == null
                                        ? '-'
                                        : item.price!.toStringAsFixed(2),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                    ),
                                    onPressed: () => _confirmDelete(item),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
