import 'package:flutter/material.dart';

import 'screens/library_screen.dart';

class LibraryRoutes {
  static const String library = "/library";

  static Map<String, WidgetBuilder> routes = {
    library: (context) => const LibraryScreen(),
  };
}
