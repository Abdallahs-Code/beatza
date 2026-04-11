// Dart imports
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/features/followers_social_graph/models/follower.dart';
import 'package:cross_team5/features/followers_social_graph/services/social_api_service.dart';
import 'package:cross_team5/features/followers_social_graph/widgets/user_tile.dart';

class FollowingScreen extends StatefulWidget {
  final String userId;

  const FollowingScreen({
    super.key,
    required this.userId,
  });

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  final SocialApiService _socialApiService = SocialApiService();
  late TabController _tabController;

  List<Follower> _following = [];
  List<Follower> _suggested = [];

  bool _isLoadingFollowing = true;
  bool _isLoadingSuggested = true;
  String? _followingError;
  String? _suggestedError;

  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _tabController.dispose();
    super.dispose();
  }

  // Refresh both lists when returning to this screen
  @override
  void didPopNext() {
    _loadAll();
  }

  // ─────────────────────────────────────────────
  // Load both lists simultaneously
  // ─────────────────────────────────────────────
  Future<void> _loadAll() async {
    _loadFollowing();
    _loadSuggested();
  }

  Future<void> _loadFollowing() async {
    setState(() {
      _isLoadingFollowing = true;
      _followingError = null;
    });

    final result = await _socialApiService.getFollowing(
      userId: widget.userId,
    );

    setState(() {
      _isLoadingFollowing = false;
      if (result.$1 == 200) {
        _following = result.$2 as List<Follower>;
      } else {
        _followingError = result.$2.toString();
      }
    });
  }

  Future<void> _loadSuggested() async {
    setState(() {
      _isLoadingSuggested = true;
      _suggestedError = null;
    });

    final result = await _socialApiService.getSuggestedUsers();

    setState(() {
      _isLoadingSuggested = false;
      if (result.$1 == 200) {
        _suggested = result.$2 as List<Follower>;
      } else {
        _suggestedError = result.$2.toString();
      }
    });
  }

  // ─────────────────────────────────────────────
  // Follow — optimistic update across both lists
  // ─────────────────────────────────────────────
  Future<void> _followUser(String targetUserId) async {
    _updateFollowState(targetUserId, isFollowing: true);

    final result = await _socialApiService.followUser(
      targetUserId: targetUserId,
    );

    if (result.$1 != 200) {
      _updateFollowState(targetUserId, isFollowing: false);
      _showSnackbar(result.$2.toString());
    }
  }

  // ─────────────────────────────────────────────
  // Unfollow — optimistic update + remove from following list
  // ─────────────────────────────────────────────
  Future<void> _unfollowUser(String targetUserId) async {
    // Optimistically mark as not following
    _updateFollowState(targetUserId, isFollowing: false);

    final result = await _socialApiService.unfollowUser(
      targetUserId: targetUserId,
    );

    if (result.$1 == 200) {
      // Remove from following list after confirmed unfollow
      setState(() {
        _following.removeWhere((f) => f.userId == targetUserId);
      });
    } else {
      // Revert on failure
      _updateFollowState(targetUserId, isFollowing: true);
      _showSnackbar(result.$2.toString());
    }
  }

  // ─────────────────────────────────────────────
  // Block — remove from both lists on success
  // ─────────────────────────────────────────────
  Future<void> _blockUser(String targetUserId) async {
    final result = await _socialApiService.blockUser(
      targetUserId: targetUserId,
    );

    if (result.$1 == 200) {
      setState(() {
        _following.removeWhere((f) => f.userId == targetUserId);
        _suggested.removeWhere((f) => f.userId == targetUserId);
      });
      _showSnackbar('User blocked successfully');
    } else {
      _showSnackbar(result.$2.toString());
    }
  }

  // ─────────────────────────────────────────────
  // HELPER: updates isFollowing across both lists
  // ─────────────────────────────────────────────
  void _updateFollowState(String userId, {required bool isFollowing}) {
    setState(() {
      for (final f in _following) {
        if (f.userId == userId) f.isFollowing = isFollowing;
      }
      for (final f in _suggested) {
        if (f.userId == userId) f.isFollowing = isFollowing;
      }
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _confirmBlock(Follower follower) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          'Block ${follower.displayName}? They will not be able to see your profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _blockUser(follower.userId);
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Following'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(text: 'Following'),
            Tab(text: 'Suggested'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Following tab ──────────────────────────────
          _isLoadingFollowing
              ? const Center(child: CircularProgressIndicator())
              : _followingError != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_followingError!),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadFollowing,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFollowing,
                      child: _following.isEmpty
                          ? const Center(
                              child: Text('You are not following anyone yet.'),
                            )
                          : ListView.separated(
                              itemCount: _following.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final follower = _following[index];
                                return UserTile(
                                  follower: follower,
                                  showBlockOption: true,
                                  showUnblockOption: false,
                                  // In following list, all users are followed —
                                  // tapping button unfollows and removes them
                                  onFollowTap: () => follower.isFollowing
                                      ? _unfollowUser(follower.userId)
                                      : _followUser(follower.userId),
                                  onBlockTap: () => _confirmBlock(follower),
                                );
                              },
                            ),
                    ),

          // ── Suggested tab ──────────────────────────────
          _isLoadingSuggested
              ? const Center(child: CircularProgressIndicator())
              : _suggestedError != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_suggestedError!),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadSuggested,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSuggested,
                      child: _suggested.isEmpty
                          ? const Center(child: Text('No suggestions yet.'))
                          : ListView.separated(
                              itemCount: _suggested.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final follower = _suggested[index];
                                return UserTile(
                                  follower: follower,
                                  // No block option on suggested list
                                  showBlockOption: false,
                                  showUnblockOption: false,
                                  onFollowTap: () => follower.isFollowing
                                      ? _unfollowUser(follower.userId)
                                      : _followUser(follower.userId),
                                );
                              },
                            ),
                    ),
        ],
      ),
    );
  }
}
