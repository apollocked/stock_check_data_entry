import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/item.dart';
import '../../../widgets/common/stock_badge.dart';
import '../../../widgets/common/surface_card.dart';
import '../../../widgets/item_image.dart';

/// An inventory row: photo, name, barcode, stock badge and price.
class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return SurfaceCard(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: const EdgeInsets.all(Gap.md),
      child: Row(
        children: [
          Hero(
            tag: 'item-image-${item.id}',
            child: ItemImage(url: item.imageUrl, size: 64, radius: Radii.md),
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.barcode != null)
                  Text(
                    item.barcode!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontFeatures: tabularFigures,
                      letterSpacing: 0.6,
                    ),
                  ),
                const SizedBox(height: Gap.sm),
                StockBadge(quantity: item.quantity),
              ],
            ),
          ),
          const SizedBox(width: Gap.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Fmt.money(item.price),
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                  fontFeatures: tabularFigures,
                ),
              ),
              Text(
                'each',
                style: text.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
