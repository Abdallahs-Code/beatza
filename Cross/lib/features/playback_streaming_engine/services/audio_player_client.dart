import 'package:audioplayers/audioplayers.dart';

import '../models/playback_track_model.dart';

abstract class AudioPlayerClient {
  Stream<PlayerState> get onPlayerStateChanged;
  Stream<Duration> get onDurationChanged;
  Stream<Duration> get onPositionChanged;
  Stream<void> get onPlayerComplete;

  Future<void> play(PlaybackTrackModel track);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> dispose();
}

class AudioplayersClient implements AudioPlayerClient {
  final AudioPlayer _audioPlayer;

  AudioplayersClient({AudioPlayer? audioPlayer})
    : _audioPlayer = audioPlayer ?? AudioPlayer() {
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  @override
  Stream<PlayerState> get onPlayerStateChanged =>
      _audioPlayer.onPlayerStateChanged;

  @override
  Stream<Duration> get onDurationChanged => _audioPlayer.onDurationChanged;

  @override
  Stream<Duration> get onPositionChanged => _audioPlayer.onPositionChanged;

  @override
  Stream<void> get onPlayerComplete => _audioPlayer.onPlayerComplete;

  @override
  Future<void> play(PlaybackTrackModel track) async {
    final Source source = switch (track.sourceType) {
      PlaybackSourceType.network => UrlSource(track.playbackUrl),
      PlaybackSourceType.deviceFile => DeviceFileSource(track.playbackUrl),
    };

    
    await _audioPlayer.setVolume(0.0);

    await _audioPlayer.stop();
    await _audioPlayer.setSource(source);

    
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await _audioPlayer.resume();
  }

  @override
  Future<void> pause() => _audioPlayer.pause();

  @override
  Future<void> resume() => _audioPlayer.resume();

  @override
  Future<void> stop() => _audioPlayer.stop();

  @override
  Future<void> seek(Duration position) => _audioPlayer.seek(position);

  @override
  Future<void> setVolume(double volume) => _audioPlayer.setVolume(volume);

  @override
  Future<void> dispose() => _audioPlayer.dispose();
}
