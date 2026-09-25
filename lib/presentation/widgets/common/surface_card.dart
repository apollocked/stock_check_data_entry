import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../motion/pressable.dart';

/// The app's standard card: a soft container that presses in when tappable.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradient;
  final double radius;

  const SurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(Gap.lg),
    this.color,
    this.gradient,
    this.radius = Radii.lg,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shape = BorderRadius.circular(radius);
    final content = Padding(padding: padding, child: child);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? cs.surfaceContainerLow) : null,
        gradient: gradient,
        borderRadius: shape,
        border: gradient == null
            ? Border.all(color: cs.outlineVariant.withAlpha(90))
            : null,
      ),
      child: onTap == null && onLongPress == null
          ? content
          : Pressable(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: shape,
              child: content,
            ),
    );
  }
}
