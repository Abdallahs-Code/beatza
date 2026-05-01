// Dart imports
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/core/theme/app_text.dart';

class WelcomeBackground extends StatelessWidget {
  const WelcomeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Image.asset(
        "assets/images/welcomebackground.jpg",
        fit: BoxFit.cover,
      ),
    );
  }
}

class WelcomeBottomPanel extends StatelessWidget {
  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;

  const WelcomeBottomPanel({
    super.key,
    required this.onCreateAccount,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      decoration: const BoxDecoration(
        color: AppColors.blueWelcome,
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
            AppText.welcomeTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 30),

          /// CREATE ACCOUNT BUTTON
          WelcomeButton(
            text: AppText.createAccount,
            backgroundColor: AppColors.whiteSmoke,
            textColor: Colors.black,
            onPressed: onCreateAccount,
          ),

          const SizedBox(height: 12),

          /// LOGIN BUTTON
          WelcomeButton(
            text: AppText.login,
            backgroundColor: const Color.fromRGBO(187, 210, 254, 1),
            textColor: Colors.black,
            onPressed: onLogin,
          ),
        ],
      ),
    );
  }
}

class WelcomeButton extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;

  const WelcomeButton({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
