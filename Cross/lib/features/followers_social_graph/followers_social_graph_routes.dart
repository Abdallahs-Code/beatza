import 'package:flutter/material.dart';

import 'screens/followers_screen.dart';
import 'screens/following_screen.dart';
import 'screens/blocked_users_screen.dart';
import 'screens/social_test_screen.dart';


class FollowersSocialGraphRoutes 
{
  static const String followers    = "/followers";
  static const String following    = "/following";
  static const String blockedUsers = "/blocked-users";
  static const String socialTest   = "/social-test"; // TEMP — remove after integration

  static Map<String, WidgetBuilder> routes = 
  {
    followers: (context) 
    {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return FollowersScreen(userId: args['userId'] as String);
    },
    following: (context) 
    {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return FollowingScreen(userId: args['userId'] as String);
    },
    blockedUsers: (context) => const BlockedUsersScreen(),
    socialTest:   (context) => const SocialTestScreen(), // TEMP — remove after integration
  };
}