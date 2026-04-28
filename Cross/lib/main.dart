// Dart imports
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cross_team5/core/navigation/app_navigator.dart';
import 'package:cross_team5/features/playback_streaming_engine/widgets/global_playback_overlay.dart';
import 'package:cross_team5/routes/app_router.dart';
import 'package:cross_team5/core/navigation/app_overlay_visibility.dart';
import 'package:cross_team5/core/widgets/global_connectivity_overlay.dart';
import 'core/services/connectivity_service.dart';
import 'features/activity/services/push_notification_service.dart';
import 'features/premium_subscription/services/offline_download_service.dart';
import 'features/premium_subscription/services/payment_service.dart';

const bool openPlaybackDebugOnStart = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beatza',
      navigatorKey: appNavigatorKey,
      navigatorObservers: [appOverlayRouteObserver],
      debugShowCheckedModeBanner: false,
      routes: AppRouter.routes,
      initialRoute: "/",
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            const GlobalPlaybackOverlay(),
            const GlobalConnectivityOverlay(),
          ],
        );
      },
    );
  }
}