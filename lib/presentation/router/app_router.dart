import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/item.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/no_access_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/barcode_lookup_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/new_item_form_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/settings/item_fields_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/shell/home_shell.dart';
import '../widgets/motion/fade_through_stack.dart';
import 'app_gate.dart';
import 'app_routes.dart';
import 'item_route_loader.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  // The router is built once; gate changes (sign in, sign out, access
  // granted) re-run the redirect through this listenable.
  final gate = ValueNotifier<Gate>(ref.read(gateProvider));
  ref.listen(gateProvider, (_, next) => gate.value = next);
  ref.onDispose(gate.dispose);

  GoRoute tab(String path, Widget screen) =>
      GoRoute(path: path, builder: (_, _) => screen);

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.inventory,
    refreshListenable: gate,
    redirect: (_, state) => redirectFor(gate.value, state.matchedLocation),
    routes: [
      tab(AppRoutes.splash, const SplashScreen()),
      tab(AppRoutes.login, const LoginScreen()),
      tab(AppRoutes.resetPassword, const ResetPasswordScreen()),
      tab(AppRoutes.noAccess, const NoAccessScreen()),
      StatefulShellRoute(
        builder: (_, _, shell) => shell,
        navigatorContainerBuilder: (context, shell, children) => HomeShell(
          shell: shell,
          child: FadeThroughStack(
            index: shell.currentIndex,
            children: children,
          ),
        ),
        branches: [
          StatefulShellBranch(
            routes: [tab(AppRoutes.inventory, const InventoryScreen())],
          ),
          StatefulShellBranch(
            routes: [tab(AppRoutes.reports, const ReportsScreen())],
          ),
          StatefulShellBranch(
            routes: [tab(AppRoutes.history, const HistoryScreen())],
          ),
          StatefulShellBranch(
            routes: [tab(AppRoutes.settings, const SettingsScreen())],
          ),
        ],
      ),
      tab(AppRoutes.scan, const BarcodeLookupScreen()),
      tab(AppRoutes.itemFields, const ItemFieldsScreen()),
      GoRoute(
        path: AppRoutes.newItem,
        builder: (_, state) =>
            ItemFormScreen(barcode: state.uri.queryParameters['barcode'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.editItem,
        builder: (_, state) => ItemRouteLoader(
          id: int.tryParse(state.pathParameters['id'] ?? ''),
          initial: state.extra as Item?,
          builder: (item) => ItemFormScreen(existingItem: item),
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
