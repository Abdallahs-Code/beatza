// Dart imports
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart'; // ← NEW

// Your existing imports
import 'package:cross_team5/core/navigation/app_navigator.dart';
import 'package:cross_team5/features/playback_streaming_engine/widgets/global_playback_overlay.dart';
import 'package:cross_team5/features/playback_streaming_engine/widgets/ad_overlay.dart';
import 'package:cross_team5/routes/app_router.dart';
import 'package:cross_team5/core/navigation/app_overlay_visibility.dart';
import 'package:cross_team5/core/widgets/global_connectivity_overlay.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/theme_service.dart'; // ← NEW
import 'core/theme/app_colors.dart'; // ← NEW
import 'features/activity/services/push_notification_service.dart';
import 'features/premium_subscription/services/offline_download_service.dart';
import 'features/premium_subscription/services/payment_service.dart';

const bool openPlaybackDebugOnStart = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  // await AuthApiService().logout();

  if (Platform.isAndroid || Platform.isIOS) {
    await Firebase.initializeApp();
  }

  await ConnectivityService.instance.initialize();

  try {
    await PaymentService.subscriptionSuccessNotifier.refresh();
  } catch (e) {
    await PaymentService.subscriptionSuccessNotifier.loadLocalStatus();
  }
  await OfflineDownloadService.shared.loadDownloadedTracks();
  await PushNotificationService.shared.initialize();

  // ── Initialize ThemeService & Sync AppColors ─────────────────────────────
  final themeService = ThemeService();
  await themeService.init();

  // Sync AppColors brightness with saved theme
  AppColors.setThemeBrightness(
    themeService.isDarkMode ? Brightness.dark : Brightness.light,
  );

  // Listen for future theme toggles
  themeService.addListener(() {
    AppColors.setThemeBrightness(
      themeService.isDarkMode ? Brightness.dark : Brightness.light,
    );
  });

  runApp(
    ChangeNotifierProvider.value(value: themeService, child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return MaterialApp(
      title: 'Beatza',
      navigatorKey: appNavigatorKey,
      navigatorObservers: [appOverlayRouteObserver, appRouteObserver],
      debugShowCheckedModeBanner: false,

      // ── Theme Configuration ────────────────────────────────────────────────
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.homeBackground,
        cardColor: AppColors.cardDark,
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryOrange,
          surface: AppColors.surfaceMid,
          onSurface: AppColors.whiteSmoke,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.homeBackground,
        cardColor: AppColors.cardDark,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primaryOrange,
          surface: AppColors.surfaceMid,
          onSurface: AppColors.whiteSmoke,
        ),
      ),
      themeMode: themeService.themeMode,

      routes: AppRouter.routes,
      initialRoute: "/",
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            const GlobalPlaybackOverlay(),
            const GlobalConnectivityOverlay(),
            const AdOverlay(),
          ],
        );
      },
    );
  }
}
