import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_2/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  testWidgets('የቀኑ ቃል app displays correctly and has timer', (
    WidgetTester tester,
  ) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    
    // Initialize date formatting for tests
    await initializeDateFormatting('am', null);
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Wait for the async loading to complete
    await tester.pumpAndSettle();

    // Verify that the app title is displayed.
    expect(find.text('የቀኑ ቃል'), findsOneWidget);

    // Tap the 3rd tab (TIMER)
    await tester.tap(find.byIcon(Icons.timer_outlined));
    await tester.pumpAndSettle();

    // Verify that the 'የሚቀጥለው ቃል በ' text is present
    expect(find.text('የሚቀጥለው ቃል በ'), findsOneWidget);

    // Go back to the 1st tab (WORD)
    await tester.tap(find.byIcon(Icons.menu_book_rounded));
    await tester.pumpAndSettle();

    // Verify that the favorite button is present
    expect(find.byTooltip('ተወዳጆች'), findsOneWidget);
  });
}
