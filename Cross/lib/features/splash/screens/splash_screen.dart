import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../authentication_user_management/authentication_user_management.dart';

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

    // await Future.delayed(
    //   const Duration(seconds: 5),
    // ); 

    bool isLoggedIn = false;
    final tokenTime = await _storage.read(key: 'token_time');

    if (tokenTime != null) {

      final currentTime = DateTime.now();
      final timeDifference = currentTime.difference(DateTime.parse(tokenTime));

      if (timeDifference < const Duration(days: 7)) {
        isLoggedIn = true;
        await authApiService.refreshToken();
      }
      else {
        await authApiService.logout();
      }

    }

    if (!mounted) return;

    if (isLoggedIn) {

      Navigator.pushReplacementNamed(context, AuthenticationRoutes.home);
      
    } 
    else {

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
