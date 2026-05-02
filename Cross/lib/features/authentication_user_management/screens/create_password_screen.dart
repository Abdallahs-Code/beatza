// Dart imports
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/authentication_user_management/screens/user_info_screen.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/auth_back_button.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/auth_link_text.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/auth_subtitle_text.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/auth_title_text.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/login_widgets.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/password_input_field.dart';

class CreatePasswordScreen extends StatefulWidget {
  final String email;

  const CreatePasswordScreen({super.key, required this.email});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    final String password = _passwordController.text.trim();

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 8 characters")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserInfoScreen(
          email: widget.email,
          password: password,
          isGoogleFlow: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('test_create_password_screen'),
      backgroundColor: AppColors.chineseBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthBackButton(),
              const SizedBox(height: 20),

              const Center(child: AuthTitleText(text: "Create an account")),

              const SizedBox(height: 36),

              const AuthSubtitleText(text: "Your email address"),
              const SizedBox(height: 6),

              Text(
                key: const Key('test_create_password_email_display'),
                widget.email,
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.whiteSmoke,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 26),

              PasswordInputField(
                key: const Key('test_create_password_input'),
                hintText: "Choose a password (min. 8 characters)",
                controller: _passwordController,
              ),

              const SizedBox(height: 24),

              LoginButton(
                key: const Key('test_create_password_continue_btn'),
                text: "Continue",
                color: AppColors.silver,
                onPressed: _handleContinue,
              ),

              const SizedBox(height: 20),

              const AuthLinkText(text: "Need help?"),
            ],
          ),
        ),
      ),
    );
  }
}
