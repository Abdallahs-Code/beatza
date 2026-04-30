// Dart imports
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/core/navigation/profile_navigator.dart';
import 'package:cross_team5/features/followers_social_graph/models/follower.dart';

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
    final normalizedCurrentUserId = currentUserId?.trim() ?? '';
    final normalizedFollowerUserId = follower.userId.trim();

    final isMe =
        normalizedCurrentUserId.isNotEmpty &&
        normalizedCurrentUserId == normalizedFollowerUserId;

    final bool canOpenProfile =
        !follower.isBlocked && normalizedFollowerUserId.isNotEmpty;

    Future<void> openProfile() async {
      if (!canOpenProfile) return;
      await ProfileNavigator.push(context, normalizedFollowerUserId);
    }

    Widget buildActionButton() {
      if (follower.isBlocked) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Blocked',
            style: TextStyle(
              color: Colors.red.shade800,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        );
      }

      return GestureDetector(
        onTap: onFollowTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: follower.isFollowing ? Colors.grey.shade300 : Colors.orange,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            follower.isFollowing ? 'Following' : 'Follow',
            style: TextStyle(
              color: follower.isFollowing ? Colors.black87 : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    Widget? buildPopupMenu() {
      if (isMe) return null;

      if (follower.isBlocked && onUnblockTap != null) {
        return PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'unblock') {
              onUnblockTap!();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'unblock', child: Text('Unblock')),
          ],
        );
      }

      if (showUnblockOption && onUnblockTap != null) {
        return PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'unblock') {
              onUnblockTap!();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'unblock', child: Text('Unblock')),
          ],
        );
      }

      if (showBlockOption && onBlockTap != null) {
        return PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'block') {
              onBlockTap!();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'block', child: Text('Block user')),
          ],
        );
      }

      return null;
    }

    final popupMenu = buildPopupMenu();

    return Opacity(
      opacity: follower.isBlocked ? 0.92 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            GestureDetector(
              onTap: canOpenProfile ? openProfile : null,
              behavior: HitTestBehavior.opaque,
              child: CircleAvatar(
                radius: 24,
                backgroundImage:
                    follower.profileImgLink != null &&
                        follower.profileImgLink!.trim().isNotEmpty
                    ? NetworkImage(follower.profileImgLink!)
                    : null,
                child:
                    follower.profileImgLink == null ||
                        follower.profileImgLink!.trim().isEmpty
                    ? Text(
                        follower.displayName.isNotEmpty
                            ? follower.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: canOpenProfile ? openProfile : null,
                behavior: HitTestBehavior.opaque,
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
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (onFollowTap != null && !isMe) buildActionButton(),
            if (popupMenu != null) ...[const SizedBox(width: 4), popupMenu],
          ],
        ),
      ),
    );
  }
}
