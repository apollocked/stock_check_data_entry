import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/item.dart';
import '../../controllers/inventory_controllers.dart';
import '../../router/app_routes.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/item_actions.dart';
import '../../widgets/motion/entrance.dart';
import '../../widgets/states/empty_state.dart';
import 'widgets/item_activity_list.dart';
import 'widgets/item_hero_header.dart';
import 'widgets/item_info_card.dart';
import 'widgets/item_stock_card.dart';

/// One item: photo, live stock with quick actions, details and its own
/// movement history.
class ItemDetailsScreen extends ConsumerWidget {
  final int itemId;
  final Item? initial;

  const ItemDetailsScreen({super.key, required this.itemId, this.initial});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(itemByIdProvider(itemId));
    final item = async.value ?? initial;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: async.isLoading
            ? const Center(child: CircularProgressIndicator())
            : const EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Item not found',
                message: 'It may have been deleted.',
              ),
      );
    }

    Future<void> delete() async {
      if (await confirmAndDeleteItem(context, ref, item) && context.mounted) {
        context.pop();
      }
    }

    final sections = [
      ItemStockCard(item: item),
      ItemInfoCard(item: item),
      const SectionHeader('Recent activity'),
    ];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          invalidateStock(ref);
          await ref.read(itemByIdProvider(itemId).future);
        },
        child: CustomScrollView(
          slivers: [
            ItemHeroHeader(
              item: item,
              onEdit: () => context.editItem(item),
              onDelete: delete,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 0),
              sliver: SliverList.separated(
                itemCount: sections.length,
                separatorBuilder: (_, _) => const SizedBox(height: Gap.md),
                itemBuilder: (_, i) => sections[i].entrance(index: i),
              ),
            ),
            ItemActivityList(itemId: item.id),
          ],
        ),
      ),
    );
  }
}
