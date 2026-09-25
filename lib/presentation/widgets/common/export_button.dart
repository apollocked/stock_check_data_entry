import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/export_controller.dart';
import '../feedback/app_feedback.dart';

/// App bar action that runs an export and reports the result.
class ExportButton extends ConsumerWidget {
  final ExportKind kind;

  const ExportButton({super.key, required this.kind});

  Future<void> _run(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(exportControllerProvider.notifier);
    try {
      final message = kind == ExportKind.csv
          ? await controller.exportCsv()
          : await controller.exportExcel();
      if (context.mounted) {
        showAppSnack(context, message, kind: SnackKind.success);
      }
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final running = ref.watch(exportControllerProvider);
    final busy = running == kind;
    return IconButton(
      tooltip: kind == ExportKind.csv ? 'Export CSV' : 'Export Excel report',
      onPressed: running == null ? () => _run(context, ref) : null,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Icon(
                kind == ExportKind.csv
                    ? Icons.ios_share_rounded
                    : Icons.table_view_rounded,
              ),
      ),
    );
  }
}
