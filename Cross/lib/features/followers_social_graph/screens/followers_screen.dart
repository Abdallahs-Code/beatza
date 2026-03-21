import 'package:flutter/material.dart';

import '../models/follower.dart';
import '../services/social_api_service.dart';
import '../widgets/user_tile.dart';


class FollowersScreen extends StatefulWidget 
{
  final String userId;

  const FollowersScreen({super.key, required this.userId});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}


class _FollowersScreenState extends State<FollowersScreen>
    with SingleTickerProviderStateMixin 
{
  final SocialApiService _socialApiService = SocialApiService();
  late TabController _tabController;

  // ── List state ──────────────────────────────────
  List<Follower> _followers = [];
  List<Follower> _following = [];
  List<Follower> _suggested = [];

  // ── Loading / error state ───────────────────────
  bool _isLoading    = true;
  String? _errorMessage;

  @override
  void initState() 
  {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() 
  {
    _tabController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Load all three lists simultaneously when screen opens
  // ─────────────────────────────────────────────
  Future<void> _loadAll() async 
  {
    setState(() 
    {
      _isLoading    = true;
      _errorMessage = null;
    });

    final followersResult = await _socialApiService.getFollowers(userId: widget.userId);
    final followingResult = await _socialApiService.getFollowing(userId: widget.userId);
    final suggestedResult = await _socialApiService.getSuggestedUsers();

    setState(() 
    {
      _isLoading = false;

      if (followersResult.$1 == 200)
      {
        _followers = followersResult.$2 as List<Follower>;
      }
      if (followingResult.$1 == 200)
      {
        _following = followingResult.$2 as List<Follower>;
      }
      if (suggestedResult.$1 == 200)
      {
        _suggested = suggestedResult.$2 as List<Follower>;
      }

      // Show error only if ALL three failed
      if (followersResult.$1 != 200 &&
          followingResult.$1 != 200 &&
          suggestedResult.$1 != 200)
      {
        _errorMessage = "Failed to load social data. Please try again.";
      }
    });
  }

  // ─────────────────────────────────────────────
  // Follow — optimistic update, revert on failure
  // ─────────────────────────────────────────────
  Future<void> _followUser(String targetUserId) async 
  {
    _updateFollowState(targetUserId, isFollowing: true);

    final result = await _socialApiService.followUser(targetUserId: targetUserId);

    if (result.$1 != 200) 
    {
      _updateFollowState(targetUserId, isFollowing: false);
      _showSnackbar(result.$2.toString());
    }
  }

  // ─────────────────────────────────────────────
  // Unfollow — optimistic update, revert on failure
  // ─────────────────────────────────────────────
  Future<void> _unfollowUser(String targetUserId) async 
  {
    _updateFollowState(targetUserId, isFollowing: false);

    final result = await _socialApiService.unfollowUser(targetUserId: targetUserId);

    if (result.$1 != 200) 
    {
      _updateFollowState(targetUserId, isFollowing: true);
      _showSnackbar(result.$2.toString());
    }
  }

  // ─────────────────────────────────────────────
  // Block — remove from all local lists on success
  // ─────────────────────────────────────────────
  Future<void> _blockUser(String targetUserId) async 
  {
    final result = await _socialApiService.blockUser(targetUserId: targetUserId);

    if (result.$1 == 200) 
    {
      setState(() 
      {
        _followers.removeWhere((f) => f.userId == targetUserId);
        _following.removeWhere((f) => f.userId == targetUserId);
        _suggested.removeWhere((f) => f.userId == targetUserId);
      });
      _showSnackbar("User blocked successfully");
    } 
    else 
    {
      _showSnackbar(result.$2.toString());
    }
  }

  // ─────────────────────────────────────────────
  // HELPER: updates isFollowing flag across all three lists
  // ─────────────────────────────────────────────
  void _updateFollowState(String userId, {required bool isFollowing}) 
  {
    setState(() 
    {
      for (final f in _followers) { if (f.userId == userId) f.isFollowing = isFollowing; }
      for (final f in _following) { if (f.userId == userId) f.isFollowing = isFollowing; }
      for (final f in _suggested) { if (f.userId == userId) f.isFollowing = isFollowing; }
    });
  }

  // ─────────────────────────────────────────────
  // HELPER: shows a snackbar message
  // ─────────────────────────────────────────────
  void _showSnackbar(String message) 
  {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ─────────────────────────────────────────────
  // HELPER: block confirmation dialog
  // ─────────────────────────────────────────────
  void _confirmBlock(Follower follower) 
  {
    showDialog(
      context: context,
      builder: (_) => AlertDialog
      (
        title: const Text('Block User'),
        content: Text('Block ${follower.displayName}? They will not be able to see your profile.'),
        actions: 
        [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () 
            {
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
  Widget build(BuildContext context) 
  {
    return Scaffold
    (
      appBar: AppBar
      (
        title: const Text('Social'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        bottom: TabBar
        (
          controller: _tabController,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orange,
          tabs: const 
          [
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
            Tab(text: 'Suggested'),
          ],
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center
                (
                  child: Column
                  (
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: 
                    [
                      Text(_errorMessage!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadAll,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView
                (
                  controller: _tabController,
                  children: 
                  [
                    _buildList(_followers, showBlock: true),
                    _buildList(_following, showBlock: true),
                    _buildList(_suggested, showBlock: false),
                  ],
                ),
    );
  }

  // ─────────────────────────────────────────────
  // HELPER: builds a scrollable list of UserTiles
  // ─────────────────────────────────────────────
  Widget _buildList(List<Follower> list, {required bool showBlock}) 
  {
    if (list.isEmpty) 
    {
      return const Center(child: Text('Nothing here yet.'));
    }

    return ListView.separated
    (
      itemCount: list.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) 
      {
        final follower = list[index];
        return UserTile
        (
          follower: follower,
          showBlockOption: showBlock,
          onFollowTap: () => follower.isFollowing
              ? _unfollowUser(follower.userId)
              : _followUser(follower.userId),
          onBlockTap: showBlock
              ? () => _confirmBlock(follower)
              : null,
        );
      },
    );
  }
}
