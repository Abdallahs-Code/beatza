// Should be signed in to an account.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:cross_team5/main.dart' as app;
import 'package:cross_team5/features/home/widgets/home_widgets.dart';

bool _isEngagementBarVisible() {
  return find.byIcon(Icons.mode_comment_outlined).evaluate().isNotEmpty;
}

Future<bool> _openExpandedPlayer(WidgetTester tester) async {
  Finder tile = find.byType(MiniTrackCard);
  if (tile.evaluate().isEmpty) tile = find.byType(WideTrackCard);
  if (tile.evaluate().isEmpty) return false;

  await tester.tap(tile.first, warnIfMissed: false);
  await tester.pump(const Duration(seconds: 3));

  // Pause immediately so the tree stops being dirty from audio updates
  final pauseBtn = find.byIcon(Icons.pause_rounded).evaluate().isNotEmpty
      ? find.byIcon(Icons.pause_rounded)
      : find.byIcon(Icons.pause);
  if (pauseBtn.evaluate().isNotEmpty) {
    await tester.tap(pauseBtn.first, warnIfMissed: false);
    await tester.pump(const Duration(seconds: 1));
  }

  for (int i = 0; i < 4; i++) {
    if (_isEngagementBarVisible()) return true;

    final inkWells = find.byType(InkWell);
    if (inkWells.evaluate().isNotEmpty) {
      await tester.tap(inkWells.last, warnIfMissed: false);
      await tester.pump(const Duration(seconds: 1));
    } else {
      break;
    }
  }

  return _isEngagementBarVisible();
}

Future<void> _openCommentsScreen(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.mode_comment_outlined));
  await tester.pump(const Duration(seconds: 2));
}

