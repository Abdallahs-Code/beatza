import 'package:flutter/material.dart';
import 'screens/upload_track_screen.dart';
import 'screens/track_management_screen.dart';
import 'screens/your_uploads_screen.dart';

class AudioUploadRoutes {
  static const String trackManagement = '/track_management';
  static const String uploadTrack = '/upload_track';
  static const String yourUploads = '/your_uploads';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      trackManagement: (context) => const TrackManagementScreen(),
      uploadTrack: (context) => const UploadTrackScreen(),
      yourUploads: (context) => const YourUploadsScreen(),
    };
  }
}