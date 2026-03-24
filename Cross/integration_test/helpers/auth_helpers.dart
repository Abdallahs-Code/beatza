import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class AuthHelpers {

  static Future<void> goToSignup(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('go_to_signup_button')));
    await tester.pumpAndSettle();
  }

  static Future<void> goToLogin(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('go_to_login_button')));
    await tester.pumpAndSettle();
  }

  static Future<void> fillSignupForm(
    WidgetTester tester, {
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    await tester.enterText(find.byKey(const Key('email_field')), email);
    await tester.enterText(find.byKey(const Key('password_field')), password);
    await tester.enterText(find.byKey(const Key('confirm_password_field')), confirmPassword);
  }

  static Future<void> submitSignupForm(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('submit_signup_button')));
    await tester.pumpAndSettle();
  }

  static Future<void> signUpWith(
    WidgetTester tester, {
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    await goToSignup(tester);
    await fillSignupForm(
      tester,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
    await submitSignupForm(tester);
  }

  static Future<void> fillLoginForm(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    await tester.enterText(find.byKey(const Key('email_field')), email);
    await tester.enterText(find.byKey(const Key('password_field')), password);
  }

  static Future<void> submitLoginForm(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();
  }

  static Future<void> loginWith(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    await fillLoginForm(tester, email: email, password: password);
    await submitLoginForm(tester);
  }

  static void assertErrorMessage(String message) {
    expect(find.text(message), findsOneWidget);
  }

  static void assertFieldError(String fieldKey) {
    expect(find.byKey(Key('${fieldKey}_error')), findsOneWidget);
  }
}