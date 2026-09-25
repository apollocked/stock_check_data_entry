import 'package:flutter_test/flutter_test.dart';
import 'package:stockly/domain/entities/daily_activity.dart';
import 'package:stockly/domain/entities/stock_movement.dart';

StockMovement _move(MovementType type, int qty, DateTime at) => StockMovement(
  id: 0,
  itemId: 1,
  branchId: 1,
  type: type,
  quantity: qty,
  createdAt: at,
);

void main() {
  final today = DateTime(2026, 9, 25, 18);

  test('fills every day of the window, oldest first', () {
    final days = DailyActivity.fromMovements(const [], today: today);
    expect(days, hasLength(DailyActivity.window));
    expect(days.first.day, DateTime(2026, 9, 12));
    expect(days.last.day, DateTime(2026, 9, 25));
    expect(days.every((d) => d.net == 0), isTrue);
  });

  test('sums units per day and type', () {
    final days = DailyActivity.fromMovements([
      _move(MovementType.inbound, 10, DateTime(2026, 9, 25, 9)),
      _move(MovementType.inbound, 5, DateTime(2026, 9, 25, 11)),
      _move(MovementType.outbound, 4, DateTime(2026, 9, 25, 12)),
      _move(MovementType.damage, 1, DateTime(2026, 9, 24, 8)),
      _move(MovementType.outbound, 99, DateTime(2026, 9, 1)), // outside
    ], today: today);

    expect(days.last.inbound, 15);
    expect(days.last.outbound, 4);
    expect(days.last.net, 11);
    expect(days[days.length - 2].damage, 1);
    expect(days.fold<int>(0, (sum, d) => sum + d.outbound), 4);
  });
}
