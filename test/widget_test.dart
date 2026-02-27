// This is a basic Flutter widget test.
//
// To perform an interaction with a widget, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_2/main.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Word of the Day app displays correctly and has timer', (
    WidgetTester tester,
  ) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Wait for the async loading to complete
    await tester.pumpAndSettle();

    // Verify that the app title is displayed.
    expect(find.text('Word of the Day'), findsOneWidget);

    // Verify that the 'NEXT WORD IN' text is present (replaces Next Word button)
    expect(find.text('NEXT WORD IN'), findsOneWidget);

    // Verify that the share button is present
    expect(find.byTooltip('Share Word'), findsOneWidget);
    
    // Verify that the favorite button is present
    expect(find.byTooltip('Favorite'), findsOneWidget);
  });
}
