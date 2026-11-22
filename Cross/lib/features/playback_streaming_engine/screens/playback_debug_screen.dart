import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:cross_team5/core/services/theme_service.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

import '../models/playback_state_model.dart';
import '../models/playback_track_model.dart';
import '../services/playback_streaming_engine_service.dart';
import '../services/playback_track_api_service.dart';
import '../widgets/playback_debug_track_tile.dart';
import '../widgets/playback_mini_player_bar.dart';
import '../widgets/playback_now_playing_card.dart';

const bool usePlayBackApiMode = false;
const String playbackApiTestTrackId = '69d81d4f7206c582e61862ab';

class PlaybackDebugScreen extends StatefulWidget {
  const PlaybackDebugScreen({super.key});
  @override
  State<PlaybackDebugScreen> createState() => _PlaybackDebugScreenState();
}

class _PlaybackDebugScreenState extends State<PlaybackDebugScreen> {
  late final PlaybackStreamingEngineService _playbackService;
  late final PlaybackTrackApiService _trackApiService;

  bool _isLoadingTracks = true;
  String? _loadTracksError;

  PlaybackTrackModel? _apiTrack;
  PlaybackTrackModel? _localPlayableTrack;
  PlaybackTrackModel? _localPreviewTrack;
  PlaybackTrackModel? _localBlockedTrack;

  static const PlaybackTrackModel _networkPlayableTrackOne = PlaybackTrackModel(
    id: 'network_playable_1',
    title: 'Sample stream A',
    artistName: 'Debug artist',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    duration: Duration(minutes: 6, seconds: 13),
  );

  static const PlaybackTrackModel _networkPlayableTrackTwo = PlaybackTrackModel(
    id: 'network_playable_2',
    title: 'Sample stream B',
    artistName: 'Debug artist',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    duration: Duration(minutes: 5, seconds: 31),
  );

  static const PlaybackTrackModel _networkPreviewTrack = PlaybackTrackModel(
    id: 'network_preview',
    title: 'Preview-locked sample',
    artistName: 'Preview demo',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    previewAudioUrl:
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    accessState: PlaybackAccessState.preview,
    previewDuration: Duration(seconds: 12),
    duration: Duration(minutes: 5),
  );

  static const PlaybackTrackModel _networkBlockedTrack = PlaybackTrackModel(
    id: 'network_blocked',
    title: 'Blocked premium sample',
    artistName: 'Restriction demo',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    accessState: PlaybackAccessState.blocked,
    blockedReason: 'Blocked for testing: premium-only track.',
    duration: Duration(minutes: 5),
  );

  static const PlaybackTrackModel _apiModePreviewDemoTrack = PlaybackTrackModel(
    id: 'api_mode_preview_demo',
    title: 'Preview demo track',
    artistName: 'Local preview demo',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
    previewAudioUrl:
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
    accessState: PlaybackAccessState.preview,
    previewDuration: Duration(seconds: 12),
    duration: Duration(minutes: 5),
  );

  static const PlaybackTrackModel _apiModeBlockedDemoTrack = PlaybackTrackModel(
    id: 'api_mode_blocked_demo',
    title: 'Blocked demo track',
    artistName: 'Local blocked demo',
    accessState: PlaybackAccessState.blocked,
    blockedReason: 'Blocked demo for API mode UI testing.',
  );

  @override
  void initState() {
    super.initState();
    _playbackService = PlaybackStreamingEngineService();
    _trackApiService = PlaybackTrackApiService();
    _loadTracks();
  }

  @override
  void dispose() {
    _playbackService.dispose();
    _trackApiService.dispose();
    super.dispose();
  }

