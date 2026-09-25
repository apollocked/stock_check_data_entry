import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../controllers/inventory_controllers.dart';
import '../../../widgets/motion/entrance.dart';
import '../../../widgets/movement_tile.dart';
import '../../../widgets/states/error_state.dart';
import '../../../widgets/states/skeleton.dart';

/// The item's own stock movements, newest first, as a sliver.
class ItemActivityList extends ConsumerWidget {
  final int itemId;

  const ItemActivityList({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const padding = EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.xxl);

    return ref
        .watch(itemMovementsProvider(itemId))
        .when(
          loading: () => const SliverToBoxAdapter(
            child: SkeletonList(count: 3, itemHeight: 64, padding: padding),
          ),
          error: (error, _) => SliverToBoxAdapter(
            child: SizedBox(
              height: 320,
              child: ErrorState(
                error: error,
                onRetry: () => ref.invalidate(itemMovementsProvider(itemId)),
              ),
            ),
          ),
          data: (movements) => movements.isEmpty
              ? SliverPadding(
                  padding: padding,
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'No stock movements yet. Use the buttons above to '
                      'record the first one.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: padding,
                  sliver: SliverList.separated(
                    itemCount: movements.length,
                    separatorBuilder: (_, _) => const SizedBox(height: Gap.sm),
                    itemBuilder: (_, i) => MovementTile(
                      movement: movements[i],
                      showItem: false,
                    ).entrance(index: i),
                  ),
                ),
        );
  }
}
