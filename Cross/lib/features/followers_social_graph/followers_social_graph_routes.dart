import 'package:flutter/material.dart';

import 'screens/followers_screen.dart';

import 'screens/blocked_users_screen.dart';



class FollowersSocialGraphRoutes 
{
  static const String followers    = "/followers";
  static const String following    = "/following";
  static const String blockedUsers = "/blocked-users";


  static Map<String, WidgetBuilder> routes = 
  {
    followers: (context) 
    {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

      return FollowersScreen(
        userId: args['userId'] as String,
        initialTabIndex: args['tabIndex'] ?? 0,
      );
    },
   
    blockedUsers: (context) => const BlockedUsersScreen(),
   
  };
}