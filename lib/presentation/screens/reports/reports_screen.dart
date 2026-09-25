import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../controllers/export_controller.dart';
import '../../controllers/inventory_controllers.dart';
import '../../widgets/common/export_button.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/motion/entrance.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/skeleton.dart';
import 'widgets/activity_chart_card.dart';
import 'widgets/attention_list.dart';
import 'widgets/movement_totals_row.dart';
import 'widgets/recent_movements.dart';
import 'widgets/stock_health_card.dart';
import 'widgets/value_hero_card.dart';

/// The Reports tab: a dashboard of stock value, activity, health, items
/// needing attention and recent movements, plus the Excel export.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(reportProvider);
    ref.invalidate(activityProvider);
    ref.invalidate(movementsProvider);
    ref.invalidate(itemsProvider);
    await ref.read(reportProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        edgeOffset: 120,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: const Text('Reports'),
              actions: const [ExportButton(kind: ExportKind.excel)],
            ),
            report.when(
              skipLoadingOnRefresh: true,
              loading: () => const SliverToBoxAdapter(
                child: SkeletonList(count: 4, itemHeight: 140),
              ),
              error: (error, _) => SliverFillRemaining(
                child: ErrorState(
                  error: error,
                  title: 'Couldn\'t load the report',
                  onRetry: () => ref.invalidate(reportProvider),
                ),
              ),
              data: (report) {
                final sections = [
                  ValueHeroCard(report: report),
                  const ActivityChartCard(),
                  StockHealthCard(report: report),
                  const SectionHeader('All-time movements'),
                  MovementTotalsRow(report: report),
                  const AttentionList(),
                  const RecentMovements(),
                ];
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Gap.lg,
                    0,
                    Gap.lg,
                    Gap.xxl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: sections.length,
                    separatorBuilder: (_, _) => const SizedBox(height: Gap.md),
                    itemBuilder: (_, i) => sections[i].entrance(index: i),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
