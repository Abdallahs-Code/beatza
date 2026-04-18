// Dart imports
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/features/followers_social_graph/screens/blocked_users_screen.dart'
    as blocked_users_screen;
import 'package:cross_team5/features/followers_social_graph/screens/followers_screen.dart'
    as followers_screen;
import 'package:cross_team5/features/followers_social_graph/screens/following_screen.dart'
    as following_screen;

class FollowersSocialGraphRoutes {
  static const String followers = '/followers';
  static const String following = '/following';
  static const String blockedUsers = '/blocked-users';

  static Map<String, WidgetBuilder> routes = {
    followers: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

      return followers_screen.FollowersScreen(
        userId: args['userId'] as String,
      );
    },
    following: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

      return following_screen.FollowingScreen(
        userId: args['userId'] as String,
        token: (args['token'] ?? '') as String,
        currentUserId: args['currentUserId'] as String?,
        initialTabIndex: (args['tabIndex'] ?? 0) as int,
      );
    },
    blockedUsers: (context) =>
        const blocked_users_screen.BlockedUsersScreen(),
  };
}