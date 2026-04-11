import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class AuthHelpers {
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
    await tester.pumpAndSettle();

    final continueBtn = find.byKey(const Key('test_email_entry_continue_btn'));
    expect(continueBtn, findsOneWidget);
    await tester.tap(continueBtn);
    await tester.pumpAndSettle(const Duration(seconds: 3));
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

    final continueBtn = find.byKey(const Key('test_create_password_continue_btn'));
    expect(continueBtn, findsOneWidget);
    await tester.tap(continueBtn);
    await tester.pumpAndSettle();
  }

  static Future<void> fillUserInfoAndSubmit(
    WidgetTester tester, {
    required String displayName,
    required String gender,
  }) async {
    final nameInput = find.byKey(const Key('test_user_info_display_name_input'));
    expect(nameInput, findsOneWidget);
    await tester.enterText(nameInput, displayName);
    await tester.pumpAndSettle();

    // Find all DropdownButtonFormField widgets inside the DOB row
    final dobRow = find.byKey(const Key('test_user_info_dob_row'));

    // Tap the Month dropdown (first DropdownButtonFormField in the row)
    final monthDropdown = find.descendant(
      of: dobRow,
      matching: find.byType(DropdownButtonFormField<int>),
    );
    await tester.tap(monthDropdown.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('January').last);
    await tester.pumpAndSettle();

    // Tap the Day dropdown (second DropdownButtonFormField in the row)
    await tester.tap(monthDropdown.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1').last);
    await tester.pumpAndSettle();

    // Tap the Year dropdown (third DropdownButtonFormField in the row)
    await tester.tap(monthDropdown.at(2));
    await tester.pumpAndSettle();
    // The year list starts from the current year descending.
    // Use scrollUntilVisible with the dropdown's own Scrollable.
    final dropdownScrollable = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.text('2000'),
      200.0,
      scrollable: dropdownScrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('2000').last);
    await tester.pumpAndSettle();

    // Tap the Gender dropdown
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

  static Future<void> loginWith(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    await goToLogin(tester);
    await goToEmailEntry(tester);
    await enterEmailAndContinue(tester, email: email);
    await enterPasswordAndContinue(tester, password: password);
  }

  static void assertSnackBarMessage(String message) {
    expect(find.text(message), findsOneWidget);
  }
}
