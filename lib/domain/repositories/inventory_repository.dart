import 'package:cross_file/cross_file.dart';

import '../entities/item.dart';
import '../entities/stock_movement.dart';
import '../entities/stock_report.dart';
import '../entities/store.dart';

abstract interface class InventoryRepository {
  // ---- Store ----
  Future<Store> fetchStore();
  Future<Store> updateStore({
    required int storeId,
    required Map<String, dynamic> updates,
  });

  // ---- Items ----
  Future<String> uploadItemImage(XFile imageFile, {String? barcode});

  Future<Item> insertItem({
    required int storeId,
    required String name,
    required double price,
    String? description,
    String? barcode,
    String? imageUrl,
    Map<String, dynamic>? customFields,
  });

  Future<List<Item>> fetchItems();
  Future<Item?> searchByBarcode(String barcode);

  Future<Item> updateItem({
    required int itemId,
    required String name,
    required double price,
    String? description,
    String? imageUrl,
    Map<String, dynamic>? customFields,
  });

  Future<void> deleteItem(Item item);

  // ---- Stock management ----
  Future<int> recordMovement({
    required Item item,
    required MovementType type,
    required int quantity,
    String? note,
  });
  Future<List<StockMovement>> fetchMovements({MovementType? type});
  Future<StockReport> fetchStockReport(int storeId);
}
