import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/stock_movement.dart';
import 'common/icon_tile.dart';
import 'common/surface_card.dart';

extension MovementTypeStyle on MovementType {
  Color color(BuildContext context) => switch (this) {
    MovementType.inbound => context.status.success,
    MovementType.outbound => context.status.info,
    MovementType.damage => context.status.danger,
  };

  IconData get icon => switch (this) {
    MovementType.inbound => Icons.south_west_rounded,
    MovementType.outbound => Icons.north_east_rounded,
    MovementType.damage => Icons.broken_image_rounded,
  };
}

/// One stock movement: what, how many, who and when.
class MovementTile extends StatelessWidget {
  final StockMovement movement;

  /// Show the date (false when the list is already grouped by day).
  final bool showDate;

  /// Show the item name (false on an item's own history).
  final bool showItem;
  final VoidCallback? onTap;

  const MovementTile({
    super.key,
    required this.movement,
    this.showDate = true,
    this.showItem = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = movement.type.color(context);
    final when = showDate
        ? Fmt.relative(movement.createdAt)
        : Fmt.time(movement.createdAt);
    final meta = [when, ?movement.userEmail].join(' · ');
    final note = movement.note;

    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Gap.md),
      child: Row(
        children: [
          IconTile(icon: movement.type.icon, color: color),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showItem
                      ? movement.itemName ?? 'Item #${movement.itemId}'
                      : movement.type.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall,
                ),
                if (note != null && note.isNotEmpty)
                  Text(
                    note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall,
                  ),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: Gap.sm),
          Text(
            Fmt.signed(movement.signedQuantity),
            style: text.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontFeatures: tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}
