import 'package:cross_file/cross_file.dart';
import 'package:stockly/domain/entities/item.dart';
import 'package:stockly/domain/entities/stock_movement.dart';
import 'package:stockly/domain/entities/stock_report.dart';
import 'package:stockly/domain/entities/store.dart';
import 'package:stockly/domain/repositories/inventory_repository.dart';

/// In-memory repository for widget tests.
class FakeInventoryRepository implements InventoryRepository {
  final store = Store(id: 1, name: 'Corner Shop', fields: defaultValueFields());

  final items = [
    Item(
      id: 1,
      branchId: 1,
      name: 'Oat milk',
      price: 2.5,
      barcode: '5000112',
      quantity: 24,
      createdAt: DateTime(2026, 9, 1),
    ),
    Item(
      id: 2,
      branchId: 1,
      name: 'Sourdough',
      price: 4,
      quantity: 2,
      createdAt: DateTime(2026, 9, 2),
    ),
    Item(
      id: 3,
      branchId: 1,
      name: 'Eggs',
      price: 3.2,
      quantity: 0,
      createdAt: DateTime(2026, 9, 3),
    ),
  ];

  late final movements = [
    StockMovement(
      id: 1,
      itemId: 1,
      branchId: 1,
      type: MovementType.inbound,
      quantity: 30,
      itemName: 'Oat milk',
      userEmail: 'sam@example.com',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    StockMovement(
      id: 2,
      itemId: 1,
      branchId: 1,
      type: MovementType.outbound,
      quantity: 6,
      note: 'Weekend sale',
      itemName: 'Oat milk',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<Store> fetchStore() async => store;

  @override
  Future<List<Item>> fetchItems() async => items;

  @override
  Future<Item?> fetchItem(int itemId) async =>
      items.where((i) => i.id == itemId).firstOrNull;

  @override
  Future<Item?> searchByBarcode(String barcode) async =>
      items.where((i) => i.barcode == barcode).firstOrNull;

  @override
  Future<List<StockMovement>> fetchMovements({
    MovementType? type,
    DateTime? day,
    int? itemId,
    DateTime? since,
    int limit = 500,
  }) async => movements
      .where((m) => type == null || m.type == type)
      .where((m) => itemId == null || m.itemId == itemId)
      .toList();

  @override
  Future<StockReport> fetchStockReport(int storeId) async => const StockReport(
    totalItems: 3,
    totalUnits: 26,
    stockValue: 68,
    inStock: 2,
    zeroStock: 1,
    minusStock: 0,
    lowStock: 1,
    totalIn: 30,
    totalOut: 6,
    totalDamage: 0,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');

  @override
  Future<String> uploadItemImage(XFile imageFile) => throw UnimplementedError();
}
