import 'package:flutter/material.dart';
import '../../authentication_user_management/authentication_user_management.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    await Future.delayed(
      const Duration(seconds: 5),
    ); // Simulate a delay for the splash screen

    bool loggedIn =
        false; // Implement your logic to check if the user is logged in

    if (!mounted) return;

    if (loggedIn) {
      Navigator.pushReplacementNamed(context, "/home");
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
