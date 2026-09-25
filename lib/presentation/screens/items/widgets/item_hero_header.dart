import 'package:flutter/material.dart';

import '../../../../domain/entities/item.dart';
import '../../../widgets/item_image.dart';

/// Collapsing header: the item photo (continuing the hero from the list)
/// fading into the title as you scroll.
class ItemHeroHeader extends StatelessWidget {
  final Item item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ItemHeroHeader({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;

    return SliverAppBar.large(
      expandedHeight: 300,
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        IconButton(
          tooltip: 'Edit',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_rounded),
        ),
        PopupMenuButton<VoidCallback>(
          tooltip: 'More',
          onSelected: (action) => action(),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: onDelete,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete_outline_rounded, color: cs.error),
                title: Text('Delete item', style: TextStyle(color: cs.error)),
              ),
            ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'item-image-${item.id}',
              child: ItemImage(url: item.imageUrl, size: width, radius: 0),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.35, 1],
                  colors: [
                    cs.surface.withAlpha(150),
                    cs.surface.withAlpha(0),
                    cs.surface,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
