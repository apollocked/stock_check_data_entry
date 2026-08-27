import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/theme/app_theme.dart';
import 'presentation/controllers/auth_controllers.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: Config.supabaseUrl,
    publishableKey: Config.supabaseAnonKey,
  );
  runApp(const ProviderScope(child: InventoryApp()));
}

class InventoryApp extends ConsumerWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Inventory Manager',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: ref
          .watch(sessionStateProvider)
          .when(
            loading: () => const _Splash(),
            data: (signedIn) =>
                signedIn ? const HomeScreen() : const LoginScreen(),
            error: (_, _) => const LoginScreen(),
          ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storefront,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
