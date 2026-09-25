import 'package:flutter/material.dart';

import '../../controllers/export_controller.dart';
import '../../widgets/common/export_button.dart';
import 'reports_tab.dart';

/// The Reports tab: stock overview, movements and the Excel export.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: const [ExportButton(kind: ExportKind.excel)],
      ),
      body: const ReportsTab(),
    );
  }
}
