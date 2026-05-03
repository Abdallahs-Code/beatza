
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';


import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/authentication_user_management/authentication_user_management_routes.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/auth_link_text.dart';
import 'package:provider/provider.dart';
import 'package:cross_team5/core/services/theme_service.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/auth_title_text.dart';

class CheckInboxScreen extends StatefulWidget {
  final String email;

  const CheckInboxScreen({super.key, required this.email});

  @override
  State<CheckInboxScreen> createState() => _CheckInboxScreenState();
}

class _CheckInboxScreenState extends State<CheckInboxScreen> {
  bool _isResending = false;

  Future<void> _openGmail() async {
    final Uri gmailUri = Uri.parse("https://mail.google.com");

    if (await canLaunchUrl(gmailUri)) {
      await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openHelpCenter() async {
    final Uri helpUri = Uri.parse("${ApiServices().baseUrl}/need-help");

    if (await canLaunchUrl(helpUri)) {
      await launchUrl(helpUri);
    }
  }

  Future<void> _handleResendVerificationEmail() async {
    setState(() {
      _isResending = true;
    });

    final authApiService = AuthApiService();

    final result = await authApiService.resendVerificationEmail(
      email: widget.email,
    );

    if (!mounted) return;

    setState(() {
      _isResending = false;
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
      key: const Key('test_check_inbox_screen'),
      backgroundColor: AppColors.chineseBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            children: [
              const SizedBox(height: 10),

              const AuthTitleText(text: "Check your inbox!"),

              const SizedBox(height: 20),

              Text(
                "Click on the link we sent to",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.white70, fontSize: 18),
              ),

              const SizedBox(height: 6),

              Text(
                key: const Key('test_check_inbox_email'),
                widget.email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              GestureDetector(
                key: const Key('test_check_inbox_resend_btn'),
                onTap: _isResending ? null : _handleResendVerificationEmail,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(fontSize: 14, color: AppColors.white70),
                    children: [
                      const TextSpan(
                        text: "No email in your inbox or spam folder? ",
                      ),
                      TextSpan(
                        text: _isResending ? "Sending..." : "Send again",
                        style: const TextStyle(
                          color: AppColors.blueHyperlink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 34),

              Container(
                height: 230,
                width: 230,
                alignment: Alignment.center,
                child: Icon(Icons.send, size: 140, color: AppColors.whiteSmoke),
              ),

              const SizedBox(height: 34),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openGmail,
                  icon: Icon(Icons.mail_outline, color: AppColors.pureBlack),
                  label: Text(
                    "Open Gmail",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pureBlack,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.whiteSmoke,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              GestureDetector(
                key: const Key('test_check_inbox_back_to_login_btn'),
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AuthenticationRoutes.login,
                    (route) => false,
                  );
                },
                child: const AuthLinkText(
                  text: "Back to login",
                  alignCenter: true,
                ),
              ),

              const SizedBox(height: 12),

              GestureDetector(
                onTap: _openHelpCenter,
                child: Text(
                  "If you still need help, visit our Help Center.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
