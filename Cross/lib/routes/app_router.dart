// Dart imports
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/features/splash/screens/splash_screen.dart';
import 'package:cross_team5/features/authentication_user_management/authentication_user_management_routes.dart';
import 'package:cross_team5/features/home/home_routes.dart';
import 'package:cross_team5/features/library/library_routes.dart';
import 'package:cross_team5/features/user_profile_social_identity/user_profile_social_identity.dart';
import 'package:cross_team5/features/followers_social_graph/followers_social_graph.dart';

class AppRouter {
  static Map<String, WidgetBuilder> routes = {
    "/": (context) => const SplashScreen(),

    ...AuthenticationRoutes.routes,
    ...HomeRoutes.routes,
    ...LibraryRoutes.routes,
    ...UserProfileSocialIdentityRoutes.routes,
    ...FollowersSocialGraphRoutes.routes,
  };
}
