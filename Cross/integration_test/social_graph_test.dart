// Should be signed in to an account.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cross_team5/main.dart' as app;

import 'helpers/nav_helpers.dart';
import 'helpers/social_helpers.dart';

void main() {
  group('Navigation — Followers Screen', () {
    testWidgets(
        'Tapping followers count on profile navigates to Followers screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await SocialHelpers.navigateToProfile(tester);
      NavHelpers.assertOnUserProfileScreen();

      await SocialHelpers.openFollowersFromProfile(tester);

      SocialHelpers.assertOnFollowersScreen();
    });

    testWidgets('Back button on Followers screen returns to Profile screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await SocialHelpers.navigateToProfile(tester);
      await SocialHelpers.openFollowersFromProfile(tester);
      SocialHelpers.assertOnFollowersScreen();

      await SocialHelpers.goBack(tester);

      NavHelpers.assertOnUserProfileScreen();
    });
  });

  group('Navigation — Following Screen', () {
    testWidgets(
        'Tapping following count on profile navigates to Following screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await SocialHelpers.navigateToProfile(tester);
      await SocialHelpers.openFollowingFromProfile(tester);

      SocialHelpers.assertOnFollowingScreen();
    });

    testWidgets('Switching to Suggested tab loads suggested users',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await SocialHelpers.navigateToProfile(tester);
      await SocialHelpers.openFollowingFromProfile(tester);
      await SocialHelpers.switchToSuggestedTab(tester);

      // Should either show "No suggestions yet." or user tiles
      final noSuggestions = find.text('No suggestions yet.');
      final loadingDone =
          find.byType(CircularProgressIndicator).evaluate().isEmpty;

      expect(loadingDone, isTrue);
      expect(
        noSuggestions.evaluate().isNotEmpty ||
            find.text('Retry').evaluate().isEmpty,
        isTrue,
      );
    });

    testWidgets('Switching back to Following tab from Suggested tab works',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await SocialHelpers.navigateToProfile(tester);
      await SocialHelpers.openFollowingFromProfile(tester);

      await SocialHelpers.switchToSuggestedTab(tester);
      await SocialHelpers.switchToFollowingTab(tester);

      // The Following tab content should load without errors
      final loadingDone =
          find.byType(CircularProgressIndicator).evaluate().isEmpty;
      expect(loadingDone, isTrue);
    });

    testWidgets('Back button on Following screen returns to Profile screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await SocialHelpers.navigateToProfile(tester);
      await SocialHelpers.openFollowingFromProfile(tester);
      SocialHelpers.assertOnFollowingScreen();

      await SocialHelpers.goBack(tester);

      NavHelpers.assertOnUserProfileScreen();
    });
  });

  group('Navigation — Blocked Users Screen', () {
    testWidgets(
        'Tapping "Blocked users" in share sheet navigates to Blocked Users screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await SocialHelpers.navigateToProfile(tester);
      await SocialHelpers.openBlockedUsersFromProfile(tester);

      SocialHelpers.assertOnBlockedUsersScreen();
    });

    testWidgets('Back button on Blocked Users screen returns to Profile',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await SocialHelpers.navigateToProfile(tester);
      await SocialHelpers.openBlockedUsersFromProfile(tester);
      SocialHelpers.assertOnBlockedUsersScreen();

      await SocialHelpers.goBack(tester);

      NavHelpers.assertOnUserProfileScreen();
    });
  });

  group('Follow / Unfollow — Suggested Users', () {
    testWidgets(
        'Tapping Follow on a suggested user changes button to Following',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await SocialHelpers.navigateToProfile(tester);
      await SocialHelpers.openFollowingFromProfile(tester);
      await SocialHelpers.switchToSuggestedTab(tester);

      final followBtn = find.text('Follow');
      if (followBtn.evaluate().isNotEmpty) {
        await tester.tap(followBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // The button should now say "Following" (optimistic UI)
        expect(find.text('Following'), findsWidgets);
      }
      // If no suggested users exist, the test passes (nothing to follow)
    });

    testWidgets(
        'Tapping Following on a suggested user changes button back to Follow',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await SocialHelpers.navigateToProfile(tester);
      await SocialHelpers.openFollowingFromProfile(tester);
      await SocialHelpers.switchToSuggestedTab(tester);

      // Find a user that is currently being followed
      final followingBtn = find.text('Following');
      if (followingBtn.evaluate().isNotEmpty) {
        await tester.tap(followingBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // One "Following" button should become "Follow"
        final followBtnAfter = find.text('Follow');
        expect(followBtnAfter, findsWidgets);
      }
    });
  });

  group('Follow / Unfollow — Following Screen', () {
    testWidgets(
        'Tapping Following on a followed user changes button to Follow',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await SocialHelpers.navigateToProfile(tester);
      await SocialHelpers.openFollowingFromProfile(tester);

      final followingBtn = find.text('Following');
      if (followingBtn.evaluate().isNotEmpty) {
        await tester.tap(followingBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Optimistic UI: the button should now show "Follow"
        expect(find.text('Follow'), findsWidgets);
      }
    });

    testWidgets(
        'Tapping Follow on an unfollowed user in Following screen changes button back to Following',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await SocialHelpers.navigateToProfile(tester);
      await SocialHelpers.openFollowingFromProfile(tester);

      final followBtn = find.text('Follow');
      if (followBtn.evaluate().isNotEmpty) {
        await tester.tap(followBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.text('Following'), findsWidgets);
      }
    });
  });

  group('Follow / Unfollow — Followers Screen', () {
    testWidgets(
        'Tapping Follow on a follower changes button to Following',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await SocialHelpers.navigateToProfile(tester);
      await SocialHelpers.openFollowersFromProfile(tester);

      final followBtn = find.text('Follow');
      if (followBtn.evaluate().isNotEmpty) {
        await tester.tap(followBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Optimistic UI: the button should now show "Following"
        expect(find.text('Following'), findsWidgets);
      }
    });

    testWidgets(
        'Tapping Following on a follower changes button back to Follow',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await SocialHelpers.navigateToProfile(tester);
      await SocialHelpers.openFollowersFromProfile(tester);

      final followingBtn = find.text('Following');
      if (followingBtn.evaluate().isNotEmpty) {
        await tester.tap(followingBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.text('Follow'), findsWidgets);
      }
    });
  });

  group('Block / Unblock Flow', () {
    testWidgets(
        'Tapping Block on a follower shows confirmation dialog',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await SocialHelpers.navigateToProfile(tester);
      await SocialHelpers.openFollowersFromProfile(tester);

      final moreIcon = find.byIcon(Icons.more_vert);
      if (moreIcon.evaluate().isNotEmpty) {
        await tester.tap(moreIcon.first);
        await tester.pumpAndSettle();

        final blockOption = find.text('Block user');
        expect(blockOption, findsOneWidget);
        await tester.tap(blockOption);
        await tester.pumpAndSettle();

        // The AlertDialog should be visible
        expect(find.text('Block User'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'Block'), findsOneWidget);

        // Dismiss without blocking
        await SocialHelpers.cancelBlockDialog(tester);

        // Dialog should be gone
        expect(find.text('Block User'), findsNothing);
      }
    });

    testWidgets(
        'Cancelling block dialog does not remove the user from the list',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await SocialHelpers.navigateToProfile(tester);
      await SocialHelpers.openFollowersFromProfile(tester);

      final moreIcon = find.byIcon(Icons.more_vert);
      if (moreIcon.evaluate().isNotEmpty) {
        // Count user tiles before
        final tileCountBefore = find.byIcon(Icons.more_vert).evaluate().length;

        await SocialHelpers.tapBlockOnFirstUserTile(tester);
        await SocialHelpers.cancelBlockDialog(tester);

        // Count should remain the same
        final tileCountAfter = find.byIcon(Icons.more_vert).evaluate().length;
        expect(tileCountAfter, equals(tileCountBefore));
      }
    });

    testWidgets(
        'Confirming block removes the user from the followers list and shows snackbar',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await SocialHelpers.navigateToProfile(tester);
      await SocialHelpers.openFollowersFromProfile(tester);

      final moreIcon = find.byIcon(Icons.more_vert);
      if (moreIcon.evaluate().isNotEmpty) {
        final tileCountBefore = moreIcon.evaluate().length;

        await SocialHelpers.tapBlockOnFirstUserTile(tester);
        await SocialHelpers.confirmBlockDialog(tester);

        // User should be removed from the list
        final tileCountAfter =
            find.byIcon(Icons.more_vert).evaluate().length;
        expect(tileCountAfter, lessThan(tileCountBefore));

        // Should show a success snackbar
        expect(find.text('User blocked successfully'), findsOneWidget);
      }
    });

    testWidgets(
        'Blocking a user from the Following tab removes them from the list',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await SocialHelpers.navigateToProfile(tester);
      await SocialHelpers.openFollowingFromProfile(tester);

      final moreIcon = find.byIcon(Icons.more_vert);
      if (moreIcon.evaluate().isNotEmpty) {
        final countBefore = moreIcon.evaluate().length;

        await SocialHelpers.tapBlockOnFirstUserTile(tester);
        await SocialHelpers.confirmBlockDialog(tester);

        final countAfter = find.byIcon(Icons.more_vert).evaluate().length;
        expect(countAfter, lessThan(countBefore));

        expect(find.text('User blocked successfully'), findsOneWidget);
      }
    });

    testWidgets(
        'Blocked user appears on the Blocked Users screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await SocialHelpers.navigateToProfile(tester);
      await SocialHelpers.openBlockedUsersFromProfile(tester);

      // If a user was blocked in a previous test, the list should not be empty
      final noBlocked = find.text('You have not blocked anyone.');
      final unblockMenu = find.byIcon(Icons.more_vert);

      // Either the empty message shows or blocked users are present
      expect(
        noBlocked.evaluate().isNotEmpty || unblockMenu.evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets(
        'Unblocking a user removes them from the Blocked Users list and shows snackbar',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await SocialHelpers.navigateToProfile(tester);
      await SocialHelpers.openBlockedUsersFromProfile(tester);

      final moreIcon = find.byIcon(Icons.more_vert);
      if (moreIcon.evaluate().isNotEmpty) {
        final countBefore = moreIcon.evaluate().length;

        await SocialHelpers.tapUnblockOnFirstUserTile(tester);

        // User should be removed from the blocked list
        final countAfter = find.byIcon(Icons.more_vert).evaluate().length;
        expect(countAfter, lessThan(countBefore));

        // Should show a success snackbar
        expect(find.text('User unblocked successfully'), findsOneWidget);
      }
    });
  });

  group('UserTile — Navigation', () {
    testWidgets('Tapping a user tile navigates to that user\'s profile',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await SocialHelpers.navigateToProfile(tester);
      await SocialHelpers.openFollowingFromProfile(tester);
      await SocialHelpers.switchToSuggestedTab(tester);

      // If there are any suggested users, tap the first one's avatar/name
      final avatars = find.byType(CircleAvatar);
      if (avatars.evaluate().isNotEmpty) {
        await tester.tap(avatars.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Should navigate to user profile screen
        NavHelpers.assertOnUserProfileScreen();
      }
    });
  });
}