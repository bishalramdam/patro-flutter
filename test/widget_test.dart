// widget_test.dart
// Basic smoke test for Patro Flutter App.

import 'package:flutter_test/flutter_test.dart';
import 'package:patro_flutter/main.dart';
import 'package:patro_flutter/engine/patro_engine.dart';

void main() {
  testWidgets('Patro app loads correctly smoke test', (WidgetTester tester) async {
    final engine = PatroEngine.instance;
    await tester.pumpWidget(PatroApp(engine: engine));
    await tester.pump();

    // Verify app bar title "पात्रो" exists
    expect(find.text('पात्रो'), findsWidgets);
    expect(find.text('आज'), findsOneWidget);
  });
}
