// Widget: CommentTile
// Displays a single comment (top-level or reply) in CommentsScreen.
//
// Design matches SoundCloud comments screen:
//   [avatar] [username]  [timestamp pill]  [age]
//            [comment body text                ]
//            Reply  ⋮                   [♡ numLikes]
//
// Options menu (⋮):
//   ALL comments  → Play from X:XX | Go to profile | Copy
//   Own comment   → + Delete comment  (gated on onDeleteTap != null)
//   Other's comment → + Report | Report as spam | Block
//
// The timestamp pill is BLUE — SoundCloud's design choice.
// Tapping it seeks the player (Module 5 integration).
//
// Optimistic like pattern:
//   Parent (CommentsScreen) owns the list and calls setState.
//   This widget fires onLikeTap — parent handles API + optimistic update.
//
// Delete:
//   onDeleteTap is non-null only when parent has verified ownership
//   (comment.isOwnComment || comment.userId == _currentUserId).
//   The confirmation dialog is shown by the parent via _confirmDelete.
//
// Block:
//   Handled inline — shows a confirmation dialog then calls
//   SocialApiService.blockUser. No parent callback needed.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:cross_team5/features/engagement_social_interactions/models/comment.dart';
import 'package:cross_team5/features/followers_social_graph/services/social_api_service.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isReply; // true → slight indent, no "Reply" button
  final VoidCallback onLikeTap; // optimistic like toggle
  final VoidCallback onReplyTap; // pre-fills reply input in parent
  final VoidCallback? onTimestampTap; // seeks player to comment timestamp
  final VoidCallback? onDeleteTap; // non-null only when parent verified ownership
  final VoidCallback? onGoToProfileTap; // navigates to commenter's profile

  const CommentTile({
    super.key,
    required this.comment,
    this.isReply = false,
    required this.onLikeTap,
    required this.onReplyTap,
    this.onTimestampTap,
    this.onDeleteTap,
    this.onGoToProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isReply ? 52 : 12,
        right: 12,
        top: 10,
        bottom: 4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar ────────────────────────────
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[800],
            backgroundImage: comment.avatarUrl != null
                ? NetworkImage(comment.avatarUrl!)
                : null,
            child: comment.avatarUrl == null
                ? Text(
                    comment.displayName.isNotEmpty
                        ? comment.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),

          const SizedBox(width: 10),

          // ── Content column ───────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: name + timestamp pill + age ──
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Timestamp pill — only shown when timestamp > 0.
                    // Replies always return from the server with timestamp 0
                    // because the backend does not store reply timestamps.
                    if (comment.timestamp > 0)
                      GestureDetector(
                        onTap: onTimestampTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C6BED),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'at ${comment.formattedTimestamp}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(width: 8),

                    // Relative age
                    Text(
                      _formatAge(comment.createdAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // ── Comment body ──────────────────
                Text(
                  comment.content,
                  style: TextStyle(
                    color: Colors.grey[200],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 6),

                // ── Bottom row: Reply + menu + like ──
                Row(
                  children: [
                    if (!isReply)
                      GestureDetector(
                        onTap: onReplyTap,
                        child: Text(
                          'Reply',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    if (!isReply) const SizedBox(width: 12),

                    // ⋮ menu
                    GestureDetector(
                      onTap: () => _showOptionsMenu(context),
                      child: Icon(
                        Icons.more_horiz,
                        color: Colors.grey[500],
                        size: 18,
                      ),
                    ),

                    const Spacer(),

                    // Like button + count
                    GestureDetector(
                      onTap: onLikeTap,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(
                                    scale: animation, child: child),
                            child: Icon(
                              comment.isLikedByUser
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              key: ValueKey(comment.isLikedByUser),
                              color: comment.isLikedByUser
                                  ? Colors.orange
                                  : Colors.grey[500],
                              size: 16,
                            ),
                          ),
                          if (comment.numLikes > 0) ...[
                            const SizedBox(width: 3),
                            Text(
                              comment.numLikes.toString(),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Options menu
  // ─────────────────────────────────────────────
  void _showOptionsMenu(BuildContext context) {
    // onDeleteTap != null  →  this is the current user's comment
    final bool isOwn = onDeleteTap != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Common tiles ──────────────────────

            // Play from timestamp — hidden for replies where server stores 0.
            if (comment.timestamp > 0)
              ListTile(
                leading: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                title: Text(
                  'Play from ${comment.formattedTimestamp}',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onTimestampTap?.call();
                },
              ),

            // Go to profile
            if (onGoToProfileTap != null)
              ListTile(
                leading:
                    const Icon(Icons.person_outline, color: Colors.white),
                title: const Text(
                  'Go to profile',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onGoToProfileTap!();
                },
              ),

            // Copy text
            ListTile(
              leading: const Icon(Icons.copy_outlined, color: Colors.white),
              title: const Text(
                'Copy',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                Clipboard.setData(ClipboardData(text: comment.content));
              },
            ),

            // ── Own comment: Delete ───────────────
            if (isOwn)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete comment',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onDeleteTap!();
                },
              ),

            // ── Other user's comment: Report / Block ──
            if (!isOwn && comment.userId.isNotEmpty) ...[
              ListTile(
                leading: const Icon(Icons.outlined_flag_rounded,
                    color: Colors.white),
                title: const Text(
                  'Report',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Comment reported'),
                      backgroundColor: Color(0xFF1A1A1A),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.white),
                title: const Text(
                  'Report as spam',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Comment reported as spam'),
                      backgroundColor: Color(0xFF1A1A1A),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.block_outlined, color: Colors.red),
                title: const Text(
                  'Block',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmBlock(context);
                },
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Block confirmation dialog + API call.
  // Matches real SoundCloud's "Block user?" dialog.
  // ─────────────────────────────────────────────
  Future<void> _confirmBlock(BuildContext context) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              'Block user?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'This user will no longer be able to follow or interact with '
              'you, and you will not see notifications from them.',
              style: TextStyle(color: Colors.grey, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text(
                  'CANCEL',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: const Text(
                  'BLOCK',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;
    if (!context.mounted) return;

    final result = await SocialApiService()
        .blockUser(targetUserId: comment.userId);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.$1 == 200
              ? '${comment.displayName} has been blocked'
              : (result.$2?.toString() ?? 'Could not block user'),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Formats ISO createdAt string into relative age.
  // e.g. "2025-01-15T12:00:00Z" → "16h", "3w", "2mo"
  // ─────────────────────────────────────────────
  String _formatAge(String createdAt) {
    try {
      final created = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(created);

      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w';
      if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo';
      return '${(diff.inDays / 365).floor()}y';
    } catch (_) {
      return '';
    }
  }
}
