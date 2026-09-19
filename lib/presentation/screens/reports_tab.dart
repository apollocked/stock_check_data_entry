import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/stock_movement.dart';
import '../controllers/inventory_controllers.dart';
import '../widgets/movement_tile.dart';

class ReportsTab extends ConsumerStatefulWidget {
  const ReportsTab({super.key});

  @override
  ConsumerState<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends ConsumerState<ReportsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Movements'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildOverview(), _buildMovements()],
          ),
        ),
      ],
    );
  }

  Widget _buildOverview() {
    final reportAsync = ref.watch(reportProvider);

    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not load report: $error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => ref.invalidate(reportProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (report) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(reportProvider);
            await ref.read(reportProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  _StatCard(
                    label: 'Items',
                    value: '${report.totalItems}',
                    icon: Icons.inventory_2_outlined,
                  ),
                  const SizedBox(width: 8),
                  _StatCard(
                    label: 'Total units',
                    value: '${report.totalUnits}',
                    icon: Icons.stacked_bar_chart,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _HeroCard(
                icon: Icons.payments_outlined,
                title: 'Stock value',
                value: report.stockValue.toStringAsFixed(2),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _MiniStat(
                    label: 'Stock in',
                    value: '${report.totalIn}',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _MiniStat(
                    label: 'Stock out',
                    value: '${report.totalOut}',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _MiniStat(
                    label: 'Damage',
                    value: '${report.totalDamage}',
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _MiniStat(
                    label: 'In stock (>0)',
                    value: '${report.inStock}',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _MiniStat(
                    label: 'Zero (=0)',
                    value: '${report.zeroStock}',
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  _MiniStat(
                    label: 'Minus (<0)',
                    value: '${report.minusStock}',
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _AlertCard(
                color: Colors.orange,
                icon: Icons.warning_amber_outlined,
                title: 'Low stock (≤5)',
                value: '${report.lowStock} items',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMovements() {
    final selected = ref.watch(_movementFilterProvider);
    final movementsAsync = ref.watch(movementsProvider(selected));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<MovementType?>(
            segments: const [
              ButtonSegment(value: null, label: Text('All')),
              ButtonSegment(
                value: MovementType.inbound,
                label: Text('In'),
                icon: Icon(Icons.south_west),
              ),
              ButtonSegment(
                value: MovementType.outbound,
                label: Text('Out'),
                icon: Icon(Icons.north_east),
              ),
              ButtonSegment(
                value: MovementType.damage,
                label: Text('Damage'),
                icon: Icon(Icons.report_problem_outlined),
              ),
            ],
            selected: {selected},
            onSelectionChanged: (sel) =>
                ref.read(_movementFilterProvider.notifier).setFilter(sel.first),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: movementsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Could not load movements:\n$error',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => ref.invalidate(movementsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (movements) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(movementsProvider);
                await ref.read(movementsProvider(selected).future);
              },
              child: movements.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Icon(Icons.history, size: 56),
                        SizedBox(height: 12),
                        Center(child: Text('No movements recorded yet.')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: movements.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (context, index) =>
                          MovementTile(movement: movements[index]),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

final _movementFilterProvider =
    NotifierProvider<MovementFilterController, MovementType?>(
      MovementFilterController.new,
    );

class MovementFilterController extends Notifier<MovementType?> {
  @override
  MovementType? build() => null;

  void setFilter(MovementType? type) => state = type;
}

class _HeroCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _HeroCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: kBrandGradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D4F46E5),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: Colors.white.withAlpha(230)),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool alignStart;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.alignStart = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: Card(
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cs.outlineVariant.withAlpha(60)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: alignStart
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cs.primary, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: cs.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(28),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: color, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String value;

  const _AlertCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
