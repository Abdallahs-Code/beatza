import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class NavHelpers {
  static void assertOnHomeScreen() {
    expect(find.byKey(const Key('test_home_screen')), findsOneWidget);
  }

  static void assertOnWelcomeScreen() {
    expect(find.byKey(const Key('test_welcome_screen')), findsOneWidget);
  }

  static void assertOnLoginScreen() {
    expect(find.byKey(const Key('test_login_screen')), findsOneWidget);
  }

  static void assertOnEmailEntryScreen() {
    expect(find.byKey(const Key('test_email_entry_screen')), findsOneWidget);
  }

  static void assertOnPasswordScreen() {
    expect(find.byKey(const Key('test_password_screen')), findsOneWidget);
  }

  static void assertOnCreatePasswordScreen() {
    expect(find.byKey(const Key('test_create_password_screen')), findsOneWidget);
  }

  static void assertOnUserInfoScreen() {
    expect(find.byKey(const Key('test_user_info_screen')), findsOneWidget);
  }

  static void assertOnCheckInboxScreen() {
    expect(find.byKey(const Key('test_check_inbox_screen')), findsOneWidget);
  }

  static void assertOnLibraryScreen() {
    expect(find.byKey(const Key('test_library_screen')), findsOneWidget);
  }

  static void assertOnUserProfileScreen() {
    expect(find.byKey(const Key('test_user_profile_screen')), findsOneWidget);
  }

  static void assertOnEditProfileScreen() {
    expect(find.byKey(const Key('test_edit_profile_screen')), findsOneWidget);
  }

  static void assertOnVerifyEmailScreen() {
    expect(find.byKey(const Key('verify_email_screen')), findsOneWidget);
  }

  static void assertOnFollowersScreen() {
    expect(find.text('Followers'), findsWidgets);
  }

  static void assertOnFollowingScreen() {
    expect(find.text('Suggested'), findsOneWidget);
  }

  static void assertOnBlockedUsersScreen() {
    expect(find.text('Blocked Users'), findsOneWidget);
  }
}