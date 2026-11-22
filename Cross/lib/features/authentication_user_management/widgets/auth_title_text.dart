
import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

class AuthTitleText extends StatelessWidget {
  final String text;

  const AuthTitleText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: AppColors.whiteSmoke,
      ),
    );
  }
}
