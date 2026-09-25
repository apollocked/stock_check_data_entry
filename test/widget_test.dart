import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockly/main.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  // "Reduce motion" stops the looping sign-in background, so frames settle.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  await tester.pumpWidget(const ProviderScope(child: StocklyApp()));
  // Supabase is not initialized in tests, so the app treats this as signed
  // out and the router redirects to sign-in.
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  testWidgets('signed-out users see the sign-in screen', (tester) async {
    await _pumpApp(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });

  testWidgets('switching to sign-up changes the form', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Create account').first);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Forgot password?'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Create account'), findsOneWidget);
  });

  testWidgets('the form validates before calling the server', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });
}
