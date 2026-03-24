import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cross_team5/features/library/screens/library_screen.dart';
import 'package:cross_team5/features/user_profile_social_identity/screens/user_profile_screen.dart';
import 'package:cross_team5/features/user_profile_social_identity/screens/edit_profile_screen.dart';

class NavHelpers {
  static void assertOnHomeScreen() {
    expect(find.byKey(const Key('home_screen')), findsOneWidget);
  }

  static void assertOnLoginScreen() {
    expect(find.byKey(const Key('login_screen')), findsOneWidget);
  }

  static void assertOnLibraryScreen() {
    expect(find.byType(LibraryScreen), findsOneWidget);
  }

  static void assertOnUserProfileScreen() {
    expect(find.byType(UserProfileScreen), findsOneWidget);
  }

  static void assertOnEditProfileScreen() {
    expect(find.byType(EditProfileScreen), findsOneWidget);
  }

  static void assertOnVerifyEmailScreen() {
    expect(find.byKey(const Key('verify_email_screen')), findsOneWidget);
  }
} 