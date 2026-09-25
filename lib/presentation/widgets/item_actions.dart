import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/item.dart';
import '../controllers/inventory_controllers.dart';
import '../providers/repository_providers.dart';
import '../router/app_routes.dart';
import 'feedback/app_feedback.dart';

/// Asks, deletes the item (and its photo), refreshes lists. Returns true
/// when the item was deleted.
Future<bool> confirmAndDeleteItem(
  BuildContext context,
  WidgetRef ref,
  Item item,
) async {
  final confirmed = await confirmAction(
    context,
    title: 'Delete item?',
    message:
        '"${item.name}" and its stock history will be removed permanently.',
    confirmLabel: 'Delete',
    destructive: true,
    icon: Icons.delete_forever_rounded,
  );
  if (!confirmed || !context.mounted) return false;
  try {
    await ref.read(inventoryRepositoryProvider).deleteItem(item);
    invalidateStock(ref);
    if (context.mounted) {
      showAppSnack(context, 'Deleted "${item.name}".', kind: SnackKind.success);
    }
    return true;
  } catch (e) {
    if (context.mounted) showErrorSnack(context, e);
    return false;
  }
}

/// Quick actions for an item, opened with a long press in lists.
Future<void> showItemActionsSheet(
  BuildContext context,
  WidgetRef ref,
  Item item,
) {
  final danger = Theme.of(context).colorScheme.error;
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(item.name, style: Theme.of(sheet).textTheme.titleLarge),
          ),
          ListTile(
            leading: const Icon(Icons.edit_rounded),
            title: const Text('Edit item'),
            onTap: () {
              Navigator.pop(sheet);
              context.editItem(item);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline_rounded, color: danger),
            title: Text('Delete', style: TextStyle(color: danger)),
            onTap: () {
              Navigator.pop(sheet);
              confirmAndDeleteItem(context, ref, item);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
