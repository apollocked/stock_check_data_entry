import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../widgets/brand/brand_logo.dart';
import '../../../widgets/motion/entrance.dart';
import 'aurora_background.dart';

/// Shared frame for sign-in screens: soft animated background, the animated
/// logo, a title, and the form in a card.
class AuthLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Gap.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: BrandLogo(size: 88, animate: true)),
                      const SizedBox(height: Gap.xl),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: text.headlineMedium,
                      ).entrance(index: 1),
                      const SizedBox(height: Gap.sm),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: text.bodyLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ).entrance(index: 2),
                      const SizedBox(height: Gap.xxl),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow.withAlpha(235),
                          borderRadius: BorderRadius.circular(Radii.xl),
                          border: Border.all(
                            color: cs.outlineVariant.withAlpha(90),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(Gap.xl),
                          child: child,
                        ),
                      ).entrance(index: 3),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
