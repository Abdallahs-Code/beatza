// Dart imports
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Package imports
import 'package:cross_team5/core/navigation/app_navigator.dart';
import 'package:cross_team5/features/playback_streaming_engine/playback_streaming_engine.dart';
import 'package:cross_team5/features/playback_streaming_engine/widgets/global_playback_overlay.dart';
import 'package:cross_team5/routes/app_router.dart';
import 'package:cross_team5/core/navigation/app_overlay_visibility.dart';

const bool OPEN_PLAYBACK_DEBUG_ON_START = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
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
          ],
        );
      },
    );
  }
}