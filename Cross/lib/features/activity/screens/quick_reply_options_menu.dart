import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/engagement_social_interactions/models/comment.dart';
import 'package:cross_team5/features/followers_social_graph/services/social_api_service.dart';

class QuickReplyOptionsMenu {
  static void show(
    BuildContext context, {
    required Comment comment,
    VoidCallback? onTimestampTap,
    VoidCallback? onGoToProfileTap,
    VoidCallback? onDeleteTap,
  }) {
    final bool isOwn = onDeleteTap != null;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.container,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (comment.timestamp > 0)
              ListTile(
                leading: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                ),
                title: Text(
                  'Play from ${comment.formattedTimestamp}',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onTimestampTap?.call();
                },
              ),
            if (onGoToProfileTap != null)
              ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.white),
                title: const Text(
                  'Go to profile',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onGoToProfileTap();
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy_outlined, color: Colors.white),
              title: const Text('Copy', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(sheetContext);
                Clipboard.setData(ClipboardData(text: comment.content));
              },
            ),
            if (isOwn)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete comment',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onDeleteTap();
                },
              ),
            if (!isOwn && comment.userId.isNotEmpty) ...[
              ListTile(
                leading: const Icon(
                  Icons.outlined_flag_rounded,
                  color: Colors.white,
                ),
                title: const Text(
                  'Report',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Comment reported'),
                      backgroundColor: AppColors.container,
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
                      backgroundColor: AppColors.container,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_outlined, color: Colors.red),
                title: const Text('Block', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmBlock(context, comment);
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static Future<void> _confirmBlock(
    BuildContext context,
    Comment comment,
  ) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: AppColors.container,
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

    final result = await SocialApiService().blockUser(
      targetUserId: comment.userId,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.$1 == 200
              ? '${comment.displayName} has been blocked'
              : (result.$2?.toString() ?? 'Could not block user'),
        ),
        backgroundColor: AppColors.container,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
