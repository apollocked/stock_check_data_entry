import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/branch.dart';
import '../../domain/entities/item.dart';
import '../providers/repository_providers.dart';

class BranchesController extends AsyncNotifier<List<Branch>> {
  @override
  FutureOr<List<Branch>> build() {
    return ref.watch(inventoryRepositoryProvider).fetchBranches();
  }

  Future<Branch> create({
    required String name,
    String? location,
    required List<BranchField> fields,
  }) async {
    final repo = ref.read(inventoryRepositoryProvider);
    final created = await repo.createBranch(
      name: name.trim(),
      location: location?.trim(),
      fields: fields,
    );
    state = const AsyncLoading<List<Branch>>();
    state = await AsyncValue.guard(repo.fetchBranches);
    return created;
  }

  Future<void> updateBranch(int branchId, Map<String, dynamic> updates) async {
    final repo = ref.read(inventoryRepositoryProvider);
    await repo.updateBranch(branchId: branchId, updates: updates);
    state = await AsyncValue.guard(repo.fetchBranches);
  }
}

final branchesProvider =
    AsyncNotifierProvider<BranchesController, List<Branch>>(
      BranchesController.new,
    );

final itemsProvider = FutureProvider.autoDispose.family<List<Item>, int?>(
  (ref, branchId) =>
      ref.watch(inventoryRepositoryProvider).fetchItems(branchId: branchId),
);
