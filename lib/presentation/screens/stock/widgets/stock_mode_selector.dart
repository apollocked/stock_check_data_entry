import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/stock_change.dart';

extension StockModeStyle on StockMode {
  Color color(BuildContext context) => switch (this) {
    StockMode.receive => context.status.success,
    StockMode.sell => context.status.info,
    StockMode.damage => context.status.danger,
    StockMode.count => Theme.of(context).colorScheme.primary,
  };

  IconData get icon => switch (this) {
    StockMode.receive => Icons.add_box_rounded,
    StockMode.sell => Icons.shopping_bag_rounded,
    StockMode.damage => Icons.broken_image_rounded,
    StockMode.count => Icons.fact_check_rounded,
  };

  String get shortLabel => switch (this) {
    StockMode.receive => 'In',
    StockMode.sell => 'Out',
    StockMode.damage => 'Damage',
    StockMode.count => 'Count',
  };
}

/// In / Out / Damage / Count, tinted with the selected mode's color.
class StockModeSelector extends StatelessWidget {
  final StockMode mode;
  final ValueChanged<StockMode> onChanged;

  const StockModeSelector({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = mode.color(context);
    return SegmentedButton<StockMode>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: color.withAlpha(40),
        selectedForegroundColor: color,
        padding: EdgeInsets.zero,
      ),
      segments: [
        for (final m in StockMode.values)
          ButtonSegment(
            value: m,
            icon: Icon(m.icon, size: 18),
            label: Text(m.shortLabel),
          ),
      ],
      selected: {mode},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
