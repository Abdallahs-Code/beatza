















import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/engagement_social_interactions/services/engagement_api_service.dart';
import 'package:cross_team5/features/engagement_social_interactions/engagement_social_interactions_routes.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/features/activity/screens/behind_the_track_screen.dart';
import 'package:cross_team5/features/activity/screens/track_options_sheet.dart';
import '../services/feed_search_api_service.dart';

class FeedCard extends StatefulWidget {
  final String itemId;
  final bool isCurrent;
  final ValueNotifier<bool> isMuted;
  final String? audioUrl;
  final String? imgLink;
  final String displayName;
  final String actorName;
  final String actorId;
  final String? permalink;
  final String? actorAvatarUrl;
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
    this.permalink,
    this.actorAvatarUrl,
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
  
  static final Map<String, bool> _likedCache = {};
  static final Map<String, int> _likeCountCache = {};
  static final Map<String, int> _commentCountCache = {};

  bool _hasStartedPreview = false;

  final EngagementApiService _engagementService = EngagementApiService();
  final AudioPlayer _localPlayer = AudioPlayer();

  late bool _isLiked;
  late int _likeCount;
  late int _commentCount;

  
  Duration _previewPosition = Duration.zero;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<void>? _completeSub;
  StreamSubscription<Duration>? _durationSub;
  bool _isSeeking = false;
  Duration? _trackDuration;

  @override
  void initState() {
    super.initState();
    
    _isLiked = _likedCache[widget.itemId] ?? widget.isLiked;
    _likeCount = _likeCountCache[widget.itemId] ?? widget.likeCount;
    _commentCount = _commentCountCache[widget.itemId] ?? widget.commentCount;

    _localPlayer.setReleaseMode(ReleaseMode.stop);
    widget.isMuted.addListener(_onMuteChanged);
    _checkLikeStatus();
    
    
  }

  @override
  void didUpdateWidget(FeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    
    if (!widget.isCurrent && oldWidget.isCurrent) {
      setState(() => _hasStartedPreview = false);
      _stopLocalAudio();
    }

    
    if (widget.isCurrent && !oldWidget.isCurrent) {
      _checkLikeStatus();
    }
  }

  @override
  void dispose() {
    widget.isMuted.removeListener(_onMuteChanged);
    _positionSub?.cancel();
    _completeSub?.cancel();
    _durationSub?.cancel();
    _localPlayer.dispose();
    super.dispose();
  }

  

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
      
      _durationSub?.cancel();
      _durationSub = _localPlayer.onDurationChanged.listen((d) {
        if (mounted && d.inMilliseconds > 0) {
          setState(() => _trackDuration = d);
        }
      });

