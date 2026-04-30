import 'package:flutter/material.dart';

import 'package:cross_team5/core/theme/app_colors.dart';

import '../models/playback_state_model.dart';
import '../models/playback_track_model.dart';
import '../services/waveform_extractor.dart';

class PlaybackNowPlayingCard extends StatefulWidget {
  final PlaybackStateModel state;
  final ValueChanged<double> onSeekChanged;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onPlayPauseTap;
  final VoidCallback onStopTap;
  final VoidCallback onRestartTap;
  final VoidCallback onMuteTap;

  const PlaybackNowPlayingCard({
    super.key,
    required this.state,
    required this.onSeekChanged,
    required this.onVolumeChanged,
    required this.onPlayPauseTap,
    required this.onStopTap,
    required this.onRestartTap,
    required this.onMuteTap,
  });

  @override
  State<PlaybackNowPlayingCard> createState() => _PlaybackNowPlayingCardState();
}

class _PlaybackNowPlayingCardState extends State<PlaybackNowPlayingCard> {
  static final Map<String, List<double>> _waveformCache =
      <String, List<double>>{};

  bool _isLoadingWaveform = false;
  List<double> _waveformPeaks = const [];

  @override
  void initState() {
    super.initState();
    _loadWaveform();
  }

  @override
  void didUpdateWidget(covariant PlaybackNowPlayingCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final String? oldTrackId = oldWidget.state.currentTrack?.id;
    final String? newTrackId = widget.state.currentTrack?.id;

    if (oldTrackId != newTrackId) {
      _loadWaveform();
    }
  }

