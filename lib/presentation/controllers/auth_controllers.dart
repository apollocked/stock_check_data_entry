import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Stream<bool> _sessionStream(GoTrueClient auth) async* {
  yield auth.currentSession != null;
  await for (final event in auth.onAuthStateChange) {
    yield event.session != null;
  }
}

/// Emits whether a user is signed in. Falls back to `false` when Supabase
/// has not been initialized (e.g. unit tests).
final sessionStateProvider = StreamProvider<bool>((ref) {
  try {
    return _sessionStream(Supabase.instance.client.auth);
  } catch (_) {
    return Stream.value(false);
  }
});
