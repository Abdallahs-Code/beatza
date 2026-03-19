import 'package:cross_team5/features/authentication_user_management/authentication_user_management_routes.dart';
import 'package:flutter/material.dart';
// import '../authentication_user_management_routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// BACKGROUND IMAGE
          SizedBox.expand(
            child: Image.asset(
              "assets/images/welcomebackground.jpg",
              fit: BoxFit.cover,
            ),
          ),

          /// BLUE PANEL
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              decoration: const BoxDecoration(
                color: Color(0xFF5A8DEE),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// LOGO
                  Image.asset("assets/images/blacklogo.png", width: 100),

                  /// TITLE
                  const Text(
                    "Where artists\n& fans connect.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// CREATE ACCOUNT
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigator.pushNamed(
                        //   context,
                        //   AuthenticationRoutes.login,
                        // );
                        Navigator.pushReplacementNamed(context, AuthenticationRoutes.login);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Create an account",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// LOGIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigator.pushNamed(
                        //   context,
                        //   AuthenticationRoutes.login,
                        // );
                        Navigator.pushReplacementNamed(context, AuthenticationRoutes.login);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(187, 210, 254, 1),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Log in",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
