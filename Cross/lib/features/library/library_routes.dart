import 'package:cross_team5/features/library/screens/qr_scanner_screen.dart';
import 'package:flutter/material.dart';

import 'screens/library_screen.dart';

class LibraryRoutes {
  static const String library = "/library";
  static const String qrScanner = "/qrScanner";

  static Map<String, WidgetBuilder> routes = {
    library: (context) => const LibraryScreen(),
    qrScanner: (context) => const QrScannerScreen(),
  };
}
