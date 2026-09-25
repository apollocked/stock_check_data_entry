import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';

/// Type a barcode by hand (or when there is no camera).
class ManualEntryBar extends StatefulWidget {
  final ValueChanged<String> onSubmit;
  final bool busy;

  const ManualEntryBar({super.key, required this.onSubmit, this.busy = false});

  @override
  State<ManualEntryBar> createState() => _ManualEntryBarState();
}

class _ManualEntryBarState extends State<ManualEntryBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim();
    if (code.isEmpty || widget.busy) return;
    FocusScope.of(context).unfocus();
    widget.onSubmit(code);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(Radii.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
        child: Row(
          children: [
            const SizedBox(width: Gap.sm),
            const Icon(Icons.keyboard_rounded),
            const SizedBox(width: Gap.sm),
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  hintText: 'Type a barcode',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            widget.busy
                ? const Padding(
                    padding: EdgeInsets.all(Gap.md),
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                : IconButton.filled(
                    tooltip: 'Look up',
                    onPressed: _submit,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
          ],
        ),
      ),
    );
  }
}
