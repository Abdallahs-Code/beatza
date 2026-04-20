// Dart imports
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/core/theme/app_text.dart';
import 'package:cross_team5/features/authentication_user_management/authentication_user_management_routes.dart';
import 'package:cross_team5/features/authentication_user_management/screens/email_entry_screen.dart';
import 'package:cross_team5/features/authentication_user_management/screens/user_info_screen.dart';
import 'package:cross_team5/features/authentication_user_management/screens/verify_code_screen.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/authentication_user_management/services/qr_polling_service.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/login_widgets.dart';
import 'package:cross_team5/features/home/home_routes.dart';
import 'package:cross_team5/features/premium_subscription/services/payment_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _showQrDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.orangeQrCode),
      ),
    );

    try {
      final authApi = AuthApiService();
      final String qrData = await authApi.getQrCodeToken();

      if (!context.mounted) {
        return;
      }

      Navigator.pop(context);

      if (!context.mounted) {
        return;
      }

      _buildQrPollingDialog(context, authApi, qrData);
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      Navigator.pop(context);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load QR Code: $e"),
          backgroundColor: AppColors.anger,
        ),
      );
    }
  }

  void _buildQrPollingDialog(
      BuildContext context,
      AuthApiService authApi,
      String initialQrData,
      ) {
    String currentQrData = initialQrData;
    bool isLoading = false;
    String pollingStatus = 'waiting';
    QrPollingService? pollingService;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppColors.chineseBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Scan to Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (pollingStatus == 'waiting')
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (pollingStatus == 'waiting') ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: currentQrData,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Open SoundCloud on your phone and scan this code',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      Icon(
                        pollingStatus == 'success'
                            ? Icons.check_circle
                            : pollingStatus == 'error'
                            ? Icons.error_outline
                            : Icons.timer_off,
                        color: pollingStatus == 'success'
                            ? Colors.green
                            : pollingStatus == 'error'
                            ? Colors.red
                            : Colors.orange,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 20),
                    if (pollingStatus == 'waiting')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.orangeQrCode,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _getStatusMessage(pollingStatus),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        _getStatusMessage(pollingStatus),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    if (pollingStatus == 'waiting') ...[
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: isLoading
                            ? null
                            : () async {
                          setDialogState(() => isLoading = true);
                          try {
                            final newToken = await authApi
                                .getQrCodeToken();

                            if (!dialogContext.mounted) return;

                            setDialogState(() {
                              currentQrData = newToken;
                              isLoading = false;
                            });
                            pollingService?.stopPolling();
                            _startPolling(
                              dialogContext,
                              authApi,
                              newToken,
                              setDialogState,
                                  (service) => pollingService = service,
                                  () => pollingStatus,
                                  (status) => setDialogState(
                                    () => pollingStatus = status,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => isLoading = false);
                            if (!dialogContext.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(
                              dialogContext,
                            ).showSnackBar(
                              SnackBar(
                                content: Text("Refresh failed: $e"),
                              ),
                            );
                          }
                        },
                        icon: isLoading
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.refresh, size: 16),
                        label: Text(
                          isLoading ? 'Refreshing...' : 'Refresh QR Code',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.orangeQrCode,
                        ),
                      ),
                    ],
                    if (pollingStatus == 'error' ||
                        pollingStatus == 'timeout') ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              pollingService?.stopPolling();
                              Navigator.pop(context);
                              _showQrDialog(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.orangeQrCode,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Try Again'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () {
                              pollingService?.stopPolling();
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white38),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      pollingService?.dispose();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPolling(
        context,
        authApi,
        currentQrData,
            (newState) {},
            (service) => pollingService = service,
            () => pollingStatus,
            (newStatus) {},
      );
    });
  }

  void _startPolling(
      BuildContext context,
      AuthApiService authApi,
      String qrData,
      void Function(void Function()) setStateFn,
      void Function(QrPollingService) onServiceReady,
      String Function() getStatusFn,
      void Function(String) onStatusChange,
      ) {
    final pollingService = QrPollingService(
      authApi: authApi,
      pollInterval: const Duration(seconds: 5),
      timeout: const Duration(minutes: 2),
    );

    onServiceReady(pollingService);

    pollingService
        .startPolling(
      qrData: qrData,
      onStatusUpdate: (status) {
        if (getStatusFn() != status) {
          onStatusChange(status);
        }
      },
      onError: (error) {
        setStateFn(() {
          onStatusChange('error');
        });

        if (!context.mounted) {
          return;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connection error: $error')));
      },
    )
        .then((result) {
      if (!context.mounted) {
        return;
      }

      if (result['status'] == 'success') {
        _handleDesktopLoginSuccess(context, result);
      }
    })
        .catchError((error) {
      if (!context.mounted) {
        return;
      }

      if (error is TimeoutException) {
        setStateFn(() {
          onStatusChange('timeout');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please scan a new QR code.'),
          ),
        );
      } else {
        setStateFn(() {
          onStatusChange('error');
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connection error: $error')));
      }
    });
  }

  Future<void> _handleDesktopLoginSuccess(
      BuildContext context,
      Map<String, dynamic> userData,
      ) async {
    try {
      final authApi = AuthApiService();
      final data = userData['data'];

      if (data != null) {
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];
        final userId = data['user']?['id']?.toString();

        if (accessToken != null && refreshToken != null) {
          await authApi.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );

          if (userId != null && userId.trim().isNotEmpty) {
            await FlutterSecureStorage().write(key: 'user_id', value: userId);
          }
        }
      }

      await PaymentService.subscriptionSuccessNotifier.refresh();

      if (!context.mounted) {
        return;
      }

      Navigator.pop(context);
      Navigator.pushNamedAndRemoveUntil(
        context,
        HomeRoutes.home,
            (route) => false,
        arguments: {'loginMethod': 'qr_desktop'},
      );
    } catch (e) {

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login completed but navigation failed: $e')),
      );
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'waiting':
        return 'Waiting for scan...';
      case 'success':
        return 'Login successful! Redirecting...';
      case 'error':
        return 'Connection error. Please try again.';
      case 'timeout':
        return 'Session expired. Please refresh.';
      default:
        return 'Verifying...';
    }
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
              const Text(
                AppText.signInOrCreateAccount,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
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
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    final authApiService = AuthApiService();
                    final authUrl =
                        "${ApiServices().baseUrl}/api/auth/v1/google?client=Android";

                    try {
                      final result = await FlutterWebAuth2.authenticate(
                        url: authUrl,
                        callbackUrlScheme: "beatza",
                        options: const FlutterWebAuth2Options(useWebview: true),
                      );

                      if (!context.mounted) {
                        return;
                      }

                      final uri = Uri.parse(result);

                      final accessToken = uri.queryParameters["accessToken"];
                      final refreshToken = uri.queryParameters["refreshToken"];
                      final pendingToken = uri.queryParameters["pendingToken"];
                      final incompleteToken =
                      uri.queryParameters["incompleteToken"];
                      final displayName = uri.queryParameters["displayName"];

                      if (accessToken != null &&
                          accessToken.isNotEmpty &&
                          refreshToken != null &&
                          refreshToken.isNotEmpty) {

                        await authApiService.saveTokens(
                          accessToken: accessToken,
                          refreshToken: refreshToken,
                        );

                        await authApiService.refreshToken();

                        await PaymentService.subscriptionSuccessNotifier.refresh();

                        if (!context.mounted) {
                          return;
                        }

                        Navigator.pushReplacementNamed(
                          context,
                          HomeRoutes.home,
                        );
                        return;
                      }

                      if (pendingToken != null && pendingToken.isNotEmpty) {

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                VerifyCodeScreen(pendingToken: pendingToken),
                          ),
                        );
                        return;
                      }

                      if (incompleteToken != null &&
                          incompleteToken.isNotEmpty) {

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

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Google sign-in returned no usable data",
                          ),
                        ),
                      );
                    } catch (e) {

                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Google sign-in failed: $e"),
                          backgroundColor: AppColors.anger,
                        ),
                      );
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/googlelogo.png',
                        height: 20,
                        width: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (Platform.isWindows) ...[
                const SizedBox(height: 5),
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
              const Text(
                AppText.orWithEmail,
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmailEntryScreen()),
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
              LoginButton(
                text: AppText.continueButtonText,
                color: AppColors.silver,
                onPressed: () {},
              ),
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