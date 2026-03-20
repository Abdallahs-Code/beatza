import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class LoginButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;
  final VoidCallback onPressed;

  const LoginButton({
    super.key,
    required this.text,
    this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: _getButtonColor(color),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 24),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Color _getButtonColor(Color backgroundColor) {
    if (backgroundColor == AppColors.googleBackGround) {
      return AppColors.whiteSmoke;
    } else {
      return AppColors.pureBlack;
    }
  }
}

class TextInputField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;

  const TextInputField({
    super.key,
    required this.hintText,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: Colors.grey[500]!),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }
}
