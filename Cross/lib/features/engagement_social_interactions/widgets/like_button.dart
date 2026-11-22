




















import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

class LikeButton extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final VoidCallback onTap; 
  final VoidCallback? onCountTap; 
  final double iconSize;
  final bool showCount; 

  const LikeButton({
    super.key,
    required this.isLiked,
    required this.likeCount,
    required this.onTap,
    this.onCountTap,
    this.iconSize = 24,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(isLiked),
              color: isLiked ? AppColors.primaryOrange : AppColors.white54,
              size: iconSize,
            ),
          ),
        ),

        
        if (showCount) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onCountTap,
            behavior: HitTestBehavior.opaque,
            child: Text(
              _formatCount(likeCount),
              style: TextStyle(
                color: isLiked ? AppColors.whiteSmoke : AppColors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  
  
  
  
  
  
  
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(count % 1000000 == 0 ? 0 : 1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}K';
    }
    return count.toString();
  }
}
