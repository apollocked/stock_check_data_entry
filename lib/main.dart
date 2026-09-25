import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/security/secure_session_storage.dart';
import 'core/theme/app_theme.dart';
import 'presentation/controllers/auth_controllers.dart';
import 'presentation/controllers/theme_controller.dart';
import 'presentation/screens/access_gate.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/reset_password_screen.dart';
import 'presentation/widgets/brand/brand_logo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  if (!Config.isConfigured) {
    runApp(const _MissingConfigApp());
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
    return MaterialApp(
      title: 'Stockly',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ref.watch(themeModeProvider),
      home: ref
          .watch(sessionStateProvider)
          .when(
            loading: () => const _Splash(),
            data: (status) => switch (status) {
              AuthStatus.signedIn => const AccessGate(),
              AuthStatus.passwordRecovery => const ResetPasswordScreen(),
              AuthStatus.signedOut => const LoginScreen(),
            },
            error: (_, _) => const LoginScreen(),
          ),
    );
  }
}

class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stockly',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Supabase is not configured.\n\n'
              'Copy env.example.json to env.json, fill in your project URL '
              'and key, then run with:\n'
              'flutter run --dart-define-from-file=env.json',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogo(size: 96),
            SizedBox(height: 20),
            Text(
              'Stockly',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
