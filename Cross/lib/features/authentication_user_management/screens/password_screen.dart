// Dart imports
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/authentication_user_management/models/user.dart'
    as user_model;
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/auth_back_button.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/auth_link_text.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/auth_subtitle_text.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/auth_title_text.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/login_widgets.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/password_input_field.dart';
import 'package:provider/provider.dart';
import 'package:cross_team5/core/services/theme_service.dart';
import 'package:cross_team5/features/home/home_routes.dart';

class PasswordScreen extends StatefulWidget {
  final String email;

  const PasswordScreen({super.key, required this.email});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isForgotPasswordLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final String password = _passwordController.text.trim();

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your password")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authApiService = AuthApiService();

    final result = await authApiService.login(
      user: user_model.User(widget.email, password, "", "", ""),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.$2.toString()),
        backgroundColor: result.$1 == 200 ? AppColors.successGreen : AppColors.anger,
      ),
    );

    if (result.$1 == 200) {
      Navigator.pushReplacementNamed(context, HomeRoutes.home);
    }
  }

  Future<void> _handleForgotPassword() async {
    setState(() {
      _isForgotPasswordLoading = true;
    });

    final authApiService = AuthApiService();

    final result = await authApiService.forgotPassword(email: widget.email);

    if (!mounted) return;

    setState(() {
      _isForgotPasswordLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.$2.toString()),
        backgroundColor: result.$1 == 200 ? AppColors.successGreen : AppColors.anger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeService>();
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

              const Center(child: AuthTitleText(text: "Welcome back!")),

              const SizedBox(height: 36),

              const AuthSubtitleText(text: "Your email address or profile URL"),
              const SizedBox(height: 6),

              Text(
                widget.email,
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.whiteSmoke,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 26),

              PasswordInputField(
                hintText: "Your Password (min. 6 characters)",
                controller: _passwordController,
              ),

              const SizedBox(height: 24),

              LoginButton(
                text: _isLoading ? "Loading..." : "Continue",
                color: AppColors.silver,
                onPressed: _isLoading ? () {} : _handleContinue,
              ),

              const SizedBox(height: 20),

              GestureDetector(
                onTap: _isForgotPasswordLoading ? null : _handleForgotPassword,
                child: AuthLinkText(
                  text: _isForgotPasswordLoading
                      ? "Sending..."
                      : "Forgot your password?",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
