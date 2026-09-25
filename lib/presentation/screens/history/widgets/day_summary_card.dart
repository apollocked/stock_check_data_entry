import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/daily_activity.dart';
import '../../../../domain/entities/stock_movement.dart';
import '../../../widgets/common/surface_card.dart';
import '../../../widgets/motion/animated_number.dart';
import '../../../widgets/movement_tile.dart';

/// Totals for the selected day: in, out, damage and the net change.
class DaySummaryCard extends StatelessWidget {
  final DateTime day;
  final List<StockMovement> movements;

  const DaySummaryCard({super.key, required this.day, required this.movements});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final totals = DailyActivity.fromMovements(
      movements,
      today: day,
      days: 1,
    ).single;
    final netColor = totals.net < 0
        ? context.status.danger
        : context.status.success;

    Widget cell(String label, int value, Color color) => Expanded(
      child: Column(
        children: [
          AnimatedNumber(
            value: value,
            format: (v) => Fmt.signed(v.toInt()),
            style: text.titleLarge?.copyWith(color: color),
          ),
          Text(label, style: text.labelMedium),
        ],
      ),
    );

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Fmt.day(day), style: text.titleMedium),
          Text(
            '${movements.length} movement${movements.length == 1 ? '' : 's'}',
            style: text.bodySmall,
          ),
          const SizedBox(height: Gap.lg),
          Row(
            children: [
              cell('In', totals.inbound, MovementType.inbound.color(context)),
              cell(
                'Out',
                -totals.outbound,
                MovementType.outbound.color(context),
              ),
              cell(
                'Damage',
                -totals.damage,
                MovementType.damage.color(context),
              ),
              cell('Net', totals.net, netColor),
            ],
          ),
        ],
      ),
    );
  }
}