      await _localPlayer.play(UrlSource(widget.audioUrl!));

      
      _positionSub?.cancel();
      _positionSub = _localPlayer.onPositionChanged.listen(_onPositionChanged);

      
      _completeSub?.cancel();
      _completeSub = _localPlayer.onPlayerComplete.listen((_) async {
        if (!mounted) return;
        setState(() => _previewPosition = Duration.zero);
        await _localPlayer.play(UrlSource(widget.audioUrl!));
      });
    } catch (_) {}
  }

  void _onPositionChanged(Duration pos) {
    if (!mounted || _isSeeking) return;
    
    final bool longTrack =
        _trackDuration == null || _trackDuration!.inMilliseconds >= 20000;
    if (longTrack && pos.inSeconds >= 20) {
      _isSeeking = true;
      setState(() => _previewPosition = Duration.zero);
      _localPlayer.seek(Duration.zero).then((_) => _isSeeking = false);
    } else {
      setState(() => _previewPosition = pos);
    }
  }

  Future<void> _stopLocalAudio() async {
    _positionSub?.cancel();
    _positionSub = null;
    _completeSub?.cancel();
    _completeSub = null;
    _durationSub?.cancel();
    _durationSub = null;
    _isSeeking = false;
    _trackDuration = null;
    if (mounted) setState(() => _previewPosition = Duration.zero);
    try {
      await _localPlayer.stop();
    } catch (_) {}
  }

  

  Future<void> _checkLikeStatus() async {
    try {
      final (code, data) = await _engagementService.checkTrackLikeStatus(
        trackId: widget.itemId,
      );
      if (code == 200 && data is Map && mounted) {
        final liked = data['liked'] as bool? ?? _isLiked;
        
        final count = data['numOfLikes'] as int?;
        setState(() {
          _isLiked = liked;
          if (count != null) _likeCount = count;
        });
        _likedCache[widget.itemId] = _isLiked;
        if (count != null) _likeCountCache[widget.itemId] = _likeCount;
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
    _likedCache[widget.itemId] = _isLiked;
    _likeCountCache[widget.itemId] = _likeCount;

    _engagementService.toggleTrackLike(trackId: widget.itemId).then((result) {
      final (code, data) = result;
      if (code == 200 && data is Map && mounted) {
        setState(() {
          _isLiked = data['liked'] as bool? ?? _isLiked;
          _likeCount = data['numOfLikes'] as int? ?? _likeCount;
        });
        _likedCache[widget.itemId] = _isLiked;
        _likeCountCache[widget.itemId] = _likeCount;
      } else if (code != 200 && mounted) {
        setState(() {
          _isLiked = prevLiked;
          _likeCount = prevCount;
        });
        _likedCache[widget.itemId] = prevLiked;
        _likeCountCache[widget.itemId] = prevCount;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update like')),
        );
      }
    });
  }

  
  

  Future<void> _fetchCommentCount() async {
    try {
      final (code, data) = await FeedSearchApiService().getTrackById(
        widget.itemId,
      );
      if (code == 200 && data is Map<String, dynamic> && mounted) {
        final count = data['numComments'] as int? ?? _commentCount;
        setState(() => _commentCount = count);
        _commentCountCache[widget.itemId] = count;
      }
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
        'syncWithPlayer': false, 
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

  

  void _openOptions(BuildContext context) {
    debugPrint('[FeedCard._openOptions] itemId="${widget.itemId}"  permalink="${widget.permalink}"  actorId="${widget.actorId}"');
    final track = PlaybackTrackModel(
      id: widget.itemId,
      title: widget.displayName,
      artistName: widget.actorName,
      audioUrl: widget.audioUrl,
      artworkUrl: widget.imgLink,
      artistId: widget.actorId.isNotEmpty ? widget.actorId : null,
      permalink: widget.permalink,
    );
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrackOptionsSheet(
        track: track,
        variant: TrackOptionsVariant.feedTrack,
        onBehindThisTrack: () =>
            Navigator.of(context, rootNavigator: true).push(
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
        _buildBackground(),
        _buildCoverImage(),

        if (widget.isCurrent && !_hasStartedPreview)
          _buildTapToPreviewOverlay(),

        if (widget.isCurrent) _buildMuteButton(),

        Positioned(right: 12, bottom: 90, child: _buildActionColumn(context)),

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
                color: AppColors.pureBlack.withValues(alpha: 0.5),
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
        if (!widget.isMuted.value && widget.audioUrl != null) {
          _startLocalAudio();
        }
      },
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: AppColors.pureBlack.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: Center(
              child: Text(
                'Tap to preview',
                style: TextStyle(
                  color: AppColors.whiteSmoke,
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
                color: AppColors.whiteSmoke,
                size: 22,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionColumn(BuildContext context) {
    final int ringCapMs =
        (_trackDuration != null && _trackDuration!.inMilliseconds < 20000)
            ? _trackDuration!.inMilliseconds
            : 20000;
    final double ringProgress = ringCapMs > 0
        ? (_previewPosition.inMilliseconds / ringCapMs).clamp(0.0, 1.0)
        : 0.0;
    final bool showRing = _hasStartedPreview && !widget.isMuted.value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        
        GestureDetector(
          onTap: () => _openOptions(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.more_horiz,
              color: AppColors.whiteSmoke,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 20),

        
        GestureDetector(
          onTap: _toggleLike,
          child: Column(
            children: [
              Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? AppColors.primaryOrange : AppColors.whiteSmoke,
                size: 32,
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _openLikers(context),
                child: Text(
                  _formatCount(_likeCount),
                  style: TextStyle(color: AppColors.whiteSmoke, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        
        GestureDetector(
          onTap: () => _openComments(context),
          child: Column(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.whiteSmoke,
                size: 30,
              ),
              const SizedBox(height: 4),
              Text(
                _formatCount(_commentCount),
                style: TextStyle(color: AppColors.whiteSmoke, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add to playlist coming soon')),
            );
          },
          child: Column(
            children: [
              Icon(Icons.playlist_add, color: AppColors.whiteSmoke, size: 30),
            ],
          ),
        ),
        const SizedBox(height: 24),

        
        GestureDetector(
          onTap: () {
            _stopLocalAudio();
            widget.onPlayTap();
          },
          child: SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: showRing ? ringProgress : 0.0,
                    strokeWidth: 3,
                    valueColor: const AlwaysStoppedAnimation(Colors.orange),
                    backgroundColor: Colors.white24,
                  ),
                ),
                
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.whiteSmoke,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.black,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [AppColors.pureBlack.withValues(alpha: 0.87), AppColors.transparent],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.displayName,
            style: TextStyle(
              color: AppColors.whiteSmoke,
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
                  backgroundImage: (widget.actorAvatarUrl != null &&
                          widget.actorAvatarUrl!.isNotEmpty)
                      ? NetworkImage(widget.actorAvatarUrl!)
                      : null,
                  child: (widget.actorAvatarUrl == null ||
                          widget.actorAvatarUrl!.isEmpty)
                      ? Icon(Icons.person, size: 16, color: AppColors.white54)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.actorName,
                  style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.isRepost) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.repeat, color: AppColors.white70, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    'Reposted by',
                    style: TextStyle(color: AppColors.white70, fontSize: 12),
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
