// Dart imports
import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

class AuthSubtitleText extends StatelessWidget {
  final String text;

  const AuthSubtitleText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 14, color: AppColors.white54, height: 1.4),
    );
  }
}
