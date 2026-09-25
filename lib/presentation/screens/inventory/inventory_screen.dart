import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/export_controller.dart';
import '../../controllers/inventory_controllers.dart';
import '../../router/app_routes.dart';
import '../../widgets/common/export_button.dart';
import 'inventory_tab.dart';

/// The Inventory tab: store name, CSV export, the item list and the scan /
/// add button.
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeName = ref.watch(storeProvider).value?.name ?? 'Inventory';

    return Scaffold(
      appBar: AppBar(
        title: Text(storeName),
        actions: const [ExportButton(kind: ExportKind.csv)],
      ),
      body: const InventoryTab(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.openScanner(),
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Scan / add'),
      ),
    );
  }
}
