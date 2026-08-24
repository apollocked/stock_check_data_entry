import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: Config.supabaseUrl, anonKey: Config.supabaseAnonKey);
  runApp(const ProviderScope(child: StockCheckEntryApp()));
}

class StockCheckEntryApp extends StatelessWidget {
  const StockCheckEntryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Check Entry',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const HomeShell(),
    );
  }
}
