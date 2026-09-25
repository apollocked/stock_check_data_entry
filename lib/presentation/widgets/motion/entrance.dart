import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_tokens.dart';

extension EntranceX on Widget {
  /// Fades and lifts the widget in. Pass the list [index] to stagger items;
  /// the delay is capped so long lists don't wait on off-screen rows.
  Widget entrance({int index = 0, double offset = 0.08}) {
    final delay = Motion.stagger * index.clamp(0, 8);
    return animate(delay: delay)
        .fadeIn(duration: Motion.medium, curve: Motion.emphasizedDecelerate)
        .slideY(
          begin: offset,
          end: 0,
          duration: Motion.long,
          curve: Motion.emphasizedDecelerate,
        );
  }

  /// A springy pop for badges and icons that appear after an action.
  Widget pop({Duration delay = Duration.zero}) => animate(delay: delay)
      .fadeIn(duration: Motion.short)
      .scaleXY(
        begin: 0.6,
        end: 1,
        duration: Motion.medium,
        curve: Motion.spring,
      );
}
