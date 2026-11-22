// Widget: PlaylistOptionsSheet
// Bottom sheet showing playlist actions: Edit, Secret/public visibility,
// secret share link, Add music, Delete, Copy playlist, Play Next, Play Last.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/sets_playlists/models/playlist_model.dart';
import 'package:cross_team5/features/sets_playlists/services/playlist_api_service.dart';

enum PlaylistOptionResult {
  edited,
  deleted,
  privacyChanged,
  secretTokenUpdated,
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
    final p = widget.playlist;
    final genre = p.genre.trim().isEmpty ? 'None' : p.genre.trim();

    // PUT validates the full `data` JSON; partial updates omitting description/genre fail.
    final (code, message) = await _service.updatePlaylist(
      playlistId: p.id,
      title: p.title,
      description: p.description,
      genre: genre,
      isPrivate: newPrivate,
      permalink: p.permalink,
      listOfTracks: p.listOfTracks,
      additionalTags: p.additionalTags,
      playlistType: p.playlistType,
    );

    if (!mounted) return;
    setState(() => _isWorking = false);

    if (code == 200) {
      Navigator.pop(context, PlaylistOptionResult.privacyChanged);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deletePlaylist() async {
    Navigator.pop(context); 
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
      description: widget.playlist.description,
      isPrivate: widget.playlist.isPrivate,
      listOfTracks: List<String>.from(widget.playlist.listOfTracks),
      imagePath: null,
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

  Future<void> _openSecretShare() async {
    final shouldReload = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _PlaylistSecretShareDialog(playlist: widget.playlist),
    );
    if (shouldReload == true && mounted) {
      Navigator.pop(context, PlaylistOptionResult.secretTokenUpdated);
    }
  }

  Future<void> _openEmbedCode() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _PlaylistEmbedDialog(playlist: widget.playlist),
    );
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
                          p.isPrivate ? 'Secret playlist' : 'Public playlist',
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
              
              if (widget.isOwner) ...[
                _tile(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () =>
                      Navigator.pop(context, PlaylistOptionResult.edited),
                ),
                _tile(
                  icon: p.isPrivate ? Icons.lock_open_outlined : Icons.lock_outline,
                  label: p.isPrivate ? 'Make public' : 'Make secret',
                  onTap: _togglePrivacy,
                ),
                if (p.isPrivate)
                  _tile(
                    icon: Icons.link,
                    label: 'Secret share link',
                    onTap: _openSecretShare,
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
              _tile(
                icon: Icons.integration_instructions_outlined,
                label: 'Embed code',
                onTap: _openEmbedCode,
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

/// Owner-only dialog: copy / regenerate secret playlist share URL.
class _PlaylistSecretShareDialog extends StatefulWidget {
  final PlaylistModel playlist;

  const _PlaylistSecretShareDialog({required this.playlist});

  @override
  State<_PlaylistSecretShareDialog> createState() =>
      _PlaylistSecretShareDialogState();
}

class _PlaylistSecretShareDialogState extends State<_PlaylistSecretShareDialog> {
  final PlaylistApiService _service = PlaylistApiService();
  String? _secretOverride;
  bool _busy = false;
  bool _didMutateToken = false;

  PlaylistModel get _p => widget.playlist;

  String? get _effectiveSecret {
    final o = _secretOverride?.trim();
    if (o != null && o.isNotEmpty) return o;
    final t = _p.secretToken?.trim();
    return (t != null && t.isNotEmpty) ? t : null;
  }

  Future<void> _rotate() async {
    setState(() => _busy = true);
    final (code, model, loose) =
        await _service.rotatePlaylistSecretToken(playlistId: _p.id);
    if (!mounted) return;
    setState(() => _busy = false);

    if (code == 200 || code == 201) {
      final fromModel = model?.secretToken?.trim();
      if (fromModel != null && fromModel.isNotEmpty) {
        _secretOverride = fromModel;
      } else if (loose != null && loose.trim().isNotEmpty) {
        _secretOverride = loose.trim();
      }
      _didMutateToken = true;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Secret link updated')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update secret link ($code)'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copy(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = _p.secretShareUrl(
      ApiServices().baseUrl,
      secretOverride: _effectiveSecret,
    );

    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: const Text(
        'Secret share link',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Anyone with this link can open the playlist while it stays secret.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (_busy)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    color: AppColors.crusta,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (url != null && url.isNotEmpty) ...[
              SelectableText(
                url,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _copy(url),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.crusta,
                        side: const BorderSide(color: AppColors.crusta),
                      ),
                      child: const Text('Copy link'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: _rotate,
                      child: const Text(
                        'New link',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Text(
                'No secret link yet. Generate one to share.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _rotate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.crusta,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Generate secret link'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _didMutateToken),
          child: const Text('Done', style: TextStyle(color: AppColors.crusta)),
        ),
      ],
    );
  }
}

/// Copy-ready `<iframe>` HTML for embedding the playlist on external sites.
class _PlaylistEmbedDialog extends StatelessWidget {
  final PlaylistModel playlist;

  const _PlaylistEmbedDialog({required this.playlist});

  @override
  Widget build(BuildContext context) {
    final apiBase = ApiServices().baseUrl;
    final snippet = playlist.embedIframeSnippet(apiBase);
    final src = playlist.embedIframeSrc(apiBase);
    final missingSecret =
        playlist.isPrivate && !src.contains('secretToken=');

    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: const Text(
        'Embed playlist',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              missingSecret
                  ? 'Create a secret share link first — the iframe needs the same '
                      'secret token in its URL.'
                  : 'Paste this HTML into your blog or site:',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            if (missingSecret) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'Embed player URL will not work for viewers until a '
                  'secret token is included.',
                  style: TextStyle(color: Colors.amberAccent, fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                snippet,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  height: 1.35,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'iframe src',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 4),
            SelectableText(
              src,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: snippet));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Embed code copied')),
            );
          },
          child: const Text(
            'Copy code',
            style: TextStyle(color: AppColors.crusta),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Close',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      ],
    );
  }
}
