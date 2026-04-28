import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/premium_subscription/services/offline_download_service.dart';
import 'package:cross_team5/features/premium_subscription/services/payment_service.dart';

import 'ad_service.dart';

import '../models/playback_state_model.dart';
import '../models/playback_track_model.dart';
import 'audio_player_client.dart';
import 'public_tracks_paging_service.dart';

enum TrackRepeatMode { none, all, one }

class PlaybackStreamingEngineService extends ChangeNotifier {
  static final PlaybackStreamingEngineService shared =
  PlaybackStreamingEngineService._shared();

  final AudioPlayerClient _audioPlayerClient;
  final FlutterSecureStorage _storage;
  final http.Client _httpClient;

  PlaybackStateModel _state = const PlaybackStateModel();
  List<PlaybackTrackModel> _activeQueue = const <PlaybackTrackModel>[];
  int _currentQueueIndex = -1;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<void>? _completionSubscription;

  bool _previewLimitReached = false;
  String? _lastHistoryReportedTrackId;
  int _outputLevelRequestId = 0;
  Future<bool> Function()? _ensureNextTrackAvailable;

  // ── Rapid-skip race-condition guard ──────────────────────────────────────
  // Each playTrack() call captures the seq at entry. Any awaits that complete
  // after a newer call has started (seq mismatch) are abandoned.
  int _playSeq = 0;
  // While true, audio-player state-change and completion events are suppressed.
  // Cleared once the winning playTrack() confirms playback has started.
  bool _ignorePlayerStateUpdates = false;

  bool _isShuffled = false;
  List<PlaybackTrackModel> _originalQueue = const <PlaybackTrackModel>[];
  TrackRepeatMode _repeatMode = TrackRepeatMode.none;

  PlaybackStreamingEngineService._shared()
      : _audioPlayerClient = AudioplayersClient(),
        _storage = const FlutterSecureStorage(),
        _httpClient = http.Client() {
    _bindPlayerStreams();
  }

  PlaybackStreamingEngineService({
    AudioPlayerClient? audioPlayerClient,
    FlutterSecureStorage? storage,
    http.Client? httpClient,
  })  : _audioPlayerClient = audioPlayerClient ?? AudioplayersClient(),
        _storage = storage ?? const FlutterSecureStorage(),
        _httpClient = httpClient ?? http.Client() {
    _bindPlayerStreams();
  }

  PlaybackStateModel get state => _state;
  List<PlaybackTrackModel> get activeQueue =>
      List<PlaybackTrackModel>.unmodifiable(_activeQueue);
  int get currentQueueIndex => _currentQueueIndex;
  bool get hasPreviousInQueue =>
      _currentQueueIndex > 0 && _activeQueue.isNotEmpty;
  bool get hasNextInQueue =>
      _currentQueueIndex >= 0 && _currentQueueIndex < _activeQueue.length - 1;
  bool get isShuffled => _isShuffled;
  TrackRepeatMode get repeatMode => _repeatMode;

