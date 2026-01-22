// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parliament_1812/app/app.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: Parliament1812App(),
      ),
    );

    // Wait for fonts to load
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that the app loads without crashing
    expect(find.byType(Parliament1812App), findsOneWidget);
  });
}
