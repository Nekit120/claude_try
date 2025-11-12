import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:claude/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Увеличиваем размер экрана для теста
    await tester.binding.setSurfaceSize(const Size(1080, 1920));

    await tester.pumpWidget(const CheckersApp());

    // Verify that our app builds correctly
    expect(find.text('Русские шашки'), findsOneWidget);

    // Restore default size
    await tester.binding.setSurfaceSize(null);
  });
}
