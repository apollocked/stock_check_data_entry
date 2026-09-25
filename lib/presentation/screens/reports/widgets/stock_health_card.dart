import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../domain/entities/stock_level.dart';
import '../../../../domain/entities/stock_report.dart';
import '../../../widgets/common/stock_badge.dart';
import '../../../widgets/common/surface_card.dart';
import 'chart_legend.dart';

/// One bar split by stock level, growing in from the left, with counts.
class StockHealthCard extends StatelessWidget {
  final StockReport report;

  const StockHealthCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final healthy = report.inStock - report.lowStock;
    final parts = [
      (StockLevel.healthy, healthy),
      (StockLevel.low, report.lowStock),
      (StockLevel.out, report.zeroStock),
      (StockLevel.negative, report.minusStock),
    ];
    final total = parts.fold<int>(0, (sum, p) => sum + p.$2);

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stock health', style: text.titleMedium),
          const SizedBox(height: Gap.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.pill),
            child: SizedBox(
              height: 14,
              child: total == 0
                  ? ColoredBox(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                    )
                  : TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Motion.long * 2,
                      curve: Motion.emphasizedDecelerate,
                      builder: (context, t, _) => Row(
                        children: [
                          for (final (level, count) in parts)
                            if (count > 0)
                              Expanded(
                                flex: (count * 1000 * t).round().clamp(
                                  1,
                                  1 << 30,
                                ),
                                child: ColoredBox(color: level.color(context)),
                              ),
                          Expanded(
                            flex: (total * 1000 * (1 - t)).round(),
                            child: const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: Gap.md),
          ChartLegend(
            entries: [
              for (final (level, count) in parts)
                ('${level.label} $count', level.color(context)),
            ],
          ),
        ],
      ),
    );
  }
}
