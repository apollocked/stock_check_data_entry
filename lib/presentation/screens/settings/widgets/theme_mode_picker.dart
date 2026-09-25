import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/theme_controller.dart';

/// System / Light / Dark switch. The whole app re-themes with an animated
/// color transition.
class ThemeModePicker extends ConsumerWidget {
  const ThemeModePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ThemeMode>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: ThemeMode.system,
            icon: Icon(Icons.brightness_auto_rounded),
            label: Text('System'),
          ),
          ButtonSegment(
            value: ThemeMode.light,
            icon: Icon(Icons.light_mode_rounded),
            label: Text('Light'),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: Icon(Icons.dark_mode_rounded),
            label: Text('Dark'),
          ),
        ],
        selected: {mode},
        onSelectionChanged: (selection) {
          HapticFeedback.selectionClick();
          ref.read(themeModeProvider.notifier).setMode(selection.first);
        },
      ),
    );
  }
}