  List<PlaybackTrackModel> get _testTracks {
    final List<PlaybackTrackModel> tracks = [];

    if (usePlayBackApiMode) {
      if (_apiTrack != null) {
        tracks.add(_apiTrack!);
      }
      tracks.add(_apiModePreviewDemoTrack);
      tracks.add(_apiModeBlockedDemoTrack);
    } else {
      tracks.addAll([
        _networkPlayableTrackOne,
        _networkPlayableTrackTwo,
        _networkPreviewTrack,
        _networkBlockedTrack,
      ]);
    }

    if (_localPlayableTrack != null) {
      tracks.insert(0, _localPlayableTrack!);
    }

    if (_localPreviewTrack != null) {
      tracks.insert(_localPlayableTrack != null ? 1 : 0, _localPreviewTrack!);
    }

    if (_localBlockedTrack != null) {
      final int insertIndex =
          (_localPlayableTrack != null ? 1 : 0) +
          (_localPreviewTrack != null ? 1 : 0);
      tracks.insert(insertIndex, _localBlockedTrack!);
    }

    return tracks;
  }

  Future<void> _loadTracks() async {
    setState(() {
      _isLoadingTracks = true;
      _loadTracksError = null;
      _apiTrack = null;
    });

    try {
      if (usePlayBackApiMode) {
        _apiTrack = await _trackApiService.getSingleTrackById(
          playbackApiTestTrackId,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingTracks = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadTracksError = error.toString();
        _isLoadingTracks = false;
      });
    }
  }

