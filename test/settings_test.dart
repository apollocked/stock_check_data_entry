import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockly/core/theme/app_theme.dart';
import 'package:stockly/presentation/controllers/auth_actions.dart';
import 'package:stockly/presentation/providers/repository_providers.dart';
import 'package:stockly/presentation/screens/settings/item_fields_screen.dart';
import 'package:stockly/domain/entities/member.dart';
import 'package:stockly/domain/repositories/access_repository.dart';
import 'package:stockly/presentation/screens/settings/settings_screen.dart';
import 'package:stockly/presentation/screens/settings/team_screen.dart';

import 'helpers/fake_inventory_repository.dart';

class _FakeAccess implements AccessRepository {
  final members = [
    Member(
      userId: 'a',
      email: 'sam@example.com',
      addedAt: DateTime(2026, 9, 1),
      isMe: true,
    ),
    Member(
      userId: 'b',
      email: 'alex@example.com',
      addedAt: DateTime(2026, 9, 5),
    ),
  ];
  final removed = <String>[];

  @override
  Future<bool> hasAccess() async => true;
  @override
  Future<List<Member>> fetchMembers() async =>
      members.where((m) => !removed.contains(m.userId)).toList();
  @override
  Future<void> addMember(String email) async {}
  @override
  Future<void> removeMember(String userId) async => removed.add(userId);
}

class _FakeAuth extends AuthActions {
  @override
  String? get currentEmail => 'sam@example.com';
}

final access = _FakeAccess();

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
        accessRepositoryProvider.overrideWithValue(access),
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

  testWidgets('team lists members and removes one', (tester) async {
    await _pump(tester, const TeamScreen());
    expect(find.text('You'), findsOneWidget);
    expect(find.text('alex@example.com'), findsOneWidget);
    // Only the other member can be removed.
    expect(find.byTooltip('Remove access'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove access'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pump(const Duration(seconds: 1));

    expect(access.removed, ['b']);
    expect(find.text('alex@example.com'), findsNothing);
    await tester.pump(const Duration(seconds: 4));
  });
}
