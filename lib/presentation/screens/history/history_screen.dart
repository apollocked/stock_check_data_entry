import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../controllers/inventory_controllers.dart';
import '../../widgets/motion/entrance.dart';
import '../../widgets/movement_tile.dart';
import '../../widgets/states/empty_state.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/skeleton.dart';
import 'widgets/day_strip.dart';
import 'widgets/day_summary_card.dart';

/// The History tab: pick a day, see its totals and every movement.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late DateTime _day = _today;

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(_today.year - 2),
      lastDate: _today,
    );
    if (picked != null) setState(() => _day = picked);
  }

  @override
  Widget build(BuildContext context) {
    final key = (_day, null);
    final movements = ref.watch(dayMovementsProvider(key));

    return Scaffold(
      body: RefreshIndicator(
        edgeOffset: 120,
        onRefresh: () async {
          ref.invalidate(dayMovementsProvider(key));
          await ref.read(dayMovementsProvider(key).future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: const Text('History'),
              actions: [
                IconButton(
                  tooltip: 'Pick a date',
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month_rounded),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: DayStrip(
                selected: _day,
                onSelect: (d) => setState(() => _day = d),
              ),
            ),
            ...movements.when(
              loading: () => const [
                SliverToBoxAdapter(
                  child: SkeletonList(count: 4, itemHeight: 72),
                ),
              ],
              error: (error, _) => [
                SliverFillRemaining(
                  child: ErrorState(
                    error: error,
                    onRetry: () => ref.invalidate(dayMovementsProvider(key)),
                  ),
                ),
              ],
              data: (list) => [
                SliverPadding(
                  padding: const EdgeInsets.all(Gap.lg),
                  sliver: SliverToBoxAdapter(
                    child: DaySummaryCard(
                      day: _day,
                      movements: list,
                    ).entrance(),
                  ),
                ),
                if (list.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.event_available_rounded,
                      title: 'A quiet day',
                      message: 'No stock activity was recorded on this day.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      Gap.lg,
                      0,
                      Gap.lg,
                      Gap.xxl,
                    ),
                    sliver: SliverList.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: Gap.sm),
                      itemBuilder: (context, i) => MovementTile(
                        movement: list[i],
                        showDate: false,
                        onTap: () => context.push('/items/${list[i].itemId}'),
                      ).entrance(index: i),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
