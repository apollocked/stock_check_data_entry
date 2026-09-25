import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_tokens.dart';

/// Shrinks slightly while pressed, for a tactile feel on cards and tiles.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius borderRadius;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius = const BorderRadius.all(Radius.circular(Radii.lg)),
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool value) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _down ? 0.97 : 1,
      duration: Motion.short,
      curve: Motion.emphasized,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  widget.onLongPress!();
                },
          onHighlightChanged: _set,
          child: widget.child,
        ),
      ),
    );
  }
}
