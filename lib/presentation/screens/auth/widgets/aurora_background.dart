import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Slowly drifting, blurred color blobs behind the sign-in screens.
/// Honors the system "reduce motion" setting by holding still.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (still) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final strength = dark ? 70 : 55;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value * 2 * math.pi;
          return Stack(
            children: [
              _Blob(
                alignment: Alignment(-0.9 + 0.2 * math.sin(t), -0.9),
                color: cs.primary.withAlpha(strength),
                size: 360,
              ),
              _Blob(
                alignment: Alignment(1.1, -0.2 + 0.25 * math.cos(t)),
                color: cs.tertiary.withAlpha(strength),
                size: 300,
              ),
              _Blob(
                alignment: Alignment(-0.3 + 0.3 * math.cos(t), 1.1),
                color: cs.secondary.withAlpha(strength - 15),
                size: 320,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double size;

  const _Blob({
    required this.alignment,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withAlpha(0)]),
        ),
      ),
    );
  }
}
