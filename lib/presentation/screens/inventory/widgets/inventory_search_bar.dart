import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../controllers/inventory_query.dart';
import '../../../router/app_routes.dart';

/// Pill search field with a clear button, sort menu and scanner shortcut.
class InventorySearchBar extends ConsumerStatefulWidget {
  const InventorySearchBar({super.key});

  @override
  ConsumerState<InventorySearchBar> createState() => _InventorySearchBarState();
}

class _InventorySearchBarState extends ConsumerState<InventorySearchBar> {
  late final _controller = TextEditingController(
    text: ref.read(inventoryQueryProvider).search,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _set(String value) {
    ref.read(inventoryQueryProvider.notifier).setSearch(value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sort = ref.watch(inventoryQueryProvider.select((q) => q.sort));
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xs, Gap.lg, Gap.sm),
      child: SearchBar(
        controller: _controller,
        hintText: 'Search name, barcode…',
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerHigh),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: Gap.lg),
        ),
        leading: const Icon(Icons.search_rounded),
        onChanged: _set,
        trailing: [
          if (_controller.text.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _controller.clear();
                _set('');
              },
            ),
          IconButton(
            tooltip: 'Scan a barcode',
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => context.openScanner(),
          ),
          PopupMenuButton<InventorySort>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort_rounded),
            initialValue: sort,
            onSelected: ref.read(inventoryQueryProvider.notifier).setSort,
            itemBuilder: (_) => [
              for (final option in InventorySort.values)
                CheckedPopupMenuItem(
                  value: option,
                  checked: option == sort,
                  child: Text(option.label),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
