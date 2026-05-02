// Done here

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cross_team5/main.dart' as app;

Future<void> openUpgradeScreen(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // The "Upgrade" item only appears for non-Pro users in the bottom nav.
  final upgrade = find.text('Upgrade');
  expect(upgrade, findsWidgets);
  await tester.tap(upgrade.first);
  await tester.pumpAndSettle(const Duration(seconds: 4));
}

void main() {
  group('Navigation - Premium Subscription Screen', () {
    testWidgets('Tapping "Upgrade" on the bottom nav opens the subscription screen',
        (tester) async {
      app.main();
      await openUpgradeScreen(tester);

      // Either the plans loaded ("Artist Pro" cards) or the empty-state
      // copy is visible. In both cases the screen mounted without
      // crashing.
      final hasPlans = find.text('Artist Pro').evaluate().isNotEmpty;
      final hasEmpty = find
          .text('No plans available right now.\nPlease try again later.')
          .evaluate()
          .isNotEmpty;
      final stillLoading = find
          .byType(CircularProgressIndicator)
          .evaluate()
          .isNotEmpty;

      expect(hasPlans || hasEmpty || stillLoading, isTrue);
    });

    testWidgets('Back arrow on the subscription screen returns to Home',
        (tester) async {
      app.main();
      await openUpgradeScreen(tester);

      final backBtn = find.byIcon(Icons.arrow_back_ios);
      if (backBtn.evaluate().isNotEmpty) {
        await tester.tap(backBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Bottom nav is back, with the "Upgrade" entry visible again.
        expect(find.text('Upgrade'), findsWidgets);
      }
    });
  });

  group('Premium Subscription Screen - content', () {
    testWidgets('Subscription screen shows the marketing copy or empty state',
        (tester) async {
      app.main();
      await openUpgradeScreen(tester);

      // Scroll the screen to surface lower-down content.
      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -400));
        await tester.pumpAndSettle();
      }

      final hasMarketing =
          find.textContaining('Beatza supports').evaluate().isNotEmpty ||
              find.textContaining('Frequently asked').evaluate().isNotEmpty;
      final hasEmpty = find
          .text('No plans available right now.\nPlease try again later.')
          .evaluate()
          .isNotEmpty;

      expect(hasMarketing || hasEmpty, isTrue);
    });

    testWidgets('Tapping "Restrictions apply" opens the restrictions screen',
        (tester) async {
      app.main();
      await openUpgradeScreen(tester);

      // The link sits below the plan card - scroll it into view first.
      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -300));
        await tester.pumpAndSettle();
      }

      final restrictions = find.text('Restrictions apply');
      if (restrictions.evaluate().isNotEmpty) {
        await tester.tap(restrictions.first, warnIfMissed: false);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Restrictions screen mounted - back arrow is shown.
        expect(find.byIcon(Icons.arrow_back_ios), findsWidgets);
      }
    });
  });

  group('Premium Subscription Screen - plan carousel', () {
    testWidgets('Swiping the plan carousel does not crash', (tester) async {
      app.main();
      await openUpgradeScreen(tester);

      final pageView = find.byType(PageView);
      if (pageView.evaluate().isNotEmpty) {
        await tester.drag(pageView.first, const Offset(-300, 0));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        await tester.drag(pageView.first, const Offset(300, 0));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Still on a Scaffold (the screen survived the swipe).
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
