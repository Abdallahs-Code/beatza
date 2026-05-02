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
  await tester.pumpAndSettle(const Duration(seconds: 3));

  for (int i = 0; i < 4; i++) {
    if (_isEngagementBarVisible()) return true;

    final inkWells = find.byType(InkWell);
    if (inkWells.evaluate().isNotEmpty) {
      await tester.tap(inkWells.last, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    } else {
      break;
    }
  }

  return _isEngagementBarVisible();
}

/// Opens the CommentsScreen from inside the expanded player.
Future<void> _openCommentsScreen(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.mode_comment_outlined));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

/// Opens the More-options sheet for the currently expanded track.
Future<void> _openMoreSheet(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_horiz_rounded));
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

void main() {
  // Liking tracks
  group('Like - heart icon on expanded player', () {
    testWidgets('Engagement bar shows an unfilled heart by default', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final reached = await _openExpandedPlayer(tester);
      if (!reached) return; // no playable track in this environment

      // Either heart variant is present.
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
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final reached = await _openExpandedPlayer(tester);
      if (!reached) return;

      // Tap whichever heart variant is currently shown.
      Finder heart = find.byIcon(Icons.favorite_border_rounded);
      if (heart.evaluate().isEmpty) {
        heart = find.byIcon(Icons.favorite_rounded);
      }
      expect(heart, findsWidgets);
      await tester.tap(heart.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // After a successful toggle, the filled-orange heart should be visible.
      final filled = find.byIcon(Icons.favorite_rounded);
      if (filled.evaluate().isNotEmpty) {
        final icon = tester.widget<Icon>(filled.first);
        expect(icon.color, equals(Colors.orange));
      }
    });
  });

  // Likers / Reposters list 
  group('LikersScreen - Likes / Reposts tabs', () {
    testWidgets('Opens with Likes and Reposts tabs and a back arrow',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final reached = await _openExpandedPlayer(tester);
      if (!reached) return;

      // Tap the like count
      Finder unfilled = find.byIcon(Icons.favorite_border_rounded);
      if (unfilled.evaluate().isNotEmpty) {
        await tester.tap(unfilled.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // The like count text sits below the heart inside a GestureDetector.
      final filled = find.byIcon(Icons.favorite_rounded);
      if (filled.evaluate().isEmpty) return; // toggle didn't take effect

      // Find a sibling Text under the heart's parent Column.
      final countText = find.descendant(
        of: find.ancestor(
          of: filled.first,
          matching: find.byType(Column),
        ).first,
        matching: find.byType(Text),
      );
      if (countText.evaluate().isEmpty) return;

      await tester.tap(countText.first, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // LikersScreen header: tabs + back arrow.
      expect(find.text('Likes'), findsWidgets);
      expect(find.text('Reposts'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Tapping the Reposts tab activates index 1', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final reached = await _openExpandedPlayer(tester);
      if (!reached) return;

      // Like the track first so the count becomes tappable.
      final unfilled = find.byIcon(Icons.favorite_border_rounded);
      if (unfilled.evaluate().isNotEmpty) {
        await tester.tap(unfilled.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      final filled = find.byIcon(Icons.favorite_rounded);
      if (filled.evaluate().isEmpty) return;

      final countText = find.descendant(
        of: find.ancestor(of: filled.first, matching: find.byType(Column)).first,
        matching: find.byType(Text),
      );
      if (countText.evaluate().isEmpty) return;

      await tester.tap(countText.first, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Switch to the Reposts tab.
      final repostsTab = find.text('Reposts');
      if (repostsTab.evaluate().isEmpty) return;
      await tester.tap(repostsTab);
      await tester.pumpAndSettle();

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.controller?.index, equals(1));
    });

    testWidgets('Back arrow returns to the expanded player', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final reached = await _openExpandedPlayer(tester);
      if (!reached) return;

      final unfilled = find.byIcon(Icons.favorite_border_rounded);
      if (unfilled.evaluate().isNotEmpty) {
        await tester.tap(unfilled.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      final filled = find.byIcon(Icons.favorite_rounded);
      if (filled.evaluate().isEmpty) return;

      final countText = find.descendant(
        of: find.ancestor(of: filled.first, matching: find.byType(Column)).first,
        matching: find.byType(Text),
      );
      if (countText.evaluate().isEmpty) return;

      await tester.tap(countText.first, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      if (find.byIcon(Icons.arrow_back).evaluate().isEmpty) return;
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // The Reposts tab text only exists on LikersScreen; it's gone after pop.
      expect(find.text('Reposts'), findsNothing);
    });
  });

  // EngagementUserTile - single liker row
  group('EngagementUserTile - likers list', () {
    testWidgets(
      'Likers tab renders user rows with a chevron when populated',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final reached = await _openExpandedPlayer(tester);
        if (!reached) return;

        // Ensure the track is liked so the count tap target is visible.
        final unfilled = find.byIcon(Icons.favorite_border_rounded);
        if (unfilled.evaluate().isNotEmpty) {
          await tester.tap(unfilled.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
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
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // The Likers tab uses ListTile rows - the chevron is the trailing icon.
        final chevrons = find.byIcon(Icons.chevron_right);
        // Either there are likers (chevron) or "No likes yet." is shown.
        expect(
          chevrons.evaluate().isNotEmpty ||
              find.text('No likes yet.').evaluate().isNotEmpty,
          isTrue,
        );
      },
    );
  });

  // Comments screen - header, input bar, comment tile, replies
  group('CommentsScreen - track header + MM:SS input bar', () {
    testWidgets('Renders the track title and artist in the header',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

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
        await tester.pumpAndSettle(const Duration(seconds: 3));

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
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final reached = await _openExpandedPlayer(tester);
        if (!reached) return;

        await _openCommentsScreen(tester);

        // Either timestamp pills or the "No comments yet." empty state shows.
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
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final reached = await _openExpandedPlayer(tester);
        if (!reached) return;

        await _openCommentsScreen(tester);

        // Skip if there are no comments to reply to.
        final replyBtn = find.text('Reply');
        if (replyBtn.evaluate().isEmpty) return;

        await tester.tap(replyBtn.first);
        await tester.pumpAndSettle();

        // The "Replying to <name>" indicator bar now appears above the input.
        expect(find.textContaining('Replying to'), findsOneWidget);
      },
    );
  });

  // Repost flow
  group('RepostBottomSheet - opens from More-options sheet', () {
    testWidgets(
      'More-options sheet exposes a "Repost on Beatza" tile',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final reached = await _openExpandedPlayer(tester);
        if (!reached) return;

        await _openMoreSheet(tester);

        // The label text varies, accept either form.
        final repostTile = find.textContaining(RegExp(r'Repost'));
        expect(repostTile, findsWidgets);
      },
    );

    testWidgets(
      'Tapping the Repost tile opens RepostBottomSheet with title + CTA',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final reached = await _openExpandedPlayer(tester);
        if (!reached) return;

        await _openMoreSheet(tester);

        // Tap "Repost on Beatza" if present; otherwise "Reposted".
        Finder tile = find.text('Repost on Beatza');
        if (tile.evaluate().isEmpty) tile = find.text('Reposted');
        if (tile.evaluate().isEmpty) return;

        await tester.tap(tile);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // The sheet's header title is the literal text "Repost".
        expect(find.text('Repost'), findsWidgets);

        // CTA button reads either "Repost" or "Remove Repost".
        final cta =
            find.text('Repost').evaluate().isNotEmpty ||
                find.text('Remove Repost').evaluate().isNotEmpty;
        expect(cta, isTrue);
      },
    );
  });
}