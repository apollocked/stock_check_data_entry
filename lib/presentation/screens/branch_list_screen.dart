import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/inventory_controllers.dart';
import 'branch_items_screen.dart';

class BranchListScreen extends ConsumerStatefulWidget {
  const BranchListScreen({super.key});

  @override
  ConsumerState<BranchListScreen> createState() => _BranchListScreenState();
}

class _BranchListScreenState extends ConsumerState<BranchListScreen> {
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await Supabase.instance.client.auth.signOut();
    } finally {
      ref.invalidate(branchesProvider);
      ref.invalidate(itemsProvider);
    }
  }

  Future<void> _showAddBranchDialog() async {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New branch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Branch name *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Branch name is required')));
      return;
    }
    try {
      await ref
          .read(branchesProvider.notifier)
          .create(name: name, location: locationController.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Check Entry'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: branchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load branches: $error'),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(branchesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (branches) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(branchesProvider);
            await ref.read(branchesProvider.future);
          },
          child: branches.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 160),
                    Icon(Icons.storefront_outlined, size: 64),
                    SizedBox(height: 16),
                    Center(
                      child: Text(
                        'No branches yet.\nTap + to create one.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: branches.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final branch = branches[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BranchItemsScreen(
                              branchId: branch.id,
                              branchName: branch.name,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: Icon(
                                  Icons.storefront,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      branch.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    if (branch.location != null &&
                                        branch.location!.isNotEmpty)
                                      Text(
                                        branch.location!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBranchDialog,
        icon: const Icon(Icons.add_business),
        label: const Text('New branch'),
      ),
    );
  }
}
