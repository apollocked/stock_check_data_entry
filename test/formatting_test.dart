import 'package:flutter_test/flutter_test.dart';
import 'package:stockly/core/utils/formatters.dart';
import 'package:stockly/domain/entities/stock_level.dart';

void main() {
  group('StockLevel.of', () {
    test('matches the report buckets', () {
      expect(StockLevel.of(-2), StockLevel.negative);
      expect(StockLevel.of(0), StockLevel.out);
      expect(StockLevel.of(1), StockLevel.low);
      expect(StockLevel.of(5), StockLevel.low);
      expect(StockLevel.of(6), StockLevel.healthy);
    });
  });

  group('Fmt', () {
    test('money has two decimals and a dash for no price', () {
      expect(Fmt.money(1234.5), '1,234.50');
      expect(Fmt.money(null), '—');
    });

    test('signed shows the direction', () {
      expect(Fmt.signed(5), '+5');
      expect(Fmt.signed(-3), '-3');
      expect(Fmt.signed(0), '0');
    });

    test('compact only shortens big numbers', () {
      expect(Fmt.compact(9999), '9,999');
      expect(Fmt.compact(12500), '12.5K');
    });

    test('relative time', () {
      final now = DateTime(2026, 9, 25, 15);
      expect(Fmt.relative(now, now: now), 'Just now');
      expect(
        Fmt.relative(now.subtract(const Duration(minutes: 5)), now: now),
        '5m ago',
      );
      expect(
        Fmt.relative(now.subtract(const Duration(hours: 3)), now: now),
        '3h ago',
      );
      expect(
        Fmt.relative(DateTime(2026, 9, 24, 9, 30), now: now),
        startsWith('Yesterday'),
      );
      expect(
        Fmt.relative(DateTime(2026, 9, 20, 9, 30), now: now),
        startsWith('Sep 20'),
      );
    });
  });
}
