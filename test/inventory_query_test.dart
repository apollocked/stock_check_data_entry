import 'package:flutter_test/flutter_test.dart';
import 'package:stockly/domain/entities/item.dart';
import 'package:stockly/domain/entities/stock_level.dart';
import 'package:stockly/presentation/controllers/inventory_query.dart';

Item _item(int id, String name, int qty, {double? price, String? barcode}) =>
    Item(
      id: id,
      branchId: 1,
      name: name,
      quantity: qty,
      price: price,
      barcode: barcode,
      createdAt: DateTime(2026, 1, id),
    );

void main() {
  final items = [
    _item(1, 'Milk', 12, price: 1.5, barcode: '5000112'),
    _item(2, 'bread', 3, price: 2),
    _item(3, 'Eggs', 0, price: 4),
    _item(4, 'Apples', -2, price: 0.5),
  ];

  List<String> names(InventoryQuery q) =>
      applyInventoryQuery(items, q).map((i) => i.name).toList();

  test('default sort is newest first', () {
    expect(names(const InventoryQuery()), ['Apples', 'Eggs', 'bread', 'Milk']);
  });

  test('search matches name case-insensitively and barcode', () {
    expect(names(const InventoryQuery(search: 'MILK')), ['Milk']);
    expect(names(const InventoryQuery(search: '0011')), ['Milk']);
    expect(names(const InventoryQuery(search: 'zzz')), isEmpty);
  });

  test('stock level filter', () {
    expect(names(const InventoryQuery(level: StockLevel.low)), ['bread']);
    expect(names(const InventoryQuery(level: StockLevel.out)), ['Eggs']);
    expect(names(const InventoryQuery(level: StockLevel.negative)), ['Apples']);
  });

  test('sort options', () {
    expect(names(const InventoryQuery(sort: InventorySort.name)), [
      'Apples',
      'bread',
      'Eggs',
      'Milk',
    ]);
    expect(
      names(const InventoryQuery(sort: InventorySort.quantity)).first,
      'Apples',
    );
    expect(
      names(const InventoryQuery(sort: InventorySort.value)).first,
      'Milk',
    );
  });

  test('countByLevel', () {
    final counts = countByLevel(items);
    expect(counts[StockLevel.healthy], 1);
    expect(counts[StockLevel.low], 1);
    expect(counts[StockLevel.out], 1);
    expect(counts[StockLevel.negative], 1);
  });
}