  Future<void> playTrack(
      PlaybackTrackModel track, {
        List<PlaybackTrackModel>? queue,
        int? startIndex,
        Future<bool> Function()? ensureNextTrackAvailable,
        bool countForAd = true,
      }) async {
    // Never interrupt an ad. When the ad finishes its onAdFinished callback
    // calls playTrack with countForAd:false, bypassing this guard because
    // isAdPlaying is already false at that point.
    if (AdService.shared.isAdPlaying) return;

    // Count every track play toward the ad threshold (non-Pro only).
    // Using countForAd:false for the post-ad resume call avoids double-counting.
    if (countForAd && !PaymentService.subscriptionSuccessNotifier.isPro) {
      final bool adScheduled = AdService.shared.checkAndScheduleAd(
        onAdFinished: () => unawaited(playTrack(
          track,
          queue: queue,
          startIndex: startIndex,
          ensureNextTrackAvailable: ensureNextTrackAvailable,
          countForAd: false,
        )),
      );
      if (adScheduled) {
        _outputLevelRequestId++;
        _playSeq++;
        await _audioPlayerClient.stop();
        _updateState(
          _state.copyWith(
            status: PlaybackStatus.paused,
            currentPosition: Duration.zero,
            clearMessage: true,
          ),
        );
        return;
      }
    }

    // Stamp this invocation. Any older in-flight call will detect the mismatch
    // after its next await and return without touching state.
    final int seq = ++_playSeq;
    _ignorePlayerStateUpdates = true;

    if (queue != null) {
      _setQueueContext(
        queue,
        preferredTrackId: track.id,
        preferredIndex: startIndex,
      );
    } else if (_activeQueue.isEmpty) {
      _setQueueContext(
        <PlaybackTrackModel>[track],
        preferredTrackId: track.id,
        preferredIndex: 0,
      );
    } else {
      final int existingIndex = _activeQueue.indexWhere(
            (item) => item.id == track.id,
      );
      if (existingIndex >= 0) {
        _currentQueueIndex = existingIndex;
      }
    }

    if (ensureNextTrackAvailable != null) {
      _ensureNextTrackAvailable = ensureNextTrackAvailable;
    } else if (queue != null) {
      _ensureNextTrackAvailable = null;
    }

    if (track.accessState == PlaybackAccessState.blocked) {
      _ignorePlayerStateUpdates = false;
      _previewLimitReached = false;
      _updateState(
        _state.copyWith(
          currentTrack: track,
          status: PlaybackStatus.blocked,
          message: track.blockedReason ?? 'This track is currently unavailable.',
          currentPosition: Duration.zero,
          totalDuration: track.duration ?? Duration.zero,
        ),
      );
      return;
    }

    final String trimmedUrl = track.playbackUrl.trim();
    if (trimmedUrl.isEmpty) {
      _ignorePlayerStateUpdates = false;
      _updateState(
        _state.copyWith(
          currentTrack: track,
          status: PlaybackStatus.error,
          message: 'Track source is missing.',
          currentPosition: Duration.zero,
          totalDuration: track.duration ?? Duration.zero,
        ),
      );
      return;
    }

    try {
      _previewLimitReached = false;
      _lastHistoryReportedTrackId = null;

      if (_state.hasTrack) {
        await _audioPlayerClient.stop();
      }
      // A newer skip arrived while we were stopping — hand off to it.
      if (seq != _playSeq) return;

      _updateState(
        _state.copyWith(
          currentTrack: track,
          status: PlaybackStatus.loading,
          currentPosition: Duration.zero,
          totalDuration: track.duration ?? Duration.zero,
          clearMessage: true,
        ),
      );

      await _applyCurrentOutputLevel();
      if (seq != _playSeq) return;

      PlaybackTrackModel trackToPlay = track;
      try {
        final localPath = await OfflineDownloadService.shared.getLocalTrackPath(track.id);
        if (seq != _playSeq) return;
        if (localPath != null && await File(localPath).exists()) {
          if (seq != _playSeq) return;
          trackToPlay = track.copyWith(
            localFilePath: localPath,
            sourceType: PlaybackSourceType.deviceFile,
          );
        }
      } catch (e) {
        debugPrint('Error checking local file for track ${track.id}: $e');
      }
      if (seq != _playSeq) return;

      await _audioPlayerClient.play(trackToPlay);
      if (seq != _playSeq) return;

      // This call won the race — confirm playback and restore event processing.
      _ignorePlayerStateUpdates = false;
      _updateState(_state.copyWith(status: PlaybackStatus.playing, clearMessage: true));
      _reportTrackPlayedIfNeeded();
      await _enforceCurrentOutputLevelForTrack(track.id);
    } catch (error) {
      if (seq == _playSeq) {
        _ignorePlayerStateUpdates = false;
        _updateState(
          _state.copyWith(
            currentTrack: track,
            status: PlaybackStatus.error,
            message: 'Failed to start playback: $error',
          ),
        );
      }
    }
  }

  Future<void> pause() async {
    if (!_state.hasTrack || _state.status != PlaybackStatus.playing) {
      return;
    }

    await _audioPlayerClient.pause();
    _updateState(_state.copyWith(status: PlaybackStatus.paused));
  }

