// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';

void main() {
  testWidgets('Splash screen loads successfully and displays branding', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our branding description text is present on the splash screen.
    expect(find.text('Your smart food & health companion'), findsOneWidget);

    // Pump frames to let the authentication check transition timer finish
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}

