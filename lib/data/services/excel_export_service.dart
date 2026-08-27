import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/item.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/entities/stock_report.dart';
import '../../domain/entities/store.dart';

class ExcelExportService {
  Future<File> buildWorkbook({
    required Store store,
    required List<Item> items,
    required List<StockMovement> movements,
    required StockReport report,
  }) async {
    final excel = Excel.createExcel();

    final overview = excel['Overview'];
    overview.appendRow([TextCellValue('Store'), TextCellValue(store.name)]);
    overview.appendRow([
      TextCellValue('Location'),
      TextCellValue(store.location ?? ''),
    ]);
    overview.appendRow([
      TextCellValue('Generated at'),
      TextCellValue(_timestamp(DateTime.now())),
    ]);
    overview.appendRow([
      TextCellValue('Total items'),
      IntCellValue(report.totalItems),
    ]);
    overview.appendRow([
      TextCellValue('Total units'),
      IntCellValue(report.totalUnits),
    ]);
    overview.appendRow([
      TextCellValue('Stock value'),
      DoubleCellValue(report.stockValue),
    ]);
    overview.appendRow([
      TextCellValue('In stock (>0)'),
      IntCellValue(report.inStock),
    ]);
    overview.appendRow([
      TextCellValue('Zero stock (=0)'),
      IntCellValue(report.zeroStock),
    ]);
    overview.appendRow([
      TextCellValue('Minus stock (<0)'),
      IntCellValue(report.minusStock),
    ]);
    overview.appendRow([
      TextCellValue('Low stock (≤5)'),
      IntCellValue(report.lowStock),
    ]);
    overview.appendRow([
      TextCellValue('Total stock in'),
      IntCellValue(report.totalIn),
    ]);
    overview.appendRow([
      TextCellValue('Total stock out'),
      IntCellValue(report.totalOut),
    ]);
    overview.appendRow([
      TextCellValue('Total damage'),
      IntCellValue(report.totalDamage),
    ]);

    final inventory = excel['Inventory'];
    final enabledCustom = store.fields
        .where((f) => f.enabled && !kStandardFieldIds.contains(f.id))
        .toList();
    inventory.appendRow([
      for (final header in [
        'item_id',
        'name',
        'description',
        'price',
        'barcode',
        'quantity',
        'status',
        'image_url',
        'created_at',
        for (final f in enabledCustom) f.id,
      ])
        TextCellValue(header),
    ]);
    for (final item in items) {
      final status = item.quantity > 0
          ? 'In stock'
          : item.quantity == 0
          ? 'Zero'
          : 'Minus stock';
      inventory.appendRow([
        IntCellValue(item.id),
        TextCellValue(item.name),
        TextCellValue(item.description ?? ''),
        DoubleCellValue(item.price ?? 0),
        TextCellValue(item.barcode ?? ''),
        IntCellValue(item.quantity),
        TextCellValue(status),
        TextCellValue(item.imageUrl ?? ''),
        TextCellValue(item.createdAt.toIso8601String()),
        for (final f in enabledCustom)
          TextCellValue(item.customValue(f.id)?.toString() ?? ''),
      ]);
    }

    final movementsSheet = excel['Movements'];
    movementsSheet.appendRow([
      for (final header in [
        'created_at',
        'item',
        'type',
        'quantity',
        'signed',
        'note',
        'user',
      ])
        TextCellValue(header),
    ]);
    for (final m in movements) {
      movementsSheet.appendRow([
        TextCellValue(m.createdAt.toIso8601String()),
        TextCellValue(m.itemName ?? 'Item #${m.itemId}'),
        TextCellValue(m.type.code),
        IntCellValue(m.quantity),
        IntCellValue(m.signedQuantity),
        TextCellValue(m.note ?? ''),
        TextCellValue(m.userEmail ?? ''),
      ]);
    }

    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Could not encode Excel workbook');
    }
    final directory = await getApplicationDocumentsDirectory();
    return File(
      '${directory.path}${Platform.pathSeparator}'
      'inventory_report_${_timestamp(DateTime.now())}.xlsx',
    ).writeAsBytes(bytes);
  }

  Future<void> share(File file) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Inventory report'),
    );
  }

  String _timestamp(DateTime time) {
    final y = time.year.toString().padLeft(4, '0');
    final m = time.month.toString().padLeft(2, '0');
    final d = time.day.toString().padLeft(2, '0');
    final h = time.hour.toString().padLeft(2, '0');
    final min = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$y$m${d}_$h$min$s';
  }
}
