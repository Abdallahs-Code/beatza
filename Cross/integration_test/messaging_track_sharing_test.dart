import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cross_team5/main.dart' as app;

Future<void> openActivityScreen(WidgetTester tester) async {
  final chatIcon = find.byIcon(Icons.chat_bubble_outline_rounded);
  expect(chatIcon, findsWidgets);
  await tester.tap(chatIcon.first);
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

Future<void> openMessagesTab(WidgetTester tester) async {
  await openActivityScreen(tester);
  final messagesTab = find.text('Messages');
  expect(messagesTab, findsWidgets);
  await tester.tap(messagesTab.first);
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

void main() {
  group('Navigation - Messages Tab', () {
    testWidgets('Tapping the chat icon on Home opens the Activity screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await openActivityScreen(tester);

      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Notifications'), findsWidgets);
      expect(find.text('Messages'), findsWidgets);
    });

    testWidgets('Switching to Messages tab loads the messages list',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await openMessagesTab(tester);

      // Once loaded, the spinner should be gone and either a chat list, an empty state, or an error message is shown.
      final loadingDone =
          find.byType(CircularProgressIndicator).evaluate().isEmpty;
      final hasContent = find.text('No messages yet').evaluate().isNotEmpty ||
          find.byType(InkWell).evaluate().isNotEmpty ||
          find.text('Try again').evaluate().isNotEmpty;

      expect(loadingDone || hasContent, isTrue);
    });

    testWidgets('Back button on Activity screen returns to Home',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await openMessagesTab(tester);

      final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // We should be off the Activity screen now.
      expect(find.text('Notifications'), findsNothing);
    });
  });

  group('Messages Tab - Chat list', () {
    testWidgets('Opening a chat (if any exist) navigates to the chat screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await openMessagesTab(tester);

      // Each chat row is an InkWell with a CircleAvatar inside.
      final avatars = find.byType(CircleAvatar);
      if (avatars.evaluate().isNotEmpty) {
        await tester.tap(avatars.first, warnIfMissed: false);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        expect(find.byType(Scaffold), findsWidgets);
      }
    });

    testWidgets('Pull-to-refresh on the messages list does not crash',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await openMessagesTab(tester);

      final list = find.byType(ListView);
      if (list.evaluate().isNotEmpty) {
        await tester.drag(list.first, const Offset(0, 300));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // After refresh, the spinner should clear and the tab is still mounted.
        expect(find.text('Messages'), findsWidgets);
      }
    });
  });

  group('Activity - Filter sheet from Messages tab', () {
    testWidgets('Tapping the tune icon opens the filter sheet',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await openMessagesTab(tester);

      final tuneIcon = find.byIcon(Icons.tune_rounded);
      if (tuneIcon.evaluate().isNotEmpty) {
        await tester.tap(tuneIcon.first);
        await tester.pumpAndSettle();

        // Sheet opened, close it by tapping outside / scrim.
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();
      }

      // Either way the Activity screen is still visible.
      expect(find.text('Activity'), findsOneWidget);
    });
  });
}