import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

/// A small section title with an optional trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionHeader(
    this.title, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(Gap.xs, Gap.lg, Gap.xs, Gap.sm),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: cs.onSurfaceVariant, letterSpacing: 0.2),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
