import 'package:flutter/material.dart';
import 'package:cross_team5/features/activity/screens/track_options_sheet.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/engagement_social_interactions/engagement_social_interactions.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/playback_streaming_engine_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/playback_track_api_service.dart';
import 'package:cross_team5/features/user_profile_social_identity/user_profile_social_identity.dart';

const _kBg = Color(0xFF111111);
const _kSurface = Color(0xFF1C1C1C);
const _kOrange = Color(0xFFFF5500);

class BehindTheTrackScreen extends StatefulWidget {
  final String trackId;
  final String actorName;
  final String actorAvatarUrl;
  final String actorUserId;
  final String activityType;

  const BehindTheTrackScreen({
    super.key,
    required this.trackId,
    required this.actorName,
    required this.actorAvatarUrl,
    required this.actorUserId,
    required this.activityType,
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

  String? _artistCity;
  String? _artistCountry;

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
          _loading = false;
        });
        _checkLikeStatus();
        _fetchArtistLocation(track.artistId);
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

  Future<void> _fetchArtistLocation(String? artistId) async {
    if (artistId == null || artistId.isEmpty) return;
    try {
      final token = await AuthApiService().getStoredAccessToken();
      if (token == null || !mounted) return;
      final profile =
          await UserProfileService().getUserProfile(artistId, token);
      if (!mounted) return;
      setState(() {
        _artistCity = profile.city.trim().isEmpty ? null : profile.city.trim();
        _artistCountry =
            profile.country.trim().isEmpty ? null : profile.country.trim();
      });
    } catch (_) {}
  }

  // ── Exact same pattern as _ExpandedEngagementBarState._checkLikeStatus ──
  Future<void> _checkLikeStatus() async {
    try {
      final userId = await AuthApiService().getStoredUserId();
      if (userId == null || !mounted) return;
      final result = await _engagementApi.getTrackLikers(
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
    // Refresh comment count after returning, same as global overlay
    final result = await _engagementApi.getTrackComments(
      trackId: widget.trackId,
      limit: 100,
    );
    if (!mounted) return;
    if (result.$1 == 200 && result.$2 is List) {
      setState(() => _commentCount = (result.$2 as List).length);
    }
  }

  Future<void> _navigateToArtist() async {
    final artistId = _track?.artistId;
    if (artistId == null || artistId.isEmpty) return;
    final token = await AuthApiService().getStoredAccessToken() ?? '';
    final currentUserId = await AuthApiService().getStoredUserId();
    if (!mounted) return;
    Navigator.pushNamed(context, '/user_profile', arguments: {
      'userId': artistId,
      'token': token,
      'currentUserId': currentUserId,
    });
  }

  Future<void> _navigateToActor() async {
    final token = await AuthApiService().getStoredAccessToken() ?? '';
    final currentUserId = await AuthApiService().getStoredUserId();
    if (!mounted) return;
    Navigator.pushNamed(context, '/user_profile', arguments: {
      'userId': widget.actorUserId,
      'token': token,
      'currentUserId': currentUserId,
    });
  }

  void _playTrack() {
    final track = _track;
    if (track == null) return;
    final svc = PlaybackStreamingEngineService.shared;
    if (svc.state.currentTrack?.id == track.id && svc.state.isPlaying) {
      svc.pause();
    } else {
      svc.playTrack(track);
    }
  }

  void _openTrackOptions() {
    final track = _track;
    if (track == null) return;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrackOptionsSheet(track: track),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _track?.title ?? '',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: _kOrange, strokeWidth: 2))
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.white38, size: 42),
          const SizedBox(height: 16),
          Text(_error!,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _loadTrack,
            child: const Text('Try again',
                style: TextStyle(
                    color: _kOrange,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
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
          const Divider(color: Color(0xFF2A2A2A), height: 1),
          const SizedBox(height: 16),
          _buildArtistCard(track),
          const SizedBox(height: 16),
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
                Text(track.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(track.artistName,
                    style: const TextStyle(
                        color: Color(0xFF999999), fontSize: 14)),
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
      color: _kSurface,
      alignment: Alignment.center,
      child: const Icon(Icons.graphic_eq_rounded,
          color: Color(0xFF444444), size: 36),
    );
  }

  Widget _buildStats(PlaybackTrackModel track) {
    final parts = <String>[];
    if (track.numPlays > 0) parts.add('▶ ${_fmt(track.numPlays)}');
    if (track.duration != null) parts.add(_fmtDuration(track.duration!));
    if (track.releaseDate != null) parts.add(_fmtDate(track.releaseDate!));
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(parts.join(' · '),
        style: const TextStyle(color: Color(0xFF777777), fontSize: 12));
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
              backgroundColor: const Color(0xFF2A2A2A),
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
                          fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: Color(0xFFAAAAAA), fontSize: 14),
                children: [
                  TextSpan(text: isLike ? 'Liked by ' : 'Reposted by '),
                  TextSpan(
                    text: widget.actorName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
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
                      fontSize: 14),
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
                const Icon(Icons.chat_bubble_outline_rounded,
                    color: Colors.white70, size: 22),
                const SizedBox(width: 5),
                Text('$_commentCount',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: 24),
          GestureDetector(
            onTap: _openTrackOptions,
            behavior: HitTestBehavior.opaque,
            child: const Icon(Icons.more_horiz_rounded,
                color: Colors.white70, size: 22),
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
    return GestureDetector(
      onTap: _navigateToArtist,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFF2A2A2A),
              child: Text(
                track.artistName.isNotEmpty
                    ? track.artistName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(track.artistName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                if (track.genre != null && track.genre!.isNotEmpty ||
                    _artistCity != null ||
                    _artistCountry != null)
                  Text(
                    [
                      if (track.genre != null && track.genre!.isNotEmpty)
                        track.genre!,
                      if (_artistCity != null || _artistCountry != null)
                        [_artistCity, _artistCountry]
                            .whereType<String>()
                            .join(', '),
                    ].join(' · '),
                    style: const TextStyle(
                        color: Color(0xFF888888), fontSize: 13),
                  ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white38, size: 22),
          ],
        ),
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
