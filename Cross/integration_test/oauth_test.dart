import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

import 'helpers/auth_helpers.dart';
import 'helpers/nav_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('OAuth — Google', () {
    testWidgets('Google sign-in button is visible', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('google_signin_button')), findsOneWidget);
    });

    testWidgets('tapping Google sign-in triggers the flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('google_signin_button')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      NavHelpers.assertOnHomeScreen();
    });

    testWidgets('cancelling Google sign-in returns to login screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('google_signin_button')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.pageBack();
      await tester.pumpAndSettle();

      NavHelpers.assertOnLoginScreen();
    });
  });

  group('OAuth — Facebook', () {
    testWidgets('Facebook sign-in button is visible', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('facebook_signin_button')), findsOneWidget);
    });

    testWidgets('tapping Facebook sign-in triggers the flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('facebook_signin_button')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      NavHelpers.assertOnHomeScreen();
    });

    testWidgets('cancelling Facebook sign-in returns to login screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('facebook_signin_button')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.pageBack();
      await tester.pumpAndSettle();

      NavHelpers.assertOnLoginScreen();
    });
  });
}