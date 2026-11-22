import '../../audio_upload_track_management/models/track.dart' as api_track;
import '../../audio_upload_track_management/models/track_model.dart';

enum SpotlightType { track, album, playlist }

class SpotlightItemModel {
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final SpotlightType type;
  final TrackModel? originalTrack;

  SpotlightItemModel({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.type,
    this.originalTrack,
  });

  factory SpotlightItemModel.fromTrack(TrackModel track, String artistName) {
    return SpotlightItemModel(
      id: track.id,
      title: track.title,
      subtitle: artistName,
      imageUrl: track.coverImagePath,
      type: SpotlightType.track,
      originalTrack: track,
    );
  }

  /// Posted track from GET `/api/public/tracks/v2/posted/{userId}` ([api_track.Track]).
  factory SpotlightItemModel.fromPostedTrack(
    api_track.Track track,
    String profileDisplayName,
  ) {
    final String artist = track.displayArtist.trim();
    return SpotlightItemModel(
      id: track.id,
      title: track.title,
      subtitle: artist.isNotEmpty ? artist : profileDisplayName,
      imageUrl: track.imageUrl,
      type: SpotlightType.track,
      originalTrack: null,
    );
  }
}
