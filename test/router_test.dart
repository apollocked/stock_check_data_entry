import 'package:flutter_test/flutter_test.dart';
import 'package:stockly/presentation/router/app_gate.dart';
import 'package:stockly/presentation/router/app_routes.dart';

void main() {
  group('redirectFor', () {
    test('signed-out users always land on sign-in', () {
      expect(redirectFor(Gate.signedOut, AppRoutes.inventory), AppRoutes.login);
      expect(redirectFor(Gate.signedOut, '/items/4'), AppRoutes.login);
      expect(redirectFor(Gate.signedOut, AppRoutes.login), isNull);
    });

    test('a password reset link must be finished first', () {
      expect(
        redirectFor(Gate.recovery, AppRoutes.settings),
        AppRoutes.resetPassword,
      );
      expect(redirectFor(Gate.recovery, AppRoutes.resetPassword), isNull);
    });

    test('accounts without access cannot reach store screens', () {
      expect(redirectFor(Gate.noAccess, AppRoutes.reports), AppRoutes.noAccess);
      expect(redirectFor(Gate.noAccess, AppRoutes.scan), AppRoutes.noAccess);
    });

    test('loading shows the splash', () {
      expect(redirectFor(Gate.loading, AppRoutes.inventory), AppRoutes.splash);
    });

    test('ready users leave the sign-in screens and keep app screens', () {
      for (final route in AppRoutes.gateRoutes) {
        expect(redirectFor(Gate.ready, route), AppRoutes.inventory);
      }
      expect(redirectFor(Gate.ready, AppRoutes.history), isNull);
      expect(redirectFor(Gate.ready, '/items/7/edit'), isNull);
    });
  });
}
