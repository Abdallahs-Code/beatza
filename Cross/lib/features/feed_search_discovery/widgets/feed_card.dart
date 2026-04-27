// Widget: FeedCard
// Full-screen TikTok-style feed card for a single feed item.
//
// Behaviour (matches SoundCloud screenshots in module_8_screens.pdf):
//   - Displays track cover image full-screen with blurred background
//   - "Tap to preview" overlay shown until audio starts
//   - Mute/unmute button on top of image (starts MUTED)
//   - Auto-plays audio when this card becomes active (isCurrent == true)
//   - Auto-stops audio when no longer current
//   - Tapping the play button (▶) navigates to the mini player card via
//     PlaybackStreamingEngineService.shared.playTrack(fullTrack) —
//     the feed screen must fetch full track details first (see FeedScreen)
//   - Right-side action column: ❤️ likes, 💬 comments, ➕ add-to-queue
//   - Bottom: poster avatar + name, "Following" chip, track title
//
// Integration notes:
//   - Like button wired to EngagementApiService.toggleTrackLike (optimistic UI)
//   - Comment icon navigates to EngagementSocialInteractionsRoutes.comments
//   - Add (➕) navigates to EngagementSocialInteractionsRoutes.likers with
//     initialTab: 1 (reposts) — TODO: wire to "add to playlist" when Module 7
//     playlist routes are available; for now opens reposts tab as placeholder.
//
// CLAUDE CODE TODO (engagement wiring):
//   1. Import EngagementApiService and call toggleTrackLike(trackId) on heart tap
//   2. Optimistic: flip _isLiked, adjust _likeCount, revert on failure + snackbar
//   3. Comment icon: Navigator.pushNamed(context,
//        EngagementSocialInteractionsRoutes.comments,
//        arguments: {
//          'trackId': widget.itemId,
//          'trackTitle': widget.displayName,
//          'trackArtist': widget.actorName,
//          'trackThumbnailUrl': widget.imgLink,
//          'currentPositionSeconds': 0,
//        })
//   4. Like count tap: Navigator.pushNamed(context,
//        EngagementSocialInteractionsRoutes.likers,
//        arguments: {'trackId': widget.itemId, 'initialTab': 0})

import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/engagement_social_interactions/services/engagement_api_service.dart';
import 'package:cross_team5/features/engagement_social_interactions/engagement_social_interactions_routes.dart';

class FeedCard extends StatefulWidget {
  /// The feed item ID (used for engagement calls).
  final String itemId;

  /// Whether this card is the currently visible card in the PageView.
  final bool isCurrent;

  /// Global mute state shared across all cards (ValueNotifier).
  final ValueNotifier<bool> isMuted;

  /// URL of the audio stream — null if not yet fetched.
  final String? audioUrl;

  /// Cover image URL.
  final String? imgLink;

  /// Track title / display name.
  final String displayName;

  /// The person who posted (actor display name).
  final String actorName;

  /// Actor user ID — used to navigate to their profile.
  final String actorId;

  /// Whether the current user follows this actor.
  final bool isFollowing;

  /// Initial like count.
  final int likeCount;

  /// Initial comment count.
  final int commentCount;

  /// Whether the current user has liked this item.
  final bool isLiked;

  /// Whether this item is a repost.
  final bool isRepost;

  /// Called when the user taps the ▶ play button.
  /// The feed screen fetches full track details and hands them to the player.
  final VoidCallback onPlayTap;

  /// Called when the user taps the poster avatar/name → profile screen.
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

  // Optimistic like state
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _likeCount = widget.likeCount;
  }

  @override
  void didUpdateWidget(FeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isCurrent && oldWidget.isCurrent) {
      // Card scrolled away — reset preview state
      setState(() => _hasStartedPreview = false);
    }
  }

  void _toggleLike() {
    final bool prevLiked = _isLiked;
    final int prevCount = _likeCount;
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    _engagementService
        .toggleTrackLike(trackId: widget.itemId)
        .then((result) {
      final (code, _) = result;
      if (code != 200 && mounted) {
        setState(() {
          _isLiked = prevLiked;
          _likeCount = prevCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update like')),
        );
      }
    });
  }

  void _openComments(BuildContext context) {
    Navigator.pushNamed(
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
  }

  void _openLikers(BuildContext context) {
    Navigator.pushNamed(
      context,
      EngagementSocialInteractionsRoutes.likers,
      arguments: {'trackId': widget.itemId, 'initialTab': 0},
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}K';
    }
    return count.toString();
  }

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

        // ── Mute/unmute button (top center of image area) ──────────────────
        if (widget.isCurrent) _buildMuteButton(),

        // ── Right-side action column ────────────────────────────────────────
        Positioned(
          right: 12,
          bottom: 140,
          child: _buildActionColumn(context),
        ),

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
        errorBuilder: (_, __, ___) =>
            Container(color: AppColors.surfaceDark),
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
                color: Colors.black.withOpacity(0.5),
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
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppColors.cardDark),
                )
              : Container(
                  color: AppColors.cardDark,
                  child: const Icon(
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
        // Audio auto-play is handled by the parent FeedScreen via isCurrent
        // The parent listens to page changes and triggers playback accordingly
      },
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
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
      // Positioned over the center of the cover art, near bottom of image
      top: MediaQuery.of(context).size.height * 0.42,
      left: MediaQuery.of(context).size.width / 2 - 24,
      child: ValueListenableBuilder<bool>(
        valueListenable: widget.isMuted,
        builder: (context, muted, _) {
          return GestureDetector(
            onTap: () => widget.isMuted.value = !muted,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
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
                _formatCount(widget.commentCount),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Add to playlist / repost ───────────────────────────────
        GestureDetector(
          // CLAUDE CODE TODO: wire to "add to playlist" sheet from Module 7
          // For now, show a repost bottom sheet or a snackbar placeholder
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add to playlist coming soon')),
            );
          },
          child: const Column(
            children: [
              Icon(Icons.playlist_add, color: Colors.white, size: 30),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Play button → navigate to full player ──────────────────
        GestureDetector(
          onTap: widget.onPlayTap,
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
          // Track title
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

          // Actor row
          GestureDetector(
            onTap: widget.onActorTap,
            child: Row(
              children: [
                // Avatar placeholder
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.tileDark,
                  child: const Icon(
                    Icons.person,
                    size: 16,
                    color: AppColors.white54,
                  ),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  const Icon(
                    Icons.repeat,
                    color: Colors.white70,
                    size: 14,
                  ),
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
