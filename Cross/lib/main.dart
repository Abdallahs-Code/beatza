// Dart imports
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Package imports
import 'package:cross_team5/routes/app_router.dart';

void main() async {
  // Test PR
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      routes: AppRouter.routes,

      initialRoute: "/",
    );
  }
}
