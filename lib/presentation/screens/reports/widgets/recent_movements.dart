import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../domain/entities/stock_movement.dart';
import '../../../controllers/inventory_controllers.dart';
import '../../../widgets/common/section_header.dart';
import '../../../widgets/movement_tile.dart';
import '../../../widgets/states/skeleton.dart';

/// The latest movements across the store, filterable by type.
class RecentMovements extends ConsumerStatefulWidget {
  const RecentMovements({super.key});

  @override
  ConsumerState<RecentMovements> createState() => _RecentMovementsState();
}

class _RecentMovementsState extends ConsumerState<RecentMovements> {
  MovementType? _type;

  @override
  Widget build(BuildContext context) {
    final movements = ref.watch(movementsProvider(_type));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Recent movements'),
        Wrap(
          spacing: Gap.sm,
          children: [
            for (final type in [null, ...MovementType.values])
              ChoiceChip(
                label: Text(type?.label ?? 'All'),
                selected: _type == type,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  setState(() => _type = type);
                },
              ),
          ],
        ),
        const SizedBox(height: Gap.md),
        AnimatedSize(
          duration: Motion.medium,
          curve: Motion.emphasized,
          alignment: Alignment.topCenter,
          child: movements.when(
            loading: () => const SkeletonList(
              count: 3,
              itemHeight: 64,
              padding: EdgeInsets.zero,
            ),
            error: (_, _) => TextButton.icon(
              onPressed: () => ref.invalidate(movementsProvider(_type)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Couldn\'t load movements. Retry'),
            ),
            data: (list) => list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(Gap.xl),
                    child: Text(
                      'No movements yet.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    children: [
                      for (final m in list.take(15)) ...[
                        MovementTile(
                          movement: m,
                          onTap: () => context.push('/items/${m.itemId}'),
                        ),
                        const SizedBox(height: Gap.sm),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
