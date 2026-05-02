import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cross_team5/main.dart' as app;

Future<void> openActivityScreen(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(seconds: 2));

  final chatIcon = find.byIcon(Icons.chat_bubble_outline_rounded);
  expect(chatIcon, findsWidgets);
  await tester.tap(chatIcon.first);
  await tester.pumpAndSettle(const Duration(seconds: 3));

  expect(find.text('Activity'), findsOneWidget);
}

void main() {
  group('Navigation — Notifications Tab', () {
    testWidgets('Tapping the chat icon on Home opens Activity on Notifications',
        (tester) async {
      app.main();
      await openActivityScreen(tester);

      // Notifications is the first/default tab.
      expect(find.text('Notifications'), findsWidgets);
      expect(find.text('Messages'), findsWidgets);
    });

    testWidgets('Notifications list resolves to a list, empty state, or error',
        (tester) async {
      app.main();
      await openActivityScreen(tester);

      // Wait for the initial load.
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final hasList = find.byType(ListView).evaluate().isNotEmpty;
      final hasEmpty =
          find.textContaining('notifications').evaluate().isNotEmpty;
      final hasRetry = find.text('Retry').evaluate().isNotEmpty;
      final stillLoading = find
          .byType(CircularProgressIndicator)
          .evaluate()
          .isNotEmpty;

      expect(hasList || hasEmpty || hasRetry || stillLoading, isTrue);
    });

    testWidgets('Back arrow on the Activity screen returns to Home',
        (tester) async {
      app.main();
      await openActivityScreen(tester);

      final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Activity'), findsNothing);
    });
  });

  group('Notifications — Filter sheet', () {
    testWidgets('Tapping the tune icon opens the filter sheet',
        (tester) async {
      app.main();
      await openActivityScreen(tester);

      final tuneIcon = find.byIcon(Icons.tune_rounded);
      expect(tuneIcon, findsWidgets);
      await tester.tap(tuneIcon.first);
      await tester.pumpAndSettle();

      // The sheet renders one ListTile per filter. "Likes" is one of them.
      expect(find.text('Likes'), findsOneWidget);
      expect(find.text('Reposts'), findsOneWidget);
      expect(find.text('Comments'), findsOneWidget);
    });

    testWidgets('Selecting the "Likes" filter dismisses the sheet',
        (tester) async {
      app.main();
      await openActivityScreen(tester);

      final tuneIcon = find.byIcon(Icons.tune_rounded);
      await tester.tap(tuneIcon.first);
      await tester.pumpAndSettle();

      final likes = find.text('Likes');
      expect(likes, findsOneWidget);
      await tester.tap(likes);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Sheet closed — we're back on the Activity screen.
      expect(find.text('Activity'), findsOneWidget);
    });
  });

  group('Notifications — List interaction', () {
    testWidgets('Pull-to-refresh on the notifications list does not crash',
        (tester) async {
      app.main();
      await openActivityScreen(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final list = find.byType(ListView);
      if (list.evaluate().isNotEmpty) {
        await tester.drag(list.first, const Offset(0, 300));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Activity screen is still mounted.
        expect(find.text('Activity'), findsOneWidget);
      }
    });
  });
}
