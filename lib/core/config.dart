/// Build-time settings, passed with `--dart-define` (or
/// `--dart-define-from-file=env.json`). See `env.example.json`.
class Config {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// Where the links in confirmation and password-reset emails send the user
  /// back to. Must match the intent filter in AndroidManifest.xml, the URL
  /// scheme in ios/Runner/Info.plist and the redirect URLs allowed in the
  /// Supabase dashboard.
  static const String authRedirectUrl =
      'com.apollocked.stockly://login-callback/';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
