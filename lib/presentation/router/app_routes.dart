import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/item.dart';

/// Every path in the app, plus typed helpers so screens never build URLs by
/// hand.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const resetPassword = '/reset-password';
  static const noAccess = '/no-access';

  static const inventory = '/inventory';
  static const reports = '/reports';
  static const history = '/history';
  static const settings = '/settings';

  static const scan = '/scan';
  static const newItem = '/items/new';
  static const item = '/items/:id';
  static const editItem = '/items/:id/edit';
  static const itemFields = '/settings/fields';
  static const team = '/settings/team';

  /// Screens shown only while signing in; a ready user is sent home.
  static const gateRoutes = {splash, login, resetPassword, noAccess};
}

extension AppNavigation on BuildContext {
  Future<void> openItem(Item item) => push('/items/${item.id}', extra: item);

  Future<void> editItem(Item item) =>
      push('/items/${item.id}/edit', extra: item);

  Future<void> newItem({String barcode = ''}) => push(
    Uri(
      path: AppRoutes.newItem,
      queryParameters: barcode.isEmpty ? null : {'barcode': barcode},
    ).toString(),
  );

  Future<void> openScanner() => push(AppRoutes.scan);
}
