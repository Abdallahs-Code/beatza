// Widget: PlaylistOptionsSheet
// Bottom sheet showing playlist actions: Edit, Make private/public, Add music,
// Delete, Copy playlist, Play Next, Play Last, Shuffle play.

import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/sets_playlists/models/playlist_model.dart';
import 'package:cross_team5/features/sets_playlists/services/playlist_api_service.dart';

enum PlaylistOptionResult {
  edited,
  deleted,
  privacyChanged,
  musicAdded,
  copied,
}

class PlaylistOptionsSheet extends StatefulWidget {
  final PlaylistModel playlist;
  final bool isOwner;

  const PlaylistOptionsSheet({
    super.key,
    required this.playlist,
    this.isOwner = false,
  });

  @override
  State<PlaylistOptionsSheet> createState() => _PlaylistOptionsSheetState();
}

class _PlaylistOptionsSheetState extends State<PlaylistOptionsSheet> {
  final PlaylistApiService _service = PlaylistApiService();
  bool _isWorking = false;

  Future<void> _togglePrivacy() async {
    setState(() => _isWorking = true);
    final newPrivate = !widget.playlist.isPrivate;

    final (code, _) = await _service.updatePlaylist(
      playlistId: widget.playlist.id,
      isPrivate: newPrivate,
    );

    if (!mounted) return;
    setState(() => _isWorking = false);

    if (code == 200) {
      Navigator.pop(context, PlaylistOptionResult.privacyChanged);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to update privacy'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deletePlaylist() async {
    Navigator.pop(context); // close sheet first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Delete Playlist',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${widget.playlist.title}"? This cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final (code, deleted) =
        await _service.deletePlaylist(playlistId: widget.playlist.id);

    if (!mounted) return;
    if (code == 200 && deleted) {
      Navigator.pop(context, PlaylistOptionResult.deleted);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to delete playlist'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _copyPlaylist() async {
    setState(() => _isWorking = true);

    final (code, newPlaylist) = await _service.createPlaylistWithImage(
      title: 'Copy of ${widget.playlist.title}',
      listOfTracks: widget.playlist.listOfTracks,
      isPrivate: widget.playlist.isPrivate,
    );

    if (!mounted) return;
    setState(() => _isWorking = false);

    if ((code == 200 || code == 201) && newPlaylist != null) {
      Navigator.pop(context, PlaylistOptionResult.copied);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('${newPlaylist.title} added to your library')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to copy playlist'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.playlist;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Header: thumbnail + title + creator
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: p.image != null && p.image!.imgLink.isNotEmpty
                        ? Image.network(
                            p.image!.imgLink,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => _placeholderThumb(),
                          )
                        : _placeholderThumb(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          p.isPrivate ? 'Private playlist' : 'Public playlist',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: AppColors.borderDark, height: 1),

            if (_isWorking)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                    color: AppColors.crusta, strokeWidth: 2),
              )
            else ...[
              // Owner-only actions
              if (widget.isOwner) ...[
                _tile(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () =>
                      Navigator.pop(context, PlaylistOptionResult.edited),
                ),
                _tile(
                  icon: p.isPrivate ? Icons.lock_open_outlined : Icons.lock_outline,
                  label: p.isPrivate ? 'Make public' : 'Make private',
                  onTap: _togglePrivacy,
                ),
                _tile(
                  icon: Icons.library_add_outlined,
                  label: 'Add music',
                  onTap: () =>
                      Navigator.pop(context, PlaylistOptionResult.musicAdded),
                ),
                _tile(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  labelColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: _deletePlaylist,
                ),
              ],

              _tile(
                icon: Icons.copy_outlined,
                label: 'Copy playlist',
                onTap: _copyPlaylist,
              ),

              Divider(color: AppColors.borderDark, height: 1),

              _tile(
                icon: Icons.playlist_add,
                label: 'Play Next',
                onTap: () => Navigator.pop(context),
              ),
              _tile(
                icon: Icons.queue_music,
                label: 'Play Last',
                onTap: () => Navigator.pop(context),
              ),
              _tile(
                icon: Icons.shuffle,
                label: 'Shuffle play',
                onTap: () => Navigator.pop(context),
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
    Color labelColor = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(label,
          style: TextStyle(color: labelColor, fontSize: 15)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      dense: true,
    );
  }

  Widget _placeholderThumb() {
    return Container(
      width: 52,
      height: 52,
      color: AppColors.cardDark,
      child: const Icon(Icons.queue_music, color: Colors.white24, size: 24),
    );
  }
}
