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
}