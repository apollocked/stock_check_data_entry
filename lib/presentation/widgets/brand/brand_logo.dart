import 'package:flutter/material.dart';

import 'brand_mark_painter.dart';

/// The Stockly logo tile, drawn in vector so it stays sharp at any size.
///
/// With [animate] the layers drop in and the spark pops, once, when the
/// widget first appears (splash and sign-in screens).
class BrandLogo extends StatefulWidget {
  final double size;
  final bool animate;

  const BrandLogo({super.key, this.size = 96, this.animate = false});

  @override
  State<BrandLogo> createState() => _BrandLogoState();
}

class _BrandLogoState extends State<BrandLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    value: widget.animate ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return Semantics(
      label: 'Stockly',
      image: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.28),
          boxShadow: [
            BoxShadow(
              color: BrandColors.indigo.withValues(alpha: 0.35),
              blurRadius: size * 0.3,
              offset: Offset(0, size * 0.12),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            size: Size.square(size),
            painter: BrandMarkPainter(progress: _controller.value),
          ),
        ),
      ),
    );
  }
}
