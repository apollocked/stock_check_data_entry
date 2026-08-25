import 'package:cross_file/cross_file.dart';

import '../../core/error/app_exception.dart';
import '../../domain/entities/branch.dart';
import '../../domain/entities/item.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/image_storage_datasource.dart';
import '../datasources/inventory_remote_datasource.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDatasource _remote;
  final ImageStorageDatasource _storage;

  const InventoryRepositoryImpl(this._remote, this._storage);

  @override
  Future<List<Branch>> fetchBranches() async {
    try {
      final rows = await _remote.fetchBranches();
      return [for (final row in rows) Branch.fromMap(row)];
    } catch (e) {
      throw AppException(
        'Could not load branches: $e',
        AppExceptionType.network,
      );
    }
  }

  @override
  Future<Branch> createBranch({required String name, String? location}) async {
    try {
      final row = await _remote.createBranch(name: name, location: location);
      return Branch.fromMap(row);
    } catch (e) {
      throw AppException('Could not create branch: $e');
    }
  }

  @override
  Future<void> deleteBranch(int branchId) async {
    try {
      await _remote.deleteBranch(branchId);
    } catch (e) {
      throw AppException('Could not delete branch: $e');
    }
  }

  @override
  Future<String> uploadItemImage(XFile imageFile) async {
    try {
      return await _storage.upload(imageFile);
    } catch (e) {
      throw AppException('Image upload failed: $e', AppExceptionType.storage);
    }
  }

  @override
  Future<Item> insertItem({
    required int branchId,
    required String name,
    required double price,
    String? description,
    String? barcode,
    String? imageUrl,
  }) async {
    try {
      final row = await _remote.insertItem(
        branchId: branchId,
        name: name,
        price: price,
        description: description,
        barcode: barcode,
        imageUrl: imageUrl,
      );
      return Item.fromMap(row);
    } catch (e) {
      throw AppException('Could not save item: $e');
    }
  }

  @override
  Future<List<Item>> fetchItems({int? branchId}) async {
    try {
      final rows = await _remote.fetchItems(branchId: branchId);
      return [for (final row in rows) Item.fromMap(row)];
    } catch (e) {
      throw AppException('Could not load items: $e', AppExceptionType.network);
    }
  }

  @override
  Future<Item?> searchByBarcode({
    required int branchId,
    required String barcode,
  }) async {
    try {
      final row = await _remote.searchByBarcode(
        branchId: branchId,
        barcode: barcode,
      );
      return row == null ? null : Item.fromMap(row);
    } catch (e) {
      throw AppException('Barcode lookup failed: $e', AppExceptionType.network);
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
}
