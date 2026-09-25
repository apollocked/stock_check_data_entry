import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

/// An [IndexedStack] that fades and gently scales the new page in when the
/// index changes (Material "fade through"). Every child keeps its state.
class FadeThroughStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const FadeThroughStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<FadeThroughStack> createState() => _FadeThroughStackState();
}

class _FadeThroughStackState extends State<FadeThroughStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.medium,
    value: 1,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Motion.emphasizedDecelerate,
  );

  @override
  void didUpdateWidget(FadeThroughStack old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: ScaleTransition(
        scale: Tween(begin: 0.98, end: 1.0).animate(_curve),
        child: IndexedStack(index: widget.index, children: widget.children),
      ),
    );
  }
}
