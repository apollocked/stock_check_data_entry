import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/error/error_messages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';

enum SnackKind { info, success, error }

/// One consistent way to show a message: floating snack bar with an icon,
/// plus a light haptic so the result is felt as well as seen.
void showAppSnack(
  BuildContext context,
  String message, {
  SnackKind kind = SnackKind.info,
  SnackBarAction? action,
}) {
  final status = context.status;
  final (icon, color) = switch (kind) {
    SnackKind.info => (Icons.info_rounded, null),
    SnackKind.success => (Icons.check_circle_rounded, status.success),
    SnackKind.error => (Icons.error_rounded, status.danger),
  };
  kind == SnackKind.error
      ? HapticFeedback.heavyImpact()
      : HapticFeedback.lightImpact();

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        action: action,
        duration: Duration(seconds: kind == SnackKind.error ? 5 : 3),
        content: Row(
          children: [
            Icon(
              icon,
              color: color ?? Theme.of(context).colorScheme.onInverseSurface,
            ),
            const SizedBox(width: Gap.md),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

void showErrorSnack(BuildContext context, Object error) =>
    showAppSnack(context, friendlyError(error), kind: SnackKind.error);

/// Asks the user to confirm. Returns true only when they tap [confirmLabel].
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  bool destructive = false,
  IconData? icon,
}) async {
  final cs = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: icon == null ? null : Icon(icon),
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: cs.error,
                  foregroundColor: cs.onError,
                  minimumSize: const Size(64, 44),
                )
              : FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
