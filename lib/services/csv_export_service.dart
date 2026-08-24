import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/item.dart';

class CsvExportService {
  Future<File> buildCsvFile(List<Item> items) async {
    final rows = <List<dynamic>>[
      [
        'branch_name',
        'item_id',
        'name',
        'description',
        'price',
        'barcode',
        'image_url',
        'created_at',
      ],
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
        ],
    ];

    final csvContent = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[:\-]'), '')
        .split('.')
        .first
        .replaceFirst('T', '_');
    final file = File(
      '${directory.path}${Platform.pathSeparator}grocery_items_$timestamp.csv',
    );
    return file.writeAsString(csvContent);
  }

  Future<void> shareCsv(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Grocery items export',
      text: 'Attached: grocery items CSV (${file.uri.pathSegments.last})',
    );
  }
}
