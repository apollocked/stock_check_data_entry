import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../domain/entities/item.dart';
import '../../../widgets/common/icon_tile.dart';
import '../../../widgets/common/stock_badge.dart';
import '../../../widgets/item_image.dart';

/// What a scan found: the item with quick actions, or an offer to add it.
class ScanResultCard extends StatelessWidget {
  final String barcode;
  final Item? item;
  final VoidCallback onOpen;
  final VoidCallback onUpdateStock;
  final VoidCallback onCreate;
  final VoidCallback onScanAgain;

  const ScanResultCard({
    super.key,
    required this.barcode,
    required this.item,
    required this.onOpen,
    required this.onUpdateStock,
    required this.onCreate,
    required this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final found = item;

    return Card(
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                found == null
                    ? IconTile(
                        icon: Icons.add_box_rounded,
                        color: cs.tertiary,
                        size: 56,
                      )
                    : ItemImage(
                        url: found.imageUrl,
                        size: 56,
                        radius: Radii.md,
                      ),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        found?.name ?? 'New barcode',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium,
                      ),
                      Text(barcode, style: text.bodySmall),
                      if (found != null) ...[
                        const SizedBox(height: Gap.xs),
                        StockBadge(quantity: found.quantity),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Scan again',
                  onPressed: onScanAgain,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: Gap.lg),
            if (found == null)
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add as new item'),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onOpen,
                      child: const Text('Open item'),
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: onUpdateStock,
                      child: const Text('Update stock'),
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
