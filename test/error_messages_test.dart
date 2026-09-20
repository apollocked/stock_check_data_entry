import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stockly/core/error/app_exception.dart';
import 'package:stockly/core/error/error_messages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('friendlyError', () {
    test('keeps the message of an AppException', () {
      expect(
        friendlyError(const AppException('Could not load items.')),
        'Could not load items.',
      );
    });

    test('reports connection problems', () {
      const expected =
          'No internet connection. Check your network and try again.';
      expect(
        friendlyError(const SocketException('Failed host lookup')),
        expected,
      );
      expect(
        friendlyError(Exception('ClientException: Connection failed')),
        expected,
      );
    });

    test('reports timeouts', () {
      expect(
        friendlyError(TimeoutException('slow')),
        'The server took too long to respond. Please try again.',
      );
    });

    test('shows messages raised by our own database functions', () {
      expect(
        friendlyError(
          const PostgrestException(message: 'Item not found.', code: 'P0001'),
        ),
        'Item not found.',
      );
    });

    test('hides raw database text', () {
      final message = friendlyError(
        const PostgrestException(
          message:
              'duplicate key value violates unique constraint "items_pkey"',
          code: '23505',
        ),
      );
      expect(message, isNot(contains('items_pkey')));
      expect(message, contains('already exists'));
    });

    test('uses the fallback for unknown database errors', () {
      expect(
        friendlyError(
          const PostgrestException(message: 'boom', code: 'XX000'),
          fallback: 'Could not save item.',
        ),
        'Could not save item.',
      );
    });

    test('explains common sign-in problems', () {
      expect(
        friendlyError(
          const AuthException(
            'Invalid login credentials',
            code: 'invalid_credentials',
          ),
        ),
        'Wrong email or password.',
      );
      expect(
        friendlyError(
          const AuthException(
            'Email not confirmed',
            code: 'email_not_confirmed',
          ),
        ),
        contains('confirm your email'),
      );
    });

    test('falls back to a generic message', () {
      expect(
        friendlyError(StateError('secret internals')),
        'Something went wrong. Please try again.',
      );
    });
  });

  group('toAppException', () {
    test('wraps errors with a friendly message and keeps the cause', () {
      final cause = StateError('secret internals');
      final result = toAppException(cause, 'Could not save item.');
      expect(result.message, 'Could not save item.');
      expect(result.type, AppExceptionType.database);
      expect(result.cause, same(cause));
    });

    test('marks connection problems as network errors', () {
      final result = toAppException(
        const SocketException('offline'),
        'Could not load items.',
        AppExceptionType.database,
      );
      expect(result.type, AppExceptionType.network);
    });

    test('does not wrap an AppException twice', () {
      const original = AppException('Item not found.');
      expect(toAppException(original, 'Could not save item.'), same(original));
    });
  });
}
