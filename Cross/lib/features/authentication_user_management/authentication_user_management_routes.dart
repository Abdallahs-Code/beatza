import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/login_screen.dart';


class AuthenticationRoutes {
  static const String welcome = "/welcome";
  static const String home = "/home";
  static const String library = "/library";
  static const String login = "/login";

  static Map<String, WidgetBuilder> routes = {
    welcome: (context) => const WelcomeScreen(),
    home: (context) => const HomeScreen(),
    library: (context) => const LibraryScreen(),
    login: (context) => const LoginScreen(),
  };
}
