import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:cross_team5/core/theme/app_colors.dart';

import '../models/playback_state_model.dart';
import '../models/playback_track_model.dart';
import '../services/playback_streaming_engine_service.dart';
import '../services/waveform_extractor.dart';
import 'package:cross_team5/core/navigation/app_navigator.dart';
import 'package:cross_team5/core/navigation/app_overlay_visibility.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/engagement_social_interactions/models/comment.dart';
import 'package:cross_team5/features/engagement_social_interactions/models/engagement_user.dart';
import 'package:cross_team5/features/engagement_social_interactions/models/repost_status.dart';
import 'package:cross_team5/features/engagement_social_interactions/services/engagement_api_service.dart';
import 'package:cross_team5/features/engagement_social_interactions/widgets/repost_bottom_sheet.dart';
import 'package:cross_team5/features/engagement_social_interactions/engagement_social_interactions_routes.dart';
import 'package:cross_team5/features/engagement_social_interactions/screens/likers_screen.dart';
import 'package:cross_team5/features/engagement_social_interactions/screens/comments_screen.dart';
import 'package:cross_team5/features/user_profile_social_identity/user_profile_social_identity.dart';
import 'package:cross_team5/features/followers_social_graph/services/social_api_service.dart';

// Tracks whether the expanded player is currently open so the mini player hides
final ValueNotifier<bool> _isExpandedPlayerVisible = ValueNotifier<bool>(false);
final ValueNotifier<bool> _isTransientSheetOpening = ValueNotifier<bool>(false);

// Notifies the engagement bar that a comment was posted from the inline bar.
// Set to the trackId of the commented track, reset to null after consumption.
final ValueNotifier<String?> _trackCommentPosted = ValueNotifier<String?>(null);

final Map<String, List<double>> _expandedWaveformCache =
    <String, List<double>>{};

class GlobalPlaybackOverlay extends StatelessWidget {
  const GlobalPlaybackOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final PlaybackStreamingEngineService globalPlayer =
        PlaybackStreamingEngineService.shared;

