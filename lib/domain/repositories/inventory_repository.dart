import 'package:cross_file/cross_file.dart';

import '../entities/branch.dart';
import '../entities/item.dart';

abstract interface class InventoryRepository {
  Future<List<Branch>> fetchBranches();
  Future<Branch> createBranch({required String name, String? location});
  Future<void> deleteBranch(int branchId);

  Future<String> uploadItemImage(XFile imageFile, {String? barcode});

  Future<Item> insertItem({
    required int branchId,
    required String name,
    required double price,
    String? description,
    String? barcode,
    String? imageUrl,
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
  });

  Future<void> deleteItem(Item item);
}
