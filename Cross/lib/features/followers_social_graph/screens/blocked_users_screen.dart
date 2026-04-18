// Dart imports
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/followers_social_graph/models/follower.dart';
import 'package:cross_team5/features/followers_social_graph/services/social_api_service.dart';
import 'package:cross_team5/features/followers_social_graph/widgets/user_tile.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen>
    with RouteAware {
  final SocialApiService _socialApiService = SocialApiService();
  final AuthApiService _authApiService = AuthApiService();

  List<Follower> _blockedUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUserId;

  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final storedCurrentUserId = await _authApiService.getStoredUserId();
    final result = await _socialApiService.getBlockedUsers();

    setState(() {
      _isLoading = false;
      _currentUserId = storedCurrentUserId;
      if (result.$1 == 200) {
        _blockedUsers = result.$2 as List<Follower>;
      } else {
        _errorMessage = result.$2.toString();
      }
    });
  }

  Future<void> _unblockUser(String targetUserId) async {
    final result = await _socialApiService.unblockUser(
      targetUserId: targetUserId,
    );

    if (result.$1 == 200) {
      setState(() {
        _blockedUsers.removeWhere((u) => u.userId == targetUserId);
      });
      _showSnackbar('User unblocked successfully');
    } else {
      _showSnackbar(result.$2.toString());
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
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
                    onPressed: _loadBlockedUsers,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadBlockedUsers,
              child: _blockedUsers.isEmpty
                  ? const Center(child: Text('You have not blocked anyone.'))
                  : ListView.separated(
                      itemCount: _blockedUsers.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = _blockedUsers[index];
                        return UserTile(
                          follower: user,
                          currentUserId: _currentUserId,
                          onFollowTap: null,
                          showBlockOption: false,
                          showUnblockOption: true,
                          onUnblockTap: () => _unblockUser(user.userId),
                        );
                      },
                    ),
            ),
    );
  }
}
