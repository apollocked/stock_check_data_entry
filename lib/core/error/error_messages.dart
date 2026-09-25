import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_exception.dart';

const _noConnection =
    'No internet connection. Check your network and try again.';
const _generic = 'Something went wrong. Please try again.';

/// Turns any error into short text that is safe to show to a user.
///
/// The original error is printed in debug builds only (release builds log
/// nothing), and raw Supabase and Postgres messages never reach the screen.
String friendlyError(Object error, {String? fallback}) {
  if (error is AppException) return error.message;

  if (kDebugMode) debugPrint('Error: $error');

  if (_isConnectionProblem(error)) return _noConnection;
  if (error is TimeoutException) {
    return 'The server took too long to respond. Please try again.';
  }
  if (error is AuthException) return _authMessage(error);
  if (error is PostgrestException) return _databaseMessage(error, fallback);
  if (error is StorageException) {
    return 'The image could not be uploaded. Please try again.';
  }
  return fallback ?? _generic;
}

/// Maps an error to an [AppException] carrying a friendly message.
AppException toAppException(
  Object error,
  String fallback, [
  AppExceptionType type = AppExceptionType.database,
]) {
  if (error is AppException) return error;
  final kind = _isConnectionProblem(error) ? AppExceptionType.network : type;
  return AppException(friendlyError(error, fallback: fallback), kind, error);
}

bool _isConnectionProblem(Object error) {
  if (error is SocketException) return true;
  final text = error.toString();
  return text.contains('SocketException') ||
      text.contains('Failed host lookup') ||
      (text.contains('ClientException') && text.contains('Connection'));
}

String _authMessage(AuthException e) {
  final code = e.code ?? '';
  final message = e.message.toLowerCase();
  if (code == 'invalid_credentials' || message.contains('invalid login')) {
    return 'Wrong email or password.';
  }
  if (code == 'email_not_confirmed' || message.contains('not confirmed')) {
    return 'Please confirm your email first. Check your inbox.';
  }
  if (code == 'user_already_exists' || message.contains('already registered')) {
    return 'An account with this email already exists. Try signing in.';
  }
  if (code == 'weak_password' || message.contains('password should')) {
    return 'That password is too weak. Use at least 8 characters with '
        'letters and numbers.';
  }
  if (code == 'over_email_send_rate_limit' ||
      code == 'over_request_rate_limit' ||
      e.statusCode == '429') {
    return 'Too many attempts. Please wait a minute and try again.';
  }
  if (code == 'same_password' || message.contains('different from the old')) {
    return 'Choose a password different from your current one.';
  }
  if (message.contains('expired') || message.contains('invalid')) {
    return 'This link has expired. Request a new one and try again.';
  }
  return 'Could not sign in. Please try again.';
}

String _databaseMessage(PostgrestException e, String? fallback) {
  switch (e.code) {
    // Raised by our own functions (see supabase/schema/); written for users.
    case 'P0001':
      return e.message;
    case '42501':
      return 'You do not have permission to do that.';
    case '23505':
      return 'That already exists, for example a barcode that is in use.';
    case '23503':
      return 'That record is still used somewhere else.';
    case '23502':
    case '23514':
      return 'Some of the values are not valid. Check the form and try again.';
    case 'PGRST116':
      return 'That record no longer exists. Refresh and try again.';
    case 'PGRST301':
    case '401':
      return 'Your session has expired. Please sign in again.';
  }
  return fallback ?? _generic;
}
