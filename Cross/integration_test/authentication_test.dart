import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cross_team5/main.dart' as app;

import 'helpers/auth_helpers.dart';
import 'helpers/nav_helpers.dart';

void main() {
  group('Navigation — Welcome Screen', () {
    testWidgets('App launches and shows Welcome screen after splash',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      NavHelpers.assertOnWelcomeScreen();
    });

    testWidgets('Tapping Login button navigates to Login screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await AuthHelpers.goToLogin(tester);

      NavHelpers.assertOnLoginScreen();
    });

    testWidgets('Tapping Create Account button navigates to Login screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final createBtn =
          find.byKey(const Key('test_welcome_create_account_btn'));
      expect(createBtn, findsOneWidget);

      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      NavHelpers.assertOnLoginScreen();
    });
  });

  group('Navigation — Login Screen', () {
    testWidgets('Back button returns to Welcome screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await AuthHelpers.goToLogin(tester);
      NavHelpers.assertOnLoginScreen();

      final backBtn = find.byKey(const Key('test_login_back_btn'));
      expect(backBtn, findsOneWidget);

      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      NavHelpers.assertOnWelcomeScreen();
    });

    testWidgets('Tapping email field navigates to Email Entry screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await AuthHelpers.goToLogin(tester);
      NavHelpers.assertOnLoginScreen();

      await AuthHelpers.goToEmailEntry(tester);

      NavHelpers.assertOnEmailEntryScreen();
    });
  });

  group('Navigation — Email Entry Screen', () {
    testWidgets(
        'Entering a registered email navigates to Password screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await AuthHelpers.goToLogin(tester);
      await AuthHelpers.goToEmailEntry(tester);

      await AuthHelpers.enterEmailAndContinue(
        tester,
        email: 'beatzacrosstester@gmail.com',
      );

      NavHelpers.assertOnPasswordScreen();
    });

    testWidgets(
        'Entering an unregistered email navigates to Create Password screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await AuthHelpers.goToLogin(tester);
      await AuthHelpers.goToEmailEntry(tester);

      await AuthHelpers.enterEmailAndContinue(
        tester,
        email: 'newuser_testonly@gmail.com',
      );

      NavHelpers.assertOnCreatePasswordScreen();
    });

    testWidgets('Submitting empty email shows SnackBar error', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await AuthHelpers.goToLogin(tester);
      await AuthHelpers.goToEmailEntry(tester);

      final continueBtn =
          find.byKey(const Key('test_email_entry_continue_btn'));
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      AuthHelpers.assertSnackBarMessage(
          'Please enter your email address or profile URL');
    });
  });

  group('Login — Password Screen', () {
    testWidgets('Displays the entered email on Password screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await AuthHelpers.goToLogin(tester);
      await AuthHelpers.goToEmailEntry(tester);
      await AuthHelpers.enterEmailAndContinue(
        tester,
        email: 'beatzacrosstester@gmail.com',
      );

      NavHelpers.assertOnPasswordScreen();

      final emailText = tester.widget<Text>(
        find.byKey(const Key('test_password_email_display')),
      );
      expect(emailText.data, equals('beatzacrosstester@gmail.com'));
    });

    testWidgets('Submitting empty password shows SnackBar error',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await AuthHelpers.goToLogin(tester);
      await AuthHelpers.goToEmailEntry(tester);
      await AuthHelpers.enterEmailAndContinue(
        tester,
        email: 'beatzacrosstester@gmail.com',
      );

      NavHelpers.assertOnPasswordScreen();

      final continueBtn = find.byKey(const Key('test_password_continue_btn'));
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      AuthHelpers.assertSnackBarMessage('Please enter your password');
    });

    testWidgets('Successful login navigates to Home screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await AuthHelpers.loginWith(
        tester,
        email: 'beatzacrosstester@gmail.com',
        password: 'Beatza@123',
      );

      NavHelpers.assertOnHomeScreen();
    });

    testWidgets('Wrong password shows error SnackBar', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await AuthHelpers.goToLogin(tester);
      await AuthHelpers.goToEmailEntry(tester);
      await AuthHelpers.enterEmailAndContinue(
        tester,
        email: 'beatzacrosstester@gmail.com',
      );

      NavHelpers.assertOnPasswordScreen();

      await AuthHelpers.enterPasswordAndContinue(
        tester,
        password: 'WrongPass@999',
      );

      NavHelpers.assertOnPasswordScreen();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Forgot password link is visible and tappable',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await AuthHelpers.goToLogin(tester);
      await AuthHelpers.goToEmailEntry(tester);
      await AuthHelpers.enterEmailAndContinue(
        tester,
        email: 'beatzacrosstester@gmail.com',
      );

      NavHelpers.assertOnPasswordScreen();

      final forgotBtn = find.byKey(const Key('test_password_forgot_btn'));
      expect(forgotBtn, findsOneWidget);

      await tester.tap(forgotBtn);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('Signup — Create Password Screen', () {
    testWidgets('Displays the entered email on Create Password screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await AuthHelpers.goToLogin(tester);
      await AuthHelpers.goToEmailEntry(tester);
      await AuthHelpers.enterEmailAndContinue(
        tester,
        email: 'newuser_testonly@gmail.com',
      );

      NavHelpers.assertOnCreatePasswordScreen();

      final emailText = tester.widget<Text>(
        find.byKey(const Key('test_create_password_email_display')),
      );
      expect(emailText.data, equals('newuser_testonly@gmail.com'));
    });

    testWidgets('Short password shows SnackBar error', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await AuthHelpers.goToLogin(tester);
      await AuthHelpers.goToEmailEntry(tester);
      await AuthHelpers.enterEmailAndContinue(
        tester,
        email: 'newuser_testonly@gmail.com',
      );

      NavHelpers.assertOnCreatePasswordScreen();

      await AuthHelpers.enterCreatePasswordAndContinue(
        tester,
        password: '123',
      );

      // Should still be on Create Password screen
      NavHelpers.assertOnCreatePasswordScreen();

      AuthHelpers.assertSnackBarMessage(
          'Password must be at least 8 characters');
    });

    testWidgets(
        'Valid password navigates to User Info screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await AuthHelpers.goToLogin(tester);
      await AuthHelpers.goToEmailEntry(tester);
      await AuthHelpers.enterEmailAndContinue(
        tester,
        email: 'newuser_testonly@gmail.com',
      );

      NavHelpers.assertOnCreatePasswordScreen();

      await AuthHelpers.enterCreatePasswordAndContinue(
        tester,
        password: 'StrongPass@123',
      );

      NavHelpers.assertOnUserInfoScreen();
    });
  });

  group('Signup — User Info Screen', () {
    testWidgets(
        'Submitting without filling required fields shows SnackBar error',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await AuthHelpers.goToLogin(tester);
      await AuthHelpers.goToEmailEntry(tester);
      await AuthHelpers.enterEmailAndContinue(
        tester,
        email: 'newuser_testonly@gmail.com',
      );
      await AuthHelpers.enterCreatePasswordAndContinue(
        tester,
        password: 'StrongPass@123',
      );

      NavHelpers.assertOnUserInfoScreen();

      // Tap submit without filling any fields
      final submitBtn = find.byKey(const Key('test_user_info_submit_btn'));
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Should show error about missing fields
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets(
        'Filling all fields and submitting navigates to Check Inbox screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await AuthHelpers.goToLogin(tester);
      await AuthHelpers.goToEmailEntry(tester);
      await AuthHelpers.enterEmailAndContinue(
        tester,
        email: 'newuser_testonly@gmail.com',
      );
      await AuthHelpers.enterCreatePasswordAndContinue(
        tester,
        password: 'StrongPass@123',
      );

      NavHelpers.assertOnUserInfoScreen();

      await AuthHelpers.fillUserInfoAndSubmit(
        tester,
        displayName: 'Test User',
        gender: 'Male',
      );

      NavHelpers.assertOnCheckInboxScreen();
    });
  });

  group('Signup — Check Inbox Screen', () {
    testWidgets('Displays the correct email on Check Inbox screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await AuthHelpers.goToLogin(tester);
      await AuthHelpers.goToEmailEntry(tester);
      await AuthHelpers.enterEmailAndContinue(
        tester,
        email: 'newuser_testonly@gmail.com',
      );
      await AuthHelpers.enterCreatePasswordAndContinue(
        tester,
        password: 'StrongPass@123',
      );
      await AuthHelpers.fillUserInfoAndSubmit(
        tester,
        displayName: 'Test User',
        gender: 'Male',
      );

      NavHelpers.assertOnCheckInboxScreen();

      final emailText = tester.widget<Text>(
        find.byKey(const Key('test_check_inbox_email')),
      );
      expect(emailText.data, equals('newuser_testonly@gmail.com'));
    });

    testWidgets('Back to login link navigates to Login screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await AuthHelpers.goToLogin(tester);
      await AuthHelpers.goToEmailEntry(tester);
      await AuthHelpers.enterEmailAndContinue(
        tester,
        email: 'newuser_testonly@gmail.com',
      );
      await AuthHelpers.enterCreatePasswordAndContinue(
        tester,
        password: 'StrongPass@123',
      );
      await AuthHelpers.fillUserInfoAndSubmit(
        tester,
        displayName: 'Test User',
        gender: 'Male',
      );

      NavHelpers.assertOnCheckInboxScreen();

      final backBtn =
          find.byKey(const Key('test_check_inbox_back_to_login_btn'));
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      NavHelpers.assertOnLoginScreen();
    });

    testWidgets('Resend verification email button is tappable',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await AuthHelpers.goToLogin(tester);
      await AuthHelpers.goToEmailEntry(tester);
      await AuthHelpers.enterEmailAndContinue(
        tester,
        email: 'newuser_testonly@gmail.com',
      );
      await AuthHelpers.enterCreatePasswordAndContinue(
        tester,
        password: 'StrongPass@123',
      );
      await AuthHelpers.fillUserInfoAndSubmit(
        tester,
        displayName: 'Test User',
        gender: 'Male',
      );

      NavHelpers.assertOnCheckInboxScreen();

      final resendBtn =
          find.byKey(const Key('test_check_inbox_resend_btn'));
      expect(resendBtn, findsOneWidget);

      await tester.tap(resendBtn);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Should show a SnackBar with the result
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
