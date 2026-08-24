import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/image_storage_datasource.dart';
import '../../data/datasources/inventory_remote_datasource.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../data/services/csv_export_service.dart';
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
