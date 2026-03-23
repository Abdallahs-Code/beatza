// Dart imports
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/authentication_user_management/screens/create_password_screen.dart';
import 'package:cross_team5/features/authentication_user_management/screens/password_screen.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/auth_back_button.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/auth_link_text.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/auth_title_text.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/login_widgets.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';

class EmailEntryScreen extends StatefulWidget {
  const EmailEntryScreen({super.key});

  @override
  State<EmailEntryScreen> createState() => _EmailEntryScreenState();
}

class _EmailEntryScreenState extends State<EmailEntryScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final String email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your email address or profile URL"),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authApiService = AuthApiService();
final bool userExists = await authApiService.checkUserExists(
  email: _emailController.text.trim(),
);

if (!mounted) return;

if (userExists) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PasswordScreen(email: _emailController.text.trim()),
    ),
  );
} else {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CreatePasswordScreen(email: _emailController.text.trim()),
    ),
  );
}
    } catch (err) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to continue: $err"),
          backgroundColor: AppColors.anger,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
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
                  text: "Sign in or create an account",
                ),
              ),

              const SizedBox(height: 30),

              TextInputField(
                hintText: "Your email address or profile URL",
                controller: _emailController,
                autofocus: true,
              ),

              const SizedBox(height: 24),

              LoginButton(
                text: _isLoading ? "Loading..." : "Continue",
                color: AppColors.silver,
                onPressed: _isLoading ? () {} : _handleContinue,
              ),

              const SizedBox(height: 20),

              const AuthLinkText(
                text: "Need help?",
              ),
            ],
          ),
        ),
      ),
    );
  }
}