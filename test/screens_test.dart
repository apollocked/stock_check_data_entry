import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockly/core/theme/app_theme.dart';
import 'package:stockly/presentation/providers/repository_providers.dart';
import 'package:stockly/presentation/screens/history/history_screen.dart';
import 'package:stockly/presentation/screens/inventory/inventory_screen.dart';
import 'package:stockly/presentation/screens/items/item_details_screen.dart';
import 'package:stockly/presentation/screens/reports/reports_screen.dart';

import 'helpers/fake_inventory_repository.dart';

/// Renders [screen] with fake data in light and dark themes, so layout
/// errors (which the analyzer can't see) fail the test.
Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  bool dark = false,
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(
          FakeInventoryRepository(),
        ),
      ],
      child: MaterialApp(
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: screen,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';

    testWidgets('inventory lists items with filters ($mode)', (tester) async {
      await _pump(tester, const InventoryScreen(), dark: dark);
      expect(find.text('Corner Shop'), findsWidgets);
      expect(find.text('Oat milk'), findsOneWidget);
      expect(find.text('Out of stock'), findsOneWidget);
      expect(find.textContaining('Low stock ·'), findsWidgets);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('reports dashboard renders ($mode)', (tester) async {
      await _pump(tester, const ReportsScreen(), dark: dark);
      expect(find.text('Stock value'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Stock health'), 300);
      await tester.scrollUntilVisible(find.text('Recent movements'), 300);
      expect(find.text('Recent movements'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('item details show stock and history ($mode)', (tester) async {
      await _pump(tester, const ItemDetailsScreen(itemId: 1), dark: dark);
      expect(find.text('Oat milk'), findsWidgets);
      expect(find.text('Count'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Weekend sale'), 300);
      expect(find.text('Weekend sale'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('history shows the day summary and movements', (tester) async {
    await _pump(tester, const HistoryScreen());
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Net'), findsOneWidget);
    // The outer list; the day strip is a second, horizontal scrollable.
    await tester.scrollUntilVisible(
      find.text('Weekend sale'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('filter chips narrow the inventory', (tester) async {
    await _pump(tester, const InventoryScreen());
    await tester.tap(find.textContaining('Out of stock ·'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Eggs'), findsOneWidget);
    expect(find.text('Oat milk'), findsNothing);
  });
}
