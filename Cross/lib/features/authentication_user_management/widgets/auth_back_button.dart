
import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.pop(context);
      },
      padding: EdgeInsets.zero,
      alignment: Alignment.centerLeft,
      icon: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: AppColors.white10,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back_ios_new,
          color: AppColors.whiteSmoke,
          size: 28,
        ),
      ),
    );
  }
}
