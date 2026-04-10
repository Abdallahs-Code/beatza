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

    final monthDropdown = find.text('Month');
    if (monthDropdown.evaluate().isNotEmpty) {
      await tester.tap(monthDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('January').last);
      await tester.pumpAndSettle();
    }

    final dayDropdown = find.text('Day');
    if (dayDropdown.evaluate().isNotEmpty) {
      await tester.tap(dayDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('1').last);
      await tester.pumpAndSettle();
    }

    final yearDropdown = find.text('Year');
    if (yearDropdown.evaluate().isNotEmpty) {
      await tester.tap(yearDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('2000').last);
      await tester.pumpAndSettle();
    }

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
