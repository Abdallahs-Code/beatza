import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cross_team5/main.dart' as app;

Future<void> openLibrary(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(seconds: 2));

  final libraryNav = find.byKey(const Key('test_home_to_library_nav'));
  expect(libraryNav, findsOneWidget);
  await tester.tap(libraryNav);
  await tester.pumpAndSettle(const Duration(seconds: 2));

  expect(find.byKey(const Key('test_library_screen')), findsOneWidget);
}

Future<void> openSection(WidgetTester tester, String sectionTitle) async {
  final header = find.text(sectionTitle);
  expect(header, findsOneWidget);

  final seeAll = find.text('See All');
  expect(seeAll, findsWidgets);
  await tester.tap(seeAll.first);
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

void main() {
  group('Library - Recently Played navigation', () {
    testWidgets('Tapping the Library tab opens the Library screen', (tester) async {
      app.main();
      await openLibrary(tester);

      expect(find.text('Recently played'), findsOneWidget);
      expect(find.text('Listening history'), findsOneWidget);
    });

    testWidgets('Tapping "See All" opens the Recently Played screen', (tester) async {
      app.main();
      await openLibrary(tester);

      await openSection(tester, 'Recently played');

      expect(find.text('Recently played'), findsWidgets);

      final empty = find.text('No recently played items yet').evaluate().isNotEmpty;
      final hasList = find.byType(ListView).evaluate().isNotEmpty;
      expect(empty || hasList, isTrue);
    });

    testWidgets('Back arrow on Recently Played returns to Library', (tester) async {
      app.main();
      await openLibrary(tester);
      await openSection(tester, 'Recently played');

      final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backBtn, findsWidgets);
      await tester.tap(backBtn.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byKey(const Key('test_library_screen')), findsOneWidget);
    });
  });

  group('Library - Menu items', () {
    testWidgets('Tapping "Your Likes" navigates off the Library screen', (tester) async {
      app.main();
      await openLibrary(tester);

      final yourLikes = find.text('Your Likes');
      if (yourLikes.evaluate().isNotEmpty) {
        await tester.tap(yourLikes.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // We've left the library screen.
        expect(find.byKey(const Key('test_library_screen')), findsNothing);
      }
    });
  });

  group('Library - Recently Played list interaction', () {
    testWidgets(
        'Tapping a Recently Played tile (if any) does not crash the app',
        (tester) async {
      app.main();
      await openLibrary(tester);
      await openSection(tester, 'Recently played');

      final tiles = find.byType(InkWell);
      if (tiles.evaluate().isNotEmpty) {
        await tester.tap(tiles.first, warnIfMissed: false);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // App still has a Scaffold rendered - no crash.
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('Recently Played list scrolls without errors', (tester) async {
      app.main();
      await openLibrary(tester);
      await openSection(tester, 'Recently played');

      final list = find.byType(ListView);
      if (list.evaluate().isNotEmpty) {
        await tester.drag(list.first, const Offset(0, -200));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.drag(list.first, const Offset(0, 200));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      expect(find.text('Recently played'), findsWidgets);
    });
  });
}
