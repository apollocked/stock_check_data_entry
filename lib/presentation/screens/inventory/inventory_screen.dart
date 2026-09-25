import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/export_controller.dart';
import '../../controllers/inventory_controllers.dart';
import '../../router/app_routes.dart';
import '../../widgets/common/export_button.dart';
import 'widgets/inventory_filter_bar.dart';
import 'widgets/inventory_list.dart';
import 'widgets/inventory_search_bar.dart';

/// The Inventory tab: a collapsing title with the store name, search,
/// filter chips and the item list. The add button shrinks while scrolling.
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  bool _fabExtended = true;

  bool _onScroll(UserScrollNotification n) {
    final extended = n.direction != ScrollDirection.reverse;
    if (n.direction != ScrollDirection.idle && extended != _fabExtended) {
      setState(() => _fabExtended = extended);
    }
    return false;
  }

  Future<void> _refresh() async {
    ref.invalidate(itemsProvider);
    await ref.read(itemsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final storeName = ref.watch(storeProvider).value?.name ?? 'Inventory';

    return Scaffold(
      body: NotificationListener<UserScrollNotification>(
        onNotification: _onScroll,
        child: RefreshIndicator(
          onRefresh: _refresh,
          edgeOffset: 120,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar.large(
                title: Text(storeName),
                actions: const [ExportButton(kind: ExportKind.csv)],
              ),
              const SliverToBoxAdapter(child: InventorySearchBar()),
              const SliverToBoxAdapter(child: InventoryFilterBar()),
              InventoryList(onAddItem: () => context.newItem()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.openScanner(),
        isExtended: _fabExtended,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Scan / add'),
      ),
    );
  }
}
