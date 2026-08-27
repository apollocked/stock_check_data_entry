import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/stock_movement.dart';
import '../controllers/inventory_controllers.dart';

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
              const SizedBox(height: 8),
              _StatCard(
                label: 'Stock value',
                value: report.stockValue.toStringAsFixed(2),
                icon: Icons.payments_outlined,
                alignStart: true,
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
              _AlertCard(
                color: Colors.red,
                icon: Icons.remove_shopping_cart,
                title: 'Out of stock',
                value: '${report.outOfStock} items',
              ),
              const SizedBox(height: 8),
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
                          _MovementTile(movement: movements[index]),
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
        elevation: 0,
        color: cs.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: alignStart
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Icon(icon, color: cs.primary),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
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
      child: Card(
        elevation: 0,
        color: color.withAlpha(25),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: color),
              ),
            ],
          ),
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
    return Card(
      elevation: 0,
      color: color.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color),
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
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  final StockMovement movement;

  const _MovementTile({required this.movement});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (color, icon) = switch (movement.type) {
      MovementType.inbound => (Colors.green, Icons.south_west),
      MovementType.outbound => (Colors.blue, Icons.north_east),
      MovementType.damage => (Colors.red, Icons.report_problem_outlined),
    };

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(25),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(movement.itemName ?? 'Item #${movement.itemId}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (movement.note != null && movement.note!.isNotEmpty)
              Text(movement.note!),
            Text(
              '${_formatTime(movement.createdAt)}'
              '${movement.userEmail != null ? ' · ${movement.userEmail}' : ''}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cs.outline),
            ),
          ],
        ),
        trailing: Text(
          '${movement.type == MovementType.inbound ? '+' : '-'}${movement.quantity}',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    final local = time.toLocal();
    return '${local.day}/${local.month}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
