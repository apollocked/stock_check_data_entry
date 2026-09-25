import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';

/// A big editable number with round − / + buttons. Hold a button to repeat.
class QuantityStepper extends StatefulWidget {
  final TextEditingController controller;
  final Color color;
  final int min;
  final ValueChanged<int> onChanged;

  const QuantityStepper({
    super.key,
    required this.controller,
    required this.color,
    required this.onChanged,
    this.min = 0,
  });

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  Timer? _repeat;

  int get _value => int.tryParse(widget.controller.text) ?? 0;

  void _step(int delta) {
    final next = (_value + delta).clamp(widget.min, 1000000);
    if (next == _value) return;
    HapticFeedback.selectionClick();
    widget.controller.text = '$next';
    widget.onChanged(next);
  }

  void _startRepeat(int delta) {
    _repeat = Timer.periodic(
      const Duration(milliseconds: 90),
      (_) => _step(delta),
    );
  }

  void _stopRepeat() {
    _repeat?.cancel();
    _repeat = null;
  }

  @override
  void dispose() {
    _stopRepeat();
    super.dispose();
  }

  Widget _button(IconData icon, int delta, String tooltip) {
    return GestureDetector(
      onLongPressStart: (_) => _startRepeat(delta),
      onLongPressEnd: (_) => _stopRepeat(),
      child: IconButton.filledTonal(
        tooltip: tooltip,
        iconSize: 28,
        style: IconButton.styleFrom(minimumSize: const Size.square(60)),
        onPressed: () => _step(delta),
        icon: Icon(icon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _button(Icons.remove_rounded, -1, 'Less'),
        Expanded(
          child: TextField(
            controller: widget.controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => widget.onChanged(int.tryParse(v) ?? 0),
            style: Theme.of(context).textTheme.displaySmall
                ?.copyWith(color: widget.color, fontFeatures: tabularFigures),
            decoration: const InputDecoration(
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: Gap.sm),
            ),
          ),
        ),
        _button(Icons.add_rounded, 1, 'More'),
      ],
    );
  }
}
