import 'package:flutter/material.dart';

import '../../../core/error/error_messages.dart';
import 'empty_state.dart';

/// Shows a friendly error with a retry button.
class ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  final String title;

  const ErrorState({
    super.key,
    required this.error,
    required this.onRetry,
    this.title = 'Something went wrong',
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: title,
      message: friendlyError(error),
      color: Theme.of(context).colorScheme.error,
      action: FilledButton.tonalIcon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Try again'),
      ),
    );
  }
}
