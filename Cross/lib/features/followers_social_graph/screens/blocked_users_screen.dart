import 'package:flutter/material.dart';

import '../models/follower.dart';
import '../services/social_api_service.dart';
import '../widgets/user_tile.dart';


class BlockedUsersScreen extends StatefulWidget 
{

  
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}


class _BlockedUsersScreenState extends State<BlockedUsersScreen> 
{
  final SocialApiService _socialApiService = SocialApiService();

  List<Follower> _blockedUsers = [];
  bool _isLoading    = true;
  String? _errorMessage;

  @override
  void initState() 
  {
    super.initState();
    _loadBlockedUsers();
  }

  // ─────────────────────────────────────────────
  // Load blocked users on screen open
  // ─────────────────────────────────────────────
  Future<void> _loadBlockedUsers() async 
  {
    setState(() 
    {
      _isLoading    = true;
      _errorMessage = null;
    });

    final result = await _socialApiService.getBlockedUsers();

    setState(() 
    {
      _isLoading = false;

      if (result.$1 == 200) 
      {
        _blockedUsers = result.$2 as List<Follower>;
      } 
      else 
      {
        _errorMessage = result.$2.toString();
      }
    });
  }

  // ─────────────────────────────────────────────
  // Unblock a user and remove from local list
  // ─────────────────────────────────────────────
  Future<void> _unblockUser(String targetUserId) async 
  {
    final result = await _socialApiService.unblockUser(targetUserId: targetUserId);

    if (result.$1 == 200) 
    {
      setState(() 
      {
        _blockedUsers.removeWhere((u) => u.userId == targetUserId);
      });
      _showSnackbar("User unblocked successfully");
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

  @override
  Widget build(BuildContext context) 
  {
    return Scaffold
    (
      appBar: AppBar
      (
        title: const Text('Blocked Users'),
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
                        onPressed: _loadBlockedUsers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _blockedUsers.isEmpty
                  ? const Center(child: Text('You have not blocked anyone.'))
                  : ListView.separated
                    (
                      itemCount: _blockedUsers.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) 
                      {
                        final user = _blockedUsers[index];
                        return UserTile
                        (
                          follower: user,
                          showBlockOption: false,
                          onUnblockTap: () => _unblockUser(user.userId),
                        );
                      },
                    ),
    );
  }
}
