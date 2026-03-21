import 'package:flutter/material.dart';

import '../models/follower.dart';
import '../services/social_api_service.dart';
import '../widgets/user_tile.dart';


class FollowingScreen extends StatefulWidget 
{
  final String userId;

  const FollowingScreen({super.key, required this.userId});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}


class _FollowingScreenState extends State<FollowingScreen> 
{
  final SocialApiService _socialApiService = SocialApiService();

  List<Follower> _following  = [];
  bool           _isLoading  = true;
  String?        _errorMessage;

  @override
  void initState() 
  {
    super.initState();
    _loadFollowing();
  }

  // ─────────────────────────────────────────────
  // Load following list on screen open
  // ─────────────────────────────────────────────
  Future<void> _loadFollowing() async 
  {
    setState(() 
    {
      _isLoading    = true;
      _errorMessage = null;
    });

    final result = await _socialApiService.getFollowing(userId: widget.userId);

    setState(() 
    {
      _isLoading = false;

      if (result.$1 == 200) 
      {
        _following = result.$2 as List<Follower>;
      } 
      else 
      {
        _errorMessage = result.$2.toString();
      }
    });
  }

  // ─────────────────────────────────────────────
  // Unfollow — optimistic update, revert on failure
  // ─────────────────────────────────────────────
  Future<void> _unfollowUser(String targetUserId) async 
  {
    setState(() 
    {
      for (final f in _following) 
      {
        if (f.userId == targetUserId) f.isFollowing = false;
      }
    });

    final result = await _socialApiService.unfollowUser(targetUserId: targetUserId);

    if (result.$1 == 200) 
    {
      // Remove from list entirely after successful unfollow
      setState(() 
      {
        _following.removeWhere((f) => f.userId == targetUserId);
      });
    } 
    else 
    {
      // Revert on failure
      setState(() 
      {
        for (final f in _following) 
        {
          if (f.userId == targetUserId) f.isFollowing = true;
        }
      });
      _showSnackbar(result.$2.toString());
    }
  }

  // ─────────────────────────────────────────────
  // Follow — for users that were unfollowed and re-followed
  // ─────────────────────────────────────────────
  Future<void> _followUser(String targetUserId) async 
  {
    setState(() 
    {
      for (final f in _following) 
      {
        if (f.userId == targetUserId) f.isFollowing = true;
      }
    });

    final result = await _socialApiService.followUser(targetUserId: targetUserId);

    if (result.$1 != 200) 
    {
      setState(() 
      {
        for (final f in _following) 
        {
          if (f.userId == targetUserId) f.isFollowing = false;
        }
      });
      _showSnackbar(result.$2.toString());
    }
  }

  // ─────────────────────────────────────────────
  // Block — remove from list on success
  // ─────────────────────────────────────────────
  Future<void> _blockUser(String targetUserId) async 
  {
    final result = await _socialApiService.blockUser(targetUserId: targetUserId);

    if (result.$1 == 200) 
    {
      setState(() 
      {
        _following.removeWhere((f) => f.userId == targetUserId);
      });
      _showSnackbar("User blocked successfully");
    } 
    else 
    {
      _showSnackbar(result.$2.toString());
    }
  }

  void _showSnackbar(String message) 
  {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

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
        title: const Text('Following'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
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
                        onPressed: _loadFollowing,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _following.isEmpty
                  ? const Center(child: Text('Not following anyone yet.'))
                  : ListView.separated
                    (
                      itemCount: _following.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) 
                      {
                        final follower = _following[index];
                        return UserTile
                        (
                          follower: follower,
                          showBlockOption: true,
                          onFollowTap: () => follower.isFollowing
                              ? _unfollowUser(follower.userId)
                              : _followUser(follower.userId),
                          onBlockTap: () => _confirmBlock(follower),
                        );
                      },
                    ),
    );
  }
}