  Future<void> resume() async {
    if (!_state.hasTrack) {
      return;
    }

    if (_state.currentTrack?.accessState == PlaybackAccessState.blocked) {
      return;
    }

    if (_state.status == PlaybackStatus.loading ||
        _state.status == PlaybackStatus.error) {
      return;
    }

    if (_previewLimitReached &&
        _state.currentTrack?.accessState == PlaybackAccessState.preview) {
      _updateState(
        _state.copyWith(
          status: PlaybackStatus.previewEnded,
          message: 'Preview finished. Unlock the full track to keep listening.',
        ),
      );
      return;
    }

    await _audioPlayerClient.resume();
    _updateState(
      _state.copyWith(status: PlaybackStatus.playing, clearMessage: true),
    );
  }

  Future<void> togglePlayPause() async {
    if (!_state.hasTrack) {
      return;
    }

    if (_state.isPlaying) {
      await pause();
      return;
    }

    if (_state.status == PlaybackStatus.previewEnded ||
        _state.status == PlaybackStatus.completed) {
      await restartFromBeginning();
      return;
    }

    await resume();
  }

  Future<bool> playNextTrack() async {
    if (!hasNextInQueue) {
      final bool loadedMore = await _tryExpandQueueForNextTrack();
      if (!loadedMore && !hasNextInQueue) {
        return false;
      }
    }

    if (!hasNextInQueue) {
      return false;
    }

    final int nextIndex = _currentQueueIndex + 1;
    await playTrack(
      _activeQueue[nextIndex],
      queue: _activeQueue,
      startIndex: nextIndex,
      ensureNextTrackAvailable: _ensureNextTrackAvailable,
    );
    return true;
  }

  Future<void> playPreviousTrack() async {
    if (!hasPreviousInQueue) {
      return;
    }

    final int previousIndex = _currentQueueIndex - 1;
    await playTrack(
      _activeQueue[previousIndex],
      queue: _activeQueue,
      startIndex: previousIndex,
      ensureNextTrackAvailable: _ensureNextTrackAvailable,
    );
  }

  Future<void> stop() async {
    _outputLevelRequestId++;
    _playSeq++;                        // cancel any in-progress playTrack
    _ignorePlayerStateUpdates = false; // restore so the stopped event is processed
    await _audioPlayerClient.stop();
    _previewLimitReached = false;
    _updateState(
      _state.copyWith(
        status: PlaybackStatus.stopped,
        currentPosition: Duration.zero,
        clearMessage: true,
      ),
    );
  }

  Future<void> seek(Duration position) async {
    final PlaybackTrackModel? currentTrack = _state.currentTrack;
    if (currentTrack == null) {
      return;
    }

    Duration targetPosition = position;
    if (currentTrack.accessState == PlaybackAccessState.preview) {
      final Duration previewLimit = currentTrack.effectivePreviewDuration;
      if (targetPosition > previewLimit) {
        targetPosition = previewLimit;
      }
    }

    await _audioPlayerClient.seek(targetPosition);
    _previewLimitReached = false;

    _updateState(
      _state.copyWith(currentPosition: targetPosition, clearMessage: true),
    );
  }

  Future<void> restartFromBeginning() async {
    await seek(Duration.zero);

    if (_state.hasTrack &&
        _state.status != PlaybackStatus.playing &&
        _state.currentTrack?.accessState != PlaybackAccessState.blocked) {
      await resume();
    }
  }

  Future<void> setVolume(double volume) async {
    final double safeVolume = volume.clamp(0.0, 1.0).toDouble();
    _updateState(_state.copyWith(volume: safeVolume));
    await _applyCurrentOutputLevel();
  }

  Future<void> toggleMute() async {
    final bool nextMutedState = !_state.isMuted;
    _updateState(_state.copyWith(isMuted: nextMutedState));
    await _applyCurrentOutputLevel();
  }

  Future<void> clearSessionState() async {
    _outputLevelRequestId++;
    _playSeq++;
    _ignorePlayerStateUpdates = false;
    _previewLimitReached = false;
    _lastHistoryReportedTrackId = null;
    _ensureNextTrackAvailable = null;
    _activeQueue = const <PlaybackTrackModel>[];
    _currentQueueIndex = -1;
    _isShuffled = false;
    _originalQueue = const <PlaybackTrackModel>[];
    _repeatMode = TrackRepeatMode.none;

    try {
      await _audioPlayerClient.stop();
    } catch (_) {}

    _updateState(const PlaybackStateModel());
  }

