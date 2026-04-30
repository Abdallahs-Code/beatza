// Widget: FeedCard
// Full-screen TikTok-style feed card for a single feed item.
//
// Behaviour:
//   - Displays track cover image full-screen with blurred background
//   - "Tap to preview" overlay shown until user taps it
//   - Mute/unmute button: track audio plays locally (no mini-player) only when
//     unmuted AND isCurrent AND user has tapped the preview overlay
//   - Tapping ▶ stops local audio and delegates to global PlaybackService
//     (mini player appears — this is the correct existing behaviour)
//   - ⋯ options button (top-right) opens the same options sheet as the
//     global track card (showTrackOptionsSheet from global_playback_overlay)
//   - Right-side: ❤️ likes (persisted via checkTrackLikeStatus on init),
//     💬 comments (count refreshed after CommentsScreen closes), ➕ playlist
//   - Like state: checked against API on init so it persists across nav

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/engagement_social_interactions/services/engagement_api_service.dart';
import 'package:cross_team5/features/engagement_social_interactions/engagement_social_interactions_routes.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/features/activity/screens/behind_the_track_screen.dart';
import 'package:cross_team5/features/activity/screens/track_options_sheet.dart';


class FeedCard extends StatefulWidget {
  final String itemId;
  final bool isCurrent;
  final ValueNotifier<bool> isMuted;
  final String? audioUrl;
  final String? imgLink;
  final String displayName;
  final String actorName;
  final String actorId;
  final bool isFollowing;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isRepost;
  final VoidCallback onPlayTap;
  final VoidCallback onActorTap;

  const FeedCard({
    super.key,
    required this.itemId,
    required this.isCurrent,
    required this.isMuted,
    this.audioUrl,
    this.imgLink,
    required this.displayName,
    required this.actorName,
    required this.actorId,
    required this.isFollowing,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.isRepost,
    required this.onPlayTap,
    required this.onActorTap,
  });

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  bool _hasStartedPreview = false;

  final EngagementApiService _engagementService = EngagementApiService();
  final AudioPlayer _localPlayer = AudioPlayer();

  // Optimistic like state — refreshed from API on init
  late bool _isLiked;
  late int _likeCount;

