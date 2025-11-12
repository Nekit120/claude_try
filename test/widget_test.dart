import 'package:flutter_test/flutter_test.dart';

import 'package:claude/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CheckersApp());

    // Verify that our app builds correctly
    expect(find.text('Русские шашки'), findsOneWidget);
  });
}
