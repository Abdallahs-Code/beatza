




























import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/engagement_social_interactions/models/comment.dart';
import 'package:cross_team5/features/followers_social_graph/services/social_api_service.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isReply; 
  final VoidCallback onLikeTap; 
  final VoidCallback onReplyTap; 
  final VoidCallback? onTimestampTap; 
  final VoidCallback?
  onDeleteTap; 
  final VoidCallback? onGoToProfileTap; 

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
          
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.tileDark,
            backgroundImage: comment.avatarUrl != null
                ? NetworkImage(comment.avatarUrl!)
                : null,
            child: comment.avatarUrl == null
                ? Text(
                    comment.displayName.isNotEmpty
                        ? comment.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),

          const SizedBox(width: 10),

          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.displayName,
                        style: TextStyle(
                          color: AppColors.whiteSmoke,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(width: 8),

                    
                    
                    if (!isReply)
                      GestureDetector(
                        onTap: onTimestampTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.linkBlue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'at ${comment.formattedTimestamp}',
                            style: TextStyle(
                              color: AppColors.whiteSmoke,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(width: 8),

                    
                    Text(
                      _formatAge(comment.createdAt),
                      style: TextStyle(color: AppColors.greyMuted, fontSize: 11),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                
                Text(
                  comment.content,
                  style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 6),

                
                Row(
                  children: [
                    if (!isReply)
                      GestureDetector(
                        onTap: onReplyTap,
                        child: Text(
                          'Reply',
                          style: TextStyle(
                            color: AppColors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    if (!isReply) const SizedBox(width: 12),

                    
                    GestureDetector(
                      onTap: () => _showOptionsMenu(context),
                      child: Icon(
                        Icons.more_horiz,
                        color: AppColors.greyMuted,
                        size: 18,
                      ),
                    ),

                    const Spacer(),

                    
                    GestureDetector(
                      onTap: onLikeTap,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: Icon(
                              comment.isLikedByUser
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              key: ValueKey(comment.isLikedByUser),
                              color: comment.isLikedByUser
                                  ? AppColors.primaryOrange
                                  : AppColors.greyMuted,
                              size: 16,
                            ),
                          ),
                          if (comment.numLikes > 0) ...[
                            const SizedBox(width: 3),
                            Text(
                              comment.numLikes.toString(),
                              style: TextStyle(
                                color: AppColors.white54,
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

  
  
  
  void _showOptionsMenu(BuildContext context) {
    
    final bool isOwn = onDeleteTap != null;

    showModalBottomSheet(
      context: context,
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
                color: AppColors.greyMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            

            
            if (!isReply)
              ListTile(
                leading: Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.whiteSmoke,
                ),
                title: Text(
                  'Play from ${comment.formattedTimestamp}',
                  style: TextStyle(color: AppColors.whiteSmoke),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onTimestampTap?.call();
                },
              ),

            
            if (onGoToProfileTap != null)
              ListTile(
                leading: Icon(
                  Icons.person_outline,
                  color: AppColors.whiteSmoke,
                ),
                title: Text(
                  'Go to profile',
                  style: TextStyle(color: AppColors.whiteSmoke),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onGoToProfileTap!();
                },
              ),

            
            ListTile(
              leading: Icon(Icons.copy_outlined, color: AppColors.whiteSmoke),
              title: Text(
                'Copy',
                style: TextStyle(color: AppColors.whiteSmoke),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                Clipboard.setData(ClipboardData(text: comment.content));
              },
            ),

            
            if (isOwn)
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.deepRed),
                title: Text(
                  'Delete comment',
                  style: TextStyle(color: AppColors.deepRed),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onDeleteTap!();
                },
              ),

            
            if (!isOwn && comment.userId.isNotEmpty) ...[
              ListTile(
                leading: Icon(
                  Icons.outlined_flag_rounded,
                  color: AppColors.whiteSmoke,
                ),
                title: Text(
                  'Report',
                  style: TextStyle(color: AppColors.whiteSmoke),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Comment reported'),
                      backgroundColor: AppColors.container,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.flag_outlined, color: AppColors.whiteSmoke),
                title: Text(
                  'Report as spam',
                  style: TextStyle(color: AppColors.whiteSmoke),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Comment reported as spam'),
                      backgroundColor: AppColors.container,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.block_outlined, color: AppColors.deepRed),
                title: Text('Block', style: TextStyle(color: AppColors.deepRed)),
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

  
  
  
  
  Future<void> _confirmBlock(BuildContext context) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: AppColors.container,
            title: Text(
              'Block user?',
              style: TextStyle(color: AppColors.whiteSmoke),
            ),
            content: Text(
              'This user will no longer be able to follow or interact with '
              'you, and you will not see notifications from them.',
              style: TextStyle(color: AppColors.greyMuted, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: Text(
                  'CANCEL',
                  style: TextStyle(color: AppColors.white70),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: const Text(
                  'BLOCK',
                  style: TextStyle(
                    color: AppColors.primaryOrange,
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
