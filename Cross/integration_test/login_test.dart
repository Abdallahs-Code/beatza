import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

import 'helpers/auth_helpers.dart';
import 'helpers/nav_helpers.dart';

const _registeredEmail = 'beatza.tester@gmail.com';
const _registeredPassword = 'Test@12345';
const _wrongPassword = 'WrongPass@999';
const _unregisteredEmail = 'notregistered@gmail.com';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login', () {
    testWidgets('successful login with valid credentials', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await AuthHelpers.goToLogin(tester);
      await AuthHelpers.loginWith(
        tester,
        email: _registeredEmail,
        password: _registeredPassword,
      );

      NavHelpers.assertOnHomeScreen();
    });

    testWidgets('shows error on wrong password', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await AuthHelpers.goToLogin(tester);
      await AuthHelpers.loginWith(
        tester,
        email: _registeredEmail,
        password: _wrongPassword,
      );

      AuthHelpers.assertErrorMessage('Incorrect password');
    });

    testWidgets('shows error on unregistered email', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await AuthHelpers.goToLogin(tester);
      await AuthHelpers.loginWith(
        tester,
        email: _unregisteredEmail,
        password: _registeredPassword,
      );

      AuthHelpers.assertErrorMessage('No account found with this email');
    });

    testWidgets('shows error on empty fields', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await AuthHelpers.goToLogin(tester);
      await AuthHelpers.submitLoginForm(tester);

      AuthHelpers.assertFieldError('email_field');
      AuthHelpers.assertFieldError('password_field');
    });

    testWidgets('successful logout', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await AuthHelpers.goToLogin(tester);
      await AuthHelpers.loginWith(
        tester,
        email: _registeredEmail,
        password: _registeredPassword,
      );
      NavHelpers.assertOnHomeScreen();

      await tester.tap(find.byKey(const Key('logout_button')));
      await tester.pumpAndSettle();

      NavHelpers.assertOnLoginScreen();
    });
  });
}