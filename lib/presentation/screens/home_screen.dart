import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/item.dart';
import '../controllers/auth_controllers.dart';
import '../controllers/inventory_controllers.dart';
import '../providers/repository_providers.dart';
import 'barcode_lookup_screen.dart';
import 'calendar_history_screen.dart';
import 'item_fields_screen.dart';
import 'inventory_tab.dart';
import 'reports_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tabIndex = 0;
  bool _exporting = false;

  Future<void> _exportCsv(List<Item> items) async {
    if (items.isEmpty) {
      _showSnackBar('No items to export.');
      return;
    }
    setState(() => _exporting = true);
    try {
      final store = ref.read(storeProvider).value;
      final csvService = ref.read(csvExportServiceProvider);
      final file = await csvService.buildCsvFile(
        items,
        store?.fields ?? const [],
      );
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

  Future<void> _exportExcel() async {
    setState(() => _exporting = true);
    try {
      final store = ref.read(storeProvider).value;
      if (store == null) throw StateError('Store is not loaded');
      final items = await ref.read(itemsProvider.future);
      final movements = await ref.read(movementsProvider(null).future);
      final report = await ref.read(reportProvider.future);
      final excelService = ref.read(excelExportServiceProvider);
      final file = await excelService.buildWorkbook(
        store: store,
        items: items,
        movements: movements,
        report: report,
      );
      await excelService.share(file);
      if (mounted) {
        _showSnackBar('Excel report saved to: ${file.path}');
      }
    } catch (e) {
      _showSnackBar('Excel export failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _openHistory() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CalendarHistoryScreen()));
    if (mounted) ref.invalidate(dayMovementsProvider);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await Supabase.instance.client.auth.signOut();
    } finally {
      ref.invalidate(itemsProvider);
      ref.invalidate(movementsProvider);
      ref.invalidate(reportProvider);
      ref.invalidate(storeProvider);
      ref.invalidate(sessionStateProvider);
    }
  }

  Future<void> _addItem() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const BarcodeLookupScreen()));
    if (mounted) ref.invalidate(itemsProvider);
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
    final storeAsync = ref.watch(storeProvider);
    final items = ref.watch(itemsProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: storeAsync.maybeWhen(
          data: (store) => Text(store.name),
          orElse: () => const Text('Inventory Manager'),
        ),
        actions: [
          if (_tabIndex == 0)
            IconButton(
              tooltip: 'Export CSV',
              icon: _exporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share),
              onPressed: items == null || _exporting
                  ? null
                  : () => _exportCsv(items),
            ),
          if (_tabIndex == 1)
            IconButton(
              tooltip: 'Export Excel report',
              icon: _exporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.grid_on),
              onPressed: _exporting ? null : _exportExcel,
            ),
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.calendar_month),
            onPressed: _openHistory,
          ),
          IconButton(
            tooltip: 'Item fields',
            icon: const Icon(Icons.tune),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ItemFieldsScreen()),
              );
              if (mounted) ref.invalidate(storeProvider);
            },
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: storeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load store: $error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(storeProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (_) => IndexedStack(
          index: _tabIndex,
          children: const [InventoryTab(), ReportsTab()],
        ),
      ),
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _addItem,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Add item'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
