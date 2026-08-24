import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_check_entry/main.dart';

void main() {
  testWidgets('App renders entry screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: StockCheckEntryApp()),
    );
    await tester.pump();
    expect(find.text('Add item'), findsOneWidget);
  });
}
