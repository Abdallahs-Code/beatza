// Dart imports
import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

// Package imports
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/followers_social_graph/followers_social_graph_routes.dart';
import 'package:cross_team5/features/followers_social_graph/models/follower.dart';
import 'package:cross_team5/features/followers_social_graph/services/social_api_service.dart';
import 'package:cross_team5/features/followers_social_graph/widgets/user_tile.dart';

class FollowingScreen extends StatefulWidget {
  final String userId;
  final String token;
  final String? currentUserId;
  final int initialTabIndex;

  const FollowingScreen({
    super.key,
    required this.userId,
    required this.token,
    this.currentUserId,
    this.initialTabIndex = 0,
  });

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  final SocialApiService _socialApiService = SocialApiService();
  final AuthApiService _authApiService = AuthApiService();

  late TabController _tabController;

  List<Follower> _following = [];
  List<Follower> _suggested = [];

  bool _isLoadingFollowing = true;
  bool _isLoadingSuggested = true;
  String? _followingError;
  String? _suggestedError;

  String? _currentUserId;
  Set<String> _blockedUserIds = {};

  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    _tabController.addListener(_handleTabChange);

    _loadAll();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;

    if (_tabController.index == 0) {
      _loadFollowing();
    } else if (_tabController.index == 1) {
      _loadSuggested();
    }
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
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadAll();
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

  Future<void> _loadAll() async {
    final storedCurrentUserId = await _authApiService.getStoredUserId();
    final blockedUserIds = await _loadBlockedUserIds();

    if (!mounted) return;

    setState(() {
      _currentUserId = storedCurrentUserId;
      _blockedUserIds = blockedUserIds;
    });

    await Future.wait([_loadFollowing(), _loadSuggested()]);
  }

  Future<void> _loadFollowing() async {
    if (!mounted) return;

    setState(() {
      _isLoadingFollowing = true;
      _followingError = null;
      _following = [];
    });

    final result = await _socialApiService.getFollowing(userId: widget.userId);

    if (!mounted) return;

    setState(() {
      _isLoadingFollowing = false;
      if (result.$1 == 200) {
        _following = List<Follower>.from(result.$2 as List<Follower>);
        _applyBlockedState(_following);
      } else {
        _followingError = result.$2.toString();
      }
    });
  }

  Future<void> _loadSuggested() async {
    if (!mounted) return;

    setState(() {
      _isLoadingSuggested = true;
      _suggestedError = null;
      _suggested = [];
    });

    final result = await _socialApiService.getSuggestedUsers();

    if (!mounted) return;

    setState(() {
      _isLoadingSuggested = false;
      if (result.$1 == 200) {
        _suggested = List<Follower>.from(result.$2 as List<Follower>);
        _applyBlockedState(_suggested);
      } else {
        _suggestedError = result.$2.toString();
      }
    });
  }

  Future<void> _followUser(String targetUserId) async {
    final blocked = _blockedUserIds.contains(targetUserId);
    if (blocked) return;

    _updateFollowState(targetUserId, isFollowing: true);

    final result = await _socialApiService.followUser(
      targetUserId: targetUserId,
    );

    if (!mounted) return;

    if (result.$1 < 200 || result.$1 >= 300) {
      _updateFollowState(targetUserId, isFollowing: false);
      _showSnackbar(result.$2.toString());
      return;
    }
  }

  Future<void> _unfollowUser(String targetUserId) async {
    final blocked = _blockedUserIds.contains(targetUserId);
    if (blocked) return;

    _updateFollowState(targetUserId, isFollowing: false);

    final result = await _socialApiService.unfollowUser(
      targetUserId: targetUserId,
    );

    if (!mounted) return;

    if (result.$1 < 200 || result.$1 >= 300) {
      _updateFollowState(targetUserId, isFollowing: true);
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

        for (final f in _following) {
          if (f.userId == targetUserId) {
            f.isBlocked = true;
            f.isFollowing = false;
          }
        }

        for (final f in _suggested) {
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

        for (final f in _following) {
          if (f.userId == targetUserId) {
            f.isBlocked = false;
          }
        }

        for (final f in _suggested) {
          if (f.userId == targetUserId) {
            f.isBlocked = false;
          }
        }
      });
      _showSnackbar('User unblocked successfully');
    } else {
      _showSnackbar(result.$2.toString());
    }
  }

  void _updateFollowState(String userId, {required bool isFollowing}) {
    if (!mounted) return;

    setState(() {
      for (final f in _following) {
        if (f.userId == userId && !f.isBlocked) {
          f.isFollowing = isFollowing;
        }
      }
      for (final f in _suggested) {
        if (f.userId == userId && !f.isBlocked) {
          f.isFollowing = isFollowing;
        }
      }
    });
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
            child: Text('Block', style: TextStyle(color: AppColors.deepRed)),
          ),
        ],
      ),
    );
  }

  void _goBackToProfile() {
    Navigator.pop(context);
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
            color: AppColors.trueFriendsBg,
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
                  border: Border.all(color: AppColors.white54, width: 1.5),
                ),
                child: Icon(Icons.group, color: AppColors.whiteSmoke, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'People who follow you back',
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'See your true friends',
                      style: TextStyle(color: AppColors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFollowingTab() {
    return RefreshIndicator(
      onRefresh: _loadFollowing,
      child: _isLoadingFollowing
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildTrueFriendsBanner(),
                const SizedBox(height: 220),
                const Center(child: CircularProgressIndicator()),
              ],
            )
          : _followingError != null
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildTrueFriendsBanner(),
                const SizedBox(height: 180),
                Center(child: Text(_followingError!)),
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton(
                    onPressed: _loadFollowing,
                    child: const Text('Retry'),
                  ),
                ),
              ],
            )
          : _following.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildTrueFriendsBanner(),
                const SizedBox(height: 180),
                const Center(child: Text('You are not following anyone yet.')),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _following.length + 1,
              separatorBuilder: (context, index) => index == 0
                  ? const SizedBox.shrink()
                  : const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == 0) return _buildTrueFriendsBanner();
                final follower = _following[index - 1];
                return UserTile(
                  follower: follower,
                  currentUserId: _currentUserId,
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
    );
  }

  Widget _buildSuggestedTab() {
    return RefreshIndicator(
      onRefresh: _loadSuggested,
      child: _isLoadingSuggested
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 300),
                Center(child: CircularProgressIndicator()),
              ],
            )
          : _suggestedError != null
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 250),
                Center(child: Text(_suggestedError!)),
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton(
                    onPressed: _loadSuggested,
                    child: const Text('Retry'),
                  ),
                ),
              ],
            )
          : _suggested.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 250),
                Center(child: Text('No suggestions yet.')),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _suggested.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final follower = _suggested[index];
                return UserTile(
                  follower: follower,
                  currentUserId: _currentUserId,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBackToProfile();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBackToProfile,
          ),
          title: const Text('Following'),
          backgroundColor: AppColors.pureBlack,
          foregroundColor: AppColors.whiteSmoke,
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryOrange,
            unselectedLabelColor: AppColors.white70,
            indicatorColor: AppColors.primaryOrange,
            tabs: const [
              Tab(text: 'Following'),
              Tab(text: 'Suggested'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_buildFollowingTab(), _buildSuggestedTab()],
        ),
      ),
    );
  }
}
