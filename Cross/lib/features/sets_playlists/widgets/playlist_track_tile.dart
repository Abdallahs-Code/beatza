




import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/sets_playlists/models/playlist_model.dart';

class PlaylistTrackTile extends StatelessWidget {
  final PlaylistTrack track;
  final bool showDragHandle;
  final bool showOptions;
  final VoidCallback? onRemove;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onTap;

  const PlaylistTrackTile({
    super.key,
    required this.track,
    this.showDragHandle = false,
    this.showOptions = false,
    this.onRemove,
    this.onAddToPlaylist,
    this.onTap,
  });

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _showTrackOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: track.imageUrl != null &&
                            track.imageUrl!.isNotEmpty
                        ? Image.network(
                            track.imageUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) =>
                                _placeholder(44),
                          )
                        : _placeholder(44),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          track.displayArtist,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.borderDark, height: 1),
            if (onAddToPlaylist != null)
              ListTile(
                leading: const Icon(Icons.playlist_add, color: Colors.white),
                title: const Text(
                  'Add to playlist',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  onAddToPlaylist!();
                },
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20),
                dense: true,
              ),
            if (onRemove != null)
              ListTile(
                leading: const Icon(Icons.remove_circle_outline,
                    color: Colors.red),
                title: const Text(
                  'Remove from playlist',
                  style: TextStyle(color: Colors.red, fontSize: 15),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  onRemove!();
                },
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20),
                dense: true,
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
            if (showDragHandle)
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.drag_handle,
                    color: Colors.white38, size: 20),
              ),

            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: track.imageUrl != null && track.imageUrl!.isNotEmpty
                  ? Image.network(
                      track.imageUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => _placeholder(48),
                    )
                  : _placeholder(48),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    track.displayArtist,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            Text(
              _formatDuration(track.durationInSeconds),
              style:
                  const TextStyle(color: Colors.white38, fontSize: 12),
            ),

            
            if (showOptions)
              IconButton(
                icon: const Icon(Icons.more_vert,
                    color: Colors.white38, size: 20),
                onPressed: () => _showTrackOptions(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32),
              )
            else if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: Colors.red, size: 20),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder([double size = 48]) {
    return Container(
      width: size,
      height: size,
      color: AppColors.tileDark,
      child: const Icon(Icons.music_note, color: Colors.white24, size: 20),
    );
  }
}
