// Dart imports
import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

// Package imports
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/welcome_widgets.dart';
import 'package:cross_team5/features/home/home_routes.dart';
import 'package:cross_team5/features/authentication_user_management/authentication_user_management_routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  final bool isCrossPlatFlow = true;

  Future<void> _openAuthFlow(BuildContext context) async {
    final authApiService = AuthApiService();
    const authUrl = "https://beatza.me/sign-in?client=Android";

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: "beatza",
      );
      debugPrint("Authentication callback received: $result");

      final uri = Uri.parse(result);
      final accessToken = uri.queryParameters["accessToken"];
      final refreshToken = uri.queryParameters["refreshToken"];

      if (accessToken != null &&
          accessToken.isNotEmpty &&
          refreshToken != null &&
          refreshToken.isNotEmpty) {
        await authApiService.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        authApiService.refreshToken();
        if (!context.mounted) return;
        Navigator.pushReplacementNamed(context, HomeRoutes.home);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Authentication failed: Missing tokens in callback URL",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Authentication failed: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Authentication failed: $e")));
      }
    }
  }

  void _handleAuth(BuildContext context) {
    if (isCrossPlatFlow) {
      Navigator.pushNamed(context, AuthenticationRoutes.login);
    } else {
      _openAuthFlow(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const WelcomeBackground(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: WelcomeBottomPanel(
              onCreateAccount: () => _handleAuth(context),
              onLogin: () => _handleAuth(context),
            ),
          ),
        ],
      ),
    );
  }
}
