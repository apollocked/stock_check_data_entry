import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../widgets/states/empty_state.dart';

/// Shown instead of the app when the build has no Supabase URL or key.
class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stockly',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const Scaffold(
        body: SafeArea(
          child: EmptyState(
            icon: Icons.settings_suggest_rounded,
            title: 'Supabase is not configured',
            message:
                'Copy env.example.json to env.json, fill in your project URL '
                'and key, then run:\n\n'
                'flutter run --dart-define-from-file=env.json',
          ),
        ),
      ),
    );
  }
}
