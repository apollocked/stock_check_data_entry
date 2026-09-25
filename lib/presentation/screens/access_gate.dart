import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/error_messages.dart';
import '../controllers/auth_controllers.dart';
import 'home_screen.dart';

/// Shows the app only to accounts on the store's member list. The database
/// enforces the same rule; this screen just explains it instead of showing
/// empty lists and permission errors.
class AccessGate extends ConsumerWidget {
  const AccessGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(accessProvider);
    return access.when(
      skipLoadingOnRefresh: false,
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => NoAccessScreen(message: friendlyError(error)),
      data: (allowed) => allowed ? const HomeScreen() : const NoAccessScreen(),
    );
  }
}

class NoAccessScreen extends ConsumerWidget {
  final String? message;

  const NoAccessScreen({super.key, this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: cs.tertiaryContainer,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Icon(
                        message == null
                            ? Icons.lock_person_rounded
                            : Icons.cloud_off_rounded,
                        size: 40,
                        color: cs.onTertiaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    message == null ? 'Waiting for access' : 'Can\'t connect',
                    textAlign: TextAlign.center,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message ??
                        'You are signed in as $email, but this account has not '
                            'been added to the store yet. Ask a team member to '
                            'add you from Settings → Team, then tap Check again.',
                    textAlign: TextAlign.center,
                    style: text.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(accessProvider),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Check again'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Supabase.instance.client.auth.signOut(),
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
