// Widget: SearchResultTile
// Single row in the search results list.
// Covers: tracks, users, playlists, albums.
//
// Tap behaviour:
//   - Track → fetch full track details → play via
//     PlaybackStreamingEngineService.shared.playTrack(fullTrack)
//     (handled by parent SearchScreen, which calls onTap callback)
//   - User → navigate to UserProfileSocialIdentityRoutes.userProfileRoute
//   - Playlist / Album → TODO when Module 7 playlist screen is available
//
// The parent screen owns the tap logic and passes onTap here.

import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

class SearchResultTile extends StatelessWidget {
  final String id;
  final String type;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final VoidCallback onTap;

  const SearchResultTile({
    super.key,
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // ── Thumbnail / Avatar ─────────────────────────────────────────
            _buildThumbnail(),
            const SizedBox(width: 12),

            // ── Title + subtitle ───────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.white54,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // ── Type badge ─────────────────────────────────────────────────
            if (type == 'user')
              _buildFollowChip()
            else
              const Icon(
                Icons.chevron_right,
                color: AppColors.white54,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final bool isUser = type == 'user';
    final double size = 50;

    Widget placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius:
            isUser ? BorderRadius.circular(size / 2) : BorderRadius.circular(6),
      ),
      child: Icon(
        isUser ? Icons.person : Icons.music_note,
        color: AppColors.white54,
        size: 24,
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius:
          isUser ? BorderRadius.circular(size / 2) : BorderRadius.circular(6),
      child: Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }

  Widget _buildFollowChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white54),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Follow',
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
