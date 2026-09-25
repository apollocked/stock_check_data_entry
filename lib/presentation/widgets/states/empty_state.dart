import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../common/icon_tile.dart';
import '../motion/entrance.dart';

/// A friendly message with an icon for empty lists and errors, with an
/// optional action. Scrollable so pull-to-refresh still works around it.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final Color? color;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(Gap.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconTile(
                    icon: icon,
                    color: color ?? cs.primary,
                    size: 96,
                  ).pop(),
                  const SizedBox(height: Gap.xl),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: text.titleLarge,
                  ),
                  if (message != null) ...[
                    const SizedBox(height: Gap.sm),
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (action != null) ...[
                    const SizedBox(height: Gap.xl),
                    action!,
                  ],
                ],
              ).entrance(),
            ),
          ),
        ),
      ),
    );
  }
}
