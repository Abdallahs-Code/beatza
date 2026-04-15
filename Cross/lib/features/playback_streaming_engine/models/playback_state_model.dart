import 'playback_track_model.dart';

enum PlaybackStatus {
  idle,
  loading,
  playing,
  paused,
  stopped,
  completed,
  blocked,
  previewEnded,
  error,
}

class PlaybackStateModel {
  final PlaybackTrackModel? currentTrack;
  final PlaybackStatus status;
  final Duration currentPosition;
  final Duration totalDuration;
  final double volume;
  final bool isMuted;
  final String? message;

  const PlaybackStateModel({
    this.currentTrack,
    this.status = PlaybackStatus.idle,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.volume = 1.0,
    this.isMuted = false,
    this.message,
  });

  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isLoading => status == PlaybackStatus.loading;
  bool get hasTrack => currentTrack != null;

  PlaybackStateModel copyWith({
    PlaybackTrackModel? currentTrack,
    bool clearTrack = false,
    PlaybackStatus? status,
    Duration? currentPosition,
    Duration? totalDuration,
    double? volume,
    bool? isMuted,
    String? message,
    bool clearMessage = false,
  }) {
    return PlaybackStateModel(
      currentTrack: clearTrack ? null : (currentTrack ?? this.currentTrack),
      status: status ?? this.status,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}