import 'package:flutter/material.dart';

import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/followers_social_graph/models/follower.dart';
import 'package:cross_team5/features/followers_social_graph/services/social_api_service.dart';
import 'package:cross_team5/features/followers_social_graph/widgets/user_tile.dart';
import 'package:provider/provider.dart';
import 'package:cross_team5/core/services/theme_service.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

class TrueFriendsScreen extends StatefulWidget {
  final String userId;

  const TrueFriendsScreen({super.key, required this.userId});

  @override
  State<TrueFriendsScreen> createState() => _TrueFriendsScreenState();
}

class _TrueFriendsScreenState extends State<TrueFriendsScreen> {
  final SocialApiService _socialApiService = SocialApiService();
  final AuthApiService _authApiService = AuthApiService();

  List<Follower> _trueFriends = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUserId;
  Set<String> _blockedUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadTrueFriends();
  }

  Future<Set<String>> _loadBlockedUserIds() async {
    final result = await _socialApiService.getBlockedUsers();
    if (result.$1 == 200) {
      return (result.$2 as List<Follower>).map((u) => u.userId).toSet();
    }
    return {};
  }

  void _applyBlockedState(List<Follower> users) {
    for (final user in users) {
      user.isBlocked = _blockedUserIds.contains(user.userId);
      if (user.isBlocked) user.isFollowing = false;
    }
  }

  Future<void> _loadTrueFriends() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _trueFriends = [];
    });

    final storedCurrentUserId = await _authApiService.getStoredUserId();

    final results = await Future.wait([
      _socialApiService.getFollowers(userId: widget.userId),
      _socialApiService.getFollowing(userId: widget.userId),
      _loadBlockedUserIds(),
    ]);

    if (!mounted) return;

    final followersResult = results[0] as (int, dynamic);
    final followingResult = results[1] as (int, dynamic);
    final blockedIds = results[2] as Set<String>;

    if (followersResult.$1 != 200) {
      setState(() {
        _isLoading = false;
        _errorMessage = followersResult.$2.toString();
      });
      return;
    }

    if (followingResult.$1 != 200) {
      setState(() {
        _isLoading = false;
        _errorMessage = followingResult.$2.toString();
      });
      return;
    }

    final followers = List<Follower>.from(followersResult.$2 as List<Follower>);
    final following = List<Follower>.from(followingResult.$2 as List<Follower>);

    final followingIds = following.map((f) => f.userId).toSet();

    final trueFriends = followers
        .where((f) => followingIds.contains(f.userId))
        .toList();

    setState(() {
      _isLoading = false;
      _currentUserId = storedCurrentUserId;
      _blockedUserIds = blockedIds;
      _trueFriends = trueFriends;
      _applyBlockedState(_trueFriends);
    });
  }

  Future<void> _followUser(String targetUserId) async {
    final idx = _trueFriends.indexWhere((f) => f.userId == targetUserId);
    if (idx == -1 || _trueFriends[idx].isBlocked) return;

    final prev = _trueFriends[idx].isFollowing;
    setState(() => _trueFriends[idx].isFollowing = true);

    final result = await _socialApiService.followUser(
      targetUserId: targetUserId,
    );
    if (!mounted) return;

    if (result.$1 < 200 || result.$1 >= 300) {
      setState(() => _trueFriends[idx].isFollowing = prev);
      _showSnackbar(result.$2.toString());
    }
  }

  Future<void> _unfollowUser(String targetUserId) async {
    final idx = _trueFriends.indexWhere((f) => f.userId == targetUserId);
    if (idx == -1 || _trueFriends[idx].isBlocked) return;

    final prev = _trueFriends[idx].isFollowing;
    setState(() => _trueFriends[idx].isFollowing = false);

    final result = await _socialApiService.unfollowUser(
      targetUserId: targetUserId,
    );
    if (!mounted) return;

    if (result.$1 < 200 || result.$1 >= 300) {
      setState(() => _trueFriends[idx].isFollowing = prev);
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
        for (final f in _trueFriends) {
          if (f.userId == targetUserId) {
            f.isBlocked = true;
            f.isFollowing = false;
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
        for (final f in _trueFriends) {
          if (f.userId == targetUserId) f.isBlocked = false;
        }
      });
      _showSnackbar('User unblocked successfully');
    } else {
      _showSnackbar(result.$2.toString());
    }
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
            child: Text('Block', style: TextStyle(color: AppColors.deepRed)),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your true friends'),
        backgroundColor: AppColors.pureBlack,
        foregroundColor: AppColors.whiteSmoke,
      ),
      body: RefreshIndicator(
        onRefresh: _loadTrueFriends,
        child: _isLoading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 220),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _errorMessage != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 220),
                  Center(child: Text(_errorMessage!)),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton(
                      onPressed: _loadTrueFriends,
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              )
            : _trueFriends.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 220),
                  Center(child: Text('No true friends yet.')),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _trueFriends.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final friend = _trueFriends[index];
                  return UserTile(
                    follower: friend,
                    currentUserId: _currentUserId,
                    showBlockOption: !friend.isBlocked,
                    showUnblockOption: friend.isBlocked,
                    onFollowTap: friend.isBlocked
                        ? null
                        : () => friend.isFollowing
                              ? _unfollowUser(friend.userId)
                              : _followUser(friend.userId),
                    onBlockTap: friend.isBlocked
                        ? null
                        : () => _confirmBlock(friend),
                    onUnblockTap: friend.isBlocked
                        ? () => _unblockUser(friend.userId)
                        : null,
                  );
                },
              ),
      ),
    );
  }
}
