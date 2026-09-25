import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/stock_level.dart';

extension StockLevelStyle on StockLevel {
  Color color(BuildContext context) => switch (this) {
    StockLevel.healthy => context.status.success,
    StockLevel.low => context.status.warning,
    StockLevel.out => context.status.neutral,
    StockLevel.negative => context.status.danger,
  };

  IconData get icon => switch (this) {
    StockLevel.healthy => Icons.check_circle_rounded,
    StockLevel.low => Icons.trending_down_rounded,
    StockLevel.out => Icons.remove_circle_outline_rounded,
    StockLevel.negative => Icons.error_rounded,
  };
}

/// A colored pill with the quantity, e.g. "24 in stock" or "Low · 3".
/// Animates when the quantity changes.
class StockBadge extends StatelessWidget {
  final int quantity;

  const StockBadge({super.key, required this.quantity});

  @override
  Widget build(BuildContext context) {
    final level = StockLevel.of(quantity);
    final color = level.color(context);
    final label = switch (level) {
      StockLevel.healthy => '${Fmt.count(quantity)} in stock',
      StockLevel.out => 'Out of stock',
      _ => '${level.label} · ${Fmt.count(quantity)}',
    };

    return AnimatedContainer(
      duration: Motion.medium,
      curve: Motion.emphasized,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(32),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(level.icon, size: 14, color: color),
          const SizedBox(width: Gap.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