    return IgnorePointer(
      ignoring: false,
      child: ValueListenableBuilder<bool>(
        valueListenable: _isExpandedPlayerVisible,
        builder: (context, isExpanded, _) {
          return ValueListenableBuilder<AppOverlayVisibilityState>(
            valueListenable: globalOverlayVisibility,
            builder: (context, overlayVisibility, _) {
              return AnimatedBuilder(
                animation: globalPlayer,
                builder: (context, _) {
                  final PlaybackStateModel state = globalPlayer.state;
                  final bool shouldHideMiniPlayer =
                      !state.hasTrack ||
                      isExpanded ||
                      overlayVisibility.isPopupRouteVisible ||
                      !overlayVisibility.shouldShowMiniPlayerOnCurrentRoute ||
                      _isTransientSheetOpening.value;

                  if (shouldHideMiniPlayer) {
                    return const SizedBox.shrink();
                  }

                  return SafeArea(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
                        child: _MiniPlayerCard(
                          state: state,
                          onTap: () => _openExpandedPlayer(context),
                          onPlayPauseTap: globalPlayer.togglePlayPause,
                          onDeviceTap: () => _showDeviceSheet(context),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> _openExpandedPlayer(BuildContext context) async {
  final BuildContext? navigatorContext = appNavigatorKey.currentContext;
  if (navigatorContext == null) return;

  _isExpandedPlayerVisible.value = true;
  try {
    await showModalBottomSheet<void>(
      context: navigatorContext,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.black,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      builder: (context) => const _ExpandedPlayerSheet(),
    );
  } finally {
    _isExpandedPlayerVisible.value = false;
  }
}

// ─────────────────────────────────────────────────────────
//  MINI PLAYER — matches SoundCloud's compact pill bar
// ─────────────────────────────────────────────────────────
class _MiniPlayerCard extends StatelessWidget {
  final PlaybackStateModel state;
  final VoidCallback onTap;
  final VoidCallback onPlayPauseTap;
  final VoidCallback onDeviceTap;

  const _MiniPlayerCard({
    required this.state,
    required this.onTap,
    required this.onPlayPauseTap,
    required this.onDeviceTap,
  });

  @override
  Widget build(BuildContext context) {
    final PlaybackTrackModel track = state.currentTrack!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onPlayPauseTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      state.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        track.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onDeviceTap,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.devices,
                    color: AppColors.brilliantOrange,
                    size: 26,
                  ),
                ),
                _MiniLikeButton(trackId: track.id),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  EXPANDED PLAYER — matches SoundCloud's now-playing screen
// ─────────────────────────────────────────────────────────
class _ExpandedPlayerSheet extends StatelessWidget {
  const _ExpandedPlayerSheet();

  @override
  Widget build(BuildContext context) {
    return _CurrentTrackListener(
      builder: (context, track) {
        if (track == null) {
          return const SizedBox.shrink();
        }

        return Material(
          color: Colors.black,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white38,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: _ExpandedArtworkLayer(track: track),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.12),
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.10),
                              ],
                              stops: const [0.0, 0.16, 0.76, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        left: 16,
                        right: 16,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 10),
                                  Text(
                                    track.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () async {
                                      final artistId = track.artistId;
                                      final navCtx =
                                          appNavigatorKey.currentContext;
                                      if (navCtx == null) return;
                                      if (artistId == null ||
                                          artistId.isEmpty) {
                                        ScaffoldMessenger.of(
                                          navCtx,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Artist profile not available',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      final token =
                                          await AuthApiService()
                                              .getStoredAccessToken() ??
                                          '';
                                      final currentUserId =
                                          await AuthApiService()
                                              .getStoredUserId() ??
                                          '';
                                      if (!navCtx.mounted) return;
                                      Navigator.pushNamed(
                                        navCtx,
                                        UserProfileSocialIdentityRoutes
                                            .userProfileRoute,
                                        arguments: {
                                          'userId': artistId,
                                          'token': token,
                                          'currentUserId': currentUserId,
                                        },
                                      );
                                    },
                                    child: Text(
                                      track.artistName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.graphic_eq,
                                          color: Colors.white70,
                                          size: 14,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Behind this track',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _TopCircleButton(
                                  icon: Icons.keyboard_arrow_down_rounded,
                                  onTap: () => Navigator.of(context).pop(),
                                ),
                                const SizedBox(height: 18),
                                _ExpandedFollowButton(track: track),
                                const SizedBox(height: 18),
                                GestureDetector(
                                  onTap: () => _showDeviceSheet(context),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.42,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.devices,
                                      color: AppColors.brilliantOrange,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 212,
                        child: _ExpandedPlaybackButtons(),
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        top: MediaQuery.of(context).size.height * 0.43,
                        child: _ExpandedProgressSection(track: track),
                      ),
                      Builder(
                        builder: (bCtx) {
                          final double keyboardOffset = MediaQuery.of(
                            bCtx,
                          ).viewInsets.bottom;
                          return Positioned(
                            left: 16,
                            right: 16,
                            bottom: 90 + keyboardOffset,
                            child: _InlineCommentBar(track: track),
                          );
                        },
                      ),
                      const Positioned(
                        left: 16,
                        right: 16,
                        bottom: 48,
                        child: _ExpandedVolumeSlider(),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
                  child: _ExpandedEngagementBar(
                    track: track,
                    onShareTap: () => _showShareSheet(context, track),
                    onMoreTap: () => _showTrackOptionsSheet(context, track),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CurrentTrackListener extends StatefulWidget {
  final Widget Function(BuildContext context, PlaybackTrackModel? track)
  builder;

  const _CurrentTrackListener({required this.builder});

  @override
  State<_CurrentTrackListener> createState() => _CurrentTrackListenerState();
}

class _CurrentTrackListenerState extends State<_CurrentTrackListener> {
  final PlaybackStreamingEngineService _globalPlayer =
      PlaybackStreamingEngineService.shared;

  PlaybackTrackModel? _track;
  String? _trackId;

  @override
  void initState() {
    super.initState();
    _track = _globalPlayer.state.currentTrack;
    _trackId = _track?.id;
    _globalPlayer.addListener(_handlePlayerUpdate);
  }

  @override
  void dispose() {
    _globalPlayer.removeListener(_handlePlayerUpdate);
    super.dispose();
  }

  void _handlePlayerUpdate() {
    final PlaybackTrackModel? nextTrack = _globalPlayer.state.currentTrack;
    final String? nextTrackId = nextTrack?.id;

    if (_trackId != nextTrackId) {
      setState(() {
        _track = nextTrack;
        _trackId = nextTrackId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _track);
  }
}

class _ExpandedArtworkLayer extends StatefulWidget {
  final PlaybackTrackModel track;

  const _ExpandedArtworkLayer({required this.track});

  @override
  State<_ExpandedArtworkLayer> createState() => _ExpandedArtworkLayerState();
}

class _ExpandedArtworkLayerState extends State<_ExpandedArtworkLayer> {
  final PlaybackStreamingEngineService _globalPlayer =
      PlaybackStreamingEngineService.shared;

  bool _isPaused = false;
  String? _trackId;

  @override
  void initState() {
    super.initState();
    _trackId = widget.track.id;
    _isPaused = !_globalPlayer.state.isPlaying;
    _globalPlayer.addListener(_handlePlayerUpdate);
  }

  @override
  void didUpdateWidget(covariant _ExpandedArtworkLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track.id != widget.track.id) {
      _trackId = widget.track.id;
      _isPaused = !_globalPlayer.state.isPlaying;
    }
  }

  @override
  void dispose() {
    _globalPlayer.removeListener(_handlePlayerUpdate);
    super.dispose();
  }

  void _handlePlayerUpdate() {
    final PlaybackTrackModel? currentTrack = _globalPlayer.state.currentTrack;
    final String? currentTrackId = currentTrack?.id;
    final bool nextPaused = !_globalPlayer.state.isPlaying;

    if (_trackId != currentTrackId) return;

    if (_isPaused != nextPaused) {
      setState(() {
        _isPaused = nextPaused;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ExpandedArtworkBackground(track: widget.track, isPaused: _isPaused);
  }
}

class _ExpandedPlaybackButtons extends StatefulWidget {
  const _ExpandedPlaybackButtons();

  @override
  State<_ExpandedPlaybackButtons> createState() =>
      _ExpandedPlaybackButtonsState();
}

class _ExpandedPlaybackButtonsState extends State<_ExpandedPlaybackButtons> {
  final PlaybackStreamingEngineService _globalPlayer =
      PlaybackStreamingEngineService.shared;

  bool _isPlaying = false;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _isPlaying = _globalPlayer.state.isPlaying;
    _position = _globalPlayer.state.currentPosition;
    _globalPlayer.addListener(_handlePlayerUpdate);
  }

  @override
  void dispose() {
    _globalPlayer.removeListener(_handlePlayerUpdate);
    super.dispose();
  }

  void _handlePlayerUpdate() {
    final bool nextPlaying = _globalPlayer.state.isPlaying;
    final Duration nextPosition = _globalPlayer.state.currentPosition;

    if (_isPlaying != nextPlaying || _position != nextPosition) {
      setState(() {
        _isPlaying = nextPlaying;
        _position = nextPosition;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _PlayerActionButton(
          icon: Icons.skip_previous_rounded,
          onTap: () async {
            if (_position > const Duration(seconds: 1)) {
              await _globalPlayer.restartFromBeginning();
              return;
            }
            await _globalPlayer.playPreviousTrack();
          },
        ),
        _PlayerActionButton(
          icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          isPrimary: true,
          onTap: _globalPlayer.togglePlayPause,
        ),
        _PlayerActionButton(
          icon: Icons.skip_next_rounded,
          onTap: _globalPlayer.playNextTrack,
        ),
      ],
    );
  }
}

class _ExpandedProgressSection extends StatefulWidget {
  final PlaybackTrackModel track;

  const _ExpandedProgressSection({required this.track});

  @override
  State<_ExpandedProgressSection> createState() =>
      _ExpandedProgressSectionState();
}

class _ExpandedProgressSectionState extends State<_ExpandedProgressSection> {
  final PlaybackStreamingEngineService _globalPlayer =
      PlaybackStreamingEngineService.shared;
  final EngagementApiService _engagementService = EngagementApiService();

  Duration _position = Duration.zero;
  Duration _totalDuration = Duration.zero;
  List<Comment> _commentMarkers = [];
  bool _isLoadingWaveform = false;
  List<double> _waveformPeaks = const [];

  @override
  void initState() {
    super.initState();
    _position = _globalPlayer.state.currentPosition;
    _totalDuration = _effectiveTotalDuration(_globalPlayer.state, widget.track);
    _globalPlayer.addListener(_handlePlayerUpdate);
    _loadCommentMarkers();
    _loadWaveform();
  }

  @override
  void didUpdateWidget(covariant _ExpandedProgressSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track.id != widget.track.id ||
        oldWidget.track.playbackUrl != widget.track.playbackUrl) {
      _position = _globalPlayer.state.currentPosition;
      _totalDuration = _effectiveTotalDuration(
        _globalPlayer.state,
        widget.track,
      );
      _commentMarkers = [];
      _waveformPeaks = const [];
      _loadCommentMarkers();
      _loadWaveform();
    }
  }

  @override
  void dispose() {
    _globalPlayer.removeListener(_handlePlayerUpdate);
    super.dispose();
  }

  void _handlePlayerUpdate() {
    final Duration nextPosition = _globalPlayer.state.currentPosition;
    final Duration nextTotalDuration = _effectiveTotalDuration(
      _globalPlayer.state,
      widget.track,
    );

    if (_position != nextPosition || _totalDuration != nextTotalDuration) {
      setState(() {
        _position = nextPosition;
        _totalDuration = nextTotalDuration;
      });
    }
  }

  Future<void> _loadCommentMarkers() async {
    try {
      final result = await _engagementService.getTrackComments(
        trackId: widget.track.id,
        limit: 20,
        sortBy: 'trackTime',
      );
      if (!mounted) return;
      if (result.$1 == 200 && result.$2 is List<Comment>) {
        setState(() => _commentMarkers = result.$2 as List<Comment>);
      }
    } catch (_) {}
  }

  Future<void> _loadWaveform() async {
    final String audioUrl = widget.track.playbackUrl.trim();

    if (audioUrl.isEmpty) {
      if (!mounted) return;
      setState(() {
        _waveformPeaks = const [];
        _isLoadingWaveform = false;
      });
      return;
    }

    final String cacheKey = '${widget.track.id}|$audioUrl';
    final List<double>? cached = _expandedWaveformCache[cacheKey];

    if (cached != null && cached.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _waveformPeaks = cached;
        _isLoadingWaveform = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoadingWaveform = true;
      _waveformPeaks = const [];
    });

    try {
      final List<double> peaks = await WaveformExtractor.extractFromUrl(
        audioUrl,
        samples: 220,
      );

      _expandedWaveformCache[cacheKey] = peaks;

      if (!mounted) return;
      setState(() {
        _waveformPeaks = peaks;
        _isLoadingWaveform = false;
      });
    } catch (error) {
      debugPrint('Expanded waveform extraction failed: $error');
      if (!mounted) return;
      setState(() {
        _waveformPeaks = const [];
        _isLoadingWaveform = false;
      });
    }
  }

  void _seekFromLocalDx(double localDx, double width) {
    if (_totalDuration <= Duration.zero || width <= 0) return;

    final double ratio = (localDx / width).clamp(0.0, 1.0);
    final int targetMs = (_totalDuration.inMilliseconds * ratio).round().clamp(
      0,
      _totalDuration.inMilliseconds,
    );

    _globalPlayer.seek(Duration(milliseconds: targetMs));
  }

  @override
  Widget build(BuildContext context) {
    final double progress = _totalDuration.inMilliseconds <= 0
        ? 0
        : (_position.inMilliseconds / _totalDuration.inMilliseconds).clamp(
            0.0,
            1.0,
          );

    final List<double> peaks = _waveformPeaks.isNotEmpty
        ? _waveformPeaks
        : widget.track.waveformPeaks.isNotEmpty
        ? widget.track.waveformPeaks
        : const [
            0.18,
            0.32,
            0.24,
            0.52,
            0.28,
            0.40,
            0.22,
            0.36,
            0.20,
            0.44,
            0.30,
            0.56,
            0.26,
            0.34,
            0.48,
            0.24,
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _formatDuration(_position),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDuration(_totalDuration),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (_, constraints) {
            final double width = constraints.maxWidth;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) =>
                  _seekFromLocalDx(details.localPosition.dx, width),
              onHorizontalDragStart: (details) =>
                  _seekFromLocalDx(details.localPosition.dx, width),
              onHorizontalDragUpdate: (details) =>
                  _seekFromLocalDx(details.localPosition.dx, width),
              child: SizedBox(
                height: 30,
                width: double.infinity,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: _isLoadingWaveform
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : _ExpandedTrackWaveform(
                              peaks: peaks,
                              progress: progress,
                            ),
                    ),
                    if (_commentMarkers.isNotEmpty &&
                        _totalDuration.inMilliseconds > 0)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Stack(
                            children: _commentMarkers.take(20).map((c) {
                              final double ratio =
                                  ((c.timestamp * 1000.0) /
                                          _totalDuration.inMilliseconds)
                                      .clamp(0.0, 1.0);
                              final double left = ratio * width;
                              return Positioned(
                                left: left - 2,
                                bottom: -2,
                                child: Container(
                                  width: 4,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2C6BED),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ExpandedTrackWaveform extends StatelessWidget {
  final List<double> peaks;
  final double progress;

  const _ExpandedTrackWaveform({required this.peaks, required this.progress});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ExpandedTrackWaveformPainter(
        peaks: peaks,
        progress: progress.clamp(0.0, 1.0),
      ),
    );
  }
}

class _ExpandedTrackWaveformPainter extends CustomPainter {
  final List<double> peaks;
  final double progress;

  _ExpandedTrackWaveformPainter({required this.peaks, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty) return;

    const double barWidth = 4.5;
    const double gap = 2.5;
    final double step = barWidth + gap;
    final int visibleBars = (size.width / step).floor();

    if (visibleBars <= 0) return;

    final Paint playedPaint = Paint()
      ..color = const Color(0xFFFF5500)
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round;

    final Paint unplayedPaint = Paint()
      ..color = Colors.white30
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round;

    final double centerY = size.height / 2;
    final double playedThreshold = size.width * progress;

    for (int i = 0; i < visibleBars; i++) {
      final int peakIndex = ((i / visibleBars) * peaks.length).floor().clamp(
        0,
        peaks.length - 1,
      );

      final double normalized = peaks[peakIndex].clamp(0.08, 1.0);
      final double barHeight = normalized * size.height;
      final double x = i * step + barWidth / 2;

      final double top = centerY - barHeight / 2;
      final double bottom = centerY + barHeight / 2;

      final Paint paint = x <= playedThreshold ? playedPaint : unplayedPaint;

      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ExpandedTrackWaveformPainter oldDelegate) {
    return oldDelegate.peaks != peaks || oldDelegate.progress != progress;
  }
}

class _ExpandedVolumeSlider extends StatefulWidget {
  const _ExpandedVolumeSlider();

  @override
  State<_ExpandedVolumeSlider> createState() => _ExpandedVolumeSliderState();
}

class _ExpandedVolumeSliderState extends State<_ExpandedVolumeSlider> {
  final PlaybackStreamingEngineService _globalPlayer =
      PlaybackStreamingEngineService.shared;

  double _volume = 1.0;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _volume = _globalPlayer.state.volume;
    _isMuted = _globalPlayer.state.isMuted;
    _globalPlayer.addListener(_handlePlayerUpdate);
  }

  @override
  void dispose() {
    _globalPlayer.removeListener(_handlePlayerUpdate);
    super.dispose();
  }

  void _handlePlayerUpdate() {
    final double nextVolume = _globalPlayer.state.volume;
    final bool nextMuted = _globalPlayer.state.isMuted;

    if (_volume != nextVolume || _isMuted != nextMuted) {
      setState(() {
        _volume = nextVolume;
        _isMuted = nextMuted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _globalPlayer.toggleMute,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                _isMuted || _volume <= 0.01
                    ? Icons.volume_off_rounded
                    : _volume < 0.5
                    ? Icons.volume_down_rounded
                    : Icons.volume_up_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbColor: Colors.white,
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white30,
                overlayShape: SliderComponentShape.noOverlay,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              ),
              child: Slider(
                value: _isMuted ? 0.0 : _volume.clamp(0.0, 1.0),
                min: 0,
                max: 1,
                onChanged: (value) {
                  _globalPlayer.setVolume(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedArtworkBackground extends StatelessWidget {
  final PlaybackTrackModel track;
  final bool isPaused;

  const _ExpandedArtworkBackground({
    required this.track,
    required this.isPaused,
  });

  Widget _buildArtwork() {
    if (track.artworkUrl != null && track.artworkUrl!.trim().isNotEmpty) {
      return Image.network(
        track.artworkUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _ArtworkFallback(track: track),
      );
    }

    return _ArtworkFallback(track: track);
  }

  @override
  Widget build(BuildContext context) {
    if (!isPaused) {
      return _buildArtwork();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: _buildArtwork(),
          ),
        ),
        Positioned.fill(
          child: Container(color: Colors.white.withValues(alpha: 0.20)),
        ),
      ],
    );
  }
}

class _ArtworkFallback extends StatelessWidget {
  final PlaybackTrackModel track;
  const _ArtworkFallback({required this.track});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.96),
            AppColors.gentlePeach,
            AppColors.brilliantOrange.withValues(alpha: 0.35),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.album_rounded,
          size: 180,
          color: Colors.black.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

class _PlayerActionButton extends StatelessWidget {
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _PlayerActionButton({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isPrimary ? 78 : 56,
        height: isPrimary ? 78 : 56,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: isPrimary ? 40 : 28),
      ),
    );
  }
}

class _BottomMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _BottomMetric({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 26),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}

// ─────────────────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────────────────
Duration _effectiveTotalDuration(
  PlaybackStateModel state,
  PlaybackTrackModel track,
) {
  if (track.accessState == PlaybackAccessState.preview) {
    return track.effectivePreviewDuration;
  }
  if (state.totalDuration > Duration.zero) return state.totalDuration;
  return track.duration ?? const Duration(minutes: 4, seconds: 3);
}

String _formatDuration(Duration duration) {
  final int minutes = duration.inMinutes;
  final int seconds = duration.inSeconds.remainder(60);
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

Future<void> _showDeviceSheet(BuildContext context) async {
  final BuildContext? navigatorContext = appNavigatorKey.currentContext;
  if (navigatorContext == null) return;

  _isTransientSheetOpening.value = true;
  try {
    await showModalBottomSheet<void>(
      context: navigatorContext,
      useRootNavigator: true,
      backgroundColor: const Color(0xFF171717),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Current Device',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 22),
                const _SheetOptionRow(
                  icon: Icons.smartphone_outlined,
                  iconColor: AppColors.brilliantOrange,
                  label: 'Speaker',
                ),
                const SizedBox(height: 28),
                Divider(color: Colors.white.withValues(alpha: 0.12)),
                const SizedBox(height: 28),
                const Text(
                  'Other Devices',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 22),
                const _SheetOptionRow(
                  icon: Icons.speaker_phone_outlined,
                  label: 'AirPlay or Bluetooth',
                ),
                const SizedBox(height: 24),
                const _SheetOptionRow(
                  icon: Icons.cast_outlined,
                  label: 'Google Cast',
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        );
      },
    );
  } finally {
    _isTransientSheetOpening.value = false;
  }
}

Future<void> _showShareSheet(
  BuildContext context,
  PlaybackTrackModel track,
) async {
  final BuildContext? navigatorContext = appNavigatorKey.currentContext;
  if (navigatorContext == null) return;

  _isTransientSheetOpening.value = true;
  try {
    await showModalBottomSheet<void>(
      context: navigatorContext,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF090909),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child:
                              track.artworkUrl != null &&
                                  track.artworkUrl!.trim().isNotEmpty
                              ? Image.network(
                                  track.artworkUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.album_rounded,
                                    color: Colors.black54,
                                    size: 34,
                                  ),
                                )
                              : const Icon(
                                  Icons.album_rounded,
                                  color: Colors.black54,
                                  size: 34,
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                track.artistName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'SHARE',
                    style: TextStyle(
                      color: Colors.white70,
                      letterSpacing: 2.2,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _ShareAction(
                          icon: Icons.send_outlined,
                          label: 'Message',
                        ),
                        _ShareAction(
                          icon: Icons.copy_outlined,
                          label: 'Copy link',
                        ),
                        _ShareAction(
                          icon: Icons.qr_code_2_outlined,
                          label: 'QR code',
                        ),
                        _ShareAction(icon: Icons.sms_outlined, label: 'SMS'),
                        _ShareAction(
                          icon: Icons.chat_bubble_outline,
                          label: 'WhatsApp',
                        ),
                        _ShareAction(
                          icon: Icons.camera_alt_outlined,
                          label: 'Stories',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  } finally {
    _isTransientSheetOpening.value = false;
  }
}

Future<void> _showTrackOptionsSheet(
  BuildContext context,
  PlaybackTrackModel track,
) async {
  final BuildContext? navigatorContext = appNavigatorKey.currentContext;
  if (navigatorContext == null) return;

  await showModalBottomSheet<void>(
    context: navigatorContext,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _TrackOptionsSheetContent(track: track),
  );
}

class _TrackOptionsHeaderCard extends StatelessWidget {
  final PlaybackTrackModel track;

  const _TrackOptionsHeaderCard({required this.track});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blueGrey.shade500.withValues(alpha: 0.95),
            Colors.grey.shade400.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 108,
              height: 90,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 58,
                    top: 8,
                    child: SizedBox(
                      width: 42,
                      height: 74,
                      child: CustomPaint(painter: _VinylPainter()),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 4,
                    child: Container(
                      width: 82,
                      height: 82,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          track.artworkUrl != null &&
                              track.artworkUrl!.trim().isNotEmpty
                          ? Image.network(
                              track.artworkUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.album_rounded,
                                color: Colors.black54,
                                size: 34,
                              ),
                            )
                          : const Icon(
                              Icons.album_rounded,
                              color: Colors.black54,
                              size: 34,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    track.artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _TrackOptionTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 2),
      leading: Icon(icon, color: color, size: 33),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _VinylPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint basePaint = Paint()..color = Colors.black;
    final Paint ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final Paint centerPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.fill;

    final Offset center = Offset(size.width * 0.45, size.height / 2);
    final double radius = size.height * 0.45;

    canvas.drawCircle(center, radius, basePaint);
    canvas.drawCircle(center, radius * 0.78, ringPaint);
    canvas.drawCircle(center, radius * 0.56, ringPaint);
    canvas.drawCircle(center, radius * 0.34, ringPaint);
    canvas.drawCircle(center, radius * 0.12, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────
//  MINI PLAYER LIKE BUTTON (stateful — resets on track change)
// ─────────────────────────────────────────────────────────
class _MiniLikeButton extends StatefulWidget {
  final String trackId;
  const _MiniLikeButton({required this.trackId});

  @override
  State<_MiniLikeButton> createState() => _MiniLikeButtonState();
}

class _MiniLikeButtonState extends State<_MiniLikeButton> {
  final EngagementApiService _engagementService = EngagementApiService();
  final AuthApiService _authApiService = AuthApiService();
  bool _isLiked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLikeStatus();
  }

  @override
  void didUpdateWidget(covariant _MiniLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trackId != widget.trackId) {
      setState(() {
        _isLiked = false;
        _isLoading = false;
      });
      _checkLikeStatus();
    }
  }

  Future<void> _checkLikeStatus() async {
    try {
      final userId = await _authApiService.getStoredUserId();
      if (userId == null || !mounted) return;
      final result = await _engagementService.getTrackLikers(
        trackId: widget.trackId,
        limit: 50,
      );
      if (!mounted) return;
      if (result.$1 == 200 && result.$2 is List) {
        final likers = result.$2 as List<EngagementUser>;
        setState(() => _isLiked = likers.any((u) => u.userId == userId));
      }
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    if (_isLoading) return;
    final bool wasLiked = _isLiked;
    setState(() {
      _isLiked = !_isLiked;
      _isLoading = true;
    });
    final result = await _engagementService.toggleTrackLike(
      trackId: widget.trackId,
    );
    if (!mounted) return;
    if (result.$1 == 200 && result.$2 is Map<String, dynamic>) {
      final data = result.$2 as Map<String, dynamic>;
      setState(() => _isLiked = data['liked'] as bool? ?? _isLiked);
    } else if (result.$1 != 200) {
      setState(() => _isLiked = wasLiked);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _toggleLike,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
      icon: Icon(
        _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: _isLiked ? Colors.orange : Colors.white,
        size: 26,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  EXPANDED PLAYER ENGAGEMENT BAR (like + comment + share + more)
// ─────────────────────────────────────────────────────────
class _ExpandedEngagementBar extends StatefulWidget {
  final PlaybackTrackModel track;
  final VoidCallback onShareTap;
  final Future<void> Function() onMoreTap;

  const _ExpandedEngagementBar({
    required this.track,
    required this.onShareTap,
    required this.onMoreTap,
  });

  @override
  State<_ExpandedEngagementBar> createState() => _ExpandedEngagementBarState();
}

class _ExpandedEngagementBarState extends State<_ExpandedEngagementBar> {
  final EngagementApiService _engagementService = EngagementApiService();
  bool _isLiked = false;
  bool _isLikeLoading = false;
  late int _likeCount;
  late int _commentCount;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.track.numLikes;
    _commentCount = widget.track.numComments;
    _checkLikeStatus();
    _trackCommentPosted.addListener(_onExternalCommentPosted);
  }

  @override
  void dispose() {
    _trackCommentPosted.removeListener(_onExternalCommentPosted);
    super.dispose();
  }

  // Increments comment count when the inline bar posts a comment for this track.
  void _onExternalCommentPosted() {
    if (_trackCommentPosted.value == widget.track.id && mounted) {
      setState(() => _commentCount++);
    }
  }

  @override
  void didUpdateWidget(covariant _ExpandedEngagementBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track.id != widget.track.id) {
      setState(() {
        _isLiked = false;
        _isLikeLoading = false;
        _likeCount = widget.track.numLikes;
        _commentCount = widget.track.numComments;
      });
      _checkLikeStatus();
    }
  }

  Future<void> _checkLikeStatus() async {
    try {
      final userId = await AuthApiService().getStoredUserId();
      if (userId == null || !mounted) return;
      final result = await _engagementService.getTrackLikers(
        trackId: widget.track.id,
        limit: 50,
      );
      if (!mounted) return;
      if (result.$1 == 200 && result.$2 is List) {
        final likers = result.$2 as List<EngagementUser>;
        setState(() => _isLiked = likers.any((u) => u.userId == userId));
      }
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    if (_isLikeLoading) return;
    final bool wasLiked = _isLiked;
    final int wasCount = _likeCount;
    setState(() {
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? wasCount + 1 : wasCount - 1;
      _isLikeLoading = true;
    });
    final result = await _engagementService.toggleTrackLike(
      trackId: widget.track.id,
    );
    if (!mounted) return;
    if (result.$1 == 200 && result.$2 is Map<String, dynamic>) {
      final data = result.$2 as Map<String, dynamic>;
      setState(() {
        _isLiked = data['liked'] as bool? ?? _isLiked;
        _likeCount = data['numOfLikes'] as int? ?? _likeCount;
      });
    } else if (result.$1 != 200) {
      setState(() {
        _isLiked = wasLiked;
        _likeCount = wasCount;
      });
    }
    setState(() => _isLikeLoading = false);
  }

  void _openLikersScreen() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => LikersScreen(trackId: widget.track.id, initialTab: 0),
      ),
    );
  }

  Future<void> _openCommentsScreen() async {
    final int positionSeconds =
        PlaybackStreamingEngineService.shared.state.currentPosition.inSeconds;
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => CommentsScreen(
          trackId: widget.track.id,
          trackTitle: widget.track.title,
          trackArtist: widget.track.artistName,
          trackThumbnailUrl: widget.track.artworkUrl,
          currentPositionSeconds: positionSeconds,
        ),
      ),
    );
    if (!mounted) return;
    // Refresh comment count after returning from CommentsScreen
    // (user may have posted or deleted comments while there).
    final result = await _engagementService.getTrackComments(
      trackId: widget.track.id,
      limit: 100,
    );
    if (!mounted) return;
    if (result.$1 == 200 && result.$2 is List) {
      setState(() => _commentCount = (result.$2 as List).length);
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(count % 1000000 == 0 ? 0 : 1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        GestureDetector(
          onTap: _toggleLike,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _isLiked ? Colors.orange : Colors.white,
                size: 26,
              ),
              if (_likeCount > 0) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _openLikersScreen,
                  child: Text(
                    _formatCount(_likeCount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        GestureDetector(
          onTap: _openCommentsScreen,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.mode_comment_outlined,
                color: Colors.white,
                size: 26,
              ),
              if (_commentCount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  _formatCount(_commentCount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        _BottomMetric(
          icon: Icons.share_outlined,
          label: '',
          onTap: widget.onShareTap,
        ),
        const _BottomMetric(icon: Icons.playlist_play_rounded, label: ''),
        _BottomMetric(
          icon: Icons.more_horiz_rounded,
          label: '',
          onTap: () async {
            final bool wasLiked = _isLiked;
            await widget.onMoreTap();
            if (!mounted) return;
            await _checkLikeStatus();
            if (!mounted) return;
            // If like state changed in the options sheet, sync the count shown here.
            if (_isLiked != wasLiked) {
              setState(() {
                _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
              });
            }
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  TRACK OPTIONS SHEET CONTENT (stateful — like + repost + comments)
// ─────────────────────────────────────────────────────────
class _TrackOptionsSheetContent extends StatefulWidget {
  final PlaybackTrackModel track;
  const _TrackOptionsSheetContent({required this.track});

  @override
  State<_TrackOptionsSheetContent> createState() =>
      _TrackOptionsSheetContentState();
}

class _TrackOptionsSheetContentState extends State<_TrackOptionsSheetContent> {
  final EngagementApiService _engagementService = EngagementApiService();
  bool _isLiked = false;
  bool _isLikeLoading = false;
  bool _isReposted = false;
  late int _repostCount;

  @override
  void initState() {
    super.initState();
    _repostCount = widget.track.numReposts;
    _checkRepostStatus();
    _checkLikeStatus();
  }

  Future<void> _checkLikeStatus() async {
    try {
      final userId = await AuthApiService().getStoredUserId();
      if (userId == null || !mounted) return;
      final result = await _engagementService.getTrackLikers(
        trackId: widget.track.id,
        limit: 50,
      );
      if (!mounted) return;
      if (result.$1 == 200 && result.$2 is List) {
        final likers = result.$2 as List<EngagementUser>;
        setState(() => _isLiked = likers.any((u) => u.userId == userId));
      }
    } catch (_) {}
  }

  Future<void> _checkRepostStatus() async {
    try {
      final result = await _engagementService.getTrackRepostStatus(
        trackId: widget.track.id,
      );
      if (!mounted) return;
      if (result.$1 == 200 && result.$2 is RepostStatus) {
        setState(() => _isReposted = (result.$2 as RepostStatus).reposted);
      }
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    if (_isLikeLoading) return;
    final bool wasLiked = _isLiked;
    setState(() {
      _isLiked = !_isLiked;
      _isLikeLoading = true;
    });
    final result = await _engagementService.toggleTrackLike(
      trackId: widget.track.id,
    );
    if (!mounted) return;
    if (result.$1 == 200 && result.$2 is Map<String, dynamic>) {
      final data = result.$2 as Map<String, dynamic>;
      setState(() => _isLiked = data['liked'] as bool? ?? _isLiked);
    } else if (result.$1 != 200) {
      setState(() => _isLiked = wasLiked);
    }
    setState(() => _isLikeLoading = false);
  }

  Future<void> _navigateToArtistProfile() async {
    final artistId = widget.track.artistId;
    if (artistId == null || artistId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artist profile not available')),
        );
      }
      return;
    }
    Navigator.pop(context);
    final navCtx = appNavigatorKey.currentContext;
    if (navCtx == null) return;
    final token = await AuthApiService().getStoredAccessToken() ?? '';
    final currentUserId = await AuthApiService().getStoredUserId() ?? '';
    if (!navCtx.mounted) return;
    Navigator.pushNamed(
      navCtx,
      UserProfileSocialIdentityRoutes.userProfileRoute,
      arguments: {
        'userId': artistId,
        'token': token,
        'currentUserId': currentUserId,
      },
    );
  }

  void _openComments() {
    Navigator.pop(context);
    final navCtx = appNavigatorKey.currentContext;
    if (navCtx == null) return;
    final int positionSeconds =
        PlaybackStreamingEngineService.shared.state.currentPosition.inSeconds;
    Navigator.pushNamed(
      navCtx,
      EngagementSocialInteractionsRoutes.comments,
      arguments: {
        'trackId': widget.track.id,
        'trackTitle': widget.track.title,
        'trackArtist': widget.track.artistName,
        'trackThumbnailUrl': widget.track.artworkUrl,
        'currentPositionSeconds': positionSeconds,
      },
    );
  }

  Future<void> _openRepost() async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RepostBottomSheet(
        trackId: widget.track.id,
        title: widget.track.title,
        artist: widget.track.artistName,
        thumbnailUrl: widget.track.artworkUrl,
        isCurrentlyReposted: _isReposted,
        currentRepostCount: _repostCount,
        onRepostToggled: (isNowReposted, newCount) {
          if (mounted) {
            setState(() {
              _isReposted = isNowReposted;
              _repostCount = newCount;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF090909),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _TrackOptionsHeaderCard(track: widget.track),
                ),
                const SizedBox(height: 22),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    'SHARE',
                    style: TextStyle(
                      color: Colors.white70,
                      letterSpacing: 2.2,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      _ShareAction(icon: Icons.send_outlined, label: 'Message'),
                      _ShareAction(
                        icon: Icons.copy_outlined,
                        label: 'Copy link',
                      ),
                      _ShareAction(
                        icon: Icons.qr_code_2_outlined,
                        label: 'QR code',
                      ),
                      _ShareAction(icon: Icons.sms_outlined, label: 'SMS'),
                      _ShareAction(
                        icon: Icons.chat_bubble_outline,
                        label: 'WhatsApp',
                      ),
                      _ShareAction(
                        icon: Icons.camera_alt_outlined,
                        label: 'Stories',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 10),
                _TrackOptionTile(
                  icon: _isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: _isLiked ? 'Liked' : 'Like',
                  color: _isLiked ? Colors.orange : Colors.white,
                  onTap: _toggleLike,
                ),
                const _TrackOptionTile(
                  icon: Icons.playlist_play_rounded,
                  label: 'Play next',
                ),
                const _TrackOptionTile(
                  icon: Icons.format_list_bulleted_rounded,
                  label: 'Play last',
                ),
                const _TrackOptionTile(
                  icon: Icons.playlist_add_outlined,
                  label: 'Add to playlist',
                ),
                const _TrackOptionTile(
                  icon: Icons.radio_outlined,
                  label: 'Start station',
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 10),
                _TrackOptionTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Go to profile',
                  onTap: _navigateToArtistProfile,
                ),
                _TrackOptionTile(
                  icon: Icons.mode_comment_outlined,
                  label: 'View comments',
                  onTap: _openComments,
                ),
                _TrackOptionTile(
                  icon: Icons.repeat_rounded,
                  label: _isReposted ? 'Reposted' : 'Repost on SoundCloud',
                  color: _isReposted ? Colors.orange : Colors.white,
                  onTap: _openRepost,
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 10),
                const _TrackOptionTile(
                  icon: Icons.graphic_eq,
                  label: 'Behind this track',
                ),
                const _TrackOptionTile(
                  icon: Icons.outlined_flag_rounded,
                  label: 'Report',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetOptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _SheetOptionRow({
    required this.icon,
    required this.label,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }
}

class _ShareAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ShareAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  INLINE COMMENT BAR — post a comment directly from the expanded player.
//  Shows a text field with emoji quick-post buttons when empty, and an
//  arrow send button once the user starts typing.
// ─────────────────────────────────────────────────────────
class _InlineCommentBar extends StatefulWidget {
  final PlaybackTrackModel track;
  const _InlineCommentBar({required this.track});

  @override
  State<_InlineCommentBar> createState() => _InlineCommentBarState();
}

class _InlineCommentBarState extends State<_InlineCommentBar> {
  final EngagementApiService _engagementService = EngagementApiService();
  final TextEditingController _controller = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _postComment(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || _isPosting) return;
    setState(() => _isPosting = true);

    final int positionSeconds =
        PlaybackStreamingEngineService.shared.state.currentPosition.inSeconds;

    final result = await _engagementService.postComment(
      trackId: widget.track.id,
      content: trimmed,
      timestamp: positionSeconds,
    );

    if (!mounted) return;
    setState(() => _isPosting = false);
    _controller.clear();

    if (result.$1 == 201) {
      // Notify the engagement bar to increment its comment count.
      _trackCommentPosted.value = widget.track.id;
      Future.microtask(() => _trackCommentPosted.value = null);
    } else {
      final ctx = appNavigatorKey.currentContext ?? context;
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Could not post comment: ${result.$2}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.grey.shade700.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(26),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Comment...',
                hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _postComment(_controller.text),
            ),
          ),
          const SizedBox(width: 6),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (_, value, child) {
              if (value.text.isNotEmpty) {
                // Show send arrow when user has typed something.
                return GestureDetector(
                  onTap: () => _postComment(_controller.text),
                  child: _isPosting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.orange,
                          ),
                        )
                      : const Icon(
                          Icons.arrow_circle_up_rounded,
                          color: Colors.orange,
                          size: 28,
                        ),
                );
              }
              // Show emoji quick-post buttons when bar is empty.
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _postComment('🔥'),
                    child: const Text('🔥', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _postComment('👏'),
                    child: const Text('👏', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _postComment('🥺'),
                    child: const Text('🥺', style: TextStyle(fontSize: 22)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  FOLLOW BUTTON — stateful, shown in expanded player header
// ─────────────────────────────────────────────────────────
class _ExpandedFollowButton extends StatefulWidget {
  final PlaybackTrackModel track;
  const _ExpandedFollowButton({required this.track});

  @override
  State<_ExpandedFollowButton> createState() => _ExpandedFollowButtonState();
}

class _ExpandedFollowButtonState extends State<_ExpandedFollowButton> {
  final SocialApiService _socialService = SocialApiService();
  bool _isFollowing = false;
  bool _isLoading = false;

  Future<void> _toggleFollow() async {
    final artistId = widget.track.artistId;
    if (_isLoading || artistId == null || artistId.isEmpty) return;
    final wasFollowing = _isFollowing;
    setState(() {
      _isFollowing = !_isFollowing;
      _isLoading = true;
    });
    final result = wasFollowing
        ? await _socialService.unfollowUser(targetUserId: artistId)
        : await _socialService.followUser(targetUserId: artistId);
    if (!mounted) return;
    if (result.$1 != 200) {
      setState(() => _isFollowing = wasFollowing);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _toggleFollow,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            )
          : Icon(
              _isFollowing
                  ? Icons.person_remove_outlined
                  : Icons.person_add_alt_1_outlined,
              color: _isFollowing ? Colors.orange : Colors.white70,
              size: 26,
            ),
    );
  }
}
