import 'package:flutter/material.dart';
import 'package:cross_team5/core/navigation/profile_navigator.dart';
import 'package:cross_team5/features/activity/screens/track_options_sheet.dart';
import 'package:cross_team5/features/user_profile_social_identity/services/user_profile_service.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/engagement_social_interactions/engagement_social_interactions.dart';
import 'package:cross_team5/features/followers_social_graph/followers_social_graph.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/playback_streaming_engine_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/playback_track_api_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/mini_player_state.dart';
import 'package:cross_team5/features/playback_streaming_engine/mini_player_state.dart';
import 'package:cross_team5/features/playback_streaming_engine/mini_player_state.dart';
import 'package:cross_team5/features/playback_streaming_engine/mini_player_state.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

class BehindTheTrackScreen extends StatefulWidget {
  final String trackId;
  final String actorName;
  final String actorAvatarUrl;
  final String actorUserId;
  final String activityType;
  final String trackOwnerId;

  const BehindTheTrackScreen({
    super.key,
    required this.trackId,
    required this.actorName,
    required this.actorAvatarUrl,
    required this.actorUserId,
    required this.activityType,
    required this.trackOwnerId,
  });

  @override
  State<BehindTheTrackScreen> createState() => _BehindTheTrackScreenState();
}

class _BehindTheTrackScreenState extends State<BehindTheTrackScreen> {
  final _trackApi = PlaybackTrackApiService();
  final _engagementApi = EngagementApiService();

  PlaybackTrackModel? _track;
  bool _loading = true;
  String? _error;

  // ── Exact same like pattern as _ExpandedEngagementBarState ──
  bool _isLiked = false;
  bool _isLikeLoading = false;
  late int _likeCount = 0;
  int _commentCount = 0;
  int _repostCount = 0;

  String? _ownerDisplayName;
  String? _ownerAvatarUrl;
  String? _ownerCity;
  String? _ownerCountry;
  bool _ownerIsFollowed = false;
  bool _isOwnerFollowLoading = false;

  bool _isReposted = false;
  String? _currentUserId;

  bool get _isCurrentlyPlaying {
    final svc = PlaybackStreamingEngineService.shared;
    return svc.state.currentTrack?.id == _track?.id && svc.state.isPlaying;
  }

  @override
  void initState() {
    super.initState();
    PlaybackStreamingEngineService.shared.addListener(_onPlayerUpdate);
    _loadTrack();
  }

  void _onPlayerUpdate() => setState(() {});

  @override
  void dispose() {
    PlaybackStreamingEngineService.shared.removeListener(_onPlayerUpdate);
    super.dispose();
  }

