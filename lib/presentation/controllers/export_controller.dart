import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/repository_providers.dart';
import 'inventory_controllers.dart';

enum ExportKind { csv, excel }

/// Builds and shares exports. The state is the export currently running, so
/// buttons can show a spinner and ignore double taps.
class ExportController extends Notifier<ExportKind?> {
  @override
  ExportKind? build() => null;

  /// Shares the inventory as CSV. Returns a short result message.
  Future<String> exportCsv() => _run(ExportKind.csv, () async {
    final items = await ref.read(itemsProvider.future);
    if (items.isEmpty) return 'No items to export yet.';
    final store = await ref.read(storeProvider.future);
    final service = ref.read(csvExportServiceProvider);
    await service.share(await service.buildCsvFile(items, store.fields));
    return 'Exported ${items.length} items.';
  });

  /// Shares the full Excel report (overview, inventory, movements).
  Future<String> exportExcel() => _run(ExportKind.excel, () async {
    final store = await ref.read(storeProvider.future);
    final items = await ref.read(itemsProvider.future);
    final movements = await ref.read(movementsProvider(null).future);
    final report = await ref.read(reportProvider.future);
    final service = ref.read(excelExportServiceProvider);
    final file = await service.buildWorkbook(
      store: store,
      items: items,
      movements: movements,
      report: report,
    );
    await service.share(file);
    return 'Excel report ready.';
  });

  Future<String> _run(ExportKind kind, Future<String> Function() body) async {
    if (state != null) return 'An export is already running.';
    state = kind;
    try {
      return await body();
    } finally {
      state = null;
    }
  }
}

final exportControllerProvider =
    NotifierProvider<ExportController, ExportKind?>(ExportController.new);
