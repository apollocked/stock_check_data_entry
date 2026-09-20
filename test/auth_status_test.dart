import 'package:flutter_test/flutter_test.dart';
import 'package:stockly/presentation/controllers/auth_controllers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Session _session() => Session(
  accessToken: 'token',
  tokenType: 'bearer',
  user: const User(
    id: 'user-id',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-01-01T00:00:00Z',
  ),
);

void main() {
  group('authStatusFor', () {
    test('signs out when there is no session', () {
      expect(
        authStatusFor(AuthChangeEvent.signedOut, null, AuthStatus.signedIn),
        AuthStatus.signedOut,
      );
    });

    test('signs in when a session appears', () {
      expect(
        authStatusFor(
          AuthChangeEvent.signedIn,
          _session(),
          AuthStatus.signedOut,
        ),
        AuthStatus.signedIn,
      );
    });

    test('asks for a new password after a recovery link', () {
      expect(
        authStatusFor(
          AuthChangeEvent.passwordRecovery,
          _session(),
          AuthStatus.signedOut,
        ),
        AuthStatus.passwordRecovery,
      );
    });

    test('stays in recovery when the token refreshes', () {
      expect(
        authStatusFor(
          AuthChangeEvent.tokenRefreshed,
          _session(),
          AuthStatus.passwordRecovery,
        ),
        AuthStatus.passwordRecovery,
      );
    });

    test('leaves recovery once the password is updated', () {
      expect(
        authStatusFor(
          AuthChangeEvent.userUpdated,
          _session(),
          AuthStatus.passwordRecovery,
        ),
        AuthStatus.signedIn,
      );
    });

    test('leaves recovery when the user cancels', () {
      expect(
        authStatusFor(
          AuthChangeEvent.signedOut,
          null,
          AuthStatus.passwordRecovery,
        ),
        AuthStatus.signedOut,
      );
    });
  });
}
