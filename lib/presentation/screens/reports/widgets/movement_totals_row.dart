import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/stock_movement.dart';
import '../../../../domain/entities/stock_report.dart';
import '../../../widgets/common/icon_tile.dart';
import '../../../widgets/common/surface_card.dart';
import '../../../widgets/motion/animated_number.dart';
import '../../../widgets/movement_tile.dart';

/// All-time units received, sold and damaged.
class MovementTotalsRow extends StatelessWidget {
  final StockReport report;

  const MovementTotalsRow({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final totals = [
      (MovementType.inbound, report.totalIn),
      (MovementType.outbound, report.totalOut),
      (MovementType.damage, report.totalDamage),
    ];
    return Row(
      children: [
        for (final (type, value) in totals) ...[
          if (type != MovementType.inbound) const SizedBox(width: Gap.sm),
          Expanded(
            child: _Tile(type: type, value: value),
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final MovementType type;
  final int value;

  const _Tile({required this.type, required this.value});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = type.color(context);
    return SurfaceCard(
      padding: const EdgeInsets.all(Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: type.icon, color: color, size: 36),
          const SizedBox(height: Gap.md),
          AnimatedNumber(
            value: value,
            format: Fmt.compact,
            style: text.titleLarge?.copyWith(color: color),
          ),
          Text(type.label, maxLines: 1, style: text.labelMedium),
        ],
      ),
    );
  }
}
