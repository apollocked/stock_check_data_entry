import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../controllers/inventory_controllers.dart';
import '../../../controllers/inventory_query.dart';
import '../../../router/app_routes.dart';
import '../../../widgets/item_actions.dart';
import '../../../widgets/motion/entrance.dart';
import '../../../widgets/states/empty_state.dart';
import '../../../widgets/states/error_state.dart';
import '../../../widgets/states/skeleton.dart';
import 'item_card.dart';

/// The item list as slivers: skeletons while loading, then the filtered
/// items with a staggered entrance, or an empty / error state.
class InventoryList extends ConsumerWidget {
  final VoidCallback onAddItem;

  const InventoryList({super.key, required this.onAddItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(inventoryQueryProvider);
    final filtering = query.search.isNotEmpty || query.level != null;

    return ref
        .watch(visibleItemsProvider)
        .when(
          skipLoadingOnRefresh: true,
          loading: () => const SliverFillRemaining(
            hasScrollBody: true,
            child: SkeletonList(),
          ),
          error: (error, _) => SliverFillRemaining(
            child: ErrorState(
              error: error,
              title: 'Couldn\'t load items',
              onRetry: () => ref.invalidate(itemsProvider),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return SliverFillRemaining(
                child: filtering
                    ? const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No matches',
                        message: 'Try another search or clear the filter.',
                      )
                    : EmptyState(
                        icon: Icons.inventory_2_rounded,
                        title: 'No items yet',
                        message: 'Scan a barcode or add your first item.',
                        action: FilledButton.icon(
                          onPressed: onAddItem,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add item'),
                        ),
                      ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, 120),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: Gap.sm),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ItemCard(
                    key: ValueKey(item.id),
                    item: item,
                    onTap: () => context.openItem(item),
                    onLongPress: () => showItemActionsSheet(context, ref, item),
                  ).entrance(index: index);
                },
              ),
            );
          },
        );
  }
}
