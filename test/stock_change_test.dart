import 'package:flutter_test/flutter_test.dart';
import 'package:stockly/domain/entities/stock_change.dart';
import 'package:stockly/domain/entities/stock_movement.dart';

void main() {
  test('in, out and damage record the amount entered', () {
    final receive = StockChange.plan(StockMode.receive, 10, 4)!;
    expect(receive.type, MovementType.inbound);
    expect(receive.applyTo(10), 14);

    final sell = StockChange.plan(StockMode.sell, 10, 3)!;
    expect(sell.type, MovementType.outbound);
    expect(sell.applyTo(10), 7);

    final damage = StockChange.plan(StockMode.damage, 1, 2)!;
    expect(damage.type, MovementType.damage);
    expect(damage.applyTo(1), -1);
  });

  test('zero amounts change nothing', () {
    expect(StockChange.plan(StockMode.receive, 5, 0), isNull);
    expect(StockChange.plan(StockMode.sell, 5, 0), isNull);
  });

  test('count records the difference with a note', () {
    final up = StockChange.plan(StockMode.count, 8, 11)!;
    expect(up.type, MovementType.inbound);
    expect(up.quantity, 3);
    expect(up.applyTo(8), 11);
    expect(up.autoNote, 'Stock count: 11 (was 8)');

    final down = StockChange.plan(StockMode.count, 8, 5)!;
    expect(down.type, MovementType.outbound);
    expect(down.quantity, 3);
    expect(down.applyTo(8), 5);

    final fromNegative = StockChange.plan(StockMode.count, -4, 0)!;
    expect(fromNegative.quantity, 4);
    expect(fromNegative.applyTo(-4), 0);

    expect(StockChange.plan(StockMode.count, 8, 8), isNull);
  });
}