  Future<void> _loadTrack() async {
    try {
      final track = await _trackApi.getSingleTrackById(widget.trackId);
      if (mounted) {
        setState(() {
          _track = track;
          _likeCount = track.numLikes;
          _commentCount = track.numComments;
          _repostCount = track.numReposts;
          _loading = false;
        });
        _checkLikeStatus();
        _checkRepostStatus();
        _fetchOwnerProfile();
        final uid = await AuthApiService().getStoredUserId();
        if (mounted) setState(() => _currentUserId = uid);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchOwnerProfile() async {
    final ownerId = widget.trackOwnerId;
    if (ownerId.isEmpty) return;
    try {
      final token = await AuthApiService().getStoredAccessToken();
      if (token == null || !mounted) return;
      final profile = await UserProfileService().getUserProfile(ownerId, token);
      if (!mounted) return;
      setState(() {
        _ownerDisplayName = profile.displayName.trim().isEmpty
            ? null
            : profile.displayName.trim();
        _ownerAvatarUrl = profile.profileImgLink.trim().isEmpty
            ? null
            : profile.profileImgLink.trim();
        _ownerCity = profile.city.trim().isEmpty ? null : profile.city.trim();
        _ownerCountry = profile.country.trim().isEmpty
            ? null
            : profile.country.trim();
        _ownerIsFollowed = profile.isFollowed;
      });
    } catch (_) {}
  }

  Future<void> _checkLikeStatus() async {
    try {
      final result = await _engagementApi.checkTrackLikeStatus(
        trackId: widget.trackId,
      );
      if (!mounted) return;
      if (result.$1 == 200 && result.$2 is Map<String, dynamic>) {
        final data = result.$2 as Map<String, dynamic>;
        setState(() => _isLiked = data['liked'] as bool? ?? false);
      }
    } catch (_) {}
  }

  Future<void> _checkRepostStatus() async {
    try {
      final result = await _engagementApi.getTrackRepostStatus(
        trackId: widget.trackId,
      );
      if (!mounted) return;
      if (result.$1 == 200 && result.$2 is RepostStatus) {
        setState(() => _isReposted = (result.$2 as RepostStatus).reposted);
      }
    } catch (_) {}
  }

  Future<void> _openRepostSheet() async {
    final track = _track;
    if (track == null) return;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RepostBottomSheet(
        trackId: track.id,
        title: track.title,
        artist: track.artistName,
        thumbnailUrl: track.artworkUrl,
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

  // ── Exact same pattern as _ExpandedEngagementBarState._toggleLike ──
  Future<void> _toggleLike() async {
    if (_isLikeLoading) return;
    final wasLiked = _isLiked;
    final wasCount = _likeCount;
    setState(() {
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? wasCount + 1 : wasCount - 1;
      _isLikeLoading = true;
    });

    final result = await _engagementApi.toggleTrackLike(
      trackId: widget.trackId,
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

  // ── Exact same pattern as _ExpandedEngagementBarState._openCommentsScreen ──
  Future<void> _openComments() async {
    final track = _track;
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => CommentsScreen(
          trackId: widget.trackId,
          trackTitle: track?.title ?? '',
          trackArtist: track?.artistName ?? '',
          trackThumbnailUrl: track?.artworkUrl,
          currentPositionSeconds: 0,
        ),
      ),
    );
    if (!mounted) return;
    try {
      final refreshed = await _trackApi.getSingleTrackById(widget.trackId);
      if (mounted) {
        setState(() {
          _commentCount = refreshed.numComments;
          _likeCount = refreshed.numLikes;
          _repostCount = refreshed.numReposts;
        });
      }
    } catch (_) {}
  }

  Future<void> _navigateToArtist() async {
    final ownerId = widget.trackOwnerId;
    if (ownerId.isEmpty) return;
    await ProfileNavigator.push(context, ownerId);
  }

  Future<void> _navigateToActor() async {
    await ProfileNavigator.push(context, widget.actorUserId);
  }

  Future<void> _toggleOwnerFollow() async {
    if (_isOwnerFollowLoading) return;
    final wasFollowing = _ownerIsFollowed;
    setState(() {
      _ownerIsFollowed = !wasFollowing;
      _isOwnerFollowLoading = true;
    });
    final result = wasFollowing
        ? await SocialApiService().unfollowUser(
            targetUserId: widget.trackOwnerId,
          )
        : await SocialApiService().followUser(
            targetUserId: widget.trackOwnerId,
          );
    if (!mounted) return;
    if (result.$1 < 200 || result.$1 >= 300) {
      setState(() {
        _ownerIsFollowed = wasFollowing;
        _isOwnerFollowLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.$2.toString())));
      return;
    }
    setState(() => _isOwnerFollowLoading = false);
  }

  void _playTrack() {
    final track = _track;
    if (track == null) return;
    final svc = PlaybackStreamingEngineService.shared;
    if (svc.state.currentTrack?.id == track.id) {
      if (svc.state.isPlaying) {
        svc.pause();
      } else {
        svc.resume();
      }
    } else {
      svc.playTrack(track);
    }
  }

  Future<void> _openTrackOptions() async {
    final track = _track;
    if (track == null) return;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrackOptionsSheet(track: track),
    );
    if (!mounted) return;
    _checkLikeStatus();
    try {
      final refreshed = await _trackApi.getSingleTrackById(widget.trackId);
      if (mounted) {
        setState(() {
          _likeCount = refreshed.numLikes;
          _repostCount = refreshed.numReposts;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _track?.title ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryOrange,
                strokeWidth: 2,
              ),
            )
          : _error != null
              ? _buildError()
              : _buildBody(),
      bottomNavigationBar: const MiniPlayerSpacer(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.white38,
            size: 42,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _loadTrack,
            child: const Text(
              'Try again',
              style: TextStyle(
                color: AppColors.primaryOrange,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final track = _track!;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTrackCard(track),
          _buildActorRow(),
          _buildActionRow(),
          if (track.tags.isNotEmpty) _buildTags(track.tags),
          Divider(color: AppColors.containerMid, height: 1),
          const SizedBox(height: 16),
          _buildArtistCard(track),
          const SizedBox(height: 24),
          _buildFanLeaderboard(),
          const SizedBox(height: 24),
          _buildInPlaylists(),
        ],
      ),
    );
  }

  Widget _buildTags(List<String> tags) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags
            .map(
              (tag) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '# $tag',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildFanLeaderboard() {
    // Hardcoded visual — no API yet
    final fans = [
      ('Ahmed Mekawy', '29 plays', null),
      ('joshy b', '22 plays', null),
      ('Fizza Shiekh', '16 plays', null),
      ('Zenza86', '15 plays', null),
      ('Sachin Kumar', '14 plays', null),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Fan leaderboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.info_outline_rounded,
                color: Colors.white38,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Top / First toggle (visual only)
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.inputFill,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Top',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          child: const Text(
                            'First',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Fans who have played this track the most.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
                ...fans.asMap().entries.map((e) {
                  final idx = e.key;
                  final (name, plays, _) = e.value;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${idx + 1}.',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.tileDark5,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          plays,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInPlaylists() {
    // Hardcoded visual — no API yet
    final playlists = [
      ('Personal Faves XX !', 'MUSIC AFiCi...'),
      ('Tracks 🔥🔥🔥', 'Hossam Moh'),
      ('Saveme', 'User 578913'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'In Playlists',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: playlists.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final (name, owner) = playlists[i];
                return SizedBox(
                  width: 110,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 110,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.queue_music_rounded,
                          color: AppColors.tileDark5,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        owner,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackCard(PlaybackTrackModel track) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: track.artworkUrl != null && track.artworkUrl!.isNotEmpty
                ? Image.network(
                    track.artworkUrl!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _artworkPlaceholder(),
                  )
                : _artworkPlaceholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _ownerDisplayName ?? track.artistName,
                  style: TextStyle(color: AppColors.greyMuted, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildStats(track),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _artworkPlaceholder() {
    return Container(
      width: 100,
      height: 100,
      color: AppColors.surface,
      alignment: Alignment.center,
      child: Icon(
        Icons.graphic_eq_rounded,
        color: AppColors.tileDark5,
        size: 36,
      ),
    );
  }

  Widget _buildStats(PlaybackTrackModel track) {
    final parts = <String>[];
    parts.add('▶ ${_fmt(track.numPlays)}');
    if (track.duration != null) parts.add(_fmtDuration(track.duration!));
    if (track.releaseDate != null) parts.add(_fmtDate(track.releaseDate!));
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      style: TextStyle(color: AppColors.greyMid, fontSize: 12),
    );
  }

  Widget _buildActorRow() {
    final isLike = widget.activityType == 'track_liked';
    return InkWell(
      onTap: _navigateToActor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.containerMid,
              backgroundImage: widget.actorAvatarUrl.isNotEmpty
                  ? NetworkImage(widget.actorAvatarUrl)
                  : null,
              child: widget.actorAvatarUrl.isEmpty
                  ? Text(
                      widget.actorName.isNotEmpty
                          ? widget.actorName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            RichText(
              text: TextSpan(
                style: TextStyle(color: AppColors.greyIcon, fontSize: 14),
                children: [
                  TextSpan(text: isLike ? 'Liked by ' : 'Reposted by '),
                  TextSpan(
                    text: widget.actorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Row(
        children: [
          // Like — same icon/color logic as global overlay
          GestureDetector(
            onTap: _isLikeLoading ? null : _toggleLike,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(
                  _isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _isLiked ? Colors.orange : Colors.white70,
                  size: 22,
                ),
                const SizedBox(width: 5),
                Text(
                  '$_likeCount',
                  style: TextStyle(
                    color: _isLiked ? Colors.orange : Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Comment
          GestureDetector(
            onTap: _openComments,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.white70,
                  size: 22,
                ),
                const SizedBox(width: 5),
                Text(
                  '$_commentCount',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Repost
          GestureDetector(
            onTap: _openRepostSheet,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(
                  Icons.repeat_rounded,
                  color: _isReposted ? AppColors.primaryOrange : Colors.white70,
                  size: 22,
                ),
                const SizedBox(width: 5),
                Text(
                  '$_repostCount',
                  style: TextStyle(
                    color: _isReposted
                        ? AppColors.primaryOrange
                        : Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          GestureDetector(
            onTap: _openTrackOptions,
            behavior: HitTestBehavior.opaque,
            child: const Icon(
              Icons.more_horiz_rounded,
              color: Colors.white70,
              size: 22,
            ),
          ),
          const Spacer(),
          // Play
          GestureDetector(
            onTap: _playTrack,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                _isCurrentlyPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.black,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistCard(PlaybackTrackModel track) {
    final displayName = _ownerDisplayName ?? track.artistName;
    final location = [_ownerCity, _ownerCountry].whereType<String>().join(', ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _navigateToArtist,
            child: CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.containerMid,
              backgroundImage: _ownerAvatarUrl != null
                  ? NetworkImage(_ownerAvatarUrl!)
                  : null,
              child: _ownerAvatarUrl == null
                  ? Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _navigateToArtist,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (location.isNotEmpty)
                    Text(
                      location,
                      style: TextStyle(color: AppColors.greyMid2, fontSize: 13),
                    ),
                ],
              ),
            ),
          ),
          if (_currentUserId != widget.trackOwnerId) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isOwnerFollowLoading ? null : _toggleOwnerFollow,
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _ownerIsFollowed
                      ? AppColors.containerMid
                      : AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: _isOwnerFollowLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _ownerIsFollowed ? 'Following' : 'Follow',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _fmtDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
