import 'package:flutter/material.dart';

/// Dims the camera outside the scan window and sweeps a line across it.
class ScanOverlay extends StatefulWidget {
  final Rect window;
  final Color color;

  const ScanOverlay({super.key, required this.window, required this.color});

  @override
  State<ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<ScanOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _sweep,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _OverlayPainter(
            window: widget.window,
            color: widget.color,
            sweep: Curves.easeInOut.transform(_sweep.value),
          ),
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect window;
  final Color color;
  final double sweep;

  _OverlayPainter({
    required this.window,
    required this.color,
    required this.sweep,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hole = RRect.fromRectAndRadius(window, const Radius.circular(28));
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(hole),
      ),
      Paint()..color = Colors.black.withAlpha(140),
    );
    canvas.drawRRect(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withAlpha(220),
    );

    final y = window.top + 16 + (window.height - 32) * sweep;
    final line = Rect.fromLTRB(
      window.left + 20,
      y - 1.5,
      window.right - 20,
      y + 1.5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(line, const Radius.circular(2)),
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(_OverlayPainter old) =>
      old.sweep != sweep || old.window != window || old.color != color;
}
