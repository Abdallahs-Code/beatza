import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/core/navigation/profile_navigator.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/engagement_social_interactions/engagement_social_interactions.dart';
import 'package:cross_team5/features/followers_social_graph/followers_social_graph.dart';
import 'package:cross_team5/features/messaging_track_sharing/screens/chat_screen.dart';
import 'package:cross_team5/features/messaging_track_sharing/screens/send_to_sheet.dart';
import 'package:cross_team5/features/messaging_track_sharing/services/messaging_api_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/playback_streaming_engine_service.dart';

enum TrackOptionsVariant { normalTrack, ownTrack, behindTrack, feedTrack }

class TrackOptionsSheet extends StatefulWidget {
  final PlaybackTrackModel track;
  final TrackOptionsVariant variant;

  /// Called when "Edit track" is tapped (ownTrack variant only).
  final VoidCallback? onEditTrack;

  /// Called when "Show me fewer posts like that" is tapped (feedTrack variant only).
  final VoidCallback? onShowFewerPosts;

  /// Called when "Switch to Classic feed" is tapped (feedTrack variant only).
  final VoidCallback? onSwitchToClassicFeed;

  /// Called when "Behind this track" is tapped. Sheet pops itself first,
  /// then invokes this callback so the caller handles navigation.
  final VoidCallback? onBehindThisTrack;

  const TrackOptionsSheet({
    super.key,
    required this.track,
    this.variant = TrackOptionsVariant.normalTrack,
    this.onEditTrack,
    this.onShowFewerPosts,
    this.onSwitchToClassicFeed,
    this.onBehindThisTrack,
  });

  @override
  State<TrackOptionsSheet> createState() => _TrackOptionsSheetState();
}

class _TrackOptionsSheetState extends State<TrackOptionsSheet> {
  final _engagementApi = EngagementApiService();

  bool _isLiked = false;
  bool _isLikeLoading = false;
  bool _isReposted = false;
  late int _repostCount;

  List<({String receiverId, String name, String photoUrl})> _recentContacts =
      [];
  String? _trackPermalink;

  bool get _hasSendTo => widget.variant != TrackOptionsVariant.feedTrack;
  bool get _hasRepost => widget.variant != TrackOptionsVariant.ownTrack;
  bool get _hasGoToProfile => widget.variant != TrackOptionsVariant.ownTrack;
  bool get _hasReport => widget.variant != TrackOptionsVariant.ownTrack;
  bool get _hasBehindThisTrack =>
      widget.variant != TrackOptionsVariant.behindTrack;
  bool get _hasStartStation => widget.variant != TrackOptionsVariant.feedTrack;
  bool get _hasEditTrack => widget.variant == TrackOptionsVariant.ownTrack;
  bool get _hasFeedOptions => widget.variant == TrackOptionsVariant.feedTrack;

  @override
  void initState() {
    super.initState();
    _repostCount = widget.track.numReposts;
    _checkLikeStatus();
    if (_hasRepost) _checkRepostStatus();
    if (_hasSendTo) _loadSendToData();
  }

