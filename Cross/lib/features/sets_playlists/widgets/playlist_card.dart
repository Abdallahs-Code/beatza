// Widget: PlaylistCard
// Compact card for displaying a playlist in list/grid views.

import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/sets_playlists/models/playlist_model.dart';

class PlaylistCard extends StatelessWidget {
  final PlaylistModel playlist;
  final VoidCallback? onTap;

  const PlaylistCard({
    super.key,
    required this.playlist,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                      errorBuilder: (ctx, err, st) => _placeholder(),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${playlist.listOfTracks.length} tracks',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          playlist.isPrivate
                              ? Icons.lock_outline
                              : Icons.public,
                          color: playlist.isPrivate
                              ? Colors.white38
                              : AppColors.crusta,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          playlist.isPrivate ? 'Private' : 'Public',
                          style: TextStyle(
                            color: playlist.isPrivate
                                ? Colors.white38
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
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 72,
      height: 72,
      color: AppColors.tileDark,
      child: const Icon(Icons.queue_music,
          color: Colors.white24, size: 30),
    );
  }
}
