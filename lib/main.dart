import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/security/secure_session_storage.dart';
import 'core/theme/app_theme.dart';
import 'presentation/controllers/theme_controller.dart';
import 'presentation/router/app_router.dart';
import 'presentation/screens/auth/missing_config_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  if (!Config.isConfigured) {
    runApp(const MissingConfigApp());
    return;
  }
  await Supabase.initialize(
    url: Config.supabaseUrl,
    publishableKey: Config.supabaseAnonKey,
    // On the web the browser has no keystore; supabase_flutter's default is
    // used there.
    authOptions: kIsWeb
        ? const FlutterAuthClientOptions()
        : FlutterAuthClientOptions(
            localStorage: SecureSessionStorage(
              persistSessionKey: SecureSessionStorage.keyFor(
                Config.supabaseUrl,
              ),
            ),
          ),
  );
  runApp(const ProviderScope(child: StocklyApp()));
}

class StocklyApp extends ConsumerWidget {
  const StocklyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Stockly',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ref.watch(themeModeProvider),
      themeAnimationDuration: Motion.long,
      themeAnimationCurve: Motion.emphasized,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