  Future<void> _loadSendToData() async {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('[SendTo] STEP 0 — _loadSendToData() called');
    debugPrint(
      '[SendTo] track.id="${widget.track.id}" track.title="${widget.track.title}"',
    );

    final currentUserId = await AuthApiService().getStoredUserId();
    debugPrint('[SendTo] STEP 1 result → currentUserId="$currentUserId"');
    if (currentUserId == null || currentUserId.isEmpty) {
      debugPrint('[SendTo] STEP 1 ❌ ABORTED — no currentUserId.');
      return;
    }

    final permalink = widget.track.permalink?.isNotEmpty == true
        ? widget.track.permalink
        : null;
    final artistId = widget.track.artistId ?? '';

    String profileLink = '';
    if (artistId.isNotEmpty) {
      try {
        profileLink =
            await MessagingApiService().getUserProfileLink(userId: artistId) ??
            '';
      } catch (e) {
        debugPrint('[SendTo] STEP 3 ❌ getUserProfileLink threw: $e');
      }
    }

    String buildPayload() {
      if (permalink == null || permalink.isEmpty) return '';
      return 'track::permalink:"$permalink",profilelink:"$profileLink"';
    }

    try {
      final result = await SocialApiService().getFollowers(
        userId: currentUserId,
      );

      if (result.$1 != 200) {
        if (mounted) setState(() => _trackPermalink = buildPayload());
        return;
      }

      final rawList = result.$2;
      List<Follower> followers = [];
      if (rawList is List) {
        followers = rawList.whereType<Follower>().toList();
      }

      final validFollowers = followers
          .where((f) => f.userId.isNotEmpty)
          .toList();

      if (!mounted) return;
      final contacts = validFollowers
          .take(6)
          .map(
            (f) => (
              receiverId: f.userId,
              name: f.displayName,
              photoUrl: f.profileImgLink ?? '',
            ),
          )
          .toList();
      setState(() {
        _recentContacts = contacts;
        _trackPermalink = buildPayload();
      });
      debugPrint('[SendTo] ✅ contacts=${_recentContacts.length}');
    } catch (e, stack) {
      debugPrint('[SendTo] ❌ EXCEPTION: $e\n$stack');
      if (mounted) setState(() => _trackPermalink = buildPayload());
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  Future<void> _checkLikeStatus() async {
    try {
      final userId = await AuthApiService().getStoredUserId();
      if (userId == null || !mounted) return;
      final result = await _engagementApi.getTrackLikers(
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
      final result = await _engagementApi.getTrackRepostStatus(
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
    final wasLiked = _isLiked;
    setState(() {
      _isLiked = !_isLiked;
      _isLikeLoading = true;
    });
    final result = await _engagementApi.toggleTrackLike(
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

  Future<void> _goToProfile() async {
    final artistId = widget.track.artistId;
    if (artistId == null || artistId.isEmpty) return;
    final nav = Navigator.of(context, rootNavigator: true);
    nav.pop();
    await ProfileNavigator.pushViaState(nav, artistId);
  }

  void _viewComments() {
    final nav = Navigator.of(context, rootNavigator: true);
    nav.pop();
    nav.push(
      MaterialPageRoute(
        builder: (_) => CommentsScreen(
          trackId: widget.track.id,
          trackTitle: widget.track.title,
          trackArtist: widget.track.artistName,
          trackThumbnailUrl: widget.track.artworkUrl,
          currentPositionSeconds: 0,
        ),
      ),
    );
  }

  void _openSendToSheet() {
    final link = _trackPermalink ?? '';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) =>
          SendToSheet(trackLink: link, trackTitle: widget.track.title),
    );
  }

  void _sendToContact(String receiverId, String name, String photoUrl) {
    final link = _trackPermalink ?? '';
    Navigator.of(context, rootNavigator: true).pop();
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          receiverId: receiverId,
          receiverName: name,
          receiverPhotoUrl: photoUrl,
          initialContent: link,
        ),
      ),
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

  void _playNext() {
    PlaybackStreamingEngineService.shared.addToQueueNext(widget.track);
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _playLast() {
    PlaybackStreamingEngineService.shared.addToQueueLast(widget.track);
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _behindThisTrack() {
    Navigator.of(context, rootNavigator: true).pop();
    widget.onBehindThisTrack?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDeepest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
                  child: _TrackHeaderCard(track: widget.track),
                ),
                const SizedBox(height: 22),

                // ── Send To ──────────────────────────────────────────────────
                if (_hasSendTo && _recentContacts.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      'SEND TO',
                      style: TextStyle(
                        color: AppColors.white70,
                        letterSpacing: 2.2,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: _recentContacts
                          .map(
                            (c) => _SendToContact(
                              name: c.name,
                              photoUrl: c.photoUrl,
                              onTap: () => _sendToContact(
                                c.receiverId,
                                c.name,
                                c.photoUrl,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: Colors.white12, height: 1),
                ],

                // ── Share ────────────────────────────────────────────────────
                const SizedBox(height: 18),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    'SHARE',
                    style: TextStyle(
                      color: AppColors.white70,
                      letterSpacing: 2.2,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      _ShareAction(
                        icon: Icons.send_outlined,
                        label: 'Message',
                        onTap: _openSendToSheet,
                      ),
                      const _ShareAction(
                        icon: Icons.copy_outlined,
                        label: 'Copy link',
                      ),
                      const _ShareAction(
                        icon: Icons.qr_code_2_outlined,
                        label: 'QR code',
                      ),
                      const _ShareAction(
                        icon: Icons.sms_outlined,
                        label: 'SMS',
                      ),
                      const _ShareAction(
                        icon: Icons.chat_bubble_outline,
                        label: 'WhatsApp',
                      ),
                      const _ShareAction(
                        icon: Icons.camera_alt_outlined,
                        label: 'Stories',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 10),

                // ── Group 1: playback + management ───────────────────────────
                _OptionTile(
                  icon: _isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: _isLiked ? 'Liked' : 'Like',
                  color: _isLiked ? Colors.orange : AppColors.whiteSmoke,
                  onTap: _toggleLike,
                ),
                if (_hasEditTrack)
                  _OptionTile(
                    icon: Icons.edit_outlined,
                    label: 'Edit track',
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      widget.onEditTrack?.call();
                    },
                  ),
                _OptionTile(
                  icon: Icons.playlist_play_rounded,
                  label: 'Play next',
                  onTap: _playNext,
                ),
                _OptionTile(
                  icon: Icons.format_list_bulleted_rounded,
                  label: 'Play last',
                  onTap: _playLast,
                ),
                _OptionTile(
                  icon: Icons.playlist_add_outlined,
                  label: 'Add to playlist',
                ),
                if (_hasStartStation)
                  _OptionTile(
                    icon: Icons.radio_outlined,
                    label: 'Start station',
                  ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 10),

                // ── Group 2: social ──────────────────────────────────────────
                if (_hasGoToProfile)
                  _OptionTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Go to profile',
                    onTap: _goToProfile,
                  ),
                _OptionTile(
                  icon: Icons.mode_comment_outlined,
                  label: 'View comments',
                  onTap: _viewComments,
                ),
                if (_hasRepost)
                  _OptionTile(
                    icon: Icons.repeat_rounded,
                    label: _isReposted ? 'Reposted' : 'Repost on Beatza',
                    color: _isReposted ? Colors.orange : AppColors.whiteSmoke,
                    onTap: _openRepost,
                  ),

                // ── Feed-specific ────────────────────────────────────────────
                if (_hasFeedOptions) ...[
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 10),
                  _OptionTile(
                    icon: Icons.thumb_down_outlined,
                    label: 'Show me fewer posts like that',
                    onTap: widget.onShowFewerPosts,
                  ),
                  _OptionTile(
                    icon: Icons.view_list_outlined,
                    label: 'Switch to Classic feed',
                    onTap: widget.onSwitchToClassicFeed,
                  ),
                ],

                const SizedBox(height: 10),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 10),

                // ── Group 3: discovery + moderation ─────────────────────────
                if (_hasBehindThisTrack)
                  _OptionTile(
                    icon: Icons.graphic_eq,
                    label: 'Behind this track',
                    onTap: widget.onBehindThisTrack != null
                        ? _behindThisTrack
                        : null,
                  ),
                if (_hasReport)
                  _OptionTile(
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

// ── Track header card ────────────────────────────────────────────────────────

class _TrackHeaderCard extends StatelessWidget {
  final PlaybackTrackModel track;

  const _TrackHeaderCard({required this.track});

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
                        color: AppColors.whiteSmoke,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          track.artworkUrl != null &&
                              track.artworkUrl!.trim().isNotEmpty
                          ? Image.network(
                              track.artworkUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
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
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    track.artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.white70, fontSize: 15),
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

// ── Share action circle button ───────────────────────────────────────────────

class _ShareAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ShareAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.whiteSmoke.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.whiteSmoke, size: 30),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: AppColors.whiteSmoke, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Send-to contact circle ────────────────────────────────────────────────────

class _SendToContact extends StatelessWidget {
  final String name;
  final String photoUrl;
  final VoidCallback onTap;

  const _SendToContact({
    required this.name,
    required this.photoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 31,
              backgroundColor: AppColors.containerMid,
              backgroundImage: photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl.isEmpty
                  ? Text(
                      _initials(name),
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 64,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.whiteSmoke, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String text) {
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

// ── Option list tile ─────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  _OptionTile({
    required this.icon,
    required this.label,
    this.onTap,
    Color? color,
  }) : color = color ?? AppColors.whiteSmoke;

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

// ── Vinyl disc painter (decorative) ─────────────────────────────────────────

class _VinylPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()..color = Colors.black;
    final ringPaint = Paint()
      ..color = AppColors.whiteSmoke.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final centerPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.fill;

    final center = Offset(size.width * 0.45, size.height / 2);
    final radius = size.height * 0.45;

    canvas.drawCircle(center, radius, basePaint);
    canvas.drawCircle(center, radius * 0.78, ringPaint);
    canvas.drawCircle(center, radius * 0.56, ringPaint);
    canvas.drawCircle(center, radius * 0.34, ringPaint);
    canvas.drawCircle(center, radius * 0.12, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