  void _setQueueContext(
      List<PlaybackTrackModel> queue, {
        String? preferredTrackId,
        int? preferredIndex,
      }) {
    _activeQueue = List<PlaybackTrackModel>.from(queue);

    if (_activeQueue.isEmpty) {
      _currentQueueIndex = -1;
      return;
    }

    int nextIndex = preferredIndex ?? -1;
    if (nextIndex < 0 || nextIndex >= _activeQueue.length) {
      nextIndex = preferredTrackId == null
          ? 0
          : _activeQueue.indexWhere((item) => item.id == preferredTrackId);
    }

    _currentQueueIndex = nextIndex >= 0 ? nextIndex : 0;
  }

  Future<bool> _tryExpandQueueForNextTrack() async {
    bool loadedMore = false;

    if (_ensureNextTrackAvailable != null) {
      loadedMore = await _ensureNextTrackAvailable!.call();
    }

    if (!loadedMore) {
      loadedMore = await PublicTracksPagingService.shared
          .ensureNextTrackAvailableForPlayer();
    }

    if (loadedMore) {
      _syncQueueFromPublicTracksPagingIfPossible();
    }

    return loadedMore;
  }

  void _syncQueueFromPublicTracksPagingIfPossible() {
    final PlaybackTrackModel? currentTrack = _state.currentTrack;
    if (currentTrack == null) {
      return;
    }

    final List<PlaybackTrackModel> pagedTracks =
        PublicTracksPagingService.shared.tracks;

    if (pagedTracks.isEmpty) {
      return;
    }

    final int currentIndexInPagedTracks = pagedTracks.indexWhere(
          (item) => item.id == currentTrack.id,
    );

    if (currentIndexInPagedTracks < 0) {
      return;
    }

    _activeQueue = List<PlaybackTrackModel>.from(pagedTracks);
    _currentQueueIndex = currentIndexInPagedTracks;
  }

  void _bindPlayerStreams() {
    _playerStateSubscription = _audioPlayerClient.onPlayerStateChanged.listen(
      _handlePlayerStateChanged,
    );
    _durationSubscription = _audioPlayerClient.onDurationChanged.listen(
      _handleDurationChanged,
    );
    _positionSubscription = _audioPlayerClient.onPositionChanged.listen(
      _handlePositionChanged,
    );
    _completionSubscription = _audioPlayerClient.onPlayerComplete.listen((_) {
      if (_ignorePlayerStateUpdates) return;
      unawaited(_handlePlaybackCompleted());
    });
  }

  void _handlePlayerStateChanged(PlayerState playerState) {
    // During a track transition suppress all audio-player events — playTrack()
    // owns state until it either confirms playback or hands off to a newer call.
    if (_ignorePlayerStateUpdates) return;

    final PlaybackStatus nextStatus = switch (playerState) {
      PlayerState.playing => PlaybackStatus.playing,
      PlayerState.paused =>
      _previewLimitReached
          ? PlaybackStatus.previewEnded
          : PlaybackStatus.paused,
      PlayerState.stopped =>
      _previewLimitReached
          ? PlaybackStatus.previewEnded
          : PlaybackStatus.stopped,
      PlayerState.completed => PlaybackStatus.completed,
      PlayerState.disposed => PlaybackStatus.stopped,
    };

    _updateState(_state.copyWith(status: nextStatus));

    if (playerState == PlayerState.playing) {
      final PlaybackTrackModel? currentTrack = _state.currentTrack;
      if (currentTrack != null) {
        unawaited(_enforceCurrentOutputLevelForTrack(currentTrack.id));
      }
      _reportTrackPlayedIfNeeded();
    }
  }

  void _handleDurationChanged(Duration duration) {
    _updateState(_state.copyWith(totalDuration: duration));
  }

  void _handlePositionChanged(Duration position) {
    final PlaybackTrackModel? currentTrack = _state.currentTrack;
    if (currentTrack == null) {
      return;
    }

    if (currentTrack.accessState == PlaybackAccessState.preview) {
      final Duration previewLimit = currentTrack.effectivePreviewDuration;
      if (position >= previewLimit) {
        _handlePreviewCompleted(previewLimit);
        return;
      }
    }

    _updateState(
      _state.copyWith(currentPosition: position, clearMessage: true),
    );
  }

