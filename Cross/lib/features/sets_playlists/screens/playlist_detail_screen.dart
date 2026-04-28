// Screen: PlaylistDetailScreen
// Shows a single playlist with its paginated tracks (API #2 / #8).
// Supports:
//  - Reordering tracks via drag-and-drop (API #17)
//  - Removing tracks (DELETE)
//  - Deleting the playlist (DELETE)
//  - Editing metadata (navigates to EditPlaylistScreen)

import 'package:flutter/material.dart';

import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/sets_playlists/models/playlist_model.dart';
import 'package:cross_team5/features/sets_playlists/screens/edit_playlist_screen.dart';
import 'package:cross_team5/features/sets_playlists/services/playlist_api_service.dart';
import 'package:cross_team5/features/sets_playlists/widgets/playlist_track_tile.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  final bool isOwner;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    this.isOwner = false,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final PlaylistApiService _service = PlaylistApiService();

  PlaylistModel? _playlist;
  bool _isLoading = true;
  String? _error;
  bool _isReordering = false;

  // Pagination
  int _page = 1;
  int _limit = 20;
  bool _hasMore = true;
  bool _isFetchingMore = false;
  final ScrollController _scrollController = ScrollController();

  List<PlaylistTrack> _tracks = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isFetchingMore &&
        _hasMore) {
      _fetchMoreTracks();
    }
  }

  Future<void> _loadPlaylist() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final (statusCode, playlist) = widget.isOwner
          ? await _service.getPlaylistWithTracks(
              playlistId: widget.playlistId,
            )
          : await _service.getPublicPlaylistWithTracks(
              playlistId: widget.playlistId,
            );

      if (!mounted) return;

      if (statusCode == 200 && playlist != null) {
        setState(() {
          _playlist = playlist;
          _tracks = List.from(playlist.tracks);
          _hasMore = (_playlist!.totalPages ?? 1) > 1;
          _page = 1;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = statusCode == 401
              ? 'Sign in to view this playlist.'
              : 'Failed to load playlist.';
          _isLoading = false;
          debugPrint('Error loading playlist: HTTP $statusCode');
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMoreTracks() async {
    if (_isFetchingMore || !_hasMore) return;
    setState(() => _isFetchingMore = true);

    final (statusCode, playlist) = widget.isOwner
        ? await _service.getPlaylistWithTracks(
            playlistId: widget.playlistId,
          )
        : await _service.getPublicPlaylistWithTracks(
            playlistId: widget.playlistId,
          );

    if (!mounted) return;

    if (statusCode == 200 && playlist != null) {
      setState(() {
        _tracks.addAll(playlist.tracks);
        _page++;
        _hasMore = _page < (playlist.totalPages ?? 1);
        _isFetchingMore = false;
      });
    } else {
      setState(() => _isFetchingMore = false);
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;

    final movedTrack = _tracks[oldIndex];

    setState(() {
      _tracks.removeAt(oldIndex);
      _tracks.insert(newIndex, movedTrack);
    });

    setState(() => _isReordering = true);

    final (statusCode, message) = await _service.reorderTrack(
      playlistId: widget.playlistId,
      trackId: movedTrack.id,
      oldPosition: oldIndex,
      newPosition: newIndex,
    );

    setState(() => _isReordering = false);

    if (!mounted) return;
    if (statusCode != 200) {
      // Revert on failure
      setState(() {
        _tracks.removeAt(newIndex);
        _tracks.insert(oldIndex, movedTrack);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _removeTrack(PlaylistTrack track) async {
    final confirmed = await _showConfirmDialog(
      title: 'Remove Track',
      content: 'Remove "${track.title}" from this playlist?',
    );
    if (!confirmed) return;

    final index = _tracks.indexOf(track);
    setState(() => _tracks.remove(track));

    final (statusCode, message) = await _service.removeTrackFromPlaylist(
      playlistId: widget.playlistId,
      trackId: track.id,
    );

    if (!mounted) return;
    if (statusCode != 200) {
      setState(() => _tracks.insert(index, track));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Track removed from playlist.')),
      );
    }
  }

  Future<void> _deletePlaylist() async {
    final confirmed = await _showConfirmDialog(
      title: 'Delete Playlist',
      content:
          'Are you sure you want to delete "${_playlist?.title}"? This cannot be undone.',
      destructive: true,
    );
    if (!confirmed) return;

    final (statusCode, deleted) =
        await _service.deletePlaylist(playlistId: widget.playlistId);

    if (!mounted) return;
    if (statusCode == 200 && deleted) {
      Navigator.pop(context, true); // signal deletion to parent
    } else if (statusCode == 403) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to delete this playlist.'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (statusCode == 404) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playlist not found.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete playlist. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title:
            Text(title, style: const TextStyle(color: Colors.white)),
        content:
            Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: destructive ? Colors.red : AppColors.crusta,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(destructive ? 'Delete' : 'Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _navigateToEdit() {
    if (_playlist == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPlaylistScreen(playlist: _playlist!),
      ),
    ).then((updated) {
      if (updated == true) _loadPlaylist();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.pureBlack,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        _playlist?.title ?? 'Playlist',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        if (widget.isOwner && _playlist != null) ...[
          if (_isReordering)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.crusta)),
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: _navigateToEdit,
          ),
          PopupMenuButton<String>(
            color: AppColors.surfaceDark,
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'delete') _deletePlaylist();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Delete playlist',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.crusta),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              Text(_error!,
                  style: const TextStyle(color: Colors.white54),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadPlaylist,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.crusta,
                    foregroundColor: Colors.white),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_playlist == null) return const SizedBox();

    return RefreshIndicator(
      onRefresh: _loadPlaylist,
      color: AppColors.crusta,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          if (widget.isOwner && _tracks.isNotEmpty)
            _buildReorderableList()
          else
            _buildStaticList(),
          if (_isFetchingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.crusta, strokeWidth: 2),
                ),
              ),
            ),
          if (_tracks.isEmpty)
            const SliverToBoxAdapter(child: _EmptyTracksState()),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final p = _playlist!;
    final mins = p.playlistLengthInSeconds ~/ 60;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover art
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: p.image != null && p.image!.imgLink.isNotEmpty
                  ? Image.network(
                      p.image!.imgLink,
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderArt(),
                    )
                  : _placeholderArt(),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            p.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          // Meta row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: p.isPrivate
                      ? AppColors.cardDark2
                      : AppColors.crusta.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  p.isPrivate ? 'Private' : 'Public',
                  style: TextStyle(
                    color: p.isPrivate
                        ? Colors.white54
                        : AppColors.crusta,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${p.listOfTracks.length} tracks · ${mins}m',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
          if (p.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              p.description,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              const Icon(Icons.favorite_border,
                  color: Colors.white54, size: 18),
              const SizedBox(width: 4),
              Text('${p.numOfLikes}',
                  style: const TextStyle(color: Colors.white54)),
              const SizedBox(width: 16),
              const Icon(Icons.repeat, color: Colors.white54, size: 18),
              const SizedBox(width: 4),
              Text('${p.numOfReposts}',
                  style: const TextStyle(color: Colors.white54)),
            ],
          ),
          if (widget.isOwner && _tracks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Hold and drag to reorder tracks',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReorderableList() {
    return SliverReorderableList(
      onReorder: _onReorder,
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final track = _tracks[index];
        return ReorderableDragStartListener(
          key: ValueKey(track.id),
          index: index,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 4),
            child: PlaylistTrackTile(
              track: track,
              showDragHandle: true,
              onRemove: () => _removeTrack(track),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaticList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 4),
          child: PlaylistTrackTile(track: _tracks[index]),
        ),
        childCount: _tracks.length,
      ),
    );
  }

  Widget _placeholderArt() {
    return Container(
      width: 220,
      height: 220,
      color: AppColors.cardDark,
      child: const Icon(Icons.queue_music,
          color: Colors.white24, size: 80),
    );
  }
}

class _EmptyTracksState extends StatelessWidget {
  const _EmptyTracksState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_note, color: Colors.white24, size: 56),
          SizedBox(height: 14),
          Text(
            'No tracks in this playlist',
            style: TextStyle(color: Colors.white54, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
