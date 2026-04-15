// Screen: LikersScreen
// Shows two tabs: users who liked a track + users who reposted it.
// This is a MODULE 6 ADDITION — real SoundCloud mobile only shows counts,
// but our clone implements the web feature in the mobile app.
//
// Navigation: pushed from any screen that shows a track's like count.
//   Navigator.pushNamed(context, EngagementRoutes.likers,
//     arguments: {'trackId': track.id, 'initialTab': 0});
//
// initialTab: 0 = Likers (default), 1 = Reposters
//
// Pagination: loads first 20 on open. "Load more" button appears at
// bottom of list when there are more results (offset-based, max 50/page).

import 'package:flutter/material.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/engagement_social_interactions/models/engagement_user.dart';
import 'package:cross_team5/features/engagement_social_interactions/services/engagement_api_service.dart';
import 'package:cross_team5/features/engagement_social_interactions/widgets/engagement_user_tile.dart';
import 'package:cross_team5/features/user_profile_social_identity/user_profile_social_identity.dart';

class LikersScreen extends StatefulWidget {
  final String trackId;
  final int initialTab; // 0 = Likers, 1 = Reposters

  const LikersScreen({
    super.key,
    required this.trackId,
    this.initialTab = 0,
  });

  @override
  State<LikersScreen> createState() => _LikersScreenState();
}

class _LikersScreenState extends State<LikersScreen>
    with SingleTickerProviderStateMixin {
  final EngagementApiService _service = EngagementApiService();
  final AuthApiService _authService = AuthApiService();
  late TabController _tabController;

  String? _currentUserId;

  // ── Likers state ─────────────────────────────
  List<EngagementUser> _likers = [];
  bool _isLoadingLikers = true;
  bool _isLoadingMoreLikers = false;
  String? _likersError;
  int _likersOffset = 1;
  static const int _pageSize = 20;

  // ── Reposters state ───────────────────────────
  List<EngagementUser> _reposters = [];
  bool _isLoadingReposters = true;
  bool _isLoadingMoreReposters = false;
  String? _repostersError;
  int _repostersOffset = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadCurrentUser();
    // Load both lists simultaneously on open.
    _loadLikers();
    _loadReposters();
  }

  Future<void> _loadCurrentUser() async {
    final userId = await _authService.getStoredUserId();
    if (mounted && userId != null) setState(() => _currentUserId = userId);
  }

  Future<void> _navigateToProfile(String userId) async {
    if (userId.trim().isEmpty) return;
    try {
      final token = await _authService.getStoredAccessToken() ?? '';
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        UserProfileSocialIdentityRoutes.userProfileRoute,
        arguments: {
          'userId': userId,
          'token': token,
          'currentUserId': _currentUserId ?? '',
        },
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Load first page of likers
  // ─────────────────────────────────────────────
  Future<void> _loadLikers() async {
    setState(() {
      _isLoadingLikers = true;
      _likersError = null;
    });

    final result = await _service.getTrackLikers(
      trackId: widget.trackId,
      offset: 1,
      limit: _pageSize,
    );

    setState(() {
      _isLoadingLikers = false;
      if (result.$1 == 200) {
        _likers = result.$2 as List<EngagementUser>;
        _likersOffset = 1;
        // Total comes from the raw response — we re-call with raw data
        // via a workaround: we trust the list length for "load more" logic.
        // If list length == _pageSize, there might be more.
      } else {
        _likersError = result.$2.toString();
      }
    });
  }

  // ─────────────────────────────────────────────
  // Load next page of likers (pagination)
  // ─────────────────────────────────────────────
  Future<void> _loadMoreLikers() async {
    if (_isLoadingMoreLikers) return;
    setState(() => _isLoadingMoreLikers = true);

    final nextOffset = _likersOffset + 1;
    final result = await _service.getTrackLikers(
      trackId: widget.trackId,
      offset: nextOffset,
      limit: _pageSize,
    );

    setState(() {
      _isLoadingMoreLikers = false;
      if (result.$1 == 200) {
        final newUsers = result.$2 as List<EngagementUser>;
        _likers.addAll(newUsers);
        _likersOffset = nextOffset;
      }
    });
  }

  // ─────────────────────────────────────────────
  // Load first page of reposters
  // ─────────────────────────────────────────────
  Future<void> _loadReposters() async {
    setState(() {
      _isLoadingReposters = true;
      _repostersError = null;
    });

    final result = await _service.getTrackReposters(
      trackId: widget.trackId,
      offset: 1,
      limit: _pageSize,
    );

    setState(() {
      _isLoadingReposters = false;
      if (result.$1 == 200) {
        _reposters = result.$2 as List<EngagementUser>;
        _repostersOffset = 1;
      } else {
        _repostersError = result.$2.toString();
      }
    });
  }

  // ─────────────────────────────────────────────
  // Load next page of reposters (pagination)
  // ─────────────────────────────────────────────
  Future<void> _loadMoreReposters() async {
    if (_isLoadingMoreReposters) return;
    setState(() => _isLoadingMoreReposters = true);

    final nextOffset = _repostersOffset + 1;
    final result = await _service.getTrackReposters(
      trackId: widget.trackId,
      offset: nextOffset,
      limit: _pageSize,
    );

    setState(() {
      _isLoadingMoreReposters = false;
      if (result.$1 == 200) {
        final newUsers = result.$2 as List<EngagementUser>;
        _reposters.addAll(newUsers);
        _repostersOffset = nextOffset;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(text: 'Likes'),
            Tab(text: 'Reposts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(
            users: _likers,
            isLoading: _isLoadingLikers,
            isLoadingMore: _isLoadingMoreLikers,
            error: _likersError,
            onRetry: _loadLikers,
            onLoadMore: _loadMoreLikers,
            emptyMessage: 'No likes yet.',
          ),
          _buildUserList(
            users: _reposters,
            isLoading: _isLoadingReposters,
            isLoadingMore: _isLoadingMoreReposters,
            error: _repostersError,
            onRetry: _loadReposters,
            onLoadMore: _loadMoreReposters,
            emptyMessage: 'No reposts yet.',
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Reusable list builder for both tabs.
  // ─────────────────────────────────────────────
  Widget _buildUserList({
    required List<EngagementUser> users,
    required bool isLoading,
    required bool isLoadingMore,
    required String? error,
    required VoidCallback onRetry,
    required VoidCallback onLoadMore,
    required String emptyMessage,
  }) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error, style: TextStyle(color: Colors.grey[400])),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (users.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(color: Colors.grey[500], fontSize: 15),
        ),
      );
    }

    return ListView.separated(
      itemCount: users.length + 1, // +1 for load more button
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: Colors.grey[900],
      ),
      itemBuilder: (context, index) {
        if (index == users.length) {
          // Load more button at the bottom
          if (users.length < _pageSize) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: isLoadingMore
                  ? const CircularProgressIndicator(
                      color: Colors.orange, strokeWidth: 2)
                  : TextButton(
                      onPressed: onLoadMore,
                      child: const Text(
                        'Load more',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
            ),
          );
        }

        return EngagementUserTile(
          user: users[index],
          onTap: () => _navigateToProfile(users[index].userId),
        );
      },
    );
  }
}
