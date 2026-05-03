
import 'package:flutter/material.dart';


import 'package:cross_team5/features/library/screens/library_screen.dart';
import 'package:cross_team5/features/library/screens/qr_scanner_screen.dart';
import 'package:cross_team5/features/library/screens/your_likes_screen.dart';

class LibraryRoutes {
  static const String library = "/library";
  static const String qrScanner = "/qrScanner";
  static const String yourLikes = "/library/your_likes";

  static Map<String, WidgetBuilder> routes = {
    library: (context) => const LibraryScreen(),
    qrScanner: (context) => const QrScannerScreen(),
    yourLikes: (context) => const YourLikesScreen(),
  };
}
