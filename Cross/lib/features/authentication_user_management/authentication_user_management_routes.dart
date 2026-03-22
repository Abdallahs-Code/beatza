// Dart imports
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/features/authentication_user_management/screens/welcome_screen.dart';
import 'package:cross_team5/features/authentication_user_management/screens/login_screen.dart';

class AuthenticationRoutes {
  static const String welcome = "/welcome";
  static const String login = "/login";

  static Map<String, WidgetBuilder> routes = {
    welcome: (context) => const WelcomeScreen(),
    login: (context) => const LoginScreen(),
  };
}