  Future<void> _handlePlaybackCompleted() async {
    // If an ad is already on screen ignore this event — the ad's onAdFinished
    // callback handles advancing to the next track.
    if (AdService.shared.isAdPlaying) return;

    _outputLevelRequestId++;
    _previewLimitReached = false;

    if (_repeatMode == TrackRepeatMode.one) {
      final PlaybackTrackModel? track = _state.currentTrack;
      if (track != null) {
        await playTrack(
          track,
          queue: List<PlaybackTrackModel>.from(_activeQueue),
          startIndex: _currentQueueIndex,
          ensureNextTrackAvailable: _ensureNextTrackAvailable,
          countForAd: false, // repeating the same track — don't count twice
        );
      }
      return;
    }

    final bool advancedToNextTrack = await playNextTrack();
    if (advancedToNextTrack) {
      return;
    }

    if (_repeatMode == TrackRepeatMode.all && _activeQueue.isNotEmpty) {
      await playTrack(
        _activeQueue[0],
        queue: List<PlaybackTrackModel>.from(_activeQueue),
        startIndex: 0,
        ensureNextTrackAvailable: _ensureNextTrackAvailable,
      );
      return;
    }

    _updateState(
      _state.copyWith(
        status: PlaybackStatus.completed,
        currentPosition: Duration.zero,
        clearMessage: true,
      ),
    );
  }

  Future<void> _handlePreviewCompleted(Duration previewLimit) async {
    if (_previewLimitReached) {
      return;
    }

    _previewLimitReached = true;
    await _audioPlayerClient.pause();
    await _audioPlayerClient.seek(Duration.zero);

    _updateState(
      _state.copyWith(
        status: PlaybackStatus.previewEnded,
        currentPosition: previewLimit,
        message: 'Preview finished. Unlock the full track to keep listening.',
      ),
    );
  }

  void _reportTrackPlayedIfNeeded() {
    final PlaybackTrackModel? currentTrack = _state.currentTrack;
    if (currentTrack == null) {
      return;
    }

    if (currentTrack.id.trim().isEmpty) {
      return;
    }

    if (_lastHistoryReportedTrackId == currentTrack.id) {
      return;
    }

    _lastHistoryReportedTrackId = currentTrack.id;
    _sendPlayedHistoryRequest(currentTrack.id);
    _sendListenCountRequest(currentTrack.id);
  }

