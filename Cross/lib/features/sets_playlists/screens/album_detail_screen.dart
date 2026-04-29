import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/sets_playlists/models/playlist_model.dart';
import 'package:cross_team5/features/sets_playlists/screens/edit_playlist_screen.dart';
import 'package:cross_team5/features/sets_playlists/services/playlist_api_service.dart';
import 'package:cross_team5/features/sets_playlists/widgets/playlist_track_tile.dart';

class AlbumDetailScreen extends StatefulWidget {
  final String playlistId;
  final bool isOwner;

  const AlbumDetailScreen({
    super.key,
    required this.playlistId,
    this.isOwner = false,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  final PlaylistApiService _service = PlaylistApiService();

  PlaylistModel? _album;
  bool _isLoading = true;
  String? _error;

  int _page = 1;
  bool _hasMore = true;
  bool _isFetchingMore = false;
  final ScrollController _scrollController = ScrollController();

  List<PlaylistTrack> _tracks = [];

  @override
  void initState() {
    super.initState();
    _loadAlbum();
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

  Future<void> _loadAlbum() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final (statusCode, album) = await _service.getPlaylistWithTracks(
        playlistId: widget.playlistId,
      );

      if (!mounted) return;

      if (statusCode == 200 && album != null) {
        setState(() {
          _album = album;
          _tracks = List.from(album.tracks);
          _hasMore = (_album!.totalPages ?? 1) > 1;
          _page = 1;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = statusCode == 401
              ? 'Sign in to view this album.'
              : 'Failed to load album.';
          _isLoading = false;
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

    final (statusCode, album) = await _service.getPlaylistWithTracks(
      playlistId: widget.playlistId,
    );

    if (!mounted) return;

    if (statusCode == 200 && album != null) {
      setState(() {
        _tracks.addAll(album.tracks);
        _page++;
        _hasMore = _page < (album.totalPages ?? 1);
        _isFetchingMore = false;
      });
    } else {
      setState(() => _isFetchingMore = false);
    }
  }

  Future<void> _removeTrack(PlaylistTrack track) async {
    final confirmed = await _showConfirmDialog(
      title: 'Remove Track',
      content: 'Remove "${track.title}" from this album?',
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
        const SnackBar(content: Text('Track removed from album.')),
      );
    }
  }

  Future<void> _deleteAlbum() async {
    final confirmed = await _showConfirmDialog(
      title: 'Delete Album',
      content:
          'Are you sure you want to delete "${_album?.title}"? This cannot be undone.',
      destructive: true,
    );
    if (!confirmed) return;

    final (statusCode, deleted) =
        await _service.deletePlaylist(playlistId: widget.playlistId);

    if (!mounted) return;
    if (statusCode == 200 && deleted) {
      Navigator.pop(context, true);
    } else if (statusCode == 403) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to delete this album.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete album. Please try again.'),
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
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
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
    if (_album == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPlaylistScreen(playlist: _album!),
      ),
    ).then((updated) {
      if (updated == true) _loadAlbum();
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
        _album?.title ?? 'Album',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        if (widget.isOwner && _album != null) ...[
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: _navigateToEdit,
          ),
          PopupMenuButton<String>(
            color: AppColors.surfaceDark,
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'delete') _deleteAlbum();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Delete album',
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
              const Icon(Icons.error_outline, color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              Text(_error!,
                  style: const TextStyle(color: Colors.white54),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadAlbum,
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

    if (_album == null) return const SizedBox();

    return RefreshIndicator(
      onRefresh: _loadAlbum,
      color: AppColors.crusta,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          _buildTrackList(),
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
    final a = _album!;
    final mins = a.playlistLengthInSeconds ~/ 60;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album art — larger, square, prominent
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 32,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: a.image != null && a.image!.imgLink.isNotEmpty
                  ? Image.network(
                      a.image!.imgLink,
                      width: 240,
                      height: 240,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholderArt(),
                    )
                  : _placeholderArt(),
            ),
          ),
          const SizedBox(height: 20),

          // Album label chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.crusta.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.album, color: AppColors.crusta, size: 13),
                SizedBox(width: 4),
                Text(
                  'Album',
                  style: TextStyle(
                    color: AppColors.crusta,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            a.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),

          // Meta row
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: a.isPrivate
                      ? AppColors.cardDark2
                      : AppColors.crusta.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  a.isPrivate ? 'Private' : 'Public',
                  style: TextStyle(
                    color: a.isPrivate ? Colors.white54 : AppColors.crusta,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${a.listOfTracks.length} tracks · ${mins}m',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),

          if (a.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              a.description,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 13),
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
              Text('${a.numOfLikes}',
                  style: const TextStyle(color: Colors.white54)),
              const SizedBox(width: 16),
              const Icon(Icons.repeat, color: Colors.white54, size: 18),
              const SizedBox(width: 4),
              Text('${a.numOfReposts}',
                  style: const TextStyle(color: Colors.white54)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: PlaylistTrackTile(
            track: _tracks[index],
            onRemove: widget.isOwner
                ? () => _removeTrack(_tracks[index])
                : null,
          ),
        ),
        childCount: _tracks.length,
      ),
    );
  }

  Widget _placeholderArt() {
    return Container(
      width: 240,
      height: 240,
      color: AppColors.cardDark,
      child: const Icon(Icons.album, color: Colors.white24, size: 80),
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
          Icon(Icons.album, color: Colors.white24, size: 56),
          SizedBox(height: 14),
          Text(
            'No tracks in this album',
            style: TextStyle(color: Colors.white54, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
