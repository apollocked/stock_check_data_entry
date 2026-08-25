import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_check_entry/main.dart';

void main() {
  testWidgets('App shows login screen when signed out', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: StockCheckEntryApp()));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });
}
