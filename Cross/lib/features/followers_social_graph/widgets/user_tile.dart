// Dart imports
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/followers_social_graph/models/follower.dart';
import 'package:cross_team5/features/user_profile_social_identity/user_profile_social_identity.dart';

class UserTile extends StatelessWidget {
  final Follower follower;
  final String? currentUserId;
  final VoidCallback? onFollowTap;
  final VoidCallback? onBlockTap;
  final VoidCallback? onUnblockTap;
  final bool showBlockOption;
  final bool showUnblockOption;

  const UserTile({
    super.key,
    required this.follower,
    this.currentUserId,
    this.onFollowTap,
    this.onBlockTap,
    this.onUnblockTap,
    this.showBlockOption = true,
    this.showUnblockOption = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMe =
        currentUserId != null &&
        currentUserId!.trim() == follower.userId.trim();

    return InkWell(
      onTap: () async {
        final authService = AuthApiService();

        final token = await authService.getStoredAccessToken();
        final currentUserIdFromStorage = await authService.getStoredUserId();

        final safeToken = (token == null || token.trim().isEmpty)
            ? 'mock_token'
            : token;

        final safeViewedUserId = follower.userId.trim().isEmpty
            ? 'mock_user_id'
            : follower.userId;

        final safeCurrentUserId =
            (currentUserIdFromStorage == null ||
                currentUserIdFromStorage.trim().isEmpty)
            ? null
            : currentUserIdFromStorage;

        if (!context.mounted) return;

        Navigator.pushNamed(
          context,
          UserProfileSocialIdentityRoutes.userProfileRoute,
          arguments: {
            'userId': safeViewedUserId,
            'token': safeToken,
            'currentUserId': safeCurrentUserId,
            'initialIsFollowing': follower.isFollowing,
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: follower.profileImgLink != null
                  ? NetworkImage(follower.profileImgLink!)
                  : null,
              child: follower.profileImgLink == null
                  ? Text(
                      follower.displayName.isNotEmpty
                          ? follower.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    follower.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${follower.trackCount} tracks',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (onFollowTap != null && !isMe)
              GestureDetector(
                onTap: onFollowTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: follower.isFollowing
                        ? Colors.grey.shade300
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    follower.isFollowing ? 'Following' : 'Follow',
                    style: TextStyle(
                      color: follower.isFollowing
                          ? Colors.black87
                          : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            if ((showBlockOption && !isMe) || (showUnblockOption && !isMe))
              const SizedBox(width: 4),
            if (showBlockOption && !isMe)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'block' && onBlockTap != null) {
                    onBlockTap!();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'block',
                    child: Text('Block user'),
                  ),
                ],
              ),
            if (showUnblockOption && !isMe)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'unblock' && onUnblockTap != null) {
                    onUnblockTap!();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'unblock', child: Text('Unblock')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
