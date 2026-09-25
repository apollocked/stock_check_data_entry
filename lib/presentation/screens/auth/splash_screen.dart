import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_tokens.dart';
import '../../widgets/brand/brand_logo.dart';

/// Shown while the session and access are checked. Continues the native
/// splash: same logo and background, then the layers animate in.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandLogo(size: 112, animate: true),
            const SizedBox(height: Gap.xl),
            Text('Stockly', style: text.headlineMedium)
                .animate(delay: 300.ms)
                .fadeIn(duration: Motion.medium)
                .slideY(begin: 0.3, curve: Motion.emphasizedDecelerate),
            const SizedBox(height: Gap.xxl),
            const SizedBox(
              width: 120,
              child: LinearProgressIndicator(minHeight: 4),
            ).animate(delay: 900.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}
