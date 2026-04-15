import 'package:flutter/material.dart';

import 'screens/playback_debug_screen.dart';

class PlaybackStreamingEngineRoutes {
  PlaybackStreamingEngineRoutes._();

  static const String debug = '/playbackDebug';

  static Map<String, WidgetBuilder> get routes => {
        debug: (context) => const PlaybackDebugScreen(),
      };
}