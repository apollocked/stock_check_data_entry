import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';

/// Counts up (or down) to [value] whenever it changes.
class AnimatedNumber extends StatelessWidget {
  final num value;
  final String Function(num value) format;
  final TextStyle? style;

  const AnimatedNumber({
    super.key,
    required this.value,
    required this.format,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: Motion.long * 2,
      curve: Motion.emphasizedDecelerate,
      builder: (context, v, _) => Text(
        format(value is int ? v.round() : v),
        style: (style ?? const TextStyle()).copyWith(
          fontFeatures: tabularFigures,
        ),
      ),
    );
  }
}
