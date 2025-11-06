import 'package:flutter_test/flutter_test.dart';
import 'package:catalog_app/main.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('MyApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app starts properly
    expect(find.byType(MyApp), findsOneWidget);
  });
}
