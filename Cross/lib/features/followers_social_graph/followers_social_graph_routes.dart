// Dart imports
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/features/followers_social_graph/screens/blocked_users_screen.dart';
import 'package:cross_team5/features/followers_social_graph/screens/followers_screen.dart';
import 'package:cross_team5/features/followers_social_graph/screens/following_screen.dart';

class FollowersSocialGraphRoutes {
  static const String followers    = '/followers';
  static const String following    = '/following';
  static const String blockedUsers = '/blocked-users';

  static Map<String, WidgetBuilder> routes = {
    followers: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return FollowersScreen(
        userId: args['userId'] as String,
      );
    },

    following: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return FollowingScreen(
        userId: args['userId'] as String,
      );
    },

    blockedUsers: (context) => const BlockedUsersScreen(),
  };
}
