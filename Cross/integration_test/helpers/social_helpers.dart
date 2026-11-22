import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class SocialHelpers {
  /// From the Home screen, navigate to Library -> Profile.
  static Future<void> navigateToProfile(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final libraryNav = find.byKey(const Key('test_home_to_library_nav'));
    expect(libraryNav, findsOneWidget);
    await tester.tap(libraryNav);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final profileBtn = find.byKey(const Key('test_library_to_profile_btn'));
    expect(profileBtn, findsOneWidget);
    await tester.tap(profileBtn);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    // Now assert the profile screen key is present
    expect(
      find.byKey(const Key('test_user_profile_screen')),
      findsOneWidget,
    );
  }

  /// Tap the followers count text on the profile screen.
  /// This navigates to the FollowersScreen.
  static Future<void> openFollowersFromProfile(WidgetTester tester) async {
    final followersTap = find.textContaining('Followers');
    expect(followersTap, findsOneWidget);
    await tester.tap(followersTap);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  /// Tap the following count text on the profile screen.
  /// This navigates to the FollowingScreen (Following tab).
  static Future<void> openFollowingFromProfile(WidgetTester tester) async {
    final followingTap = find.textContaining('Following');
    expect(followingTap, findsOneWidget);
    await tester.tap(followingTap);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  /// Open the share/more sheet on the profile screen, then tap "Blocked users".
  static Future<void> openBlockedUsersFromProfile(
      WidgetTester tester) async {
    final moreBtn = find.byKey(const Key('test_profile_more_btn'));
    expect(moreBtn, findsOneWidget);
    await tester.tap(moreBtn);
    await tester.pumpAndSettle();

    final blockedTile = find.text('Blocked users');
    expect(blockedTile, findsOneWidget);
    await tester.tap(blockedTile);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  /// Assert that the Followers screen is visible.
  static void assertOnFollowersScreen() {
    expect(find.text('Followers'), findsWidgets);
  }

  /// Assert that the Following screen is visible (has Following tab).
  static void assertOnFollowingScreen() {
    // The TabBar has both "Following" and "Suggested" tabs
    expect(find.text('Suggested'), findsOneWidget);
  }

  /// Assert that the Blocked Users screen is visible.
  static void assertOnBlockedUsersScreen() {
    expect(find.text('Blocked Users'), findsOneWidget);
  }

  /// Tap the Follow/Following button on the first UserTile in the list.
  /// Returns the display name of that user for later assertions.
  static Future<String?> tapFollowOnFirstUserTile(
      WidgetTester tester) async {
    // Find the first Follow or Following button text in user tiles
    final followBtn = find.text('Follow');
    final followingBtn = find.text('Following');

    if (followBtn.evaluate().isNotEmpty) {
      await tester.tap(followBtn.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      return null;
    } else if (followingBtn.evaluate().isNotEmpty) {
      await tester.tap(followingBtn.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      return null;
    }
    return null;
  }

  /// Tap the three-dot menu on the first UserTile and select "Block user".
  static Future<void> tapBlockOnFirstUserTile(WidgetTester tester) async {
    final moreIcon = find.byIcon(Icons.more_vert);
    expect(moreIcon, findsWidgets);
    await tester.tap(moreIcon.first);
    await tester.pumpAndSettle();

    final blockOption = find.text('Block user');
    expect(blockOption, findsOneWidget);
    await tester.tap(blockOption);
    await tester.pumpAndSettle();
  }

  /// Tap the three-dot menu on the first UserTile and select "Unblock".
  static Future<void> tapUnblockOnFirstUserTile(WidgetTester tester) async {
    final moreIcon = find.byIcon(Icons.more_vert);
    expect(moreIcon, findsWidgets);
    await tester.tap(moreIcon.first);
    await tester.pumpAndSettle();

    final unblockOption = find.text('Unblock');
    expect(unblockOption, findsOneWidget);
    await tester.tap(unblockOption);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  /// Confirm a block action in the AlertDialog.
  static Future<void> confirmBlockDialog(WidgetTester tester) async {
    final blockConfirm = find.widgetWithText(TextButton, 'Block');
    expect(blockConfirm, findsOneWidget);
    await tester.tap(blockConfirm);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  /// Cancel a block action in the AlertDialog.
  static Future<void> cancelBlockDialog(WidgetTester tester) async {
    final cancelBtn = find.widgetWithText(TextButton, 'Cancel');
    expect(cancelBtn, findsOneWidget);
    await tester.tap(cancelBtn);
    await tester.pumpAndSettle();
  }

  /// Switch to the "Suggested" tab on the FollowingScreen.
  static Future<void> switchToSuggestedTab(WidgetTester tester) async {
    final suggestedTab = find.text('Suggested');
    expect(suggestedTab, findsOneWidget);
    await tester.tap(suggestedTab);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  /// Switch to the "Following" tab on the FollowingScreen.
  static Future<void> switchToFollowingTab(WidgetTester tester) async {
    // The "Following" text appears in the tab and possibly in buttons;
    // target the Tab widget specifically
    final followingTab = find.descendant(
      of: find.byType(TabBar),
      matching: find.text('Following'),
    );
    expect(followingTab, findsOneWidget);
    await tester.tap(followingTab);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  /// Go back from the current screen.
  static Future<void> goBack(WidgetTester tester) async {
    final backBtn = find.byIcon(Icons.arrow_back);
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();
  }
}
