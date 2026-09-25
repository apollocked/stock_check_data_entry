import 'dart:io';

import 'package:csv/csv.dart';

import '../../core/security/spreadsheet_safety.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/store.dart';
import 'export_files.dart';

class CsvExportService {
  static const _standardHeaders = [
    'item_id',
    'name',
    'description',
    'price',
    'barcode',
    'image_url',
    'quantity',
    'created_at',
  ];

  /// Builds the CSV text. User-typed values are neutralized so the file
  /// cannot run formulas when opened in a spreadsheet app.
  String buildCsv(List<Item> items, List<ItemField> storeFields) {
    final enabledCustom = storeFields
        .where((f) => f.enabled && !kStandardFieldIds.contains(f.id))
        .toList();

    final headers = [..._standardHeaders, for (final f in enabledCustom) f.id];

    final rows = <List<dynamic>>[
      headers,
      for (final item in items)
        [
          item.id,
          neutralizeFormula(item.name),
          neutralizeFormula(item.description ?? ''),
          item.price?.toStringAsFixed(2) ?? '',
          neutralizeFormula(item.barcode ?? ''),
          item.imageUrl ?? '',
          item.quantity,
          item.createdAt.toIso8601String(),
          for (final f in enabledCustom)
            neutralizeFormula(item.customValue(f.id)?.toString() ?? ''),
        ],
    ];
    return const ListToCsvConverter().convert(rows);
  }

  Future<File> buildCsvFile(
    List<Item> items,
    List<ItemField> storeFields,
  ) async {
    final file = await exportFile('inventory', 'csv');
    return file.writeAsString(buildCsv(items, storeFields));
  }

  /// Opens the share sheet, then deletes the temporary file.
  Future<void> share(File file) =>
      shareAndDelete(file, text: 'Inventory export');
}
