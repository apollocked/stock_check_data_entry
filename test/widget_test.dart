import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stockly/main.dart';

void main() {
  testWidgets('App shows login screen when signed out', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: StocklyApp()));
    await tester.pump();
    await tester.pumpAndSettle();
    // Let delayed entrance animations finish.
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Stockly'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });
}
