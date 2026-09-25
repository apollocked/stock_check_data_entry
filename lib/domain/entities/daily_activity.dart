import 'stock_movement.dart';

/// Units moved on one calendar day.
class DailyActivity {
  /// How many days the reports chart covers.
  static const window = 14;

  final DateTime day;
  final int inbound;
  final int outbound;
  final int damage;

  const DailyActivity({
    required this.day,
    this.inbound = 0,
    this.outbound = 0,
    this.damage = 0,
  });

  int get net => inbound - outbound - damage;

  /// Buckets [movements] into one entry per day, oldest first, ending today.
  /// Days without movements are included with zeros so the chart has no gaps.
  static List<DailyActivity> fromMovements(
    List<StockMovement> movements, {
    required DateTime today,
    int days = window,
  }) {
    final start = DateTime(today.year, today.month, today.day - days + 1);
    final totals = List.generate(days, (_) => [0, 0, 0]);
    for (final m in movements) {
      final local = m.createdAt.toLocal();
      final index = DateTime(
        local.year,
        local.month,
        local.day,
      ).difference(start).inDays;
      if (index < 0 || index >= days) continue;
      totals[index][m.type.index] += m.quantity;
    }
    return [
      for (var i = 0; i < days; i++)
        DailyActivity(
          day: DateTime(start.year, start.month, start.day + i),
          inbound: totals[i][MovementType.inbound.index],
          outbound: totals[i][MovementType.outbound.index],
          damage: totals[i][MovementType.damage.index],
        ),
    ];
  }
}
