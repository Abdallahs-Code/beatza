import 'package:cross_team5/core/navigation/profile_navigator.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/activity/controllers/activity_notifications_controller.dart';
import 'package:cross_team5/features/activity/models/activity_notification_model.dart';
import 'package:cross_team5/features/activity/screens/behind_the_track_screen.dart';
import 'package:cross_team5/features/activity/screens/quick_reply_sheet.dart';
import 'package:cross_team5/features/activity/screens/track_options_sheet.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/engagement_social_interactions/engagement_social_interactions.dart';
import 'package:cross_team5/features/followers_social_graph/followers_social_graph.dart';
import 'package:cross_team5/features/messaging_track_sharing/widgets/messages_tab.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/playback_track_api_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/mini_player_state.dart';
import 'package:flutter/material.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late final ActivityNotificationsController _controller;
  late final TabController _tabController;
  bool _didRequestFreshState = false;
  MessageFilter _messageFilter = MessageFilter.all;

  // ── Secondary-data cache keyed by ID so tiles never re-fetch on scroll ──
  final Map<String, bool> _followCache = {}; // actorUserId → isFollowing
  final Map<String, bool> _likeCache = {}; // commentId   → isLiked
  final Map<String, PlaybackTrackModel?> _trackCache = {}; // trackId → track
  final Map<String, bool> _trackFetchedCache = {}; // trackId → was attempted
  final Map<String, int?> _timestampCache = {}; // commentId → timestamp
  final Set<String> _readyIds = {};
  bool _initialLoadComplete = false;

  @override
  void initState() {
    super.initState();
    _controller = ActivityNotificationsController.shared;
    _controller.initialize();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onUpdate);
    _controller.addListener(_onUpdate);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didRequestFreshState) {
      _didRequestFreshState = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.ensureFreshState();
      });
    } else {
      ActivityNotificationsController.shared.reconnectIfNeeded();
    }
  }

  @override
  void didUpdateWidget(covariant ActivityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_didRequestFreshState) {
      _didRequestFreshState = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.ensureFreshState();
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _tabController.removeListener(_onUpdate);
    _tabController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  static String _trackIdFor(ActivityNotificationModel n) =>
      (n.target.trackId?.isNotEmpty == true)
      ? n.target.trackId!
      : n.target.targetId;

  bool get _tilesLoading {
    if (_initialLoadComplete) return false;
    final all = [
      ..._controller.todayNotifications,
      ..._controller.olderNotifications,
    ];
    if (all.isEmpty) return false;
    return !all.every((n) => _readyIds.contains(n.notificationId));
  }

  void _onTileDataFetched(
    ActivityNotificationModel n, {
    bool? isFollowing,
    bool? isLiked,
    PlaybackTrackModel? track,
    bool trackFetched = false,
    int? commentTimestamp,
  }) {
    if (!mounted) return;
    setState(() {
      if (isFollowing != null) _followCache[n.actor.userId] = isFollowing;
      if (isLiked != null) _likeCache[n.target.targetId] = isLiked;
      if (trackFetched) {
        _trackCache[_trackIdFor(n)] = track;
        _trackFetchedCache[_trackIdFor(n)] = true;
      }
      if (commentTimestamp != null)
        _timestampCache[n.target.targetId] = commentTimestamp;
    });
  }

  void _onTileReady(String notificationId) {
    if (_initialLoadComplete || _readyIds.contains(notificationId)) return;
    setState(() {
      _readyIds.add(notificationId);
      final all = [
        ..._controller.todayNotifications,
        ..._controller.olderNotifications,
      ];
      final remaining = all
          .where((n) => !_readyIds.contains(n.notificationId))
          .length;
      debugPrint(
        '[READY] $notificationId — ${_readyIds.length}/${all.length} remaining=$remaining',
      );
      if (all.isNotEmpty && remaining == 0) {
        _initialLoadComplete = true;
        debugPrint('[READY] ALL DONE — revealing list');
      }
    });
  }

  // ─── Filter sheet ──────────────────────────────────────────────────────────

  Future<void> _openFilterSheet() async {
    if (_tabController.index == 1) {
      await _openMessageFilterSheet();
    } else {
      await _openNotificationFilterSheet();
    }
  }

  Future<void> _openNotificationFilterSheet() async {
    final selected = await showModalBottomSheet<ActivityNotificationFilter>(
      context: context,
      backgroundColor: AppColors.container,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ...ActivityNotificationFilter.values.map((f) {
                final sel = f == _controller.filter;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: Icon(
                    f.icon,
                    color: sel ? AppColors.primaryOrange : Colors.white70,
                    size: 22,
                  ),
                  title: Text(
                    f.label,
                    style: TextStyle(
                      color: sel ? AppColors.primaryOrange : Colors.white,
                      fontSize: 15,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  trailing: sel
                      ? Icon(
                          Icons.check_rounded,
                          color: AppColors.primaryOrange,
                          size: 20,
                        )
                      : null,
                  onTap: () => Navigator.of(ctx).pop(f),
                );
              }),
            ],
          ),
        ),
      ),
    );
    if (selected != null) _controller.setFilter(selected);
  }

  Future<void> _openMessageFilterSheet() async {
    final selected = await showModalBottomSheet<MessageFilter>(
      context: context,
      backgroundColor: AppColors.container,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _msgFilterTile(ctx, MessageFilter.all, 'All messages'),
              _msgFilterTile(ctx, MessageFilter.unreadOnly, 'Unread only'),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _messageFilter = selected);
    }
  }

  Widget _msgFilterTile(BuildContext ctx, MessageFilter f, String label) {
    final sel = f == _messageFilter;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(
        label,
        style: TextStyle(
          color: sel ? AppColors.primaryOrange : Colors.white,
          fontSize: 15,
          fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      trailing: sel
          ? Icon(Icons.check_rounded, color: AppColors.primaryOrange, size: 20)
          : null,
      onTap: () => Navigator.of(ctx).pop(f),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [_buildNotificationsTab(), _buildMessagesTab()],
      ),
      bottomNavigationBar: const MiniPlayerSpacer(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: const Text(
        'Activity',
        style: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      actions: [
        if (_controller.unreadCount > 0)
          TextButton(
            onPressed: _controller.markAllAsRead,
            child: const Text(
              'Mark all read',
              style: TextStyle(
                color: AppColors.primaryOrange,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
          onPressed: _openFilterSheet,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 2,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Notifications'),
            Tab(text: 'Messages'),
          ],
        ),
      ),
    );
  }

  // ─── Notifications tab ─────────────────────────────────────────────────────

  Widget _buildNotificationsTab() {
    if (_controller.isLoading && _controller.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryOrange,
          strokeWidth: 2,
        ),
      );
    }

    if (_controller.errorMessage != null && _controller.notifications.isEmpty) {
      return _buildErrorState(_controller.errorMessage!);
    }

    final today = _controller.todayNotifications;
    final older = _controller.olderNotifications;

    if (today.isEmpty && older.isEmpty) return _buildEmptyState();

    Widget tile(ActivityNotificationModel n) => _NotificationTile(
      key: ValueKey(n.notificationId),
      notification: n,
      controller: _controller,
      initialIsFollowing: _followCache[n.actor.userId],
      initialIsLiked: _likeCache[n.target.targetId],
      initialTrack: _trackCache[_trackIdFor(n)],
      initialTrackFetched: _trackFetchedCache[_trackIdFor(n)] ?? false,
      initialCommentTimestamp: _timestampCache[n.target.targetId],
      onDataFetched:
          (isFollowing, isLiked, track, trackFetched, commentTimestamp) =>
              _onTileDataFetched(
                n,
                isFollowing: isFollowing,
                isLiked: isLiked,
                track: track,
                trackFetched: trackFetched,
                commentTimestamp: commentTimestamp,
              ),
      onTileReady: () => _onTileReady(n.notificationId),
    );

    // SingleChildScrollView + Column builds ALL children eagerly (no lazy
    // viewport). This is required so every tile's initState fires immediately
    // and onTileReady callbacks can fill _readyIds.
    final list = RefreshIndicator(
      color: AppColors.primaryOrange,
      backgroundColor: AppColors.surface,
      onRefresh: _controller.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (today.isNotEmpty) ...[
              _sectionLabel('Today'),
              ...today.map(tile),
            ],
            if (older.isNotEmpty) ...[
              _sectionLabel('Older'),
              ...older.map(tile),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );

    debugPrint(
      '[LOADING_GATE] tilesLoading=$_tilesLoading '
      'ready=${_readyIds.length} total=${today.length + older.length} '
      'initialComplete=$_initialLoadComplete',
    );

    return Stack(
      children: [
        list,
        if (_tilesLoading)
          Positioned.fill(
            child: Container(
              color: AppColors.backgroundDark,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryOrange,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ─── Empty / error / messages ──────────────────────────────────────────────

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
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
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _controller.refresh,
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
      ),
    );
  }

  Widget _buildEmptyState() {
    final filtered = _controller.filter != ActivityNotificationFilter.all;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        const Icon(
          Icons.notifications_none_rounded,
          color: Colors.white24,
          size: 60,
        ),
        const SizedBox(height: 20),
        Text(
          filtered
              ? 'No ${_controller.filter.label.toLowerCase()} yet'
              : 'No notifications yet',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'When new activity happens, it will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 14, height: 1.5),
          ),
        ),
        if (filtered) ...[
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: _controller.showAllNotifications,
              child: const Text(
                'Show all notifications',
                style: TextStyle(
                  color: AppColors.primaryOrange,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMessagesTab() {
    return MessagesTab(filter: _messageFilter);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _NotificationTile — own StatefulWidget so each tile owns its like state
// ═════════════════════════════════════════════════════════════════════════════

class _NotificationTile extends StatefulWidget {
  final ActivityNotificationModel notification;
  final ActivityNotificationsController controller;

  // Cached values from parent — provided on remount so tile renders immediately.
  final bool? initialIsFollowing;
  final bool? initialIsLiked;
  final PlaybackTrackModel? initialTrack;
  final bool initialTrackFetched;
  final int? initialCommentTimestamp;

  // Called whenever a secondary API returns so parent can cache the result.
  final void Function(
    bool? isFollowing,
    bool? isLiked,
    PlaybackTrackModel? track,
    bool trackFetched,
    int? commentTimestamp,
  )
  onDataFetched;

  // Called once all secondary API calls for this tile have completed.
  final VoidCallback onTileReady;

  const _NotificationTile({
    super.key,
    required this.notification,
    required this.controller,
    required this.initialIsFollowing,
    required this.initialIsLiked,
    required this.initialTrack,
    required this.initialTrackFetched,
    required this.initialCommentTimestamp,
    required this.onDataFetched,
    required this.onTileReady,
  });

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  // Exact same service instance pattern as _ExpandedEngagementBarState
  final EngagementApiService _engagementService = EngagementApiService();

  bool _isLiked = false;
  bool _isLikeLoading = false;
  bool _isFollowing = false;
  bool _isFollowLoading = false;
  bool _trackFetched = false;
  PlaybackTrackModel? _track;
  int? _commentTimestamp;

  // Tracks how many secondary API calls are still in-flight.
  int _pendingLoads = 0;
  bool _tileReadyFired = false;

  ActivityNotificationModel get n => widget.notification;

  String get _resolvedTrackId => (n.target.trackId?.isNotEmpty == true)
      ? n.target.trackId!
      : n.target.targetId;

  @override
  void initState() {
    super.initState();

    // Track data — use cache if available, otherwise fetch.
    final trackId = _resolvedTrackId;
    if (trackId.isEmpty) {
      _trackFetched = true;
    } else if (widget.initialTrackFetched) {
      _track = widget.initialTrack;
      _trackFetched = true;
    } else {
      _pendingLoads++;
      _fetchTrackData();
    }

    // Like / comment status.
    if (_hasActions(n.activityType)) {
      if (widget.initialIsLiked != null) {
        _isLiked = widget.initialIsLiked!;
        _commentTimestamp = widget.initialCommentTimestamp;
      } else {
        _pendingLoads++;
        _checkLikeStatus();
      }
    }

    // Follow status.
    if (n.activityType == 'user_followed') {
      if (widget.initialIsFollowing != null) {
        _isFollowing = widget.initialIsFollowing!;
      } else {
        _pendingLoads++;
        _checkFollowStatus();
      }
    }

    debugPrint(
      '[TILE_INIT] ${n.notificationId} type=${n.activityType} pending=$_pendingLoads',
    );

    // Nothing to fetch — report ready after first frame.
    if (_pendingLoads == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_tileReadyFired) {
          _tileReadyFired = true;
          debugPrint('[TILE] ${n.notificationId} READY (no pending)');
          widget.onTileReady();
        }
      });
    }
  }

  // Called by every async method on completion (success or error).
  void _completePending({
    bool? isFollowing,
    bool? isLiked,
    PlaybackTrackModel? track,
    bool trackFetched = false,
    int? commentTimestamp,
  }) {
    widget.onDataFetched(
      isFollowing,
      isLiked,
      track,
      trackFetched,
      commentTimestamp,
    );
    _pendingLoads--;
    debugPrint('[TILE] ${n.notificationId} pending=$_pendingLoads');
    if (_pendingLoads <= 0 && !_tileReadyFired) {
      _tileReadyFired = true;
      debugPrint('[TILE] ${n.notificationId} READY');
      widget.onTileReady();
    }
  }

  Future<void> _fetchTrackData() async {
    final trackId = _resolvedTrackId;
    if (trackId.isEmpty) {
      if (mounted) setState(() => _trackFetched = true);
      _completePending(trackFetched: true);
      return;
    }
    try {
      final track = await PlaybackTrackApiService().getSingleTrackById(trackId);
      if (mounted)
        setState(() {
          _track = track;
          _trackFetched = true;
        });
      _completePending(track: track, trackFetched: true);
    } catch (_) {
      if (mounted) setState(() => _trackFetched = true);
      _completePending(trackFetched: true);
    }
  }

  Future<void> _checkFollowStatus() async {
    try {
      final currentUserId = await AuthApiService().getStoredUserId();
      if (currentUserId == null) {
        _completePending();
        return;
      }
      final result = await SocialApiService().getFollowing(
        userId: currentUserId,
      );
      if (result.$1 == 200 && result.$2 is List) {
        final isFollowing = (result.$2 as List<Follower>).any(
          (f) => f.userId == n.actor.userId,
        );
        if (mounted) setState(() => _isFollowing = isFollowing);
        _completePending(isFollowing: isFollowing);
      } else {
        _completePending();
      }
    } catch (_) {
      _completePending();
    }
  }

  Future<void> _toggleFollow() async {
    if (_isFollowLoading) return;
    final wasFollowing = _isFollowing;
    setState(() {
      _isFollowing = !wasFollowing;
      _isFollowLoading = true;
    });
    final result = wasFollowing
        ? await SocialApiService().unfollowUser(targetUserId: n.actor.userId)
        : await SocialApiService().followUser(targetUserId: n.actor.userId);
    if (!mounted) return;
    if (result.$1 != 200 && result.$1 != 201) {
      setState(() => _isFollowing = wasFollowing);
    }
    setState(() => _isFollowLoading = false);
  }

  Future<void> _checkLikeStatus() async {
    final trackId = n.target.trackId;
    final commentId = n.target.targetId;
    if (trackId == null || trackId.isEmpty || commentId.isEmpty) {
      _completePending();
      return;
    }
    try {
      final result = await _engagementService.getTrackComments(
        trackId: trackId,
        limit: 100,
      );
      if (result.$1 == 200 && result.$2 is List) {
        final match = (result.$2 as List<Comment>).cast<Comment?>().firstWhere(
          (c) => c?.commentId == commentId,
          orElse: () => null,
        );
        if (match != null) {
          if (mounted)
            setState(() {
              _isLiked = match.isLikedByUser;
              _commentTimestamp = match.timestamp;
            });
          _completePending(
            isLiked: match.isLikedByUser,
            commentTimestamp: match.timestamp,
          );
        } else {
          _completePending();
        }
      } else {
        _completePending();
      }
    } catch (_) {
      _completePending();
    }
  }

  Future<void> _toggleLike() async {
    if (_isLikeLoading) return;
    final commentId = n.target.targetId;
    final bool wasLiked = _isLiked;
    setState(() {
      _isLiked = !_isLiked;
      _isLikeLoading = true;
    });
    final result = await _engagementService.toggleCommentLike(
      commentId: commentId,
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

  // Opens quick reply without pre-filling (used for tile tap)
  void _openQuickReply() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickReplySheet(
        trackId: _resolvedTrackId,
        trackTitle: _track?.title ?? n.target.title ?? '',
        trackArtist: _track?.artistName ?? '',
        trackThumbnailUrl: _track?.artworkUrl,
        numComments: _track?.numComments ?? 0,
        numReposts: _track?.numReposts ?? 0,
      ),
    );
  }

  // Opens quick reply pre-filled with the actor's @mention and comment timestamp
  void _openReply() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickReplySheet(
        trackId: _resolvedTrackId,
        trackTitle: _track?.title ?? n.target.title ?? '',
        trackArtist: _track?.artistName ?? '',
        trackThumbnailUrl: _track?.artworkUrl,
        numComments: _track?.numComments ?? 0,
        numReposts: _track?.numReposts ?? 0,
        initialParentCommentId: n.target.targetId,
        initialMentionDisplayName: n.actor.displayName,
        initialMentionUserId: n.actor.userId,
        initialTimestamp: _commentTimestamp,
      ),
    );
  }

  void _openTrackOptions() {
    final track = _track;
    if (track == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrackOptionsSheet(
        track: track,
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

  // ── Tap on the whole tile ──
  void _handleTap() {
    if (!n.read) {
      widget.controller.markNotificationAsRead(n.notificationId);
    }
    switch (n.activityType) {
      case 'user_followed':
        _navigateToUserProfile(n.actor.userId);
      case 'track_liked':
      case 'track_reposted':
        _navigateToBehindTheTrack();
      case 'track_commented':
      case 'user_mentioned':
        _openQuickReply();
      case 'new_track':
        _navigateToBehindTheTrack();
    }
  }

  Future<void> _navigateToUserProfile(String userId) async {
    await ProfileNavigator.push(context, userId);
  }

  void _navigateToBehindTheTrack() {
    // For like/repost: n.to = track owner. For new_track: n.actor.userId = uploader.
    final trackOwnerId = n.activityType == 'new_track' ? n.actor.userId : n.to;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BehindTheTrackScreen(
          trackId: _resolvedTrackId,
          actorName: n.actor.displayName,
          actorAvatarUrl: n.actor.avatarUrl,
          actorUserId: n.actor.userId,
          activityType: n.activityType,
          trackOwnerId: trackOwnerId,
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final trailing = _trailingWidget();

    return InkWell(
      onTap: _handleTap,
      splashColor: Colors.white.withValues(alpha: 0.04),
      highlightColor: Colors.white.withValues(alpha: 0.03),
      child: Container(
        color: n.read
            ? Colors.transparent
            : Colors.white.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _avatarWithBadge(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: n.actor.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                        ),
                        TextSpan(
                          text: '  ${_ts(n.createdAt)}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  _descriptionText(),
                  if (_hasActions(n.activityType)) ...[
                    const SizedBox(height: 10),
                    _actionChips(),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing],
          ],
        ),
      ),
    );
  }

  Widget _avatarWithBadge() {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.containerMid,
            backgroundImage: n.actor.avatarUrl.trim().isNotEmpty
                ? NetworkImage(n.actor.avatarUrl)
                : null,
            child: n.actor.avatarUrl.trim().isEmpty
                ? Text(
                    _initials(n.actor.displayName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _badgeColor(n.activityType),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.backgroundDark, width: 2),
              ),
              child: Center(
                child: Icon(
                  _badgeIcon(n.activityType),
                  color: Colors.white,
                  size: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _descriptionText() {
    return RichText(
      text: TextSpan(
        style: TextStyle(color: AppColors.greyIcon, fontSize: 14, height: 1.4),
        children: _descSpans(),
      ),
    );
  }

  List<TextSpan> _descSpans() {
    const bold = TextStyle(color: Colors.white, fontWeight: FontWeight.w600);

    switch (n.activityType) {
      case 'track_liked':
        final title = n.target.title?.trim() ?? '';
        return [
          const TextSpan(text: 'liked your track '),
          if (title.isNotEmpty) TextSpan(text: title, style: bold),
        ];
      case 'track_commented':
        final comment = n.target.commentText?.trim() ?? '';
        final title = _trackFetched
            ? (_track?.title ?? n.target.title ?? '').trim()
            : (n.target.title?.trim() ?? '…');
        return [
          const TextSpan(text: 'commented '),
          if (comment.isNotEmpty) TextSpan(text: '"$comment"', style: bold),
          if (title.isNotEmpty) ...[
            const TextSpan(text: ' on '),
            TextSpan(text: title, style: bold),
          ],
        ];
      case 'track_reposted':
        final title = n.target.title?.trim() ?? '';
        return [
          const TextSpan(text: 'reposted your track '),
          if (title.isNotEmpty) TextSpan(text: title, style: bold),
        ];
      case 'user_followed':
        return [const TextSpan(text: 'followed you')];
      case 'new_track':
        final title = n.target.title?.trim() ?? '';
        return [
          const TextSpan(text: 'uploaded '),
          if (title.isNotEmpty)
            TextSpan(text: title, style: bold)
          else
            const TextSpan(text: 'a new track'),
        ];
      case 'user_mentioned':
        final mention = n.target.commentText?.trim() ?? '';
        final title = _trackFetched
            ? (_track?.title ?? n.target.title ?? '').trim()
            : (n.target.title?.trim() ?? '…');
        return [
          const TextSpan(text: 'mentioned you '),
          if (mention.isNotEmpty) TextSpan(text: mention, style: bold),
          if (title.isNotEmpty) ...[
            const TextSpan(text: '\non '),
            TextSpan(text: title, style: bold),
          ],
        ];
      default:
        return [const TextSpan(text: 'sent you a notification')];
    }
  }

  Widget? _trailingWidget() {
    if (n.activityType == 'user_followed') {
      return GestureDetector(
        onTap: _isFollowLoading ? null : _toggleFollow,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _isFollowing
                ? AppColors.containerMid
                : AppColors.primaryOrange,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: _isFollowLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _isFollowing ? 'Following' : 'Follow',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      );
    }

    // Show track thumbnail for track notifications AND comment/mention
    // notifications (targetType == 'comment' but they reference a track).
    if (n.target.targetType == 'track' ||
        n.activityType == 'track_commented' ||
        n.activityType == 'user_mentioned' ||
        n.activityType == 'new_track') {
      final artworkUrl = _track?.artworkUrl;
      final thumb = ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: artworkUrl != null && artworkUrl.isNotEmpty
            ? Image.network(
                artworkUrl,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 52,
                  height: 52,
                  color: AppColors.cardDark2,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    color: AppColors.greyDark3,
                    size: 26,
                  ),
                ),
              )
            : Container(
                width: 52,
                height: 52,
                color: AppColors.cardDark2,
                alignment: Alignment.center,
                child: Icon(
                  Icons.graphic_eq_rounded,
                  color: AppColors.greyDark3,
                  size: 26,
                ),
              ),
      );
      if (_track != null) {
        return GestureDetector(onTap: _openTrackOptions, child: thumb);
      }
      return thumb;
    }

    return null;
  }

  // Only comments and mentions show action chips
  bool _hasActions(String type) =>
      type == 'track_commented' || type == 'user_mentioned';

  Widget _actionChips() {
    return Row(
      children: [
        _chip(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Reply',
          filled: false,
          onTap: _openReply,
        ),
        const SizedBox(width: 8),
        _chip(
          icon: _isLiked
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          label: _isLiked ? 'Liked' : 'Like',
          filled: _isLiked,
          onTap: _toggleLike,
        ),
      ],
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    final color = filled ? AppColors.primaryOrange : AppColors.greyMuted;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: filled
                ? AppColors.primaryOrange.withValues(alpha: 0.5)
                : AppColors.inputFill,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  IconData _badgeIcon(String type) {
    switch (type) {
      case 'track_liked':
        return Icons.favorite_rounded;
      case 'track_commented':
        return Icons.mode_comment_rounded;
      case 'track_reposted':
        return Icons.repeat_rounded;
      case 'user_followed':
        return Icons.person_add_alt_1_rounded;
      case 'new_track':
        return Icons.music_note_rounded;
      case 'user_mentioned':
        return Icons.alternate_email_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _badgeColor(String type) {
    switch (type) {
      case 'track_liked':
        return AppColors.notifLike;
      case 'track_commented':
        return AppColors.notifComment;
      case 'track_reposted':
        return AppColors.notifFollow;
      case 'user_followed':
        return AppColors.primaryOrange;
      case 'new_track':
        return AppColors.notifOther;
      case 'user_mentioned':
        return AppColors.notifAlt;
      default:
        return AppColors.primaryOrange;
    }
  }

  String _initials(String text) {
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  String _ts(DateTime dt) {
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    final l = dt.toLocal();
    return '${l.day}/${l.month}/${l.year}';
  }
}
