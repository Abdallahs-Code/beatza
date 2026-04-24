// Barrel: audio_upload_track_management
// Import this to access all Module 4 exports.
// Zero dependency on Module 5 or Module 6.

// Models
export 'models/track_model.dart'; // local upload model
export 'models/track.dart'; // API Track model

// Services
export 'services/audio_upload_service.dart'; // local file + ValueNotifier
export 'services/track_api_service.dart'; // all 13 API methods

// Widgets (teammate's — unchanged)
export 'widgets/metadata_form_widget.dart';
export 'widgets/pro_disabled_switch_widget.dart';
export 'widgets/pro_radio_tile_widget.dart';

// Screens
export 'screens/upload_track_screen.dart';
export 'screens/your_uploads_screen.dart';
export 'screens/track_management_screen.dart';
export 'screens/artist_studio_screen.dart';
export 'screens/your_insights_screen.dart';
export 'screens/artist_pro_screens.dart';

// Routes
export 'audio_upload_track_management_routes.dart';
