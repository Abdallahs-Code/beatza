// Dart imports
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/features/followers_social_graph/models/follower.dart';
import 'package:cross_team5/features/followers_social_graph/services/social_api_service.dart';
import 'package:cross_team5/features/followers_social_graph/widgets/user_tile.dart';

class FollowersScreen extends StatefulWidget {
  final String userId;

  const FollowersScreen({
    super.key,
    required this.userId,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen>
    with RouteAware {
  final SocialApiService _socialApiService = SocialApiService();

  List<Follower> _followers = [];
  bool _isLoading = true;
  String? _errorMessage;

  // RouteObserver for detecting when user returns to this screen
  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route events so we can refresh when returning to this screen
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Called when user navigates back to this screen from another screen
  @override
  void didPopNext() {
    _loadFollowers();
  }

  // ─────────────────────────────────────────────
  // Load followers from API — called on open and on return
  // ─────────────────────────────────────────────
  Future<void> _loadFollowers() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  final followersResult = await _socialApiService.getFollowers(
    userId: widget.userId,
  );

  if (followersResult.$1 != 200) {
    setState(() {
      _isLoading = false;
      _errorMessage = followersResult.$2.toString();
    });
    return;
  }

  final followingResult = await _socialApiService.getFollowing(
    userId: widget.userId,
  );

  final followers = List<Follower>.from(followersResult.$2 as List<Follower>);

  if (followingResult.$1 == 200) {
    final following = followingResult.$2 as List<Follower>;
    final followedUserIds = following.map((u) => u.userId).toSet();

    for (final follower in followers) {
      follower.isFollowing = followedUserIds.contains(follower.userId);
    }
  }

  setState(() {
    _followers = followers;
    _isLoading = false;
  });
}

  // ─────────────────────────────────────────────
  // Follow — optimistic update, revert on failure
  // ─────────────────────────────────────────────
  Future<void> _followUser(String targetUserId) async {
    setState(() {
      for (final f in _followers) {
        if (f.userId == targetUserId) f.isFollowing = true;
      }
    });

    final result = await _socialApiService.followUser(
      targetUserId: targetUserId,
    );

    if (result.$1 != 200) {
      setState(() {
        for (final f in _followers) {
          if (f.userId == targetUserId) f.isFollowing = false;
        }
      });
      _showSnackbar(result.$2.toString());
    }
  }

  // ─────────────────────────────────────────────
  // Unfollow — optimistic update, revert on failure
  // ─────────────────────────────────────────────
  Future<void> _unfollowUser(String targetUserId) async {
    setState(() {
      for (final f in _followers) {
        if (f.userId == targetUserId) f.isFollowing = false;
      }
    });

    final result = await _socialApiService.unfollowUser(
      targetUserId: targetUserId,
    );

    if (result.$1 != 200) {
      setState(() {
        for (final f in _followers) {
          if (f.userId == targetUserId) f.isFollowing = true;
        }
      });
      _showSnackbar(result.$2.toString());
    }
  }

  // ─────────────────────────────────────────────
  // Block — remove from local list on success
  // ─────────────────────────────────────────────
  Future<void> _blockUser(String targetUserId) async {
    final result = await _socialApiService.blockUser(
      targetUserId: targetUserId,
    );

    if (result.$1 == 200) {
      setState(() {
        _followers.removeWhere((f) => f.userId == targetUserId);
      });
      _showSnackbar('User blocked successfully');
    } else {
      _showSnackbar(result.$2.toString());
    }
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
        title: const Text('Followers'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadFollowers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  // Pull-to-refresh support
                  onRefresh: _loadFollowers,
                  child: _followers.isEmpty
                      ? const Center(child: Text('No followers yet.'))
                      : ListView.separated(
                          itemCount: _followers.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final follower = _followers[index];
                            return UserTile(
                              follower: follower,
                              showBlockOption: true,
                              showUnblockOption: false,
                              // Follow if not following, unfollow if already following
                              onFollowTap: () => follower.isFollowing
                                  ? _unfollowUser(follower.userId)
                                  : _followUser(follower.userId),
                              onBlockTap: () => _confirmBlock(follower),
                            );
                          },
                        ),
                ),
    );
  }
}
