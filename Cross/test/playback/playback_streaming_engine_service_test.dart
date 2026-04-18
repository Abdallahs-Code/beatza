import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cross_team5/features/playback_streaming_engine/playback_streaming_engine.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAudioPlayerClient implements AudioPlayerClient {
  final StreamController<PlayerState> _playerStateController =
      StreamController<PlayerState>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<void> _completionController =
      StreamController<void>.broadcast();

  PlaybackTrackModel? playedTrack;
  Duration? lastSeekPosition;
  double? lastVolume;
  int playCallCount = 0;
  int stopCallCount = 0;
  int pauseCallCount = 0;
  int resumeCallCount = 0;
  bool disposed = false;

  @override
  Stream<PlayerState> get onPlayerStateChanged => _playerStateController.stream;

  @override
  Stream<Duration> get onDurationChanged => _durationController.stream;

  @override
  Stream<Duration> get onPositionChanged => _positionController.stream;

  @override
  Stream<void> get onPlayerComplete => _completionController.stream;

  @override
  Future<void> play(PlaybackTrackModel track) async {
    playCallCount++;
    playedTrack = track;
  }

  @override
  Future<void> pause() async {
    pauseCallCount++;
  }

  @override
  Future<void> resume() async {
    resumeCallCount++;
  }

  @override
  Future<void> stop() async {
    stopCallCount++;
  }

  @override
  Future<void> seek(Duration position) async {
    lastSeekPosition = position;
  }

  @override
  Future<void> setVolume(double volume) async {
    lastVolume = volume;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _playerStateController.close();
    await _durationController.close();
    await _positionController.close();
    await _completionController.close();
  }

  void emitPlayerState(PlayerState state) {
    _playerStateController.add(state);
  }

  void emitDuration(Duration duration) {
    _durationController.add(duration);
  }

  void emitPosition(Duration position) {
    _positionController.add(position);
  }

  void emitCompletion() {
    _completionController.add(null);
  }
}

void main() {
  group('PlaybackStreamingEngineService', () {
    late FakeAudioPlayerClient fakeAudioPlayerClient;
    late PlaybackStreamingEngineService service;

    const playableTrack = PlaybackTrackModel(
      id: '1',
      title: 'Playable Track',
      artistName: 'Artist A',
      audioUrl: 'https://example.com/playable.mp3',
    );

    const previewTrack = PlaybackTrackModel(
      id: '2',
      title: 'Preview Track',
      artistName: 'Artist B',
      audioUrl: 'https://example.com/full.mp3',
      previewAudioUrl: 'https://example.com/preview.mp3',
      accessState: PlaybackAccessState.preview,
      previewDuration: Duration(seconds: 30),
    );

    const blockedTrack = PlaybackTrackModel(
      id: '3',
      title: 'Blocked Track',
      artistName: 'Artist C',
      audioUrl: 'https://example.com/blocked.mp3',
      accessState: PlaybackAccessState.blocked,
      blockedReason: 'Premium only.',
    );

    setUp(() {
      fakeAudioPlayerClient = FakeAudioPlayerClient();
      service = PlaybackStreamingEngineService(
        audioPlayerClient: fakeAudioPlayerClient,
      );
    });

    tearDown(() async {
      service.dispose();
    });

    test(
      'plays a playable track and updates state from player streams',
      () async {
        await service.playTrack(playableTrack);

        expect(service.state.currentTrack?.id, '1');
        expect(service.state.status, PlaybackStatus.loading);
        expect(fakeAudioPlayerClient.playCallCount, 1);
        expect(
          fakeAudioPlayerClient.playedTrack?.playbackUrl,
          playableTrack.audioUrl,
        );

        fakeAudioPlayerClient.emitDuration(const Duration(minutes: 4));
        fakeAudioPlayerClient.emitPlayerState(PlayerState.playing);
        fakeAudioPlayerClient.emitPosition(const Duration(seconds: 12));

        await Future<void>.delayed(Duration.zero);

        expect(service.state.status, PlaybackStatus.playing);
        expect(service.state.totalDuration, const Duration(minutes: 4));
        expect(service.state.currentPosition, const Duration(seconds: 12));
      },
    );

    test(
      'does not play blocked tracks and exposes the blocked reason',
      () async {
        await service.playTrack(blockedTrack);

        expect(fakeAudioPlayerClient.playCallCount, 0);
        expect(service.state.status, PlaybackStatus.blocked);
        expect(service.state.message, 'Premium only.');
        expect(service.state.currentTrack?.id, '3');
      },
    );

    test('stops previous playback before switching tracks', () async {
      await service.playTrack(playableTrack);
      await service.playTrack(previewTrack);

      expect(fakeAudioPlayerClient.stopCallCount, 1);
      expect(fakeAudioPlayerClient.playCallCount, 2);
      expect(service.state.currentTrack?.id, '2');
    });

    test('preview playback stops at the preview limit', () async {
      await service.playTrack(previewTrack);
      fakeAudioPlayerClient.emitPlayerState(PlayerState.playing);
      fakeAudioPlayerClient.emitPosition(const Duration(seconds: 30));

      await Future<void>.delayed(Duration.zero);

      expect(fakeAudioPlayerClient.pauseCallCount, 1);
      expect(fakeAudioPlayerClient.lastSeekPosition, Duration.zero);
      expect(service.state.status, PlaybackStatus.previewEnded);
      expect(service.state.message, isNotNull);
    });

    test('seek clamps preview tracks to the preview duration', () async {
      await service.playTrack(previewTrack);
      await service.seek(const Duration(seconds: 45));

      expect(
        fakeAudioPlayerClient.lastSeekPosition,
        const Duration(seconds: 30),
      );
      expect(service.state.currentPosition, const Duration(seconds: 30));
    });

    test('pause, resume, volume and mute update the engine state', () async {
      await service.playTrack(playableTrack);
      fakeAudioPlayerClient.emitPlayerState(PlayerState.playing);
      await Future<void>.delayed(Duration.zero);

      await service.pause();
      expect(fakeAudioPlayerClient.pauseCallCount, 1);
      expect(service.state.status, PlaybackStatus.paused);

      await service.resume();
      expect(fakeAudioPlayerClient.resumeCallCount, 1);
      expect(service.state.status, PlaybackStatus.playing);

      await service.setVolume(0.4);
      expect(service.state.volume, 0.4);
      expect(fakeAudioPlayerClient.lastVolume, 0.4);

      await service.toggleMute();
      expect(service.state.isMuted, isTrue);
      expect(fakeAudioPlayerClient.lastVolume, 0.0);
    });
  });
}
