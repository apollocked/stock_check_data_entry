import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/image_storage_datasource.dart';
import '../../data/datasources/inventory_remote_datasource.dart';
import '../../data/repositories/access_repository_impl.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../data/services/csv_export_service.dart';
import '../../data/services/excel_export_service.dart';
import '../../domain/repositories/access_repository.dart';
import '../../domain/repositories/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepositoryImpl(
    InventoryRemoteDatasource(),
    ImageStorageDatasource(),
  );
});

final csvExportServiceProvider = Provider<CsvExportService>((ref) {
  return CsvExportService();
});

final excelExportServiceProvider = Provider<ExcelExportService>((ref) {
  return ExcelExportService();
});

final accessRepositoryProvider = Provider<AccessRepository>((ref) {
  return AccessRepositoryImpl();
});
