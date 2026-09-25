import 'stock_movement.dart';

/// What the user wants to do from the stock sheet.
enum StockMode {
  receive('Stock in'),
  sell('Stock out'),
  damage('Damage'),

  /// Stock check: enter the counted quantity; the difference is recorded.
  count('Count');

  const StockMode(this.label);
  final String label;
}

/// The movement to record for a [StockMode] and the number entered.
class StockChange {
  final MovementType type;
  final int quantity;
  final String? autoNote;

  const StockChange(this.type, this.quantity, [this.autoNote]);

  /// Returns null when nothing would change (zero amount, or a count that
  /// matches the current stock).
  static StockChange? plan(StockMode mode, int current, int amount) {
    switch (mode) {
      case StockMode.receive:
        return amount > 0 ? StockChange(MovementType.inbound, amount) : null;
      case StockMode.sell:
        return amount > 0 ? StockChange(MovementType.outbound, amount) : null;
      case StockMode.damage:
        return amount > 0 ? StockChange(MovementType.damage, amount) : null;
      case StockMode.count:
        final delta = amount - current;
        if (delta == 0) return null;
        return StockChange(
          delta > 0 ? MovementType.inbound : MovementType.outbound,
          delta.abs(),
          'Stock count: $amount (was $current)',
        );
    }
  }

  /// Stock after this change is recorded.
  int applyTo(int current) => switch (type) {
    MovementType.inbound => current + quantity,
    _ => current - quantity,
  };
}
