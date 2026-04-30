// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

// Package imports
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/library/services/account_settings_api_service.dart';
import 'package:cross_team5/features/authentication_user_management/authentication_user_management_routes.dart';
import 'package:cross_team5/features/home/home_routes.dart';
import 'package:cross_team5/core/services/theme_service.dart';
import '../../premium_subscription/services/payment_service.dart';

// Your connectivity service
import 'package:cross_team5/core/services/connectivity_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final AuthApiService authApiService = AuthApiService();
  final AccountSettingsApiService accountSettingsApiService = AccountSettingsApiService();

  bool _isChecking = true;
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();
    _startApp();
  }

  Future<void> _startApp() async {
    setState(() {
      _isChecking = true;
    });

    final bool hasInternet = await ConnectivityService.instance
        .hasInternetConnection();
    final bool isPro = PaymentService.subscriptionSuccessNotifier.isPro;
    if (!mounted) return;
    if (!hasInternet && !isPro) {
      setState(() {
        _isChecking = false;
        _hasInternet = false;
      });
      return;
    }

    await checkLoginStatus(hasInternet);
  }

  Future<void> checkLoginStatus(bool hasInternet) async {
    bool isLoggedIn = false;

    // Get token for API settings fetch
    final accessToken = await _storage.read(key: 'access_token');
    final tokenTime = await _storage.read(key: 'token_time');

    if (tokenTime != null) {
      final currentTime = DateTime.now();
      final timeDifference = currentTime.difference(DateTime.parse(tokenTime));

      if (timeDifference < const Duration(days: 7)) {
        isLoggedIn = true;
        if (hasInternet) {
          try {
            await authApiService.refreshToken();

            // ── SYNC THEME FROM API ────────────────────────────────────────
            if (accessToken != null && mounted) {
              try {
                // Your API returns AccountSettings with a `theme` String property
                final settings = await accountSettingsApiService.getSettings(accessToken);
                await Provider.of<ThemeService>(context, listen: false)
                    .syncThemeFromApi(settings.theme);
              } catch (e) {
                // Non-blocking: app continues with locally saved or default theme
                debugPrint('⚠️ Failed to sync theme from settings API: $e');
              }
            }
            // ───────────────────────────────────────────────────────────────

          } catch (_) {
            isLoggedIn = false;
            await authApiService.logout();
          }
        }
      } else {
        await authApiService.logout();
      }
    }

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, HomeRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AuthenticationRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isChecking
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/images/whitelogo.png", width: 175),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(color: Colors.white),
                ],
              )
            : !_hasInternet
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/images/whitelogo.png", width: 175),
                  const SizedBox(height: 20),
                  const Text(
                    "No Internet Connection",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Please connect to the internet and try again",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _startApp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text("Retry"),
                  ),
                ],
              )
            : const SizedBox(),
      ),
    );
  }
}