  // Comment count — refreshed after CommentsScreen closes
  late int _commentCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _likeCount = widget.likeCount;
    _commentCount = widget.commentCount;
    _localPlayer.setReleaseMode(ReleaseMode.stop);
    widget.isMuted.addListener(_onMuteChanged);
    _checkLikeStatus();
    _fetchCommentCount();
  }

  @override
  void didUpdateWidget(FeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isCurrent && oldWidget.isCurrent) {
      setState(() => _hasStartedPreview = false);
      _stopLocalAudio();
    }
  }

  @override
  void dispose() {
    widget.isMuted.removeListener(_onMuteChanged);
    _localPlayer.dispose();
    super.dispose();
  }

  // ── Local audio (feed preview, no mini-player) ─────────────────────────────

  void _onMuteChanged() {
    if (!widget.isMuted.value &&
        widget.isCurrent &&
        widget.audioUrl != null &&
        _hasStartedPreview) {
      _startLocalAudio();
    } else {
      _stopLocalAudio();
    }
  }

  Future<void> _startLocalAudio() async {
    if (widget.audioUrl == null || widget.audioUrl!.isEmpty) return;
    try {
      await _localPlayer.play(UrlSource(widget.audioUrl!));
    } catch (_) {}
  }

  Future<void> _stopLocalAudio() async {
    try {
      await _localPlayer.stop();
    } catch (_) {}
  }

  // ── Like status (persisted across navigation) ──────────────────────────────

  Future<void> _checkLikeStatus() async {
    try {
      final (code, data) = await _engagementService.checkTrackLikeStatus(
        trackId: widget.itemId,
      );
      if (code == 200 && data is Map && mounted) {
        setState(() => _isLiked = data['liked'] as bool? ?? _isLiked);
      }
    } catch (_) {}
  }

  void _toggleLike() {
    final bool prevLiked = _isLiked;
    final int prevCount = _likeCount;
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    _engagementService.toggleTrackLike(trackId: widget.itemId).then((result) {
      final (code, data) = result;
      if (code == 200 && data is Map && mounted) {
        setState(() {
          _isLiked = data['liked'] as bool? ?? _isLiked;
          _likeCount = data['numOfLikes'] as int? ?? _likeCount;
        });
      } else if (code != 200 && mounted) {
        setState(() {
          _isLiked = prevLiked;
          _likeCount = prevCount;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to update like')));
      }
    });
  }

  // ── Comment count ──────────────────────────────────────────────────────────

  Future<void> _fetchCommentCount() async {
    try {
      final count = await _engagementService.getTrackCommentCount(
        widget.itemId,
      );
      if (mounted) setState(() => _commentCount = count);
    } catch (_) {}
  }

  Future<void> _openComments(BuildContext context) async {
    await Navigator.pushNamed(
      context,
      EngagementSocialInteractionsRoutes.comments,
      arguments: {
        'trackId': widget.itemId,
        'trackTitle': widget.displayName,
        'trackArtist': widget.actorName,
        'trackThumbnailUrl': widget.imgLink,
        'currentPositionSeconds': 0,
      },
    );
    if (mounted) _fetchCommentCount();
  }

  void _openLikers(BuildContext context) {
    Navigator.pushNamed(
      context,
      EngagementSocialInteractionsRoutes.likers,
      arguments: {'trackId': widget.itemId, 'initialTab': 0},
    );
  }

  // ── Track options sheet — feed variant ────────────────────────────────────

  void _openOptions(BuildContext context) {
    final track = PlaybackTrackModel(
      id: widget.itemId,
      title: widget.displayName,
      artistName: widget.actorName,
      audioUrl: widget.audioUrl,
      artworkUrl: widget.imgLink,
      artistId: widget.actorId.isNotEmpty ? widget.actorId : null,
    );
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrackOptionsSheet(
        track: track,
        variant: TrackOptionsVariant.feedTrack,
        onBehindThisTrack: () => Navigator.of(
          context,
          rootNavigator: true,
        ).push(
          MaterialPageRoute<void>(
            builder: (_) => BehindTheTrackScreen(
              trackId: track.id,
              actorName: track.artistName,
              actorAvatarUrl: track.artworkUrl ?? '',
              actorUserId: track.artistId ?? '',
              activityType: 'new_track',
              trackOwnerId: track.artistId ?? '',
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}K';
    }
    return count.toString();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Background (blurred cover art) ─────────────────────────────────
        _buildBackground(),

        // ── Cover image centered ────────────────────────────────────────────
        _buildCoverImage(),

        // ── "Tap to preview" overlay (shown until audio started) ───────────
        if (widget.isCurrent && !_hasStartedPreview)
          _buildTapToPreviewOverlay(),

        // ── Mute/unmute button ─────────────────────────────────────────────
        if (widget.isCurrent) _buildMuteButton(),

        // ── Options button (top right, below tab bar) ──────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 52,
          right: 12,
          child: GestureDetector(
            onTap: () => _openOptions(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.more_horiz,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),

        // ── Right-side action column ────────────────────────────────────────
        Positioned(right: 12, bottom: 140, child: _buildActionColumn(context)),

        // ── Bottom info bar ─────────────────────────────────────────────────
        Positioned(
          left: 0,
          right: 64,
          bottom: 0,
          child: _buildBottomInfo(context),
        ),
      ],
    );
  }

  Widget _buildBackground() {
    if (widget.imgLink != null && widget.imgLink!.isNotEmpty) {
      return Image.network(
        widget.imgLink!,
        fit: BoxFit.cover,
        errorBuilder: (ctx, e, st) => Container(color: AppColors.surfaceDark),
      );
    }
    return Container(color: AppColors.surfaceDark);
  }

  Widget _buildCoverImage() {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: widget.imgLink != null && widget.imgLink!.isNotEmpty
              ? Image.network(
                  widget.imgLink!,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, e, st) =>
                      Container(color: AppColors.cardDark),
                )
              : Container(
                  color: AppColors.cardDark,
                  child: Icon(
                    Icons.music_note,
                    size: 64,
                    color: AppColors.white54,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTapToPreviewOverlay() {
    return GestureDetector(
      onTap: () {
        setState(() => _hasStartedPreview = true);
        // Start local audio immediately if already unmuted
        if (!widget.isMuted.value && widget.audioUrl != null) {
          _startLocalAudio();
        }
      },
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const AspectRatio(
            aspectRatio: 1,
            child: Center(
              child: Text(
                'Tap to preview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMuteButton() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.42,
      left: MediaQuery.of(context).size.width / 2 - 24,
      child: ValueListenableBuilder<bool>(
        valueListenable: widget.isMuted,
        builder: (context, muted, _) {
          return GestureDetector(
            onTap: () => widget.isMuted.value = !muted,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(
                muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionColumn(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Like ──────────────────────────────────────────────────
        GestureDetector(
          onTap: _toggleLike,
          child: Column(
            children: [
              Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.orange : Colors.white,
                size: 32,
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _openLikers(context),
                child: Text(
                  _formatCount(_likeCount),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Comments ───────────────────────────────────────────────
        GestureDetector(
          onTap: () => _openComments(context),
          child: Column(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: 30,
              ),
              const SizedBox(height: 4),
              Text(
                _formatCount(_commentCount),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Add to playlist ────────────────────────────────────────
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add to playlist coming soon')),
            );
          },
          child: const Column(
            children: [Icon(Icons.playlist_add, color: Colors.white, size: 30)],
          ),
        ),
        const SizedBox(height: 24),

        // ── Play button → stops local audio, opens global mini-player ──
        GestureDetector(
          onTap: () {
            _stopLocalAudio();
            widget.onPlayTap();
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.black,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          GestureDetector(
            onTap: widget.onActorTap,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.tileDark,
                  child: Icon(Icons.person, size: 16, color: AppColors.white54),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.actorName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.isFollowing)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white54),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Following',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),

                if (widget.isRepost) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.repeat, color: Colors.white70, size: 14),
                  const SizedBox(width: 2),
                  const Text(
                    'Repost',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
