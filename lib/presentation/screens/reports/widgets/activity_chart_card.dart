import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/daily_activity.dart';
import '../../../controllers/inventory_controllers.dart';
import '../../../widgets/common/surface_card.dart';
import '../../../widgets/states/skeleton.dart';
import 'chart_legend.dart';

/// Units in vs. out per day for the last two weeks, as paired bars.
class ActivityChartCard extends ConsumerWidget {
  const ActivityChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final days = ref.watch(activityProvider);
    final status = context.status;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last ${DailyActivity.window} days', style: text.titleMedium),
          const SizedBox(height: Gap.xs),
          ChartLegend(
            entries: [
              ('In', status.success),
              ('Out', status.info),
              ('Damage', status.danger),
            ],
          ),
          const SizedBox(height: Gap.lg),
          SizedBox(
            height: 180,
            child: days.when(
              loading: () => const SkeletonBox(height: 180, radius: Radii.md),
              error: (_, _) => Center(
                child: TextButton.icon(
                  onPressed: () => ref.invalidate(activityProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Couldn\'t load activity. Retry'),
                ),
              ),
              data: (days) => _Chart(days: days),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  final List<DailyActivity> days;

  const _Chart({required this.days});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = context.status;
    final label = Theme.of(context).textTheme.labelSmall;
    final radius = const BorderRadius.vertical(top: Radius.circular(6));

    return BarChart(
      duration: Motion.long,
      curve: Motion.emphasizedDecelerate,
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => cs.inverseSurface,
            getTooltipItem: (group, _, _, _) {
              final d = days[group.x];
              return BarTooltipItem(
                '${Fmt.shortDay(d.day)}\n+${d.inbound}  −${d.outbound + d.damage}',
                TextStyle(
                  color: cs.onInverseSurface,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                final show =
                    i == days.length - 1 || (days.length - 1 - i) % 3 == 0;
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    !show
                        ? ''
                        : (i == days.length - 1
                              ? 'Today'
                              : Fmt.weekday(days[i].day)),
                    style: label,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 2,
              barRods: [
                BarChartRodData(
                  toY: days[i].inbound.toDouble(),
                  width: 7,
                  color: status.success,
                  borderRadius: radius,
                ),
                BarChartRodData(
                  toY: (days[i].outbound + days[i].damage).toDouble(),
                  width: 7,
                  borderRadius: radius,
                  rodStackItems: [
                    BarChartRodStackItem(
                      0,
                      days[i].outbound.toDouble(),
                      status.info,
                    ),
                    BarChartRodStackItem(
                      days[i].outbound.toDouble(),
                      (days[i].outbound + days[i].damage).toDouble(),
                      status.danger,
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
