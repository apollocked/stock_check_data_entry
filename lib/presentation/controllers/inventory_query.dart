import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/item.dart';
import '../../domain/entities/stock_level.dart';
import 'inventory_controllers.dart';

enum InventorySort {
  recent('Recently added'),
  name('Name (A–Z)'),
  quantity('Lowest stock first'),
  value('Highest stock value');

  const InventorySort(this.label);
  final String label;
}

/// Search text, stock filter and sort order for the inventory list.
class InventoryQuery {
  final String search;
  final StockLevel? level;
  final InventorySort sort;

  const InventoryQuery({
    this.search = '',
    this.level,
    this.sort = InventorySort.recent,
  });

  InventoryQuery copyWith({
    String? search,
    StockLevel? Function()? level,
    InventorySort? sort,
  }) => InventoryQuery(
    search: search ?? this.search,
    level: level != null ? level() : this.level,
    sort: sort ?? this.sort,
  );
}

/// Filters and sorts [items]. Search matches name, barcode or description.
List<Item> applyInventoryQuery(List<Item> items, InventoryQuery query) {
  final needle = query.search.trim().toLowerCase();
  final result = items.where((item) {
    if (query.level != null && StockLevel.of(item.quantity) != query.level) {
      return false;
    }
    if (needle.isEmpty) return true;
    return item.name.toLowerCase().contains(needle) ||
        (item.barcode?.toLowerCase().contains(needle) ?? false) ||
        (item.description?.toLowerCase().contains(needle) ?? false);
  }).toList();

  double value(Item i) => i.quantity * (i.price ?? 0);
  switch (query.sort) {
    case InventorySort.recent:
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case InventorySort.name:
      result.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    case InventorySort.quantity:
      result.sort((a, b) => a.quantity.compareTo(b.quantity));
    case InventorySort.value:
      result.sort((a, b) => value(b).compareTo(value(a)));
  }
  return result;
}

/// How many items are in each stock level, for the filter chips.
Map<StockLevel, int> countByLevel(List<Item> items) {
  final counts = {for (final l in StockLevel.values) l: 0};
  for (final item in items) {
    counts.update(StockLevel.of(item.quantity), (n) => n + 1);
  }
  return counts;
}

class InventoryQueryController extends Notifier<InventoryQuery> {
  @override
  InventoryQuery build() => const InventoryQuery();

  void setSearch(String text) => state = state.copyWith(search: text);
  void setLevel(StockLevel? level) =>
      state = state.copyWith(level: () => level);
  void setSort(InventorySort sort) => state = state.copyWith(sort: sort);
}

final inventoryQueryProvider =
    NotifierProvider<InventoryQueryController, InventoryQuery>(
      InventoryQueryController.new,
    );

final visibleItemsProvider = Provider.autoDispose<AsyncValue<List<Item>>>((
  ref,
) {
  final query = ref.watch(inventoryQueryProvider);
  return ref
      .watch(itemsProvider)
      .whenData((items) => applyInventoryQuery(items, query));
});
