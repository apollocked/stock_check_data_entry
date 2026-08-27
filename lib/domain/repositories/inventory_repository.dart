import 'package:cross_file/cross_file.dart';

import '../entities/branch.dart';
import '../entities/item.dart';
import '../entities/stock_movement.dart';
import '../entities/stock_report.dart';

abstract interface class InventoryRepository {
  Future<List<Branch>> fetchBranches();
  Future<Branch> createBranch({
    required String name,
    String? location,
    required List<BranchField> fields,
  });
  Future<Branch> updateBranch({
    required int branchId,
    required Map<String, dynamic> updates,
  });
  Future<void> deleteBranch(int branchId);

  Future<String> uploadItemImage(XFile imageFile, {String? barcode});

  Future<Item> insertItem({
    required int branchId,
    required String name,
    required double price,
    String? description,
    String? barcode,
    String? imageUrl,
    Map<String, dynamic>? customFields,
  });

  Future<List<Item>> fetchItems({int? branchId});
  Future<Item?> searchByBarcode({
    required int branchId,
    required String barcode,
  });
  Future<Item?> searchByBarcodeGlobal(String barcode);

  Future<void> copyItemToBranch({
    required Item sourceItem,
    required int targetBranchId,
  });

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
  Future<List<StockMovement>> fetchMovements({
    required int branchId,
    MovementType? type,
  });
  Future<StockReport> fetchStockReport(int branchId);
}
