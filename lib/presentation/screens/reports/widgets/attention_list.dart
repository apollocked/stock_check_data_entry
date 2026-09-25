import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../domain/entities/stock_level.dart';
import '../../../controllers/inventory_controllers.dart';
import '../../../controllers/inventory_query.dart';
import '../../../router/app_routes.dart';
import '../../../widgets/common/section_header.dart';
import '../../../widgets/common/stock_badge.dart';
import '../../../widgets/common/surface_card.dart';
import '../../../widgets/item_image.dart';

/// Items that need restocking (negative, out, then low), up to five.
class AttentionList extends ConsumerWidget {
  const AttentionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider).value ?? const [];
    final urgent =
        items
            .where((i) => StockLevel.of(i.quantity) != StockLevel.healthy)
            .toList()
          ..sort((a, b) => a.quantity.compareTo(b.quantity));
    if (urgent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'Needs attention · ${urgent.length}',
          trailing: TextButton(
            onPressed: () {
              ref
                  .read(inventoryQueryProvider.notifier)
                  .setSort(InventorySort.quantity);
              context.go(AppRoutes.inventory);
            },
            child: const Text('See all'),
          ),
        ),
        SurfaceCard(
          padding: const EdgeInsets.symmetric(vertical: Gap.xs),
          child: Column(
            children: [
              for (final item in urgent.take(5))
                ListTile(
                  leading: ItemImage(
                    url: item.imageUrl,
                    size: 40,
                    radius: Radii.sm,
                  ),
                  title: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: StockBadge(quantity: item.quantity),
                  onTap: () => context.openItem(item),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
