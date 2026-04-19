import 'package:cross_team5/features/activity/controllers/activity_notifications_controller.dart';
import 'package:cross_team5/features/activity/models/activity_notification_model.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = ActivityNotificationsController.shared;
    _controller.initialize();
    _tabController = TabController(length: 2, vsync: this);
    _controller.addListener(_onControllerUpdated);
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
    _controller.removeListener(_onControllerUpdated);
    _tabController.dispose();
    super.dispose();
  }

  void _onControllerUpdated() {
    if (mounted) {
      setState(() {});
    }
  }
  bool _didRequestFreshState = false;

  Future<void> _openFilterSheet() async {
    final selected = await showModalBottomSheet<ActivityNotificationFilter>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ActivityNotificationFilter.values.map((filter) {
                final isSelected = filter == _controller.filter;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 2,
                  ),
                  leading: Icon(
                    filter.icon,
                    color: isSelected ? const Color(0xFFFF5500) : Colors.white,
                  ),
                  title: Text(
                    filter.label,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFFF5500) : Colors.white,
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFFFF5500),
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(filter),
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (selected != null) {
      _controller.setFilter(selected);
    }
  }

  void _handleNotificationPressed(ActivityNotificationModel notification) {
    if (!notification.read) {
      _controller.markNotificationAsRead(notification.notificationId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayNotifications = _controller.todayNotifications;
    final olderNotifications = _controller.olderNotifications;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: const Text(
          'Activity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_controller.unreadCount > 0)
            TextButton(
              onPressed: _controller.markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: Color(0xFFFF5500),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          IconButton(
            onPressed: _openFilterSheet,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: const Color(0xFFFF5500),
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Notifications'),
                Tab(text: 'Messages'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsTab(todayNotifications, olderNotifications),
          _buildMessagesPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab(
    List<ActivityNotificationModel> todayNotifications,
    List<ActivityNotificationModel> olderNotifications,
  ) {
    if (_controller.isLoading && _controller.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF5500),
        ),
      );
    }

    if (_controller.errorMessage != null && _controller.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white70,
                size: 38,
              ),
              const SizedBox(height: 12),
              Text(
                _controller.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _controller.refresh,
                child: const Text(
                  'Try again',
                  style: TextStyle(
                    color: Color(0xFFFF5500),
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

    if (todayNotifications.isEmpty && olderNotifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: const Color(0xFFFF5500),
      backgroundColor: const Color(0xFF121212),
      onRefresh: _controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
        children: [
          if (todayNotifications.isNotEmpty) ...[
            _buildSectionHeader('Today'),
            ...todayNotifications.map(_buildNotificationTile),
          ],
          if (olderNotifications.isNotEmpty) ...[
            _buildSectionHeader('Older'),
            ...olderNotifications.map(_buildNotificationTile),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildNotificationTile(ActivityNotificationModel notification) {
    final accentColor = _accentColor(notification.activityType);
    final trailing = _buildTrailingPreview(notification);
    final subtitle = _buildSubtitle(notification);
    final timestamp = _formatTimestamp(notification.createdAt);

    return Material(
      color: notification.read
          ? Colors.transparent
          : const Color(0x14FFFFFF),
      child: InkWell(
        onTap: () => _handleNotificationPressed(notification),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLeadingAvatar(notification, accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.35,
                        ),
                        children: [
                          TextSpan(
                            text: notification.actor.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: subtitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          timestamp,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!notification.read) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF5500),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_showsActionRow(notification.activityType)) ...[
                      const SizedBox(height: 12),
                      _buildActionRow(notification),
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
      ),
    );
  }

  Widget _buildLeadingAvatar(
    ActivityNotificationModel notification,
    Color accentColor,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF202020),
          backgroundImage: notification.actor.avatarUrl.trim().isNotEmpty
              ? NetworkImage(notification.actor.avatarUrl)
              : null,
          child: notification.actor.avatarUrl.trim().isEmpty
              ? Text(
                  _initials(notification.actor.displayName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
            ),
            child: Icon(
              _activityIcon(notification.activityType),
              color: Colors.white,
              size: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildTrailingPreview(ActivityNotificationModel notification) {
    if (notification.activityType == 'user_followed') {
      return OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(86, 34),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.28),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          foregroundColor: Colors.white,
        ),
        child: const Text(
          'Follow',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (notification.target.targetType == 'track') {
      return Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: const Color(0xFF1E1E1E),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.graphic_eq_rounded,
          color: Colors.white70,
          size: 26,
        ),
      );
    }

    if (notification.target.targetType == 'comment') {
      return Container(
        constraints: const BoxConstraints(
          minWidth: 64,
          maxWidth: 84,
          minHeight: 42,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF1B1B1B),
        ),
        child: Text(
          notification.target.commentText?.trim().isNotEmpty == true
              ? notification.target.commentText!.trim()
              : 'Comment',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            height: 1.2,
          ),
        ),
      );
    }

    return null;
  }

  Widget _buildActionRow(ActivityNotificationModel notification) {
    return Row(
      children: [
        _buildActionChip(
          icon: Icons.favorite_border_rounded,
          label: 'Like',
        ),
        const SizedBox(width: 10),
        _buildActionChip(
          icon: Icons.reply_rounded,
          label: 'Reply',
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
  }) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white70,
              size: 17,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _showsActionRow(String activityType) {
    return activityType == 'track_liked' ||
        activityType == 'track_commented' ||
        activityType == 'track_reposted' ||
        activityType == 'new_track';
  }

  String _buildSubtitle(ActivityNotificationModel notification) {
    switch (notification.activityType) {
      case 'track_liked':
        final title = notification.target.title?.trim() ?? '';
        return title.isEmpty ? ' liked your track' : ' liked your track $title';
      case 'track_commented':
        final text = notification.target.commentText?.trim() ?? '';
        return text.isEmpty
            ? ' commented on your track'
            : ' commented: "$text"';
      case 'track_reposted':
        final title = notification.target.title?.trim() ?? '';
        return title.isEmpty
            ? ' reposted your track'
            : ' reposted your track $title';
      case 'user_followed':
        return ' started following you';
      case 'new_track':
        final title = notification.target.title?.trim() ?? '';
        return title.isEmpty
            ? ' uploaded a new track'
            : ' uploaded a new track $title';
      default:
        return ' sent you a notification';
    }
  }

  IconData _activityIcon(String activityType) {
    switch (activityType) {
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
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _accentColor(String activityType) {
    switch (activityType) {
      case 'track_liked':
        return const Color(0xFFFF5500);
      case 'track_commented':
        return const Color(0xFF3B82F6);
      case 'track_reposted':
        return const Color(0xFF22C55E);
      case 'user_followed':
        return const Color(0xFFA855F7);
      case 'new_track':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFFF5500);
    }
  }

  String _initials(String text) {
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }

    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  String _formatTimestamp(DateTime dateTime) {
    final local = dateTime.toLocal();
    final difference = DateTime.now().difference(local);

    if (difference.inMinutes < 1) {
      return 'Now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} hr';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} d';
    }

    return '${local.day}/${local.month}/${local.year}';
  }

  Widget _buildMessagesPlaceholder() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Center(
          child: Text(
            'Messages',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(height: 12),
        Center(
          child: Text(
            'This tab will stay blank for now.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final isFiltered = _controller.filter != ActivityNotificationFilter.all;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 110),
        const Icon(
          Icons.notifications_none_rounded,
          color: Colors.white54,
          size: 64,
        ),
        const SizedBox(height: 20),
        Text(
          isFiltered
              ? 'No ${_controller.filter.label.toLowerCase()} yet'
              : 'No notifications yet',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'When new activity happens, it will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (isFiltered)
          Center(
            child: TextButton(
              onPressed: _controller.showAllNotifications,
              child: const Text(
                'Show all notifications',
                style: TextStyle(
                  color: Color(0xFFFF5500),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}