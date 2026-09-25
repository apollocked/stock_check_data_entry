import 'package:flutter/material.dart';

/// Brand and surface colors. The surfaces match the native splash screens
/// (android/app/src/main/res/values*/colors.xml and the iOS LaunchBackground
/// color set) so launch fades straight into the first frame.
abstract final class AppColors {
  static const seed = Color(0xFF5B4CFF);
  static const accent = Color(0xFF3CE0B0);

  static const lightSurface = Color(0xFFFBFAFF);
  static const darkSurface = Color(0xFF100E1A);

  static const brandGradient = [Color(0xFF8B5CF6), seed, Color(0xFF2E1A9E)];
}

/// Status colors that stay readable in both light and dark themes.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  final Color success;
  final Color info;
  final Color warning;
  final Color danger;
  final Color neutral;

  const StatusColors({
    required this.success,
    required this.info,
    required this.warning,
    required this.danger,
    required this.neutral,
  });

  static const light = StatusColors(
    success: Color(0xFF0F8A5F),
    info: Color(0xFF2F5BEA),
    warning: Color(0xFFB45309),
    danger: Color(0xFFC62828),
    neutral: Color(0xFF5B5870),
  );

  static const dark = StatusColors(
    success: Color(0xFF4FE3B0),
    info: Color(0xFF8AA8FF),
    warning: Color(0xFFFFC857),
    danger: Color(0xFFFF8A80),
    neutral: Color(0xFFB2AEC6),
  );

  @override
  StatusColors copyWith({
    Color? success,
    Color? info,
    Color? warning,
    Color? danger,
    Color? neutral,
  }) => StatusColors(
    success: success ?? this.success,
    info: info ?? this.info,
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
    neutral: neutral ?? this.neutral,
  );

  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      success: Color.lerp(success, other.success, t)!,
      info: Color.lerp(info, other.info, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }
}

extension StatusColorsX on BuildContext {
  StatusColors get status => Theme.of(this).extension<StatusColors>()!;
}
