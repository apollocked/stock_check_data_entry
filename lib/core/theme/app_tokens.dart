import 'package:flutter/animation.dart';

/// Spacing scale (4 pt grid).
abstract final class Gap {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Corner radii. Large, soft shapes in the Material 3 Expressive style.
abstract final class Radii {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double pill = 999;
}

/// Motion tokens, so every screen moves with the same rhythm.
abstract final class Motion {
  static const short = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 320);
  static const long = Duration(milliseconds: 520);

  /// Delay between items of a staggered list entrance.
  static const stagger = Duration(milliseconds: 45);

  static const emphasized = Cubic(0.2, 0, 0, 1);
  static const emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1);
  static const spring = Curves.easeOutBack;
}