  Future<void> _loadWaveform() async {
    final PlaybackTrackModel? track = widget.state.currentTrack;

    if (track == null || track.playbackUrl.isEmpty) {
      if (!mounted) return;
      setState(() {
        _waveformPeaks = const [];
        _isLoadingWaveform = false;
      });
      return;
    }

    final String cacheKey = '${track.id}|${track.playbackUrl}';

    if (_waveformCache.containsKey(cacheKey)) {
      if (!mounted) return;
      setState(() {
        _waveformPeaks = _waveformCache[cacheKey]!;
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
      final peaks = await WaveformExtractor.extractFromUrl(
        track.playbackUrl,
        samples: 220,
      );

      _waveformCache[cacheKey] = peaks;

      if (!mounted) return;
      setState(() {
        _waveformPeaks = peaks;
        _isLoadingWaveform = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _waveformPeaks = const [];
        _isLoadingWaveform = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.state.currentTrack;
    final double maxSeek = _buildSeekMax(track, widget.state.totalDuration);
    final double currentSeek = widget.state.currentPosition.inMilliseconds
        .clamp(0, maxSeek.toInt())
        .toDouble();

    final double progress = maxSeek <= 0
        ? 0
        : (currentSeek / maxSeek).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.25,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [AppColors.brilliantOrange, AppColors.anger],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.multitrack_audio_rounded,
                  color: AppColors.whiteSmoke,
                  size: 70,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            track?.title ?? 'No track selected',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            track?.artistName ?? 'Choose one of the test tracks below',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.white60, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(label: _buildStatusLabel(widget.state.status)),
              if (track != null)
                _StatusChip(label: _buildAccessLabel(track.accessState)),
              if (widget.state.message != null &&
                  widget.state.message!.trim().isNotEmpty)
                _StatusChip(label: widget.state.message!, highlighted: true),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 96,
            width: double.infinity,
            child: _isLoadingWaveform
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _waveformPeaks.isEmpty
                ? Center(
                    child: Text(
                      'Waveform unavailable',
                      style: TextStyle(color: AppColors.white60, fontSize: 12),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: track == null
                            ? null
                            : (details) {
                                final double ratio =
                                    (details.localPosition.dx /
                                            constraints.maxWidth)
                                        .clamp(0.0, 1.0);
                                widget.onSeekChanged(maxSeek * ratio);
                              },
                        onHorizontalDragUpdate: track == null
                            ? null
                            : (details) {
                                final double ratio =
                                    (details.localPosition.dx /
                                            constraints.maxWidth)
                                        .clamp(0.0, 1.0);
                                widget.onSeekChanged(maxSeek * ratio);
                              },
                        child: SoundCloudWaveform(
                          peaks: _waveformPeaks,
                          progress: progress,
                          height: 96,
                          barWidth: 3,
                          gap: 2,
                          activeColor: AppColors.primaryOrange,
                          inactiveColor: const Color(0xFFBDBDBD),
                        ),
                      );
                    },
                  ),
          ),
          Row(
            children: [
              Text(
                _formatDuration(widget.state.currentPosition),
                style: TextStyle(color: AppColors.white60, fontSize: 12),
              ),
              const Spacer(),
              Text(
                _formatDuration(Duration(milliseconds: maxSeek.toInt())),
                style: TextStyle(color: AppColors.white60, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CircleControl(
                icon: Icons.replay_rounded,
                onTap: track == null ? null : widget.onRestartTap,
              ),
              _CircleControl(
                icon: widget.state.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                onTap: track == null ? null : widget.onPlayPauseTap,
                isPrimary: true,
              ),
              _CircleControl(
                icon: Icons.stop_rounded,
                onTap: track == null ? null : widget.onStopTap,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                onPressed: track == null ? null : widget.onMuteTap,
                icon: Icon(
                  widget.state.isMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  color: AppColors.whiteSmoke,
                ),
              ),
              Expanded(
                child: Slider(
                  value: widget.state.volume,
                  min: 0,
                  max: 1,
                  onChanged: track == null ? null : widget.onVolumeChanged,
                ),
              ),
              SizedBox(
                width: 38,
                child: Text(
                  '${(widget.state.volume * 100).round()}%',
                  textAlign: TextAlign.end,
                  style: TextStyle(color: AppColors.white60, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildStatusLabel(PlaybackStatus status) {
    return switch (status) {
      PlaybackStatus.idle => 'Idle',
      PlaybackStatus.loading => 'Loading',
      PlaybackStatus.playing => 'Playing',
      PlaybackStatus.paused => 'Paused',
      PlaybackStatus.stopped => 'Stopped',
      PlaybackStatus.completed => 'Completed',
      PlaybackStatus.blocked => 'Blocked',
      PlaybackStatus.previewEnded => 'Preview ended',
      PlaybackStatus.error => 'Error',
    };
  }

  String _buildAccessLabel(PlaybackAccessState accessState) {
    return switch (accessState) {
      PlaybackAccessState.playable => 'Full track',
      PlaybackAccessState.preview => 'Preview only',
      PlaybackAccessState.blocked => 'Not playable',
    };
  }

  double _buildSeekMax(PlaybackTrackModel? track, Duration totalDuration) {
    if (track == null) {
      return 1;
    }

    if (track.accessState == PlaybackAccessState.preview) {
      return track.effectivePreviewDuration.inMilliseconds.toDouble();
    }

    if (totalDuration > Duration.zero) {
      return totalDuration.inMilliseconds.toDouble();
    }

    return (track.duration ?? const Duration(seconds: 1)).inMilliseconds
        .toDouble();
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class SoundCloudWaveform extends StatelessWidget {
  final List<double> peaks;
  final double progress;
  final double height;
  final double barWidth;
  final double gap;
  final Color activeColor;
  final Color inactiveColor;

  const SoundCloudWaveform({
    super.key,
    required this.peaks,
    this.progress = 0.0,
    this.height = 100,
    this.barWidth = 3,
    this.gap = 2,
    this.activeColor = AppColors.primaryOrange,
    this.inactiveColor = const Color(0xFFBDBDBD),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SoundCloudWaveformPainter(
          peaks: peaks,
          progress: progress.clamp(0.0, 1.0),
          barWidth: barWidth,
          gap: gap,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
        ),
      ),
    );
  }
}

class _SoundCloudWaveformPainter extends CustomPainter {
  final List<double> peaks;
  final double progress;
  final double barWidth;
  final double gap;
  final Color activeColor;
  final Color inactiveColor;

  _SoundCloudWaveformPainter({
    required this.peaks,
    required this.progress,
    required this.barWidth,
    required this.gap,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty) return;

    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round;

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final step = barWidth + gap;
    final maxBars = (size.width / step).floor();

    if (maxBars <= 0) return;

    for (int i = 0; i < maxBars; i++) {
      final peakIndex = ((i / maxBars) * peaks.length).floor().clamp(
        0,
        peaks.length - 1,
      );

      final normalized = peaks[peakIndex].clamp(0.03, 1.0);
      final barHeight = normalized * size.height;
      final x = i * step + barWidth / 2;

      final y1 = centerY - barHeight / 2;
      final y2 = centerY + barHeight / 2;

      final playedThreshold = size.width * progress;
      final paint = x <= playedThreshold ? activePaint : inactivePaint;

      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SoundCloudWaveformPainter oldDelegate) {
    return oldDelegate.peaks != peaks ||
        oldDelegate.progress != progress ||
        oldDelegate.barWidth != barWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool highlighted;

  const _StatusChip({required this.label, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.brilliantOrange.withValues(alpha: 0.14)
            : AppColors.whiteSmoke.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: highlighted ? AppColors.brilliantOrange : AppColors.whiteSmoke,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CircleControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isPrimary;

  const _CircleControl({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isPrimary ? 70 : 54,
        height: isPrimary ? 70 : 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPrimary
              ? AppColors.whiteSmoke
              : AppColors.whiteSmoke.withValues(alpha: 0.08),
        ),
        child: Icon(
          icon,
          color: isPrimary ? AppColors.chineseBlack : AppColors.whiteSmoke,
          size: isPrimary ? 36 : 28,
        ),
      ),
    );
  }
}
