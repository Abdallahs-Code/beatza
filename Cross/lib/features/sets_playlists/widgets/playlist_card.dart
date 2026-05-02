import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/sets_playlists/models/playlist_model.dart';

class PlaylistCard extends StatelessWidget {
  final PlaylistModel playlist;
  final VoidCallback? onTap;
  final VoidCallback? onMenuEdit;
  final VoidCallback? onMenuDelete;
  final VoidCallback? onMenuEmbed;

  const PlaylistCard({
    super.key,
    required this.playlist,
    this.onTap,
    this.onMenuEdit,
    this.onMenuDelete,
    this.onMenuEmbed,
  });

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get _hasMenu =>
      onMenuEdit != null || onMenuDelete != null || onMenuEmbed != null;

  @override
  Widget build(BuildContext context) {
    final subtitle =
        'Playlist · ${playlist.listOfTracks.length} tracks · ${_formatDuration(playlist.playlistLengthInSeconds)}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: playlist.image?.imgLink.isNotEmpty == true
                  ? Image.network(
                      playlist.image!.imgLink,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.title,
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(color: AppColors.white54, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          playlist.isPrivate
                              ? Icons.lock_outline
                              : Icons.public,
                          color: playlist.isPrivate
                              ? AppColors.white54
                              : AppColors.crusta,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          playlist.isPrivate ? 'Private' : 'Public',
                          style: TextStyle(
                            color: playlist.isPrivate
                                ? AppColors.white54
                                : AppColors.crusta,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Right action
            if (_hasMenu)
              _buildMenu()
            else
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right, color: AppColors.white54),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu() {
    return PopupMenuButton<String>(
      color: AppColors.surfaceDark,
      icon: Icon(Icons.more_vert, color: AppColors.white54, size: 20),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      onSelected: (value) {
        if (value == 'edit') onMenuEdit?.call();
        if (value == 'delete') onMenuDelete?.call();
        if (value == 'embed') onMenuEmbed?.call();
      },
      itemBuilder: (_) => [
        if (onMenuEdit != null)
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, color: AppColors.white70, size: 18),
                const SizedBox(width: 8),
                Text('Edit', style: TextStyle(color: AppColors.white70)),
              ],
            ),
          ),
        if (onMenuEmbed != null)
          PopupMenuItem(
            value: 'embed',
            child: Row(
              children: [
                Icon(Icons.code, color: AppColors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Share / Embed',
                  style: TextStyle(color: AppColors.white70),
                ),
              ],
            ),
          ),
        if (onMenuDelete != null)
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      width: 72,
      height: 72,
      color: AppColors.tileDark,
      child: Icon(Icons.queue_music, color: AppColors.white24, size: 30),
    );
  }
}
