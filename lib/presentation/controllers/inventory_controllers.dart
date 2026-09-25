import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/daily_activity.dart';
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

  Future<Store> updateFields(List<ItemField> fields) =>
      _update({'fields': fields.map((f) => f.toMap()).toList()});

  Future<Store> updateProfile({required String name, String? location}) =>
      _update({
        'name': name.trim(),
        'location': (location?.trim().isEmpty ?? true)
            ? null
            : location!.trim(),
      });

  Future<Store> _update(Map<String, dynamic> updates) async {
    final current = state.value ?? await future;
    final updated = await ref
        .read(inventoryRepositoryProvider)
        .updateStore(storeId: current.id, updates: updates);
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

/// One item, kept in sync with the inventory list so stock changes show
/// everywhere at once. Falls back to the server for items not in the list.
final itemByIdProvider = FutureProvider.autoDispose.family<Item?, int>((
  ref,
  id,
) async {
  final items = await ref.watch(itemsProvider.future);
  for (final item in items) {
    if (item.id == id) return item;
  }
  return ref.watch(inventoryRepositoryProvider).fetchItem(id);
});

final movementsProvider = FutureProvider.autoDispose
    .family<List<StockMovement>, MovementType?>(
      (ref, type) =>
          ref.watch(inventoryRepositoryProvider).fetchMovements(type: type),
    );

final itemMovementsProvider = FutureProvider.autoDispose
    .family<List<StockMovement>, int>(
      (ref, itemId) => ref
          .watch(inventoryRepositoryProvider)
          .fetchMovements(itemId: itemId, limit: 200),
    );

final dayMovementsProvider = FutureProvider.autoDispose
    .family<List<StockMovement>, (DateTime, MovementType?)>((ref, key) {
      final (day, type) = key;
      return ref
          .watch(inventoryRepositoryProvider)
          .fetchMovements(
            type: type,
            day: DateTime(day.year, day.month, day.day),
          );
    });

/// Stock in / out / damage per day for the last [DailyActivity.window] days.
final activityProvider = FutureProvider.autoDispose<List<DailyActivity>>((
  ref,
) async {
  final today = DateTime.now();
  final start = DateTime(
    today.year,
    today.month,
    today.day - DailyActivity.window + 1,
  );
  final movements = await ref
      .watch(inventoryRepositoryProvider)
      .fetchMovements(since: start, limit: 5000);
  return DailyActivity.fromMovements(movements, today: today);
});

final reportProvider = FutureProvider.autoDispose<StockReport>((ref) async {
  final store = await ref.watch(storeProvider.future);
  return ref.watch(inventoryRepositoryProvider).fetchStockReport(store.id);
});

/// Refreshes everything that depends on stock levels, after a movement or an
/// item change.
void invalidateStock(WidgetRef ref) {
  ref.invalidate(itemsProvider);
  ref.invalidate(itemByIdProvider);
  ref.invalidate(movementsProvider);
  ref.invalidate(itemMovementsProvider);
  ref.invalidate(dayMovementsProvider);
  ref.invalidate(activityProvider);
  ref.invalidate(reportProvider);
}
