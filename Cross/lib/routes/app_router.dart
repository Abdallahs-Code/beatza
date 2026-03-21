import 'package:flutter/material.dart';

import '../features/splash/screens/splash_screen.dart';
import '../features/authentication_user_management/authentication_user_management_routes.dart';
import '../features/home/home_routes.dart';
import '../features/library/library_routes.dart';
import '../features/user_profile_social_identity/user_profile_social_identity.dart';
import '../features/followers_social_graph/followers_social_graph.dart';

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
