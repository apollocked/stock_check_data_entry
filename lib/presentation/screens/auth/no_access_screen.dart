import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_messages.dart';
import '../../../core/theme/app_tokens.dart';
import '../../controllers/auth_actions.dart';
import '../../controllers/auth_controllers.dart';
import '../../widgets/states/empty_state.dart';

/// For signed-in accounts that are not store members yet (or when the check
/// itself failed). The database enforces the same rule; this screen explains
/// it instead of showing empty lists and permission errors.
class NoAccessScreen extends ConsumerWidget {
  const NoAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(accessProvider).error;
    final email = ref.read(authActionsProvider).currentEmail ?? '';

    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          icon: error == null
              ? Icons.lock_person_rounded
              : Icons.cloud_off_rounded,
          color: Theme.of(context).colorScheme.tertiary,
          title: error == null ? 'Waiting for access' : 'Can\'t connect',
          message: error != null
              ? friendlyError(error)
              : 'You are signed in as $email, but this account has not been '
                    'added to the store yet. Ask a team member to add you '
                    'from Settings → Team, then check again.',
          action: SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: () => ref.invalidate(accessProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Check again'),
                ),
                const SizedBox(height: Gap.sm),
                TextButton(
                  onPressed: () => ref.read(authActionsProvider).signOut(),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
