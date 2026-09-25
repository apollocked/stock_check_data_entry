import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/item.dart';
import '../controllers/inventory_controllers.dart';
import '../widgets/states/empty_state.dart';
import '../widgets/states/error_state.dart';

/// Resolves the item for an `/items/:id/...` route: uses the item passed
/// along with the navigation when there is one, otherwise loads it by id.
class ItemRouteLoader extends ConsumerWidget {
  final int? id;
  final Item? initial;
  final Widget Function(Item item) builder;

  const ItemRouteLoader({
    super.key,
    required this.id,
    required this.builder,
    this.initial,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initial != null) return builder(initial!);
    final notFound = Scaffold(
      appBar: AppBar(),
      body: const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Item not found',
        message: 'It may have been deleted.',
      ),
    );
    if (id == null) return notFound;

    return ref
        .watch(itemByIdProvider(id!))
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(
            appBar: AppBar(),
            body: ErrorState(
              error: error,
              onRetry: () => ref.invalidate(itemByIdProvider(id!)),
            ),
          ),
          data: (item) => item == null ? notFound : builder(item),
        );
  }
}
