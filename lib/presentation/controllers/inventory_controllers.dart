import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/branch.dart';
import '../../domain/entities/item.dart';
import 'repository_providers.dart';

class BranchesController extends AsyncNotifier<List<Branch>> {
  @override
  FutureOr<List<Branch>> build() {
    return ref.watch(inventoryRepositoryProvider).fetchBranches();
  }

  Future<Branch> create({required String name, String? location}) async {
    final repo = ref.read(inventoryRepositoryProvider);
    final created =
        await repo.createBranch(name: name.trim(), location: location?.trim());
    state = const AsyncLoading<List<Branch>>();
    state = await AsyncValue.guard(repo.fetchBranches);
    return created;
  }
}

final branchesProvider =
    AsyncNotifierProvider<BranchesController, List<Branch>>(
  BranchesController.new,
);

class SelectedBranchIdController extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? id) => state = id;
}

final selectedBranchIdProvider =
    NotifierProvider<SelectedBranchIdController, int?>(
  SelectedBranchIdController.new,
);

final itemsProvider = FutureProvider.autoDispose.family<List<Item>, int?>(
  (ref, branchId) =>
      ref.watch(inventoryRepositoryProvider).fetchItems(branchId: branchId),
);
