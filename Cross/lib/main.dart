// Dart imports
import 'package:cross_team5/features/authentication_user_management/authentication_user_management.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Package imports
import 'package:cross_team5/routes/app_router.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  await AuthApiService().logout();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beatza',

      debugShowCheckedModeBanner: false,

      routes: AppRouter.routes,

      initialRoute: "/",
    );
  }
}
