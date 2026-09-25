import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controllers.dart';
import 'app_routes.dart';

/// Where the user is in the sign-in flow. The router redirects on this.
enum Gate { loading, signedOut, recovery, noAccess, ready }

final gateProvider = Provider<Gate>((ref) {
  final session = ref.watch(sessionStateProvider);
  return session.when(
    loading: () => Gate.loading,
    error: (_, _) => Gate.signedOut,
    data: (status) => switch (status) {
      AuthStatus.signedOut => Gate.signedOut,
      AuthStatus.passwordRecovery => Gate.recovery,
      // Only signed-in accounts are checked, so the membership check always
      // runs for the current user (it is disposed on sign-out).
      AuthStatus.signedIn =>
        ref
            .watch(accessProvider)
            .when(
              skipLoadingOnRefresh: false,
              loading: () => Gate.loading,
              error: (_, _) => Gate.noAccess,
              data: (allowed) => allowed ? Gate.ready : Gate.noAccess,
            ),
    },
  );
});

/// The redirect for [location] in the current [gate] state, or null to stay.
String? redirectFor(Gate gate, String location) {
  final target = switch (gate) {
    Gate.loading => AppRoutes.splash,
    Gate.signedOut => AppRoutes.login,
    Gate.recovery => AppRoutes.resetPassword,
    Gate.noAccess => AppRoutes.noAccess,
    Gate.ready => null,
  };
  if (target != null) return location == target ? null : target;
  return AppRoutes.gateRoutes.contains(location) ? AppRoutes.inventory : null;
}
