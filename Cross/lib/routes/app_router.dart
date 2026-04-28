// Dart imports
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/features/splash/screens/splash_screen.dart';
import 'package:cross_team5/features/authentication_user_management/authentication_user_management_routes.dart';
import 'package:cross_team5/features/home/home_routes.dart';
import 'package:cross_team5/features/library/library_routes.dart';
import 'package:cross_team5/features/user_profile_social_identity/user_profile_social_identity.dart';
import 'package:cross_team5/features/followers_social_graph/followers_social_graph.dart';
import 'package:cross_team5/features/playback_streaming_engine/playback_streaming_engine.dart';
import 'package:cross_team5/features/engagement_social_interactions/engagement_social_interactions.dart';
import 'package:cross_team5/features/messaging_track_sharing/messaging_track_sharing_routes.dart';
import 'package:cross_team5/features/sets_playlists/sets_playlists_routes.dart';
import 'package:cross_team5/features/feed_search_discovery/feed_search_discovery_routes.dart';

class AppRouter {
  static Map<String, WidgetBuilder> routes = {
    "/": (context) => const SplashScreen(),

    ...AuthenticationRoutes.routes,
    ...HomeRoutes.routes,
    ...LibraryRoutes.routes,
    ...UserProfileSocialIdentityRoutes.routes,
    ...FollowersSocialGraphRoutes.routes,
    ...PlaybackStreamingEngineRoutes.routes,
    // Module 6 — Engagement & Social Interactions
    ...EngagementSocialInteractionsRoutes.routes,
    // Messaging & Track Sharing
    ...MessagingTrackSharingRoutes.routes,
    ...SetsPlaylistsRoutes.routes,
    // Module 8 — Feed, Search & Discovery
    ...FeedSearchDiscoveryRoutes.routes,
  };
}