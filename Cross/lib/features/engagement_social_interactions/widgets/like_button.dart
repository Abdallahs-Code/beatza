// Widget: LikeButton
// Reusable heart button with like count.
// Used embedded in: Track detail page (Module 4), persistent player bar (Module 5).
//
// Design matches SoundCloud:
//   ♡ 2.4K  →  unfilled heart + grey count  (not liked)
//   ♥ 2.4K  →  filled orange heart + white count (liked)
//
// The PARENT screen owns all state and API calls.
// This widget is purely presentational — it fires onTap and renders.
//
// Optimistic update pattern (in parent):
//   1. Flip isLiked + adjust likeCount locally (instant UI response)
//   2. Call toggleTrackLike / togglePlaylistLike
//   3. On failure: revert both and show snackbar
//   4. On success: update likeCount from response["numOfLikes"]
//
// The likeCount text is also a GestureDetector that navigates to
// LikersScreen — required by project spec (unlike real SoundCloud
// mobile app where count is non-tappable).

import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

class LikeButton extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final VoidCallback onTap; // triggers optimistic toggle in parent
  final VoidCallback? onCountTap; // navigates to LikersScreen
  final double iconSize;
  final bool showCount; // false in compact player bar layouts

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
        // ── Heart icon ──────────────────────────
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

        // ── Count (tappable → LikersScreen) ────
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

  // ─────────────────────────────────────────────
  // Formats count SoundCloud-style:
  //   999   → "999"
  //   1000  → "1K"
  //   2400  → "2.4K"
  //   1000000 → "1M"
  // ─────────────────────────────────────────────
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(count % 1000000 == 0 ? 0 : 1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}K';
    }
    return count.toString();
  }
}
