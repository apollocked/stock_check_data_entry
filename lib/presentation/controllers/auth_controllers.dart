import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/member.dart';
import '../providers/repository_providers.dart';

enum AuthStatus { signedOut, signedIn, passwordRecovery }

/// Works out what the app should show after an auth event.
///
/// A password-recovery link signs the user in, but they must set a new
/// password before entering the app, so that state sticks until the password
/// is updated (`userUpdated`) or the user signs out.
AuthStatus authStatusFor(
  AuthChangeEvent event,
  Session? session,
  AuthStatus previous,
) {
  if (session == null) return AuthStatus.signedOut;
  if (event == AuthChangeEvent.passwordRecovery) {
    return AuthStatus.passwordRecovery;
  }
  if (previous == AuthStatus.passwordRecovery &&
      event != AuthChangeEvent.userUpdated) {
    return AuthStatus.passwordRecovery;
  }
  return AuthStatus.signedIn;
}

Stream<AuthStatus> _sessionStream(GoTrueClient auth) async* {
  var status = auth.currentSession != null
      ? AuthStatus.signedIn
      : AuthStatus.signedOut;
  yield status;
  await for (final state in auth.onAuthStateChange) {
    status = authStatusFor(state.event, state.session, status);
    yield status;
  }
}

/// Emits what the user should see. Falls back to signed out when Supabase has
/// not been initialized (e.g. unit tests).
final sessionStateProvider = StreamProvider<AuthStatus>((ref) {
  try {
    return _sessionStream(Supabase.instance.client.auth);
  } catch (_) {
    return Stream.value(AuthStatus.signedOut);
  }
});

/// Whether the signed-in account is on the store's member list.
final accessProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(accessRepositoryProvider).hasAccess(),
);

final membersProvider = FutureProvider.autoDispose<List<Member>>(
  (ref) => ref.watch(accessRepositoryProvider).fetchMembers(),
);
