// Dart imports
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/features/followers_social_graph/models/follower.dart';

class UserTile extends StatelessWidget {
  final Follower follower;
  final VoidCallback? onFollowTap;
  final VoidCallback? onBlockTap;
  final VoidCallback? onUnblockTap;
  final bool showBlockOption;

  const UserTile({
    super.key,
    required this.follower,
    this.onFollowTap,
    this.onBlockTap,
    this.onUnblockTap,
    this.showBlockOption = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // ── Avatar ──────────────────────────────────
      leading: CircleAvatar(
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

      // ── Display name & track count ───────────────
      title: Text(
        follower.displayName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${follower.trackCount} tracks'),

      // ── Follow button + block menu ───────────────
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onFollowTap != null)
            OutlinedButton(
              onPressed: onFollowTap,
              style: OutlinedButton.styleFrom(
                backgroundColor: follower.isFollowing
                    ? Colors.grey.shade200
                    : Colors.orange,
                foregroundColor: follower.isFollowing
                    ? Colors.black
                    : Colors.white,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Text(follower.isFollowing ? 'Following' : 'Follow'),
            ),

          if (showBlockOption)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'block' && onBlockTap != null) onBlockTap!();
                if (value == 'unblock' && onUnblockTap != null) onUnblockTap!();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'block', child: Text('Block user')),
                const PopupMenuItem(
                  value: 'unblock',
                  child: Text('Unblock user'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