  Future<void> _sendPlayedHistoryRequest(String trackId) async {
    try {
      final String? accessToken = await _storage.read(key: 'access_token');

      if (accessToken == null || accessToken.trim().isEmpty) {
        _lastHistoryReportedTrackId = null;
        return;
      }

      final String url =
          '${ApiServices().baseUrl}/api/tracks/v1/played/$trackId';

      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'User-Agent': 'Android',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _lastHistoryReportedTrackId = null;
      }
    } catch (error) {
      _lastHistoryReportedTrackId = null;
    }
  }

  Future<void> _sendListenCountRequest(String trackId) async {
    try {
      final String? accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null || accessToken.trim().isEmpty) return;
      final String url =
          '${ApiServices().baseUrl}/api/tracks/v1/listen/$trackId';
      await _httpClient.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'User-Agent': 'Android',
        },
      );
    } catch (_) {}
  }

  void toggleShuffle() {
    if (_activeQueue.isEmpty) return;

    final PlaybackTrackModel? currentTrack =
        _currentQueueIndex >= 0 && _currentQueueIndex < _activeQueue.length
            ? _activeQueue[_currentQueueIndex]
            : null;

    if (!_isShuffled) {
      _originalQueue = List<PlaybackTrackModel>.from(_activeQueue);
      final List<PlaybackTrackModel> remaining =
          List<PlaybackTrackModel>.from(_activeQueue);
      if (currentTrack != null) remaining.removeAt(_currentQueueIndex);
      remaining.shuffle(Random());
      _activeQueue = [
        ?currentTrack,
        ...remaining,
      ];
      _currentQueueIndex = 0;
      _isShuffled = true;
    } else {
      if (_originalQueue.isNotEmpty) {
        final int originalIndex = currentTrack != null
            ? _originalQueue.indexWhere((t) => t.id == currentTrack.id)
            : -1;
        _activeQueue = List<PlaybackTrackModel>.from(_originalQueue);
        _currentQueueIndex = originalIndex >= 0 ? originalIndex : 0;
      }
      _originalQueue = const <PlaybackTrackModel>[];
      _isShuffled = false;
    }

    notifyListeners();
  }

  void cycleTrackRepeatMode() {
    _repeatMode = switch (_repeatMode) {
      TrackRepeatMode.none => TrackRepeatMode.all,
      TrackRepeatMode.all => TrackRepeatMode.one,
      TrackRepeatMode.one => TrackRepeatMode.none,
    };
    notifyListeners();
  }

  void removeFromQueue(int absoluteIndex) {
    if (absoluteIndex < 0 || absoluteIndex >= _activeQueue.length) return;
    if (absoluteIndex == _currentQueueIndex) return;

    final List<PlaybackTrackModel> queue =
        List<PlaybackTrackModel>.from(_activeQueue);
    queue.removeAt(absoluteIndex);
    _activeQueue = queue;

    if (absoluteIndex < _currentQueueIndex) {
      _currentQueueIndex--;
    }

    notifyListeners();
  }

  void reorderQueue(int relativeOldIndex, int relativeNewIndex) {
    if (_currentQueueIndex < 0) return;

    final int afterOffset = _currentQueueIndex + 1;
    final int absOld = afterOffset + relativeOldIndex;
    final int absNew = afterOffset + relativeNewIndex;

    if (absOld < 0 || absOld >= _activeQueue.length) return;
    if (absNew < 0 || absNew >= _activeQueue.length) return;
    if (absOld == absNew) return;

    final List<PlaybackTrackModel> queue =
        List<PlaybackTrackModel>.from(_activeQueue);
    final PlaybackTrackModel item = queue.removeAt(absOld);
    queue.insert(absNew, item);
    _activeQueue = queue;

    notifyListeners();
  }

  void addToQueueNext(PlaybackTrackModel track) {
    if (_activeQueue.isEmpty || _currentQueueIndex < 0) {
      _activeQueue = [track];
      _currentQueueIndex = 0;
    } else {
      final List<PlaybackTrackModel> queue =
          List<PlaybackTrackModel>.from(_activeQueue);
      queue.insert(_currentQueueIndex + 1, track);
      _activeQueue = queue;
    }
    notifyListeners();
  }

  void addToQueueLast(PlaybackTrackModel track) {
    final List<PlaybackTrackModel> queue =
        List<PlaybackTrackModel>.from(_activeQueue);
    queue.add(track);
    _activeQueue = queue;
    notifyListeners();
  }

  void updateQueueKeepingCurrentTrack(List<PlaybackTrackModel> newQueue) {
    final PlaybackTrackModel? currentTrack = _state.currentTrack;
    if (currentTrack == null || newQueue.isEmpty) return;

    _activeQueue = List<PlaybackTrackModel>.from(newQueue);
    final int idx = _activeQueue.indexWhere((t) => t.id == currentTrack.id);
    _currentQueueIndex = idx >= 0 ? idx : 0;

    notifyListeners();
  }

  Future<void> _applyCurrentOutputLevel() async {
    await _audioPlayerClient.setVolume(_state.isMuted ? 0.0 : _state.volume);
  }

  Future<void> _enforceCurrentOutputLevelForTrack(String trackId) async {
    final int requestId = ++_outputLevelRequestId;

    Future<void> applyIfStillCurrent() async {
      if (_outputLevelRequestId != requestId) return;
      if (_state.currentTrack?.id != trackId) return;
      await _applyCurrentOutputLevel();
    }

    await applyIfStillCurrent();

    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 20), () async {
        await applyIfStillCurrent();
      }),
    );

    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 80), () async {
        await applyIfStillCurrent();
      }),
    );

    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 180), () async {
        await applyIfStillCurrent();
      }),
    );

    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 320), () async {
        await applyIfStillCurrent();
      }),
    );
  }

  void _updateState(PlaybackStateModel nextState) {
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _completionSubscription?.cancel();
    _httpClient.close();
    _audioPlayerClient.dispose();
    super.dispose();
  }
}