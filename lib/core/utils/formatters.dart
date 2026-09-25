import 'package:intl/intl.dart';

/// Number and date formatting in one place, following the device locale.
abstract final class Fmt {
  static final _money = NumberFormat.decimalPatternDigits(decimalDigits: 2);
  static final _compact = NumberFormat.compact();
  static final _int = NumberFormat.decimalPattern();

  /// 1,234.50 (the store's currency is not configured, so no symbol).
  static String money(num? value) => value == null ? '—' : _money.format(value);

  /// 1.2K, 3.4M — for tight spaces like stat tiles.
  static String compact(num value) =>
      value.abs() < 10000 ? _int.format(value) : _compact.format(value);

  static String count(num value) => _int.format(value);

  /// +5, -3, 0.
  static String signed(int value) => value > 0 ? '+$value' : '$value';

  static String day(DateTime d) => DateFormat.yMMMMd().format(d);
  static String shortDay(DateTime d) => DateFormat.MMMd().format(d);
  static String weekday(DateTime d) => DateFormat.E().format(d);
  static String time(DateTime d) => DateFormat.jm().format(d);

  /// "Just now", "5m ago", "3h ago", "Yesterday", then the date.
  static String relative(DateTime time, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final diff = current.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24 && current.day == time.day) {
      return '${diff.inHours}h ago';
    }
    final yesterday = DateTime(current.year, current.month, current.day - 1);
    if (!time.isBefore(yesterday)) return 'Yesterday, ${Fmt.time(time)}';
    return '${shortDay(time)}, ${Fmt.time(time)}';
  }
}
