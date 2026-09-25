import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

/// Brand colors used by the logo, launcher icons and splash screen.
abstract final class BrandColors {
  static const indigo = Color(0xFF5B4CFF);
  static const violet = Color(0xFF8B5CF6);
  static const deep = Color(0xFF2E1A9E);
  static const mint = Color(0xFF3CE0B0);
}

/// The Stockly mark: three stacked layers (stock on a shelf) with a mint
/// "in stock" spark, optionally on the rounded gradient tile.
///
/// Drawn in a unit square, so the same painter serves the in-app logo and
/// `tool/brand/generate_brand_assets_test.dart`, which renders the PNGs.
class BrandMarkPainter extends CustomPainter {
  /// Draw the gradient tile behind the mark.
  final bool background;

  /// Size of the mark relative to the canvas (1 = fills the safe area).
  final double scale;

  /// 0 → 1: layers drop in from above, one after another.
  final double progress;

  /// Draw everything in one solid color (Android themed icons).
  final Color? monochrome;

  /// Corner radius of the tile relative to its size; 0 for a square tile.
  final double cornerRadius;

  /// Draw the layers (false renders the tile alone, for adaptive icons).
  final bool showMark;

  const BrandMarkPainter({
    this.background = true,
    this.scale = 0.8,
    this.progress = 1,
    this.monochrome,
    this.cornerRadius = 0.28,
    this.showMark = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    canvas.scale(s);
    if (background) _paintTile(canvas);
    if (!showMark) return canvas.restore();

    canvas.translate(0.5, 0.5);
    canvas.scale(scale);
    canvas.translate(-0.5, -0.515);
    _paintLayers(canvas);
    canvas.restore();
  }

  void _paintTile(Canvas canvas) {
    final rect = const Rect.fromLTWH(0, 0, 1, 1);
    final tile = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));
    canvas.drawRRect(
      tile,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BrandColors.violet, BrandColors.indigo, BrandColors.deep],
          stops: [0, 0.45, 1],
        ).createShader(rect),
    );
    canvas.drawRRect(
      tile,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.7, -0.8),
          radius: 0.9,
          colors: [const Color(0x40FFFFFF), const Color(0x00FFFFFF)],
        ).createShader(rect),
    );
  }

  void _paintLayers(Canvas canvas) {
    const w = 0.30, h = 0.165, gap = 0.14, top = 0.36;
    final colors = monochrome != null
        ? [monochrome!, monochrome!, monochrome!]
        : [
            const Color(0xFFFFFFFF),
            const Color(0xDDFFFFFF),
            const Color(0x99FFFFFF),
          ];

    // Bottom layer first so the upper ones sit on top.
    for (var i = 2; i >= 0; i--) {
      final t = _stagger(i);
      if (t <= 0) continue;
      final y = top + gap * i - (1 - t) * 0.18;
      final paint = Paint()
        ..color = colors[i].withValues(alpha: colors[i].a * t)
        ..isAntiAlias = true;
      if (i == 0) {
        final slab = Path()
          ..moveTo(0.5 - w, y)
          ..lineTo(0.5, y - h)
          ..lineTo(0.5 + w, y)
          ..lineTo(0.5, y + h)
          ..close();
        canvas.drawPath(slab, paint);
        canvas.drawPath(
          slab,
          Paint()
            ..color = paint.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.05
            ..strokeJoin = StrokeJoin.round,
        );
      } else {
        final chevron = Path()
          ..moveTo(0.5 - w, y)
          ..lineTo(0.5, y + h)
          ..lineTo(0.5 + w, y);
        canvas.drawPath(
          chevron,
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.075
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }
    _paintSpark(canvas, colors.first);
  }

  /// Four-point spark above the right corner of the top layer.
  void _paintSpark(Canvas canvas, Color fallback) {
    final t = ((progress - 0.75) / 0.25).clamp(0.0, 1.0);
    if (t <= 0) return;
    final r = 0.075 * Curves.easeOutBack.transform(t);
    const c = Offset(0.8, 0.2);
    final spark = Path();
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 - math.pi / 2;
      final radius = i.isEven ? r : r * 0.32;
      final p = c + Offset(math.cos(angle), math.sin(angle)) * radius;
      i == 0 ? spark.moveTo(p.dx, p.dy) : spark.lineTo(p.dx, p.dy);
    }
    spark.close();
    canvas.drawPath(spark, Paint()..color = monochrome ?? BrandColors.mint);
  }

  double _stagger(int i) {
    // Layers land bottom-up: index 2 first, then 1, then the top slab.
    final start = (2 - i) * 0.2;
    final t = ((progress - start) / 0.4).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(t);
  }

  @override
  bool shouldRepaint(BrandMarkPainter old) =>
      old.progress != progress ||
      old.background != background ||
      old.scale != scale ||
      old.monochrome != monochrome ||
      old.cornerRadius != cornerRadius ||
      old.showMark != showMark;
}
