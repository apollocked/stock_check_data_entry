import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/item.dart';
import '../../../../domain/entities/store.dart';
import '../../../controllers/inventory_controllers.dart';
import '../../../widgets/common/surface_card.dart';
import '../../../widgets/feedback/app_feedback.dart';

/// Price, barcode, description, custom fields and when the item was added.
class ItemInfoCard extends ConsumerWidget {
  final Item item;

  const ItemInfoCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fields = ref.watch(storeProvider).value?.enabledFields ?? const [];
    final custom = [
      for (final f in fields)
        if (!kStandardFieldIds.contains(f.id) &&
            '${item.customValue(f.id) ?? ''}'.isNotEmpty)
          (f.label, '${item.customValue(f.id)}'),
    ];
    final rows = <(String, String, IconData)>[
      ('Price', Fmt.money(item.price), Icons.sell_outlined),
      if (item.barcode != null)
        ('Barcode', item.barcode!, Icons.qr_code_2_rounded),
      for (final (label, value) in custom) (label, value, Icons.label_outline),
      ('Added', Fmt.day(item.createdAt.toLocal()), Icons.event_outlined),
    ];

    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: Gap.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item.description?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.lg,
                Gap.md,
                Gap.lg,
                Gap.sm,
              ),
              child: Text(
                item.description!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          for (final (label, value, icon) in rows)
            ListTile(
              dense: true,
              leading: Icon(icon),
              title: Text(label),
              trailing: Text(
                value,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: value));
                showAppSnack(context, '$label copied');
              },
            ),
        ],
      ),
    );
  }
}
