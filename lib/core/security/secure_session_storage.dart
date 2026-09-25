import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the Supabase session (access and refresh tokens) in the Android
/// Keystore / iOS Keychain instead of plain SharedPreferences.
///
/// Sessions saved by older versions of the app are moved over on first launch,
/// so nobody is signed out by the upgrade.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({required this.persistSessionKey});

  final String persistSessionKey;

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// The key supabase_flutter uses for its own SharedPreferences storage.
  static String keyFor(String supabaseUrl) =>
      'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token';

  @override
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(persistSessionKey);
      if (legacy == null) return;
      if (!await _storage.containsKey(key: persistSessionKey)) {
        await _storage.write(key: persistSessionKey, value: legacy);
      }
      await prefs.remove(persistSessionKey);
    } catch (e) {
      // A failed migration only means signing in again.
      if (kDebugMode) debugPrint('Session migration failed: $e');
    }
  }

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: persistSessionKey);

  @override
  Future<String?> accessToken() => _storage.read(key: persistSessionKey);

  @override
  Future<void> removePersistedSession() =>
      _storage.delete(key: persistSessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: persistSessionKey, value: persistSessionString);
}
