import 'package:flutter_test/flutter_test.dart';

import 'package:stock_check_entry/domain/entities/item.dart';

void main() {
  group('Item.fromMap', () {
    test('parses numeric price returned as string', () {
      final item = Item.fromMap({
        'id': 1,
        'branch_id': 2,
        'name': 'Milk',
        'price': '9.99',
        'created_at': '2026-08-25T10:00:00.000Z',
      });
      expect(item.price, 9.99);
      expect(item.branchName, isNull);
    });

    test('parses embedded branch name and nullable fields', () {
      final item = Item.fromMap({
        'id': 3,
        'branch_id': 4,
        'name': 'Rice',
        'branches': {'name': 'Downtown'},
        'description': null,
        'price': null,
        'barcode': '123456789',
        'image_url': null,
        'created_at': '2026-08-25T10:00:00.000Z',
      });
      expect(item.branchName, 'Downtown');
      expect(item.price, isNull);
      expect(item.barcode, '123456789');
    });
  });
}
