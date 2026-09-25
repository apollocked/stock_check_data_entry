import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/stock_level.dart';
import '../../../widgets/common/stock_badge.dart';
import '../../../widgets/motion/animated_number.dart';

/// "12 → 17": current stock and what it will be after the change.
class StockPreview extends StatelessWidget {
  final int current;
  final int? next;

  const StockPreview({super.key, required this.current, required this.next});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final target = next ?? current;
    final color = StockLevel.of(target).color(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          Text('Stock', style: text.labelLarge),
          const Spacer(),
          Text(
            Fmt.count(current),
            style: text.titleMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          AnimatedSwitcher(
            duration: Motion.short,
            transitionBuilder: (child, a) => SizeTransition(
              sizeFactor: a,
              axis: Axis.horizontal,
              child: child,
            ),
            child: next == null
                ? const SizedBox.shrink()
                : Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
                        child: Icon(Icons.arrow_forward_rounded, color: color),
                      ),
                      AnimatedNumber(
                        value: target,
                        format: (v) => Fmt.count(v),
                        style: text.titleLarge?.copyWith(color: color),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
