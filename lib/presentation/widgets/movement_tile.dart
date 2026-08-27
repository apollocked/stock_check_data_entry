import 'package:flutter/material.dart';

import '../../domain/entities/stock_movement.dart';

class MovementTile extends StatelessWidget {
  final StockMovement movement;
  final bool showDate;

  const MovementTile({super.key, required this.movement, this.showDate = true});

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
              showDate
                  ? '${formatMovementTime(movement.createdAt)}'
                        '${movement.userEmail != null ? ' · ${movement.userEmail}' : ''}'
                  : movement.userEmail ?? '',
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
}

String formatMovementTime(DateTime time) {
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
