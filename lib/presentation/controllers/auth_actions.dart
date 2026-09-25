import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';

/// The auth calls the screens make. Navigation follows automatically from
/// the auth state (see router/app_gate.dart).
class AuthActions {
  GoTrueClient get _auth => Supabase.instance.client.auth;

  Future<void> signIn(String email, String password) =>
      _auth.signInWithPassword(email: email.trim(), password: password);

  /// Returns true when the account still needs its email confirmed.
  Future<bool> signUp(String email, String password) async {
    final response = await _auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: Config.authRedirectUrl,
    );
    return response.session == null;
  }

  Future<void> sendPasswordReset(String email) => _auth.resetPasswordForEmail(
    email.trim(),
    redirectTo: Config.authRedirectUrl,
  );

  Future<void> updatePassword(String password) =>
      _auth.updateUser(UserAttributes(password: password));

  Future<void> signOut() => _auth.signOut();

  String? get currentEmail => _auth.currentUser?.email;
}

final authActionsProvider = Provider<AuthActions>((ref) => AuthActions());

/// Loose email check for instant form feedback; Supabase validates for real.
String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Enter your email';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Enter a valid email';
  }
  return null;
}
