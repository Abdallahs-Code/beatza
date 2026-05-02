// Dart imports
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Package imports
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/core/theme/app_text.dart';

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
  final bool autofocus;

  const TextInputField({
    super.key,
    required this.hintText,
    required this.controller,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      style: TextStyle(color: AppColors.whiteSmoke),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: AppColors.white54),
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.white54),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.white70),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
    );
  }
}

class QrCodeLoginDialog extends StatelessWidget {
  final String qrData;
  final VoidCallback? onRefresh;
  final bool isLoading;

  const QrCodeLoginDialog({
    super.key,
    required this.qrData,
    this.onRefresh,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.chineseBlack,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white10, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Title
            Text(
              AppText.qrCodeLoginTitle,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.whiteSmoke,
              ),
            ),
            const SizedBox(height: 16),

            /// Description
            Text(
              AppText.qrCodeLoginDesc,
              style: TextStyle(fontSize: 16, color: AppColors.white70),
            ),
            const SizedBox(height: 24),

            /// Steps
            _buildStep('1', AppText.stepInstruction[0]),
            _buildStep('2', AppText.stepInstruction[1]),
            _buildStep('3', AppText.stepInstruction[2]),

            const SizedBox(height: 32),

            /// QR Code Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.pureBlack,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.white10, width: 1),
              ),
              child: Center(
                child: isLoading
                    ? // CONDITIONAL RENDERING
                      const CircularProgressIndicator(
                        color: AppColors.orangeQrCode,
                      )
                    : QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 220.0,
                        backgroundColor: AppColors.white70,
                      ),
              ),
            ),

            const SizedBox(height: 24),

            /// Status and Refresh Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// Status Text
                Text(
                  AppText.qrCodeLoginStatus,
                  style: TextStyle(color: AppColors.white70, fontSize: 14),
                ),

                /// Refresh Button
                ElevatedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orangeQrCode,
                    foregroundColor: AppColors.white70,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number.',
            style: TextStyle(
              color: AppColors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.white70,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
