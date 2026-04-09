import 'package:flutter/material.dart';

import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/auth_back_button.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/auth_title_text.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/login_widgets.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String pendingToken;

  const VerifyCodeScreen({
    super.key,
    required this.pendingToken,
  });

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter the verification code"),
        ),
      );
      return;
    }

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("The verification code must be 6 digits"),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authApiService = AuthApiService();

    final result = await authApiService.verifyGoogleCode(
      pendingToken: widget.pendingToken,
      code: code,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.$1 >= 200 && result.$1 < 300) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        "/home", // replace with your actual route
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.$2.toString()),
          backgroundColor: AppColors.anger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.chineseBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthBackButton(),
              const SizedBox(height: 20),

              const Center(
                child: AuthTitleText(
                  text: "Enter verification code",
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "We sent a 6-digit verification code to your email. Enter it below to finish signing in with Google.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "6-digit code",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: AppColors.googleBackGround,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              LoginButton(
                text: _isLoading ? "Verifying..." : "Verify",
                color: AppColors.silver,
                onPressed: _isLoading ? () {} : _handleVerify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}