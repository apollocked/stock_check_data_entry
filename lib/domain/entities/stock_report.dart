class StockReport {
  final int totalItems;
  final int totalUnits;
  final double stockValue;
  final int lowStock;
  final int outOfStock;
  final int totalIn;
  final int totalOut;
  final int totalDamage;

  const StockReport({
    required this.totalItems,
    required this.totalUnits,
    required this.stockValue,
    required this.lowStock,
    required this.outOfStock,
    required this.totalIn,
    required this.totalOut,
    required this.totalDamage,
  });

  factory StockReport.fromMap(Map<String, dynamic> map) {
    return StockReport(
      totalItems: (map['total_items'] as int?) ?? 0,
      totalUnits: (map['total_units'] as int?) ?? 0,
      stockValue: double.tryParse(map['stock_value']?.toString() ?? '') ?? 0,
      lowStock: (map['low_stock'] as int?) ?? 0,
      outOfStock: (map['out_of_stock'] as int?) ?? 0,
      totalIn: (map['total_in'] as int?) ?? 0,
      totalOut: (map['total_out'] as int?) ?? 0,
      totalDamage: (map['total_damage'] as int?) ?? 0,
    );
  }
}
