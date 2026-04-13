// Routes for audio_upload_track_management (Module 4).
// Spread into AppRouter.routes:
//   ...AudioUploadRoutes.getRoutes()

import 'package:flutter/material.dart';
import 'package:cross_team5/features/audio_upload_track_management/screens/upload_track_screen.dart';
import 'package:cross_team5/features/audio_upload_track_management/screens/track_management_screen.dart';
import 'package:cross_team5/features/audio_upload_track_management/screens/your_uploads_screen.dart';

class AudioUploadRoutes {
  static const String trackManagement = '/track_management';
  static const String uploadTrack = '/upload_track';
  static const String yourUploads = '/your_uploads';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      trackManagement: (_) => const TrackManagementScreen(),
      uploadTrack: (_) => const UploadTrackScreen(),
      yourUploads: (_) => const YourUploadsScreen(),
    };
  }
}
