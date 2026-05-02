// Widget: AddToPlaylistSheet
// Full-screen modal for adding a track to one or more of the user's playlists.
// Shows user's playlists with checkboxes (multi-select).
// "Create playlist" row creates a new playlist and adds the track immediately.
// Tapping Done calls addTrackToPlaylist for each newly-checked playlist.

import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/sets_playlists/models/playlist_model.dart';
import 'package:cross_team5/features/sets_playlists/services/playlist_api_service.dart';
import 'package:cross_team5/features/sets_playlists/widgets/create_playlist_sheet.dart';

class AddToPlaylistSheet extends StatefulWidget {
  final String trackId;

  const AddToPlaylistSheet({super.key, required this.trackId});

  /// Convenience method — shows this sheet as a full-screen modal.
  static Future<void> show(BuildContext context, {required String trackId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddToPlaylistSheet(trackId: trackId),
    );
  }

  @override
  State<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<AddToPlaylistSheet> {
  final PlaylistApiService _service = PlaylistApiService();

  List<PlaylistModel> _playlists = [];
  List<PlaylistModel> _filtered = [];
  final Set<String> _selected = {};
  bool _isLoading = true;
  bool _isSaving = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_playlists)
          : _playlists
              .where((p) => p.title.toLowerCase().contains(q))
              .toList();
    });
  }

  Future<void> _loadPlaylists() async {
    setState(() => _isLoading = true);

    final (code, playlists) = await _service.getMyPlaylists();

    if (!mounted) return;
    setState(() {
      _playlists = code == 200 ? playlists : [];
      _filtered = List.from(_playlists);
      _isLoading = false;
    });
  }

  Future<void> _done() async {
    if (_selected.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    final names = <String>[];
    for (final playlistId in _selected) {
      final (code, _) = await _service.addTrackToPlaylist(
        playlistId: playlistId,
        trackId: widget.trackId,
      );
      if (code == 200) {
        final match = _playlists.where((p) => p.id == playlistId).firstOrNull;
        if (match != null) names.add(match.title);
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    Navigator.pop(context);

    if (names.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            names.length == 1
                ? 'Track added to ${names.first}'
                : 'Track added to ${names.length} playlists',
          ),
        ),
      );
    }
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreatePlaylistSheet(
        initialTrackId: widget.trackId,
        onCreated: (playlist) {
          setState(() {
            _playlists.insert(0, playlist);
            _filtered.insert(0, playlist);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Track added to ${playlist.title}')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.pureBlack,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),

              // AppBar row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Add to playlist',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    GestureDetector(
                      onTap: _isSaving ? null : _done,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black),
                              )
                            : const Text(
                                'Done',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText:
                        'Search ${_playlists.length} playlist${_playlists.length == 1 ? '' : 's'}',
                    hintStyle:
                        const TextStyle(color: Colors.white38, fontSize: 14),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.white38, size: 20),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ),

              // List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.crusta))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _filtered.length + 2, // create row + label
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // Create playlist row
                            return ListTile(
                              leading: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.cardDark,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.add,
                                    color: Colors.white54, size: 24),
                              ),
                              title: const Text('Create playlist',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                              onTap: _showCreateSheet,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                            );
                          }

                          if (index == 1) {
                            return const Padding(
                              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                              child: Text('Recently updated',
                                  style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            );
                          }

                          final playlist = _filtered[index - 2];
                          final isSelected = _selected.contains(playlist.id);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: playlist.image?.imgLink.isNotEmpty == true
                                  ? Image.network(
                                      playlist.image!.imgLink,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, st) =>
                                          _placeholder(),
                                    )
                                  : _placeholder(),
                            ),
                            title: Text(
                              playlist.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Playlist · ${playlist.trackCount} Track${playlist.trackCount == 1 ? '' : 's'}${playlist.isPrivate ? '  🔒' : ''}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                            trailing: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.crusta
                                      : Colors.white38,
                                  width: 2,
                                ),
                                color: isSelected
                                    ? AppColors.crusta
                                    : Colors.transparent,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 14)
                                  : null,
                            ),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selected.remove(playlist.id);
                                } else {
                                  _selected.add(playlist.id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _placeholder() {
    return Container(
      width: 52,
      height: 52,
      color: AppColors.tileDark,
      child: const Icon(Icons.queue_music, color: Colors.white24, size: 22),
    );
  }
}