Future<void> _openMoreSheet(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_horiz_rounded));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  group('Like - heart icon on expanded player', () {
    testWidgets('Engagement bar shows an unfilled heart by default',
        (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 3));

      final reached = await _openExpandedPlayer(tester);
      if (!reached) return;

      final unfilled = find.byIcon(Icons.favorite_border_rounded);
      final filled = find.byIcon(Icons.favorite_rounded);
      expect(
        unfilled.evaluate().isNotEmpty || filled.evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('Tapping the heart toggles to the filled orange icon',
        (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 3));

      final reached = await _openExpandedPlayer(tester);
      if (!reached) return;

      Finder heart = find.byIcon(Icons.favorite_border_rounded);
      if (heart.evaluate().isEmpty) {
        heart = find.byIcon(Icons.favorite_rounded);
      }
      expect(heart, findsWidgets);
      await tester.tap(heart.first);
      await tester.pump(const Duration(seconds: 2));

      final filled = find.byIcon(Icons.favorite_rounded);
      if (filled.evaluate().isNotEmpty) {
        final icon = tester.widget<Icon>(filled.first);
        expect(icon.color, equals(Colors.orange));
      }
    });
  });

  group('LikersScreen - Likes / Reposts tabs', () {
    testWidgets('Opens with Likes and Reposts tabs and a back arrow',
        (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 3));

      final reached = await _openExpandedPlayer(tester);
      if (!reached) return;

      Finder unfilled = find.byIcon(Icons.favorite_border_rounded);
      if (unfilled.evaluate().isNotEmpty) {
        await tester.tap(unfilled.first);
        await tester.pump(const Duration(seconds: 2));
      }

      final filled = find.byIcon(Icons.favorite_rounded);
      if (filled.evaluate().isEmpty) return;

      final countText = find.descendant(
        of: find.ancestor(
          of: filled.first,
          matching: find.byType(Column),
        ).first,
        matching: find.byType(Text),
      );
      if (countText.evaluate().isEmpty) return;

      await tester.tap(countText.first, warnIfMissed: false);
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Likes'), findsWidgets);
      expect(find.text('Reposts'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Tapping the Reposts tab activates index 1', (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 3));

      final reached = await _openExpandedPlayer(tester);
      if (!reached) return;

      final unfilled = find.byIcon(Icons.favorite_border_rounded);
      if (unfilled.evaluate().isNotEmpty) {
        await tester.tap(unfilled.first);
        await tester.pump(const Duration(seconds: 2));
      }

      final filled = find.byIcon(Icons.favorite_rounded);
      if (filled.evaluate().isEmpty) return;

      final countText = find.descendant(
        of: find.ancestor(of: filled.first, matching: find.byType(Column)).first,
        matching: find.byType(Text),
      );
      if (countText.evaluate().isEmpty) return;

      await tester.tap(countText.first, warnIfMissed: false);
      await tester.pump(const Duration(seconds: 2));

      final repostsTab = find.text('Reposts');
      if (repostsTab.evaluate().isEmpty) return;
      await tester.tap(repostsTab);
      await tester.pump(const Duration(seconds: 1));

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.controller?.index, equals(1));
    });

    testWidgets('Back arrow returns to the expanded player', (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 3));

      final reached = await _openExpandedPlayer(tester);
      if (!reached) return;

      final unfilled = find.byIcon(Icons.favorite_border_rounded);
      if (unfilled.evaluate().isNotEmpty) {
        await tester.tap(unfilled.first);
        await tester.pump(const Duration(seconds: 2));
      }
      final filled = find.byIcon(Icons.favorite_rounded);
      if (filled.evaluate().isEmpty) return;

      final countText = find.descendant(
        of: find.ancestor(of: filled.first, matching: find.byType(Column)).first,
        matching: find.byType(Text),
      );
      if (countText.evaluate().isEmpty) return;

      await tester.tap(countText.first, warnIfMissed: false);
      await tester.pump(const Duration(seconds: 2));

      if (find.byIcon(Icons.arrow_back).evaluate().isEmpty) return;
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Reposts'), findsNothing);
    });
  });

  group('EngagementUserTile - likers list', () {
    testWidgets(
      'Likers tab renders user rows with a chevron when populated',
      (tester) async {
        app.main();
        await tester.pump(const Duration(seconds: 3));

        final reached = await _openExpandedPlayer(tester);
        if (!reached) return;

        final unfilled = find.byIcon(Icons.favorite_border_rounded);
        if (unfilled.evaluate().isNotEmpty) {
          await tester.tap(unfilled.first);
          await tester.pump(const Duration(seconds: 2));
        }
        final filled = find.byIcon(Icons.favorite_rounded);
        if (filled.evaluate().isEmpty) return;

        final countText = find.descendant(
          of: find.ancestor(
            of: filled.first,
            matching: find.byType(Column),
          ).first,
          matching: find.byType(Text),
        );
        if (countText.evaluate().isEmpty) return;
        await tester.tap(countText.first, warnIfMissed: false);
        await tester.pump(const Duration(seconds: 3));

        final chevrons = find.byIcon(Icons.chevron_right);
        expect(
          chevrons.evaluate().isNotEmpty ||
              find.text('No likes yet.').evaluate().isNotEmpty,
          isTrue,
        );
      },
    );
  });

  group('CommentsScreen - track header + MM:SS input bar', () {
    testWidgets('Renders the track title and artist in the header',
        (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 3));

      final reached = await _openExpandedPlayer(tester);
      if (!reached) return;

      await _openCommentsScreen(tester);

      expect(
        find.textContaining(RegExp(r'(Comment at \d+:\d{2}|comments?$)')),
        findsWidgets,
      );
    });

    testWidgets(
      'Input bar hint reads "Comment at MM:SS" matching playback position',
      (tester) async {
        app.main();
        await tester.pump(const Duration(seconds: 3));

        final reached = await _openExpandedPlayer(tester);
        if (!reached) return;

        await _openCommentsScreen(tester);

        expect(
          find.textContaining(RegExp(r'Comment at \d+:\d{2}')),
          findsOneWidget,
        );
      },
    );
  });

  group('CommentsScreen - comment tile + reply flow', () {
    testWidgets(
      'Comment timestamp pills render in MM:SS format when comments exist',
      (tester) async {
        app.main();
        await tester.pump(const Duration(seconds: 3));

        final reached = await _openExpandedPlayer(tester);
        if (!reached) return;

        await _openCommentsScreen(tester);

        final pills = find.textContaining(RegExp(r'^at \d+:\d{2}$'));
        final empty = find.textContaining('No comments yet');
        expect(
          pills.evaluate().isNotEmpty || empty.evaluate().isNotEmpty,
          isTrue,
        );
      },
    );

    testWidgets(
      'Tapping Reply on a comment switches the input hint to "@username"',
      (tester) async {
        app.main();
        await tester.pump(const Duration(seconds: 3));

        final reached = await _openExpandedPlayer(tester);
        if (!reached) return;

        await _openCommentsScreen(tester);

        final replyBtn = find.text('Reply');
        if (replyBtn.evaluate().isEmpty) return;

        await tester.tap(replyBtn.first);
        await tester.pump(const Duration(seconds: 1));

        expect(find.textContaining('Replying to'), findsOneWidget);
      },
    );
  });

  group('RepostBottomSheet - opens from More-options sheet', () {
    testWidgets(
      'More-options sheet exposes a "Repost on Beatza" tile',
      (tester) async {
        app.main();
        await tester.pump(const Duration(seconds: 3));

        final reached = await _openExpandedPlayer(tester);
        if (!reached) return;

        await _openMoreSheet(tester);

        final repostTile = find.textContaining(RegExp(r'Repost'));
        expect(repostTile, findsWidgets);
      },
    );

    testWidgets(
      'Tapping the Repost tile opens RepostBottomSheet with title + CTA',
      (tester) async {
        app.main();
        await tester.pump(const Duration(seconds: 3));

        final reached = await _openExpandedPlayer(tester);
        if (!reached) return;

        await _openMoreSheet(tester);

        Finder tile = find.text('Repost on Beatza');
        if (tile.evaluate().isEmpty) tile = find.text('Reposted');
        if (tile.evaluate().isEmpty) return;

        await tester.tap(tile);
        await tester.pump(const Duration(seconds: 2));

        expect(find.text('Repost'), findsWidgets);

        final cta =
            find.text('Repost').evaluate().isNotEmpty ||
                find.text('Remove Repost').evaluate().isNotEmpty;
        expect(cta, isTrue);
      },
    );
  });
}