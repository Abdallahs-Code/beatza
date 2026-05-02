// Widget: PlaylistTrackTile
// Displays a single track inside the PlaylistDetailScreen.
// Supports drag handle (for reordering) and remove action (for owner).

import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/sets_playlists/models/playlist_model.dart';

class PlaylistTrackTile extends StatelessWidget {
  final PlaylistTrack track;
  final bool showDragHandle;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const PlaylistTrackTile({
    super.key,
    required this.track,
    this.showDragHandle = false,
    this.onRemove,
    this.onTap,
  });

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Drag handle
            if (showDragHandle)
              Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.drag_handle,
                  color: AppColors.white54,
                  size: 20,
                ),
              ),

            // Track thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: track.imageUrl != null && track.imageUrl!.isNotEmpty
                  ? Image.network(
                      track.imageUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),

            // Title + artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    track.displayArtist,
                    style: TextStyle(color: AppColors.white54, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Duration
            Text(
              _formatDuration(track.durationInSeconds),
              style: TextStyle(color: AppColors.white54, fontSize: 12),
            ),

            // Remove button (owner only)
            if (onRemove != null)
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 48,
      height: 48,
      color: AppColors.tileDark,
      child: Icon(Icons.music_note, color: AppColors.white24, size: 20),
    );
  }
}
