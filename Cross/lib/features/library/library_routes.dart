// Dart imports
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/features/library/screens/library_screen.dart';

class LibraryRoutes {
  static const String library = "/library";

  static Map<String, WidgetBuilder> routes = {
    library: (context) => const LibraryScreen(),
  };
}
