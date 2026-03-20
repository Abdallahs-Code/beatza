import "package:flutter/material.dart";
import "package:flutter/gestures.dart";
import "package:url_launcher/url_launcher.dart";

import "package:cross_team5/core/services/api_services.dart";
import '../authentication_user_management_routes.dart';
import "../widgets/login_widgets.dart";
import "../../../core/theme/app_colors.dart";
import "../../../core/theme/app_text.dart";
import 'dart:io' show Platform;

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    return Scaffold(
      backgroundColor: AppColors.chineseBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// BACK BUTTON
              IconButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    AuthenticationRoutes.welcome,
                  );
                },
                alignment: Alignment.centerLeft,
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              ),

              const SizedBox(height: 40),

              /// TITLE
              const Text(
                AppText.signInOrCreateAccount,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              /// SUBTITLE WITH HYPERLINKS
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: AppText.termsAgreementStart),

                    TextSpan(
                      text: AppText.termsOfUse,
                      style: const TextStyle(
                        color: AppColors.blueHyperlink,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          await launchUrl(
                            Uri.parse('${ApiServices().baseUrl}/legal'),
                          );
                        },
                    ),

                    const TextSpan(text: AppText.andAcknowledge),

                    TextSpan(
                      text: AppText.privacyPolicy,
                      style: const TextStyle(
                        color: AppColors.blueHyperlink,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          await launchUrl(
                            Uri.parse(
                              '${ApiServices().baseUrl}/privacy-policy',
                            ),
                          );
                        },
                    ),
                  ],
                ),
              ),

              

              const SizedBox(height: 10),

              /// GOOGLE LOGIN BUTTON
              LoginButton(
                text: AppText.continueWithGoogle,
                icon: Icons.g_mobiledata,
                color: AppColors.googleBackGround,
                onPressed: () {},
              ),

              if (Platform.isWindows) ...[
                const SizedBox(height: 5),

                /// QR CODE LOGIN BUTTON
                LoginButton(
                  text: AppText.continueWithQrCode,
                  icon: Icons.qr_code,
                  color: AppColors.orangeQrCode,
                  onPressed: () {},
                ),
              ],

              const SizedBox(height: 10),

              /// Text
              const Text(
                AppText.orWithEmail,
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              TextInputField(
                hintText: AppText.emailOrProfileUrlHint,
                controller: emailController,
              ),

              const SizedBox(height: 20),

              /// CONTINUE BUTTON
              LoginButton(
                text: AppText.continueButtonText,
                color: AppColors.silver,
                onPressed: () {},
              ),

              /// NEED HELP?
              RichText(
                text: TextSpan(
                  text: AppText.needHelp,
                  style: TextStyle(
                    color: AppColors.blueHyperlink,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      await launchUrl(
                        Uri.parse('${ApiServices().baseUrl}/need-help'),
                      );
                    },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}