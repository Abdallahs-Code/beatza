// Dart imports
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/features/home/screens/home_screen.dart';

class HomeRoutes {
  static const String home = "/home";

  static Map<String, WidgetBuilder> routes = {
    home: (context) => const HomeScreen(),
  };
}
