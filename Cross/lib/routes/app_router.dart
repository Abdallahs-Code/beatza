import 'package:flutter/material.dart';

import '../features/splash/screens/splash_screen.dart';
import '../features/authentication_user_management/authentication_user_management.dart';

class AppRouter {
  static Map<String, WidgetBuilder> routes = {
    "/": (context) => const SplashScreen(),

    ...AuthenticationRoutes.routes,
  };
}
