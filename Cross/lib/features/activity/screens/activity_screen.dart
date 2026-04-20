import 'package:cross_team5/features/activity/controllers/activity_notifications_controller.dart';
import 'package:cross_team5/features/activity/models/activity_notification_model.dart';
import 'package:cross_team5/features/activity/screens/behind_the_track_screen.dart';
import 'package:cross_team5/features/activity/screens/quick_reply_sheet.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/engagement_social_interactions/engagement_social_interactions.dart';
import 'package:flutter/material.dart';

const _kBg = Color(0xFF111111);
const _kSurface = Color(0xFF1C1C1C);
const _kOrange = Color(0xFFFF5500);

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

  @override
  void initState() {
    super.initState();
    _controller = ActivityNotificationsController.shared;
    _controller.initialize();
    _tabController = TabController(length: 2, vsync: this);
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
    _tabController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  // ─── Filter sheet ──────────────────────────────────────────────────────────

  Future<void> _openFilterSheet() async {
    final selected = await showModalBottomSheet<ActivityNotificationFilter>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  leading: Icon(f.icon,
                      color: sel ? _kOrange : Colors.white70, size: 22),
                  title: Text(f.label,
                      style: TextStyle(
                        color: sel ? _kOrange : Colors.white,
                        fontSize: 15,
                        fontWeight:
                            sel ? FontWeight.w700 : FontWeight.w400,
                      )),
                  trailing: sel
                      ? const Icon(Icons.check_rounded,
                          color: _kOrange, size: 20)
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

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsTab(),
          _buildMessagesPlaceholder(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kBg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
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
                color: _kOrange,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.tune_rounded,
              color: Colors.white, size: 22),
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
              fontSize: 15, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w400),
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
              color: _kOrange, strokeWidth: 2));
    }

    if (_controller.errorMessage != null &&
        _controller.notifications.isEmpty) {
      return _buildErrorState(_controller.errorMessage!);
    }

    final today = _controller.todayNotifications;
    final older = _controller.olderNotifications;

    if (today.isEmpty && older.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      color: _kOrange,
      backgroundColor: _kSurface,
      onRefresh: _controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          if (today.isNotEmpty) ...[
            _sectionLabel('Today'),
            ...today.map(
                (n) => _NotificationTile(notification: n, controller: _controller)),
          ],
          if (older.isNotEmpty) ...[
            _sectionLabel('Older'),
            ...older.map(
                (n) => _NotificationTile(notification: n, controller: _controller)),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700)),
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
            const Icon(Icons.error_outline_rounded,
                color: Colors.white38, size: 42),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _controller.refresh,
              child: const Text('Try again',
                  style: TextStyle(
                      color: _kOrange,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final filtered =
        _controller.filter != ActivityNotificationFilter.all;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.notifications_none_rounded,
            color: Colors.white24, size: 60),
        const SizedBox(height: 20),
        Text(
          filtered
              ? 'No ${_controller.filter.label.toLowerCase()} yet'
              : 'No notifications yet',
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'When new activity happens, it will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white38, fontSize: 14, height: 1.5),
          ),
        ),
        if (filtered) ...[
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: _controller.showAllNotifications,
              child: const Text('Show all notifications',
                  style: TextStyle(
                      color: _kOrange,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMessagesPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mail_outline_rounded,
              color: Colors.white24, size: 52),
          SizedBox(height: 16),
          Text('No messages yet',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('Your messages will appear here.',
              style:
                  TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _NotificationTile — own StatefulWidget so each tile owns its like state
// ═════════════════════════════════════════════════════════════════════════════

class _NotificationTile extends StatefulWidget {
  final ActivityNotificationModel notification;
  final ActivityNotificationsController controller;

  const _NotificationTile({
    required this.notification,
    required this.controller,
  });

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  // Exact same service instance pattern as _ExpandedEngagementBarState
  final EngagementApiService _engagementService = EngagementApiService();

  bool _isLiked = false;
  bool _isLikeLoading = false;

  ActivityNotificationModel get n => widget.notification;

  String get _resolvedTrackId =>
      (n.target.trackId?.isNotEmpty == true)
          ? n.target.trackId!
          : n.target.targetId;

  @override
  void initState() {
    super.initState();
    if (_hasActions(n.activityType)) {
      _checkLikeStatus();
    }
  }

  Future<void> _checkLikeStatus() async {
    final trackId = n.target.trackId;
    final commentId = n.target.targetId;
    if (trackId == null || trackId.isEmpty || commentId.isEmpty) return;
    try {
      final result = await _engagementService.getTrackComments(
        trackId: trackId,
        limit: 100,
      );
      if (!mounted) return;
      if (result.$1 == 200 && result.$2 is List) {
        final comments = result.$2 as List<Comment>;
        final match = comments.cast<Comment?>().firstWhere(
          (c) => c?.commentId == commentId,
          orElse: () => null,
        );
        if (match != null) setState(() => _isLiked = match.isLikedByUser);
      }
    } catch (_) {}
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

  // ── Reply opens the custom Quick Reply bottom sheet ──
  void _openQuickReply() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickReplySheet(
        trackId: _resolvedTrackId,
        trackTitle: n.target.title ?? '',
        trackArtist: '',
        numComments: 0,
        numReposts: 0,
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
    }
  }

  Future<void> _navigateToUserProfile(String userId) async {
    final token = await AuthApiService().getStoredAccessToken() ?? '';
    final currentUserId = await AuthApiService().getStoredUserId();
    if (!mounted) return;
    Navigator.pushNamed(context, '/user_profile', arguments: {
      'userId': userId,
      'token': token,
      'currentUserId': currentUserId,
    });
  }

  void _navigateToBehindTheTrack() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BehindTheTrackScreen(
          trackId: _resolvedTrackId,
          actorName: n.actor.displayName,
          actorAvatarUrl: n.actor.avatarUrl,
          actorUserId: n.actor.userId,
          activityType: n.activityType,
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
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing,
            ],
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
            backgroundColor: const Color(0xFF2A2A2A),
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
                border: Border.all(color: _kBg, width: 2),
              ),
              child: Center(
                child: Icon(_badgeIcon(n.activityType),
                    color: Colors.white, size: 10),
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
        style: const TextStyle(
          color: Color(0xFFAAAAAA),
          fontSize: 14,
          height: 1.4,
        ),
        children: _descSpans(),
      ),
    );
  }

  List<TextSpan> _descSpans() {
    const bold =
        TextStyle(color: Colors.white, fontWeight: FontWeight.w600);

    switch (n.activityType) {
      case 'track_liked':
        final title = n.target.title?.trim() ?? '';
        return [
          const TextSpan(text: 'liked your track '),
          if (title.isNotEmpty) TextSpan(text: title, style: bold),
        ];
      case 'track_commented':
        final comment = n.target.commentText?.trim() ?? '';
        final title = n.target.title?.trim() ?? '';
        return [
          const TextSpan(text: 'commented '),
          if (comment.isNotEmpty) TextSpan(text: comment, style: bold),
          if (title.isNotEmpty) ...[
            const TextSpan(text: '\non '),
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
        final title = n.target.title?.trim() ?? '';
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
      return Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: const Text('Following',
            style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      );
    }

    // Show track thumbnail for track notifications AND comment/mention
    // notifications (targetType == 'comment' but they reference a track).
    if (n.target.targetType == 'track' ||
        n.activityType == 'track_commented' ||
        n.activityType == 'user_mentioned' ||
        n.activityType == 'new_track') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 52,
          height: 52,
          color: const Color(0xFF222222),
          alignment: Alignment.center,
          child: const Icon(Icons.graphic_eq_rounded,
              color: Color(0xFF555555), size: 26),
        ),
      );
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
          onTap: _openQuickReply,
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
    final color = filled ? _kOrange : const Color(0xFF999999);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: filled
                ? _kOrange.withValues(alpha: 0.5)
                : const Color(0xFF333333),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
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
        return const Color(0xFFFF4B6E);
      case 'track_commented':
        return const Color(0xFF4B9EFF);
      case 'track_reposted':
        return const Color(0xFF2DB44A);
      case 'user_followed':
        return const Color(0xFFFF5500);
      case 'new_track':
        return const Color(0xFFF59E0B);
      case 'user_mentioned':
        return const Color(0xFFA855F7);
      default:
        return _kOrange;
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