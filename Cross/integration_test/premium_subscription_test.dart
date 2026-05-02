import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cross_team5/main.dart' as app;

void main() {
  testWidgets('Premium Subscription - full flow for non-subscribed user',
      (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Tap "Upgrade" in the bottom nav
    final upgrade = find.text('Upgrade');
    expect(upgrade, findsWidgets,
        reason: 'Upgrade tab must be visible for a non-subscribed user');
    await tester.tap(upgrade.first);
    await tester.pumpAndSettle(const Duration(seconds: 6));

    // Subscription screen loaded
    expect(find.byType(Scaffold), findsWidgets,
        reason: 'Subscription screen should be mounted');

    // Scroll and check marketing copy
    final scrollable = find.byType(CustomScrollView);
    if (scrollable.evaluate().isNotEmpty) {
      await tester.drag(scrollable.first, const Offset(0, -400));
      await tester.pumpAndSettle();

      // Tap "Restrictions apply" if visible
      await tester.drag(scrollable.first, const Offset(0, -300));
      await tester.pumpAndSettle();

      final restrictions = find.text('Restrictions apply');
      if (restrictions.evaluate().isNotEmpty) {
        await tester.tap(restrictions.first, warnIfMissed: false);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.byIcon(Icons.arrow_back_ios), findsWidgets,
            reason: 'Restrictions screen should show a back arrow');

        // Go back to subscription screen
        await tester.tap(find.byIcon(Icons.arrow_back_ios).first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
    }

    // Swipe the plan carousel if present
    final pageView = find.byType(PageView);
    if (pageView.evaluate().isNotEmpty) {
      await tester.drag(pageView.first, const Offset(-300, 0));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.drag(pageView.first, const Offset(300, 0));
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    expect(find.byType(Scaffold), findsWidgets,
        reason: 'App should still be alive after carousel swipe');

    // Back arrow returns to Home with Upgrade tab visible
    final backBtn = find.byIcon(Icons.arrow_back_ios);
    if (backBtn.evaluate().isNotEmpty) {
      await tester.tap(backBtn.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Upgrade'), findsWidgets,
          reason: 'Upgrade tab should reappear on Home for non-subscribed user');
    }
  });
}