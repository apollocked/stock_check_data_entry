import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

/// A full-width filled button that swaps its label for a spinner while busy.
class BusyButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool busy;
  final VoidCallback? onPressed;
  final Color? color;

  const BusyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final child = busy
        ? SizedBox.square(
            key: const ValueKey('busy'),
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: cs.onPrimary,
            ),
          )
        : Row(
            key: ValueKey(label),
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: Gap.sm),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: color,
      ),
      onPressed: busy ? null : onPressed,
      child: AnimatedSwitcher(
        duration: Motion.short,
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: child,
      ),
    );
  }
}
