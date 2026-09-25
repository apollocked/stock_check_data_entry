import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';

/// Small colored dots with labels under a chart title.
class ChartLegend extends StatelessWidget {
  final List<(String, Color)> entries;

  const ChartLegend({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Wrap(
      spacing: Gap.lg,
      runSpacing: Gap.xs,
      children: [
        for (final (label, color) in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: Gap.xs + 2),
              Text(label, style: style),
            ],
          ),
      ],
    );
  }
}
