import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/item.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/entities/stock_report.dart';
import '../../domain/entities/store.dart';
import '../providers/repository_providers.dart';

class StoreController extends AsyncNotifier<Store> {
  @override
  Future<Store> build() {
    return ref.watch(inventoryRepositoryProvider).fetchStore();
  }

  Future<Store> updateFields(List<ItemField> fields) async {
    final store = state.value;
    if (store == null) {
      state = const AsyncLoading<Store>();
      state = await AsyncValue.guard(
        () => ref.read(inventoryRepositoryProvider).fetchStore(),
      );
    }
    final current = state.value;
    if (current == null) throw StateError('Store is not loaded');

    final updated = await ref
        .read(inventoryRepositoryProvider)
        .updateStore(
          storeId: current.id,
          updates: {
            'fields': [
              for (final f in fields)
                {
                  'id': f.id,
                  'label': f.label,
                  'type': f.type,
                  'enabled': f.enabled,
                  'required': f.required,
                },
            ],
          },
        );
    state = AsyncData(updated);
    return updated;
  }
}

final storeProvider = AsyncNotifierProvider<StoreController, Store>(
  StoreController.new,
);

final itemsProvider = FutureProvider.autoDispose<List<Item>>(
  (ref) => ref.watch(inventoryRepositoryProvider).fetchItems(),
);

final movementsProvider = FutureProvider.autoDispose
    .family<List<StockMovement>, MovementType?>(
      (ref, type) =>
          ref.watch(inventoryRepositoryProvider).fetchMovements(type: type),
    );

final reportProvider = FutureProvider.autoDispose<StockReport>((ref) {
  final store = ref.watch(storeProvider).value;
  if (store == null) {
    throw StateError('Store is not loaded');
  }
  return ref.watch(inventoryRepositoryProvider).fetchStockReport(store.id);
});
