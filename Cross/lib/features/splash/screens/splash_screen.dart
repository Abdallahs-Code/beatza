// Dart imports
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Package imports
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/authentication_user_management/authentication_user_management_routes.dart';
import 'package:cross_team5/features/home/home_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final AuthApiService authApiService = AuthApiService();

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    bool isLoggedIn = false;
    final tokenTime = await _storage.read(key: 'token_time');

    if (tokenTime != null) {
      final currentTime = DateTime.now();
      final timeDifference = currentTime.difference(DateTime.parse(tokenTime));

      if (timeDifference < const Duration(days: 7)) {
        isLoggedIn = true;
        await authApiService.refreshToken();
      } else {
        await authApiService.logout();
      }
    }

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, HomeRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AuthenticationRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Center(
        child: Image.asset("assets/images/whitelogo.png", width: 175),
      ),
    );
  }
}
