// Dart imports
import 'dart:io' show Platform;
import 'dart:ui';
import 'package:cross_team5/core/services/logger_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:url_launcher/url_launcher.dart';

// Package imports
import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/core/theme/app_text.dart';
import 'package:cross_team5/features/authentication_user_management/authentication_user_management_routes.dart';
import 'package:cross_team5/features/authentication_user_management/screens/email_entry_screen.dart';
import 'package:cross_team5/features/authentication_user_management/screens/user_info_screen.dart';
import 'package:cross_team5/features/authentication_user_management/screens/verify_code_screen.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/login_widgets.dart';
import 'package:cross_team5/features/home/home_routes.dart';


class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  String? _readQueryParam(Uri uri, String key) {
    final value = uri.queryParameters[key]?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> _handleGoogleLogin(BuildContext context) async {
    final authApiService = AuthApiService();
    final authUrl =
        "${ApiServices().baseUrl}/api/auth/v1/google?client=Android";

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: "beatza",
        options: const FlutterWebAuth2Options(useWebview: true),
      );

      final uri = Uri.parse(result);

      final accessToken = _readQueryParam(uri, "accessToken");
      final refreshToken = _readQueryParam(uri, "refreshToken");
      final pendingToken = _readQueryParam(uri, "pendingToken");
      final incompleteToken = _readQueryParam(uri, "incompleteToken");
      final displayName = _readQueryParam(uri, "displayName");

      LoggerService.logger.i("result: $result");

      // Case 3: returning Google user
      if (accessToken != null && refreshToken != null) {
        LoggerService.logger.i("Case 3: Returning Google user logged in successfully");
        await authApiService.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        await authApiService.refreshToken();

        if (!context.mounted) return;
        Navigator.pushReplacementNamed(context, HomeRoutes.home);
        return;
      }

      // Case 2: existing user, first Google login
      if (pendingToken != null) {
        if (!context.mounted) return;
        LoggerService.logger.i("Case 2: Existing user, first Google login");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyCodeScreen(
              pendingToken: pendingToken,
            ),
          ),
        );
        return;
      }

      // Case 1: new Google user
      if (incompleteToken != null) {
        if (!context.mounted) return;
        LoggerService.logger.i("Case 1: New Google user");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserInfoScreen(
              incompleteToken: incompleteToken,
              initialDisplayName: displayName ?? "",
              isGoogleFlow: true,
            ),
          ),
        );
        return;
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Google sign-in returned no usable data"),
          backgroundColor: AppColors.anger,
        ),
      );
    } catch (e) {

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Google sign-in failed: $e"),
          backgroundColor: AppColors.anger,
        ),
      );
    }
  }

  Future<void> _showQrDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.orangeQrCode),
      ),
    );

    try {
      final authController = AuthApiService();
      final String qrData = await authController.getQrCodeToken();

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        _buildQrDialog(context, qrData);
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load QR Code: $e"),
            backgroundColor: AppColors.anger,
          ),
        );
      }
    }
  }

  void _buildQrDialog(BuildContext context, String initialQrData) {
    String currentQrData = initialQrData;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return QrCodeLoginDialog(
              qrData: currentQrData,
              isLoading: isLoading,
              onRefresh: () async {
                setDialogState(() {
                  isLoading = true;
                });

                try {
                  final authController = AuthApiService();
                  final newToken = await authController.getQrCodeToken();

                  setDialogState(() {
                    currentQrData = newToken;
                    isLoading = false;
                  });
                } catch (e) {
                  setDialogState(() {
                    isLoading = false;
                  });

                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text("Refresh failed: $e")),
                    );
                  }
                }
              },
            );
          },
        );
      },
    );
  }

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
                onPressed: () async {
                  final authApiService = AuthApiService();
                  final authUrl = "${ApiServices().baseUrl}/api/auth/v1/google?client=Android";

                  try {
                    final result = await FlutterWebAuth2.authenticate(
                      url: authUrl,
                      callbackUrlScheme: "beatza",
                      options: const FlutterWebAuth2Options(useWebview: true)
                    );

                    LoggerService.logger.i("Google auth callback result: $result");

                    final uri = Uri.parse(result);

                    final accessToken = uri.queryParameters["accessToken"];
                    final refreshToken = uri.queryParameters["refreshToken"];
                    final pendingToken = uri.queryParameters["pendingToken"];
                    final incompleteToken = uri.queryParameters["incompleteToken"];
                    final displayName = uri.queryParameters["displayName"];

                    // Case 3: returning Google user
                    if (accessToken != null && accessToken.isNotEmpty && refreshToken != null && refreshToken.isNotEmpty) {
                      
                      await authApiService.saveTokens(accessToken: accessToken, refreshToken: refreshToken);

                      await authApiService.refreshToken();

                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, HomeRoutes.home);
                      }
                      return;
                    }

                    // Case 2: existing user, first Google login
                    if (pendingToken != null && pendingToken.isNotEmpty) {
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VerifyCodeScreen(
                              pendingToken: pendingToken,
                            ),
                          ),
                        );
                      }
                      return;
                    }

                    // Case 1: new Google user
                    if (incompleteToken != null && incompleteToken.isNotEmpty) {
                      if (context.mounted) {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (_) => UserInfoScreen(
                        //       incompleteToken: incompleteToken,
                        //       initialDisplayName: displayName ?? "",
                        //       isGoogleFlow: true,
                        //     ),
                        //   ),
                        // );
                      }
                      return;
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Google sign-in returned no usable data"),
                        ),
                      );
                    }
                  } catch (e) {
                    LoggerService.logger.i("Google sign-in failed: $e");

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Google sign-in failed: $e"),
                          backgroundColor: AppColors.anger,
                        ),
                      );
                    }
                  }
                },
              ),

              if (Platform.isWindows) ...[
                const SizedBox(height: 5),

                /// QR CODE LOGIN BUTTON
                LoginButton(
                  text: AppText.continueWithQrCode,
                  icon: Icons.qr_code,
                  color: AppColors.orangeQrCode,
                  onPressed: () {
                    _showQrDialog(context);
                  },
                ),
              ],

              const SizedBox(height: 10),

              /// TEXT
              const Text(
                AppText.orWithEmail,
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EmailEntryScreen(),
                    ),
                  );
                },
                child: AbsorbPointer(
                  child: TextInputField(
                    hintText: AppText.emailOrProfileUrlHint,
                    controller: emailController,
                  ),
                ),
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
                  style: const TextStyle(
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