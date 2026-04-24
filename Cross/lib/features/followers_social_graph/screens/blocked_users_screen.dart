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
  bool _isRefreshing = false;
  String? _errorMessage;

  String? _currentUserId;
  String? _accessToken;

  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers(initial: true);
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
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers({bool initial = false}) async {
    if (!mounted) return;

    setState(() {
      if (initial) {
        _isLoading = true;
      } else {
        _isRefreshing = true;
      }
      _errorMessage = null;
    });

    final storedCurrentUserId = await _authApiService.getStoredUserId();
    final storedAccessToken = await _authApiService.getStoredAccessToken();
    final result = await _socialApiService.getBlockedUsers();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isRefreshing = false;

      _currentUserId = storedCurrentUserId;
      _accessToken = storedAccessToken;

      if (result.$1 == 200) {
        _blockedUsers = List<Follower>.from(result.$2 as List<Follower>);

        // IMPORTANT:
        // Mark every user here as blocked so UserTile disables navigation.
        for (final user in _blockedUsers) {
          user.isBlocked = true;
          user.isFollowing = false;
        }
      } else {
        _errorMessage = result.$2.toString();
      }
    });
  }

  Future<void> _unblockUser(String targetUserId) async {
    final result = await _socialApiService.unblockUser(
      targetUserId: targetUserId,
    );

    if (!mounted) return;

    if (result.$1 >= 200 && result.$1 < 300) {
      setState(() {
        _blockedUsers.removeWhere((u) => u.userId == targetUserId);
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
        title: const Text('Blocked Users'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => _loadBlockedUsers(),
            child: _isLoading
                ? _buildScrollableMessage(
                    child: const CircularProgressIndicator(),
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
                          onPressed: () => _loadBlockedUsers(),
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  )
                : _blockedUsers.isEmpty
                ? _buildScrollableMessage(
                    child: const Text('You have not blocked anyone.'),
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _blockedUsers.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = _blockedUsers[index];
                      return UserTile(
                        follower: user,
                        currentUserId: _currentUserId,
                        accessToken: _accessToken,
                        onFollowTap: null,
                        showBlockOption: false,
                        showUnblockOption: true,
                        onUnblockTap: () => _unblockUser(user.userId),
                      );
                    },
                  ),
          ),
          if (_isRefreshing)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}