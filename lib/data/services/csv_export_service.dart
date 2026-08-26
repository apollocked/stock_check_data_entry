import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/branch.dart';
import '../../domain/entities/item.dart';

class CsvExportService {
  static const _standardHeaders = [
    'branch_name',
    'item_id',
    'name',
    'description',
    'price',
    'barcode',
    'image_url',
    'created_at',
  ];

  Future<File> buildCsvFile(
    List<Item> items,
    List<BranchField> branchFields,
  ) async {
    final enabledCustom = branchFields
        .where(
          (f) =>
              f.enabled &&
              !const {
                'name',
                'price',
                'description',
                'barcode',
                'image_url',
              }.contains(f.id),
        )
        .toList();

    final headers = [..._standardHeaders, for (final f in enabledCustom) f.id];

    final rows = <List<dynamic>>[
      headers,
      for (final item in items)
        [
          item.branchName ?? '',
          item.id,
          item.name,
          item.description ?? '',
          item.price?.toStringAsFixed(2) ?? '',
          item.barcode ?? '',
          item.imageUrl ?? '',
          item.createdAt.toIso8601String(),
          for (final f in enabledCustom)
            item.customValue(f.id)?.toString() ?? '',
        ],
    ];
    final csvContent = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    return File(
      '${directory.path}${Platform.pathSeparator}grocery_items_${_timestamp(DateTime.now())}.csv',
    ).writeAsString(csvContent);
  }

  Future<void> share(File file) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Grocery items export'),
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
