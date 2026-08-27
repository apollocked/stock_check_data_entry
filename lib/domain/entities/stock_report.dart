class StockReport {
  final int totalItems;
  final int totalUnits;
  final double stockValue;
  final int inStock;
  final int zeroStock;
  final int minusStock;
  final int lowStock;
  final int totalIn;
  final int totalOut;
  final int totalDamage;

  const StockReport({
    required this.totalItems,
    required this.totalUnits,
    required this.stockValue,
    required this.inStock,
    required this.zeroStock,
    required this.minusStock,
    required this.lowStock,
    required this.totalIn,
    required this.totalOut,
    required this.totalDamage,
  });

  factory StockReport.fromMap(Map<String, dynamic> map) {
    return StockReport(
      totalItems: (map['total_items'] as int?) ?? 0,
      totalUnits: (map['total_units'] as int?) ?? 0,
      stockValue: double.tryParse(map['stock_value']?.toString() ?? '') ?? 0,
      inStock: (map['in_stock'] as int?) ?? 0,
      zeroStock: (map['zero_stock'] as int?) ?? 0,
      minusStock: (map['minus_stock'] as int?) ?? 0,
      lowStock: (map['low_stock'] as int?) ?? 0,
      totalIn: (map['total_in'] as int?) ?? 0,
      totalOut: (map['total_out'] as int?) ?? 0,
      totalDamage: (map['total_damage'] as int?) ?? 0,
    );
  }
}
