/// How healthy an item's stock is. "Low" matches the report's 1 to 5 units
/// (see branch_stock_report in supabase/schema/).
enum StockLevel {
  healthy,
  low,
  out,
  negative;

  static const lowThreshold = 5;

  static StockLevel of(int quantity) {
    if (quantity < 0) return StockLevel.negative;
    if (quantity == 0) return StockLevel.out;
    if (quantity <= lowThreshold) return StockLevel.low;
    return StockLevel.healthy;
  }

  String get label => switch (this) {
    StockLevel.healthy => 'In stock',
    StockLevel.low => 'Low stock',
    StockLevel.out => 'Out of stock',
    StockLevel.negative => 'Negative',
  };
}