  Future<void> _pickLocalAudioFile() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
    );

    if (!mounted || result == null || result.files.single.path == null) {
      return;
    }

    final PlatformFile file = result.files.single;
    final String filePath = file.path!;
    final String name = file.name;

    setState(() {
      _localPlayableTrack = PlaybackTrackModel(
        id: 'local_playable',
        title: name,
        artistName: 'Local test file',
        localFilePath: filePath,
        sourceType: PlaybackSourceType.deviceFile,
        accessState: PlaybackAccessState.playable,
      );
      _localPreviewTrack = PlaybackTrackModel(
        id: 'local_preview',
        title: '$name (Preview)',
        artistName: 'Local test file',
        localFilePath: filePath,
        sourceType: PlaybackSourceType.deviceFile,
        accessState: PlaybackAccessState.preview,
        previewDuration: const Duration(seconds: 10),
      );
      _localBlockedTrack = PlaybackTrackModel(
        id: 'local_blocked',
        title: '$name (Blocked)',
        artistName: 'Local test file',
        localFilePath: filePath,
        sourceType: PlaybackSourceType.deviceFile,
        accessState: PlaybackAccessState.blocked,
        blockedReason: 'Blocked for testing: region restriction mock.',
      );
    });
  }

  Future<void> _togglePlayback() async {
    final PlaybackStateModel state = _playbackService.state;

    if (!state.hasTrack) {
      return;
    }

    if (state.isPlaying) {
      await _playbackService.pause();
      return;
    }

    if (state.status == PlaybackStatus.previewEnded ||
        state.status == PlaybackStatus.completed) {
      await _playbackService.restartFromBeginning();
      return;
    }

    await _playbackService.resume();
  }

  Future<void> _openNowPlayingSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.chineseBlack,
      isScrollControlled: true,
      builder: (context) {
        return AnimatedBuilder(
          animation: _playbackService,
          builder: (context, _) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewPadding.bottom + 16,
              ),
              child: PlaybackNowPlayingCard(
                state: _playbackService.state,
                onSeekChanged: (value) {
                  _playbackService.seek(Duration(milliseconds: value.round()));
                },
                onVolumeChanged: (value) {
                  _playbackService.setVolume(value);
                },
                onPlayPauseTap: _togglePlayback,
                onStopTap: _playbackService.stop,
                onRestartTap: _playbackService.restartFromBeginning,
                onMuteTap: _playbackService.toggleMute,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoadingTracks) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brilliantOrange),
      );
    }

    if (_loadTracksError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: AppColors.anger, size: 42),
              const SizedBox(height: 12),
              Text(
                'Failed to load playback tracks',
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _loadTracksError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.white60, height: 1.45),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTracks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brilliantOrange,
                  foregroundColor: AppColors.whiteSmoke,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _playbackService,
      builder: (context, _) {
        final PlaybackStateModel state = _playbackService.state;

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                children: [
                  const _ScreenHeader(),
                  const SizedBox(height: 18),
                  _ModeCard(onReloadTap: _loadTracks),
                  const SizedBox(height: 16),
                  const _InstructionsCard(),
                  const SizedBox(height: 16),
                  _LocalFileCard(onPickAudioTap: _pickLocalAudioFile),
                  const SizedBox(height: 16),
                  PlaybackNowPlayingCard(
                    state: state,
                    onSeekChanged: (value) {
                      _playbackService.seek(
                        Duration(milliseconds: value.round()),
                      );
                    },
                    onVolumeChanged: (value) {
                      _playbackService.setVolume(value);
                    },
                    onPlayPauseTap: _togglePlayback,
                    onStopTap: _playbackService.stop,
                    onRestartTap: _playbackService.restartFromBeginning,
                    onMuteTap: _playbackService.toggleMute,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    usePlayBackApiMode
                        ? 'Tap any track below to test the engine in API mode'
                        : 'Tap any track below to test the engine in mock mode',
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._testTracks.map(
                    (track) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PlaybackDebugTrackTile(
                        track: track,
                        onPlayTap: () {
                          _playbackService.playTrack(track);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PlaybackMiniPlayerBar(
              state: state,
              onPlayPauseTap: _togglePlayback,
              onTap: _openNowPlayingSheet,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeService>();
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: SafeArea(bottom: false, child: _buildBody()),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Playback Engine Test Screen',
          style: TextStyle(
            color: AppColors.whiteSmoke,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'This screen lets you test Person 1 playback features before Home and Library integration.',
          style: TextStyle(
            color: AppColors.white60,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final Future<void> Function() onReloadTap;

  const _ModeCard({required this.onReloadTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              usePlayBackApiMode
                  ? 'Current mode: API mode\nTrack ID: $playbackApiTestTrackId'
                  : 'Current mode: Mock mode\nToggle usePlayBackApiMode to switch.',
              style: TextStyle(
                color: AppColors.whiteSmoke,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onReloadTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brilliantOrange,
              foregroundColor: AppColors.whiteSmoke,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Reload'),
          ),
        ],
      ),
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  const _InstructionsCard();

  @override
  Widget build(BuildContext context) {
    final List<String> steps = usePlayBackApiMode
        ? const [
            '1. The first track comes from the backend API and maps enableAppPlayback into playable or blocked.',
            '2. The preview and blocked demo tracks remain available so you can still test preview-only behavior even though the current API does not expose preview metadata.',
            '3. Play a full track and test play, pause, resume, stop, seek, mute, and volume.',
            '4. Play a preview track and wait for it to auto-stop at the preview limit.',
            '5. Tap a blocked track and confirm no playback starts and a restriction message appears.',
          ]
        : const [
            '1. Play a full track and test play, pause, resume, stop, seek, mute, and volume.',
            '2. Switch from one track to another and confirm the old one stops cleanly.',
            '3. Play a preview track and wait for it to auto-stop at the preview limit.',
            '4. Tap a blocked track and confirm no playback starts and a restriction message appears.',
            '5. Open the mini player to confirm the now-playing state stays in sync.',
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manual test checklist',
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (int index = 0; index < steps.length; index++) ...[
            Text(
              steps[index],
              style: TextStyle(color: AppColors.white60, height: 1.5),
            ),
            if (index != steps.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _LocalFileCard extends StatelessWidget {
  final Future<void> Function() onPickAudioTap;

  const _LocalFileCard({required this.onPickAudioTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use your own audio file',
                  style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Pick one local file and the screen will generate playable, preview, and blocked test cases from it.',
                  style: TextStyle(
                    color: AppColors.white60,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          ElevatedButton(
            onPressed: onPickAudioTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brilliantOrange,
              foregroundColor: AppColors.whiteSmoke,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Pick file'),
          ),
        ],
      ),
    );
  }
}
