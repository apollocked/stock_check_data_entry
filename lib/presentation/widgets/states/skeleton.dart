import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_tokens.dart';

/// A shimmering placeholder block shown while content loads.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = Radii.sm,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(radius),
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1400.ms, color: cs.surface.withAlpha(140));
  }
}

/// A list of card-shaped skeletons, matching the item and movement rows.
class SkeletonList extends StatelessWidget {
  final int count;
  final double itemHeight;
  final EdgeInsets padding;

  const SkeletonList({
    super.key,
    this.count = 6,
    this.itemHeight = 84,
    this.padding = const EdgeInsets.all(Gap.lg),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: Gap.sm),
      itemBuilder: (_, _) => SkeletonBox(height: itemHeight, radius: Radii.lg),
    );
  }
}
