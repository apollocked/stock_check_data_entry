import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockly/core/theme/app_theme.dart';
import 'package:stockly/presentation/controllers/auth_actions.dart';
import 'package:stockly/presentation/providers/repository_providers.dart';
import 'package:stockly/presentation/screens/settings/item_fields_screen.dart';
import 'package:stockly/presentation/screens/settings/settings_screen.dart';

import 'helpers/fake_inventory_repository.dart';

class _FakeAuth extends AuthActions {
  @override
  String? get currentEmail => 'sam@example.com';
}

Future<FakeInventoryRepository> _pump(
  WidgetTester tester,
  Widget screen,
) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final repo = FakeInventoryRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(repo),
        authActionsProvider.overrideWithValue(_FakeAuth()),
      ],
      child: MaterialApp(theme: lightTheme, home: screen),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  return repo;
}

void main() {
  testWidgets('settings shows store, theme and account', (tester) async {
    await _pump(tester, const SettingsScreen());
    expect(find.text('Corner Shop'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('sam@example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('item field toggles are saved', (tester) async {
    final repo = await _pump(tester, const ItemFieldsScreen());
    expect(find.text('No changes'), findsOneWidget);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Barcode'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Save changes'));
    await tester.pump(const Duration(seconds: 1));

    final fields = repo.lastStoreUpdate!['fields'] as List;
    final barcode = fields.firstWhere((f) => f['id'] == 'barcode') as Map;
    expect(barcode['enabled'], isTrue);
    expect(find.text('No changes'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });
}
