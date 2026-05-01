// Routes for engagement_social_interactions feature.
// Spread into AppRouter.routes like all other feature route files:
//   ...EngagementSocialInteractionsRoutes.routes
//
// Available routes:
//   /engagement/likers    → LikersScreen  (2-tab: Likes + Reposts)
//   /engagement/comments  → CommentsScreen

import 'package:flutter/material.dart';
import 'package:cross_team5/features/engagement_social_interactions/screens/likers_screen.dart';
import 'package:cross_team5/features/engagement_social_interactions/screens/comments_screen.dart';

class EngagementSocialInteractionsRoutes {
  // ── Route name constants ────────────────────
  // Import this class wherever you need to navigate:
  //   import 'package:cross_team5/features/engagement_social_interactions/
  //           engagement_social_interactions.dart';
  //   Navigator.pushNamed(context, EngagementSocialInteractionsRoutes.likers, ...);

  static const String likers = '/engagement/likers';
  static const String comments = '/engagement/comments';

  static Map<String, WidgetBuilder> routes = {
    // ── LikersScreen ──────────────────────────
    // Required arguments (pass as Map<String, dynamic>):
    //   'trackId'     String  — the track whose likers/reposters to show
    //   'initialTab'  int     — 0 for Likes tab, 1 for Reposts tab (default 0)
    //
    // Example:
    //   Navigator.pushNamed(
    //     context,
    //     EngagementSocialInteractionsRoutes.likers,
    //     arguments: {'trackId': 'trk_456', 'initialTab': 0},
    //   );
    likers: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return LikersScreen(
        trackId: args['trackId'] as String,
        initialTab: args['initialTab'] as int? ?? 0,
      );
    },

    // ── CommentsScreen ────────────────────────
    // Required arguments (pass as Map<String, dynamic>):
    //   'trackId'                String  — the track to show comments for
    //   'trackTitle'             String  — shown in the header card
    //   'trackArtist'            String  — shown in the header card
    //   'trackThumbnailUrl'      String? — shown in the header card (nullable)
    //   'currentPositionSeconds' int     — player position for "Comment at MM:SS"
    //                                      (pass 0 if player not available yet)
    //
    // Example:
    //   Navigator.pushNamed(
    //     context,
    //     EngagementSocialInteractionsRoutes.comments,
    //     arguments: {
    //       'trackId': 'trk_456',
    //       'trackTitle': 'My Track',
    //       'trackArtist': 'Artist Name',
    //       'trackThumbnailUrl': 'https://...',
    //       'currentPositionSeconds': 1506,  // 25:06
    //     },
    //   );
    comments: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return CommentsScreen(
        trackId: args['trackId'] as String,
        trackTitle: args['trackTitle'] as String,
        trackArtist: args['trackArtist'] as String,
        trackThumbnailUrl: args['trackThumbnailUrl'] as String?,
        currentPositionSeconds: args['currentPositionSeconds'] as int? ?? 0,
        syncWithPlayer: args['syncWithPlayer'] as bool? ?? true,
      );
    },
  };
}
