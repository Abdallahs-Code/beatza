








import 'package:flutter/material.dart';
import 'package:cross_team5/features/engagement_social_interactions/models/engagement_user.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

class EngagementUserTile extends StatelessWidget {
  final EngagementUser user;
  final VoidCallback? onTap; 

  const EngagementUserTile({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),

      
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.tileDark,
        backgroundImage: user.avatarUrl != null
            ? NetworkImage(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null
            ? Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : null,
      ),

      
      title: Text(
        user.displayName,
        style: TextStyle(
          color: AppColors.whiteSmoke,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _formatFollowerCount(user.followersCount),
        style: TextStyle(color: AppColors.white54, fontSize: 12),
      ),

      
      trailing: Icon(Icons.chevron_right, color: AppColors.white54, size: 20),
    );
  }

  
  
  
  
  
  
  
  String _formatFollowerCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M followers';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K followers';
    } else if (count == 1) {
      return '1 follower';
    } else {
      return '$count followers';
    }
  }
}
