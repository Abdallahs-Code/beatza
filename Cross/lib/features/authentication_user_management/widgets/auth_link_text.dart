// Dart imports
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/core/theme/app_colors.dart';

class AuthLinkText extends StatelessWidget {
  final String text;
  final bool alignCenter;

  const AuthLinkText({
    super.key,
    required this.text,
    this.alignCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignCenter ? Alignment.center : Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.blueHyperlink,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.blueHyperlink,
        ),
      ),
    );
  }
}