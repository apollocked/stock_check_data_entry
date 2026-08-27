import 'package:cross_file/cross_file.dart';

import '../../core/error/app_exception.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/entities/stock_report.dart';
import '../../domain/entities/store.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/image_storage_datasource.dart';
import '../datasources/inventory_remote_datasource.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDatasource _remote;
  final ImageStorageDatasource _storage;

  const InventoryRepositoryImpl(this._remote, this._storage);

  @override
  Future<Store> fetchStore() async {
    try {
      final row = await _remote.fetchStore();
      return Store.fromMap(row);
    } catch (e) {
      throw AppException('Could not load store: $e', AppExceptionType.network);
    }
  }

  @override
  Future<Store> updateStore({
    required int storeId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final row = await _remote.updateStore(storeId: storeId, updates: updates);
      return Store.fromMap(row);
    } catch (e) {
      throw AppException('Could not update store: $e');
    }
  }

  @override
  Future<String> uploadItemImage(XFile imageFile, {String? barcode}) async {
    try {
      return await _storage.upload(imageFile, barcode: barcode);
    } catch (e) {
      throw AppException('Image upload failed: $e', AppExceptionType.storage);
    }
  }

  @override
  Future<Item> insertItem({
    required int storeId,
    required String name,
    required double price,
    String? description,
    String? barcode,
    String? imageUrl,
    Map<String, dynamic>? customFields,
  }) async {
    try {
      final row = await _remote.insertItem(
        storeId: storeId,
        name: name,
        price: price,
        description: description,
        barcode: barcode,
        imageUrl: imageUrl,
        customFields: customFields,
      );
      return Item.fromMap(row);
    } catch (e) {
      throw AppException('Could not save item: $e');
    }
  }

  @override
  Future<List<Item>> fetchItems() async {
    try {
      final rows = await _remote.fetchItems();
      return [for (final row in rows) Item.fromMap(row)];
    } catch (e) {
      throw AppException('Could not load items: $e', AppExceptionType.network);
    }
  }

  @override
  Future<Item?> searchByBarcode(String barcode) async {
    try {
      final row = await _remote.searchByBarcode(barcode);
      return row == null ? null : Item.fromMap(row);
    } catch (e) {
      throw AppException('Barcode lookup failed: $e', AppExceptionType.network);
    }
  }

  @override
  Future<Item> updateItem({
    required int itemId,
    required String name,
    required double price,
    String? description,
    String? imageUrl,
    Map<String, dynamic>? customFields,
  }) async {
    try {
      final row = await _remote.updateItem(
        itemId: itemId,
        updates: {
          'name': name,
          'price': price,
          'description': description,
          'image_url': imageUrl,
          'custom_fields': customFields ?? {},
        },
      );
      return Item.fromMap(row);
    } catch (e) {
      throw AppException('Could not update item: $e');
    }
  }

  @override
  Future<void> deleteItem(Item item) async {
    try {
      await _remote.deleteItem(item.id);
      await _storage.remove(item.imageUrl);
    } catch (e) {
      throw AppException('Could not delete item: $e');
    }
  }

  @override
  Future<int> recordMovement({
    required Item item,
    required MovementType type,
    required int quantity,
    String? note,
  }) async {
    try {
      return await _remote.recordMovement(
        itemId: item.id,
        movementType: type.code,
        quantity: quantity,
        note: note,
      );
    } catch (e) {
      throw AppException('Could not record movement: $e');
    }
  }

  @override
  Future<List<StockMovement>> fetchMovements({MovementType? type}) async {
    try {
      final rows = await _remote.fetchMovements(type: type?.code);
      return [for (final row in rows) StockMovement.fromMap(row)];
    } catch (e) {
      throw AppException(
        'Could not load movements: $e',
        AppExceptionType.network,
      );
    }
  }

  @override
  Future<StockReport> fetchStockReport(int storeId) async {
    try {
      final row = await _remote.fetchStockReport(storeId);
      return StockReport.fromMap(row);
    } catch (e) {
      throw AppException('Could not load report: $e', AppExceptionType.network);
    }
  }
}
