// Dart imports
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/followers_social_graph/followers_social_graph_routes.dart';
import 'package:cross_team5/features/followers_social_graph/models/follower.dart';
import 'package:cross_team5/features/followers_social_graph/services/social_api_service.dart';
import 'package:cross_team5/features/followers_social_graph/widgets/user_tile.dart';

class FollowersScreen extends StatefulWidget {
  final String userId;

  const FollowersScreen({super.key, required this.userId});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> with RouteAware {
  final SocialApiService _socialApiService = SocialApiService();
  final AuthApiService _authApiService = AuthApiService();

  List<Follower> _followers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUserId;
  String? _accessToken;
  Set<String> _blockedUserIds = {};

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
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadFollowers();
  }

  void _applyBlockedState(List<Follower> users) {
    for (final user in users) {
      user.isBlocked = _blockedUserIds.contains(user.userId);
      if (user.isBlocked) {
        user.isFollowing = false;
      }
    }
  }

  Future<Set<String>> _loadBlockedUserIds() async {
    final blockedResult = await _socialApiService.getBlockedUsers();
    if (blockedResult.$1 == 200) {
      final blockedUsers = List<Follower>.from(
        blockedResult.$2 as List<Follower>,
      );
      return blockedUsers.map((u) => u.userId).toSet();
    }
    return <String>{};
  }

  Future<void> _loadFollowers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _followers = [];
    });

    final storedCurrentUserId = await _authApiService.getStoredUserId();
    final storedAccessToken = await _authApiService.getStoredAccessToken();

    final followersResult = await _socialApiService.getFollowers(
      userId: widget.userId,
    );
    final blockedUserIds = await _loadBlockedUserIds();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _currentUserId = storedCurrentUserId;
      _accessToken = storedAccessToken;
      _blockedUserIds = blockedUserIds;

      if (followersResult.$1 == 200) {
        _followers = List<Follower>.from(followersResult.$2 as List<Follower>);
        _applyBlockedState(_followers);
      } else {
        _errorMessage = followersResult.$2.toString();
      }
    });
  }

  Future<void> _followUser(String targetUserId) async {
    final previousIndex = _followers.indexWhere((f) => f.userId == targetUserId);
    if (previousIndex == -1) return;
    if (_followers[previousIndex].isBlocked) return;

    final previousValue = _followers[previousIndex].isFollowing;

    setState(() {
      _followers[previousIndex].isFollowing = true;
    });

    final result = await _socialApiService.followUser(
      targetUserId: targetUserId,
    );

    if (!mounted) return;

    if (result.$1 < 200 || result.$1 >= 300) {
      setState(() {
        _followers[previousIndex].isFollowing = previousValue;
      });
      _showSnackbar(result.$2.toString());
    }
  }

  Future<void> _unfollowUser(String targetUserId) async {
    final previousIndex = _followers.indexWhere((f) => f.userId == targetUserId);
    if (previousIndex == -1) return;
    if (_followers[previousIndex].isBlocked) return;

    final previousValue = _followers[previousIndex].isFollowing;

    setState(() {
      _followers[previousIndex].isFollowing = false;
    });

    final result = await _socialApiService.unfollowUser(
      targetUserId: targetUserId,
    );

    if (!mounted) return;

    if (result.$1 < 200 || result.$1 >= 300) {
      setState(() {
        _followers[previousIndex].isFollowing = previousValue;
      });
      _showSnackbar(result.$2.toString());
    }
  }

  Future<void> _blockUser(String targetUserId) async {
    final result = await _socialApiService.blockUser(
      targetUserId: targetUserId,
    );

    if (!mounted) return;

    if (result.$1 >= 200 && result.$1 < 300) {
      setState(() {
        _blockedUserIds.add(targetUserId);
        for (final follower in _followers) {
          if (follower.userId == targetUserId) {
            follower.isBlocked = true;
            follower.isFollowing = false;
          }
        }
      });
      _showSnackbar('User blocked successfully');
    } else {
      _showSnackbar(result.$2.toString());
    }
  }

  Future<void> _unblockUser(String targetUserId) async {
    final result = await _socialApiService.unblockUser(
      targetUserId: targetUserId,
    );

    if (!mounted) return;

    if (result.$1 >= 200 && result.$1 < 300) {
      setState(() {
        _blockedUserIds.remove(targetUserId);
        for (final follower in _followers) {
          if (follower.userId == targetUserId) {
            follower.isBlocked = false;
          }
        }
      });
      _showSnackbar('User unblocked successfully');
    } else {
      _showSnackbar(result.$2.toString());
    }
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  bool get _isOwnProfile =>
      _currentUserId != null && _currentUserId == widget.userId;

  Widget _buildTrueFriendsBanner() {
    if (!_isOwnProfile) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(
          context,
          FollowersSocialGraphRoutes.trueFriends,
          arguments: {'userId': widget.userId},
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white54, width: 1.5),
                ),
                child: const Icon(Icons.group, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'People who follow you back',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'See your true friends',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableMessage({
    required Widget child,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 220),
        Center(child: child),
      ],
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
      body: RefreshIndicator(
        onRefresh: _loadFollowers,
        child: _isLoading
            ? _buildScrollableMessage(
                child: const CircularProgressIndicator(),
              )
            : _errorMessage != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildTrueFriendsBanner(),
                  const SizedBox(height: 180),
                  Center(child: Text(_errorMessage!)),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton(
                      onPressed: _loadFollowers,
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              )
            : _followers.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildTrueFriendsBanner(),
                  const SizedBox(height: 180),
                  const Center(child: Text('No followers yet.')),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _followers.length + 1,
                separatorBuilder: (context, index) =>
                    index == 0 ? const SizedBox.shrink() : const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index == 0) return _buildTrueFriendsBanner();
                  final follower = _followers[index - 1];
                  return UserTile(
                    follower: follower,
                    currentUserId: _currentUserId,
                    accessToken: _accessToken,
                    showBlockOption: !follower.isBlocked,
                    showUnblockOption: follower.isBlocked,
                    onFollowTap: follower.isBlocked
                        ? null
                        : () => follower.isFollowing
                              ? _unfollowUser(follower.userId)
                              : _followUser(follower.userId),
                    onBlockTap: follower.isBlocked
                        ? null
                        : () => _confirmBlock(follower),
                    onUnblockTap: follower.isBlocked
                        ? () => _unblockUser(follower.userId)
                        : null,
                  );
                },
              ),
      ),
    );
  }
}