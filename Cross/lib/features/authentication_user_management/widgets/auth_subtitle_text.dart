// Dart imports
import 'package:flutter/material.dart';

class AuthSubtitleText extends StatelessWidget {
  final String text;

  const AuthSubtitleText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, color: Colors.white54, height: 1.4),
    );
  }
}
