import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cross_team5/main.dart' as app;

class AuthHelpers {
  /// Ticks the "I'm not a robot" checkbox and types the fixed test CAPTCHA.
  /// Must be called after goToEmailEntry() and before enterEmailAndContinue().
  /// Uses pump() instead of pumpAndSettle() because the CAPTCHA canvas has
  /// an infinite animation that would freeze pumpAndSettle forever.
  static Future<void> completeCaptcha(WidgetTester tester) async {
    final robotCheckbox = find.byType(Checkbox);
    expect(robotCheckbox, findsOneWidget);
    await tester.tap(robotCheckbox);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(
        find.byKey(const Key('test_captcha_input')), 'AAAAAA');
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Logs in with the given credentials and deletes the account via the UI.
  /// Assumes the account exists — the test will fail if it doesn't.
  /// Ends on the Welcome screen after successful deletion.
  static Future<void> deleteAccount(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    // Log in
    await loginWith(tester, email: email, password: password);

    // Navigate to Library
    final libraryNav = find.byKey(const Key('test_home_to_library_nav'));
    expect(libraryNav, findsOneWidget);
    await tester.tap(libraryNav);
    await tester.pumpAndSettle();

    // Tap Settings
    final settingsBtn = find.byKey(const Key('test_library_settings_btn'));
    expect(settingsBtn, findsOneWidget);
    await tester.tap(settingsBtn);
    await tester.pumpAndSettle();

    // Scroll to and tap Delete account button
    final deleteBtn = find.byKey(const Key('test_settings_delete_account_btn'));
    await tester.scrollUntilVisible(
      deleteBtn,
      200.0,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(deleteBtn);
    await tester.pumpAndSettle();

    // Check the confirmation checkbox
    final checkbox = find.byKey(const Key('test_delete_account_checkbox'));
    expect(checkbox, findsOneWidget);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    // Tap "Delete my account" confirm button
    final confirmBtn = find.byKey(const Key('test_delete_account_confirm_btn'));
    expect(confirmBtn, findsOneWidget);
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Should be back on Welcome screen after deletion
  }

  static Future<void> goToLogin(WidgetTester tester) async {
    final loginBtn = find.byKey(const Key('test_welcome_login_btn'));
    expect(loginBtn, findsOneWidget);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();
  }

  static Future<void> goToEmailEntry(WidgetTester tester) async {
    final emailField = find.byKey(const Key('test_login_email_field'));
    expect(emailField, findsOneWidget);
    await tester.tap(emailField);
    await tester.pumpAndSettle();
  }

  static Future<void> enterEmailAndContinue(
    WidgetTester tester, {
    required String email,
  }) async {
    final input = find.byKey(const Key('test_email_entry_input'));
    expect(input, findsOneWidget);
    await tester.enterText(input, email);
    await tester.pump();

    final continueBtn = find.byKey(const Key('test_email_entry_continue_btn'));
    expect(continueBtn, findsOneWidget);
    await tester.tap(continueBtn);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  static Future<void> enterPasswordAndContinue(
    WidgetTester tester, {
    required String password,
  }) async {
    final input = find.byKey(const Key('test_password_input'));
    expect(input, findsOneWidget);
    await tester.enterText(input, password);
    await tester.pumpAndSettle();

    final continueBtn = find.byKey(const Key('test_password_continue_btn'));
    expect(continueBtn, findsOneWidget);
    await tester.tap(continueBtn);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  static Future<void> enterCreatePasswordAndContinue(
    WidgetTester tester, {
    required String password,
  }) async {
    final input = find.byKey(const Key('test_create_password_input'));
    expect(input, findsOneWidget);
    await tester.enterText(input, password);
    await tester.pumpAndSettle();

    final continueBtn =
        find.byKey(const Key('test_create_password_continue_btn'));
    expect(continueBtn, findsOneWidget);
    await tester.tap(continueBtn);
    await tester.pumpAndSettle();
  }

  static Future<void> fillUserInfoAndSubmit(
    WidgetTester tester, {
    required String displayName,
    required String gender,
  }) async {
    final nameInput =
        find.byKey(const Key('test_user_info_display_name_input'));
    expect(nameInput, findsOneWidget);
    await tester.enterText(nameInput, displayName);
    await tester.pumpAndSettle();

    final dobRow = find.byKey(const Key('test_user_info_dob_row'));

    final monthDropdown = find.descendant(
      of: dobRow,
      matching: find.byType(DropdownButtonFormField<int>),
    );
    await tester.tap(monthDropdown.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('January').last);
    await tester.pumpAndSettle();

    await tester.tap(monthDropdown.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1').last);
    await tester.pumpAndSettle();

    await tester.tap(monthDropdown.at(2));
    await tester.pumpAndSettle();
    final dropdownScrollable = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.text('2000'),
      200.0,
      scrollable: dropdownScrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('2000').last);
    await tester.pumpAndSettle();

    final genderDropdown = find.text('Gender (required)');
    if (genderDropdown.evaluate().isNotEmpty) {
      await tester.tap(genderDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text(gender).last);
      await tester.pumpAndSettle();
    }

    final submitBtn = find.byKey(const Key('test_user_info_submit_btn'));
    expect(submitBtn, findsOneWidget);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  /// Full login flow including CAPTCHA completion.
  static Future<void> loginWith(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    await goToLogin(tester);
    await goToEmailEntry(tester);
    await completeCaptcha(tester);
    await enterEmailAndContinue(tester, email: email);
    await enterPasswordAndContinue(tester, password: password);
  }

  static void assertSnackBarMessage(String message) {
    expect(find.text(message), findsOneWidget);
  }
}