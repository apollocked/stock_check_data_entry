import 'package:flutter/material.dart';

/// Bolder, tighter headlines and roomier body text on top of the platform
/// font (Roboto / SF Pro), which keeps the app offline and light.
TextTheme buildTextTheme(TextTheme base, ColorScheme scheme) {
  TextStyle? tight(TextStyle? s, FontWeight w, double spacing) =>
      s?.copyWith(fontWeight: w, letterSpacing: spacing, height: 1.15);

  return base
      .copyWith(
        displayLarge: tight(base.displayLarge, FontWeight.w800, -1.5),
        displayMedium: tight(base.displayMedium, FontWeight.w800, -1.2),
        displaySmall: tight(base.displaySmall, FontWeight.w800, -1),
        headlineLarge: tight(base.headlineLarge, FontWeight.w800, -0.8),
        headlineMedium: tight(base.headlineMedium, FontWeight.w800, -0.6),
        headlineSmall: tight(base.headlineSmall, FontWeight.w700, -0.4),
        titleLarge: tight(base.titleLarge, FontWeight.w700, -0.2),
        titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: base.bodyLarge?.copyWith(height: 1.45),
        bodyMedium: base.bodyMedium?.copyWith(height: 1.4),
        labelLarge: base.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      )
      .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
}

/// Numbers that line up in columns and don't jump while animating.
const tabularFigures = [FontFeature.tabularFigures()];
