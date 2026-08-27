import 'package:flutter_test/flutter_test.dart';

import 'package:stock_check_entry/domain/entities/stock_movement.dart';
import 'package:stock_check_entry/domain/entities/stock_report.dart';

void main() {
  group('StockMovement', () {
    StockMovement build({required String type, required int quantity}) {
      return StockMovement.fromMap({
        'id': 1,
        'item_id': 2,
        'branch_id': 3,
        'movement_type': type,
        'quantity': quantity,
        'created_at': '2026-08-25T10:00:00.000Z',
      });
    }

    test('signedQuantity is positive for IN', () {
      expect(build(type: 'IN', quantity: 10).signedQuantity, 10);
    });

    test('signedQuantity is negative for OUT and DAMAGE', () {
      expect(build(type: 'OUT', quantity: 4).signedQuantity, -4);
      expect(build(type: 'DAMAGE', quantity: 2).signedQuantity, -2);
    });
  });

  group('StockReport', () {
    test('parses the three stock categories', () {
      final report = StockReport.fromMap({
        'total_items': 3,
        'total_units': 5,
        'stock_value': '15.50',
        'in_stock': 2,
        'zero_stock': 1,
        'minus_stock': 0,
        'low_stock': 1,
        'total_in': 10,
        'total_out': 3,
        'total_damage': 2,
      });
      expect(report.inStock, 2);
      expect(report.zeroStock, 1);
      expect(report.minusStock, 0);
      expect(report.stockValue, 15.50);
    });

    test('treats negative total_units', () {
      final report = StockReport.fromMap({'total_units': -3});
      expect(report.totalUnits, -3);
      expect(report.inStock, 0);
    });
  });
}
