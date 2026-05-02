// Widget: RepostButton
// Reusable repost icon button with repost count.
// Used embedded in: Track detail page (Module 4).
//
// Design matches SoundCloud:
//   ↺ 15  →  grey repost icon + grey count  (not reposted)
//   ↺ 16  →  orange repost icon + white count (reposted)
//
// Tapping opens RepostBottomSheet (not a direct toggle).
// The bottom sheet handles both the initial repost and the
// un-repost action, so this button never toggles directly.
//
// The PARENT screen:
//   1. Passes isReposted + repostCount
//   2. Provides onTap → opens RepostBottomSheet via showModalBottomSheet
//   3. Updates state after sheet is dismissed

import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

class RepostButton extends StatelessWidget {
  final bool isReposted;
  final int repostCount;
  final VoidCallback onTap; // parent opens RepostBottomSheet
  final double iconSize;
  final bool showCount;

  const RepostButton({
    super.key,
    required this.isReposted,
    required this.repostCount,
    required this.onTap,
    this.iconSize = 24,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Repost icon ──────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              Icons.repeat,
              key: ValueKey(isReposted),
              color: isReposted ? AppColors.primaryOrange : AppColors.white54,
              size: iconSize,
            ),
          ),

          // ── Count ────────────────────────────
          if (showCount) ...[
            const SizedBox(width: 4),
            Text(
              _formatCount(repostCount),
              style: TextStyle(
                color: isReposted ? AppColors.whiteSmoke : AppColors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
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
