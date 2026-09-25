import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stockly/core/security/password_policy.dart';
import 'package:stockly/core/security/spreadsheet_safety.dart';
import 'package:stockly/core/security/trusted_url.dart';
import 'package:stockly/data/datasources/image_storage_datasource.dart';

void main() {
  group('neutralizeFormula', () {
    test('escapes values a spreadsheet would run', () {
      expect(neutralizeFormula('=1+1'), "'=1+1");
      expect(neutralizeFormula('+cmd'), "'+cmd");
      expect(neutralizeFormula('-2+3'), "'-2+3");
      expect(neutralizeFormula('@SUM(A1)'), "'@SUM(A1)");
      expect(neutralizeFormula('\t=x'), "'\t=x");
    });

    test('leaves plain text and signed numbers alone', () {
      expect(neutralizeFormula('Milk 1L'), 'Milk 1L');
      expect(neutralizeFormula(''), '');
      expect(neutralizeFormula('-3'), '-3');
      expect(neutralizeFormula('+5.50'), '+5.50');
    });
  });

  group('isTrustedImageUrl', () {
    const project = 'https://abcd.supabase.co';

    test('accepts HTTPS links on the project host', () {
      expect(
        isTrustedImageUrl(
          'https://abcd.supabase.co/storage/v1/object/public/grocery_images/items/x.jpg',
          supabaseUrl: project,
        ),
        isTrue,
      );
    });

    test('rejects other hosts, plain HTTP and empty values', () {
      expect(
        isTrustedImageUrl('https://evil.example/x.jpg', supabaseUrl: project),
        isFalse,
      );
      expect(
        isTrustedImageUrl(
          'https://abcd.supabase.co.evil.example/x.jpg',
          supabaseUrl: project,
        ),
        isFalse,
      );
      expect(
        isTrustedImageUrl(
          'http://abcd.supabase.co/x.jpg',
          supabaseUrl: project,
        ),
        isFalse,
      );
      expect(isTrustedImageUrl(null, supabaseUrl: project), isFalse);
      expect(isTrustedImageUrl('', supabaseUrl: project), isFalse);
      expect(
        isTrustedImageUrl('https://abcd.supabase.co/x', supabaseUrl: ''),
        isFalse,
      );
    });
  });

  group('detectImageType', () {
    Uint8List bytes(List<int> v) => Uint8List.fromList([...v, 0, 0, 0, 0]);

    test('reads real image signatures', () {
      expect(
        detectImageType(bytes([0xFF, 0xD8, 0xFF]))?.mimeType,
        'image/jpeg',
      );
      expect(
        detectImageType(bytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]))
            ?.mimeType,
        'image/png',
      );
      expect(
        detectImageType(bytes([0x47, 0x49, 0x46, 0x38]))?.mimeType,
        'image/gif',
      );
      expect(
        detectImageType(
          bytes([0x52, 0x49, 0x46, 0x46, 1, 2, 3, 4, 0x57, 0x45, 0x42, 0x50]),
        )?.mimeType,
        'image/webp',
      );
    });

    test('rejects anything else, whatever its name', () {
      expect(detectImageType(bytes('<html>'.codeUnits)), isNull);
      expect(detectImageType(Uint8List(0)), isNull);
    });
  });

  test('randomObjectName is 32 hex characters and unique', () {
    final a = randomObjectName();
    expect(a, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(randomObjectName(), isNot(a));
  });

  test('validateNewPassword', () {
    expect(validateNewPassword('short1'), isNotNull);
    expect(validateNewPassword('onlyletters'), isNotNull);
    expect(validateNewPassword('12345678'), isNotNull);
    expect(validateNewPassword('stockly2026'), isNull);
  });
}
