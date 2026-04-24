// Dart imports
import 'package:flutter/material.dart';

class AuthTitleText extends StatelessWidget {
  final String text;

  const AuthTitleText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}
