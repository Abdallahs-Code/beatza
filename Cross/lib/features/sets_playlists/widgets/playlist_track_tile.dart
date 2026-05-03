// Widget: PlaylistTrackTile
// Displays a single track inside PlaylistDetailScreen or EditPlaylistScreen.
// showOptions → ⋮ opens the same [TrackOptionsSheet] as home / mini player.
// showDragHandle → drag handle for the reorderable list in EditPlaylistScreen.

import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/activity/screens/track_options_sheet_launcher.dart';
import 'package:cross_team5/features/sets_playlists/models/playlist_model.dart';
import 'package:cross_team5/features/sets_playlists/playlist_playback.dart';

class PlaylistTrackTile extends StatelessWidget {
  final PlaylistTrack track;
  final bool showDragHandle;
  final bool showOptions;
  /// Playlist/album owner id — fills track uploader id when API omits it on tracks.
  final String? playlistOwnerArtistId;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const PlaylistTrackTile({
    super.key,
    required this.track,
    this.showDragHandle = false,
    this.showOptions = false,
    this.playlistOwnerArtistId,
    this.onRemove,
    this.onTap,
  });

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _openTrackOptionsSheet(BuildContext context) {
    final playback = playbackModelFromPlaylistTrack(
      track,
      playlistArtistId: playlistOwnerArtistId,
    );
    showTrackOptionsSheet(context, playback);
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

            // ⋮ options button (detail view) OR inline remove button (edit view)
            if (showOptions)
              IconButton(
                icon: const Icon(Icons.more_vert,
                    color: Colors.white38, size: 20),
                onPressed: () => _openTrackOptionsSheet(context),
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
