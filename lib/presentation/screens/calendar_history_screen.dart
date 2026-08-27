import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/stock_movement.dart';
import '../controllers/inventory_controllers.dart';
import '../widgets/movement_tile.dart';

class CalendarHistoryScreen extends ConsumerStatefulWidget {
  const CalendarHistoryScreen({super.key});

  @override
  ConsumerState<CalendarHistoryScreen> createState() =>
      _CalendarHistoryScreenState();
}

class _CalendarHistoryScreenState extends ConsumerState<CalendarHistoryScreen> {
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickDay(DateTime day) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime.now().subtract(const Duration(days: 730)),
      lastDate: _today,
    );
    if (picked != null && mounted) {
      setState(() => _selectedDay = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final movementsAsync = ref.watch(
      dayMovementsProvider((_selectedDay, null)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _selectedDay = _today),
            icon: const Icon(Icons.today),
            label: const Text('Today'),
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            elevation: 0,
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: 'Previous day',
                        onPressed: () {
                          final prev = _selectedDay.subtract(
                            const Duration(days: 1),
                          );
                          if (prev.isBefore(
                            DateTime.now().subtract(const Duration(days: 730)),
                          )) {
                            return;
                          }
                          setState(() => _selectedDay = prev);
                        },
                        icon: const Icon(Icons.chevron_left),
                      ),
                      TextButton(
                        onPressed: () => _pickDay(_selectedDay),
                        child: Text(
                          _formatFullDay(_selectedDay),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next day',
                        onPressed: _selectedDay.isBefore(_today)
                            ? () => setState(
                                () => _selectedDay = _selectedDay.add(
                                  const Duration(days: 1),
                                ),
                              )
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  movementsAsync.maybeWhen(
                    data: (movements) => _DaySummary(movements: movements),
                    orElse: () => const SizedBox(height: 40),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: movementsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Could not load history:\n$error',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () => ref.invalidate(dayMovementsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (movements) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(dayMovementsProvider);
                  await ref.read(
                    dayMovementsProvider((_selectedDay, null)).future,
                  );
                },
                child: movements.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 100),
                          Icon(Icons.event_busy, size: 56),
                          SizedBox(height: 12),
                          Center(child: Text('No stock activity on this day.')),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: movements.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 4),
                        itemBuilder: (context, index) => MovementTile(
                          movement: movements[index],
                          showDate: false,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDay(DateTime day) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[day.month - 1]} ${day.day}, ${day.year}';
  }
}

class _DaySummary extends StatelessWidget {
  final List<StockMovement> movements;

  const _DaySummary({required this.movements});

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) {
      return const SizedBox.shrink();
    }
    var inQty = 0;
    var outQty = 0;
    var damageQty = 0;
    for (final m in movements) {
      switch (m.type) {
        case MovementType.inbound:
          inQty += m.quantity;
        case MovementType.outbound:
          outQty += m.quantity;
        case MovementType.damage:
          damageQty += m.quantity;
      }
    }
    final net = inQty - outQty - damageQty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Chip(label: 'In +$inQty', color: Colors.green),
          const SizedBox(width: 8),
          _Chip(label: 'Out -$outQty', color: Colors.blue),
          const SizedBox(width: 8),
          _Chip(label: 'Damage -$damageQty', color: Colors.red),
          const SizedBox(width: 8),
          _Chip(
            label: 'Net ${net >= 0 ? '+' : ''}$net',
            color: net < 0 ? Colors.red : Colors.green,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
