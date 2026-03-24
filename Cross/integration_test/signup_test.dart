import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

import 'helpers/auth_helpers.dart';
import 'helpers/gmail_helper.dart';
import 'helpers/nav_helper.dart';

const _testEmail = 'beatza.tester@gmail.com';
const _testPassword = 'Test@12345';
const _weakPassword = '123';
const _wrongConfirmPassword = 'Different@999';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Signup — Normal', () {
    setUpAll(() async {
      await GmailHelper.deleteVerificationEmail(toEmail: _testEmail);
    });

    testWidgets('successful signup and email verification', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await AuthHelpers.signUpWith(
        tester,
        email: _testEmail,
        password: _testPassword,
      );

      NavHelpers.assertOnVerifyEmailScreen();

      await GmailHelper.verifyEmail(email: _testEmail);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      NavHelpers.assertOnHomeScreen();
    });

    testWidgets('shows error on weak password', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await AuthHelpers.signUpWith(
        tester,
        email: _testEmail,
        password: _weakPassword,
      );

      AuthHelpers.assertFieldError('password_field');
    });

    testWidgets('shows error on mismatched passwords', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await AuthHelpers.signUpWith(
        tester,
        email: _testEmail,
        password: _testPassword,
        confirmPassword: _wrongConfirmPassword,
      );

      AuthHelpers.assertFieldError('confirm_password_field');
    });

    testWidgets('shows error on invalid email format', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await AuthHelpers.signUpWith(
        tester,
        email: 'not-an-email',
        password: _testPassword,
      );

      AuthHelpers.assertFieldError('email_field');
    });

    testWidgets('shows error when email already registered', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await AuthHelpers.signUpWith(
        tester,
        email: _testEmail,
        password: _testPassword,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();

      await AuthHelpers.signUpWith(
        tester,
        email: _testEmail,
        password: _testPassword,
      );

      AuthHelpers.assertErrorMessage('Email already in use');
    });
  });
}