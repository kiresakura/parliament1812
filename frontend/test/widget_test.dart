// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:parliament_1812/main.dart';
import 'package:parliament_1812/providers/accessibility_provider.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Create accessibility provider for testing
    final accessibilityProvider = AccessibilityProvider();

    // Build our app and trigger a frame.
    await tester.pumpWidget(Parliament1812App(
      accessibilityProvider: accessibilityProvider,
    ));

    // Verify that the app title components are displayed
    expect(find.text('1812'), findsOneWidget);
    expect(find.text('國會風雲'), findsOneWidget);
  });
}
