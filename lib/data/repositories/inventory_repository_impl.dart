import 'package:cross_file/cross_file.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/error_messages.dart';
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

  /// Runs [body] and turns any failure into an [AppException] with a
  /// user-friendly message.
  Future<T> _guard<T>(
    Future<T> Function() body,
    String fallback, [
    AppExceptionType type = AppExceptionType.database,
  ]) async {
    try {
      return await body();
    } catch (e) {
      throw toAppException(e, fallback, type);
    }
  }

  static const _read = AppExceptionType.network;

  @override
  Future<Store> fetchStore() => _guard(
    () async => Store.fromMap(await _remote.fetchStore()),
    'Could not load store.',
    _read,
  );

  @override
  Future<Store> updateStore({
    required int storeId,
    required Map<String, dynamic> updates,
  }) => _guard(
    () async => Store.fromMap(
      await _remote.updateStore(storeId: storeId, updates: updates),
    ),
    'Could not update store.',
  );

  @override
  Future<String> uploadItemImage(XFile imageFile) => _guard(
    () => _storage.upload(imageFile),
    'Image upload failed.',
    AppExceptionType.storage,
  );

  @override
  Future<Item> insertItem({
    required int storeId,
    required String name,
    required double price,
    String? description,
    String? barcode,
    String? imageUrl,
    Map<String, dynamic>? customFields,
  }) => _guard(
    () async => Item.fromMap(
      await _remote.insertItem(
        storeId: storeId,
        name: name,
        price: price,
        description: description,
        barcode: barcode,
        imageUrl: imageUrl,
        customFields: customFields,
      ),
    ),
    'Could not save item.',
  );

  @override
  Future<List<Item>> fetchItems() => _guard(
    () async => [
      for (final row in await _remote.fetchItems()) Item.fromMap(row),
    ],
    'Could not load items.',
    _read,
  );

  @override
  Future<Item?> fetchItem(int itemId) => _guard(
    () async {
      final row = await _remote.fetchItem(itemId);
      return row == null ? null : Item.fromMap(row);
    },
    'Could not load the item.',
    _read,
  );

  @override
  Future<Item?> searchByBarcode(String barcode) => _guard(
    () async {
      final row = await _remote.searchByBarcode(barcode);
      return row == null ? null : Item.fromMap(row);
    },
    'Barcode lookup failed.',
    _read,
  );

  @override
  Future<Item> updateItem({
    required int itemId,
    required String name,
    required double price,
    String? description,
    String? barcode,
    String? imageUrl,
    Map<String, dynamic>? customFields,
  }) => _guard(
    () async => Item.fromMap(
      await _remote.updateItem(
        itemId: itemId,
        updates: {
          'name': name,
          'price': price,
          'description': description,
          'barcode': barcode,
          'image_url': imageUrl,
          'custom_fields': customFields ?? {},
        },
      ),
    ),
    'Could not update item.',
  );

  @override
  Future<void> deleteItem(Item item) => _guard(() async {
    await _remote.deleteItem(item.id);
    await _storage.remove(item.imageUrl);
  }, 'Could not delete item.');

  @override
  Future<int> recordMovement({
    required Item item,
    required MovementType type,
    required int quantity,
    String? note,
  }) => _guard(
    () => _remote.recordMovement(
      itemId: item.id,
      movementType: type.code,
      quantity: quantity,
      note: note,
    ),
    'Could not record movement.',
  );

  @override
  Future<List<StockMovement>> fetchMovements({
    MovementType? type,
    DateTime? day,
    int? itemId,
    DateTime? since,
    int limit = 500,
  }) => _guard(
    () async => [
      for (final row in await _remote.fetchMovements(
        type: type?.code,
        day: day,
        itemId: itemId,
        since: since,
        limit: limit,
      ))
        StockMovement.fromMap(row),
    ],
    'Could not load movements.',
    _read,
  );

  @override
  Future<StockReport> fetchStockReport(int storeId) => _guard(
    () async => StockReport.fromMap(await _remote.fetchStockReport(storeId)),
    'Could not load report.',
    _read,
  );
}
