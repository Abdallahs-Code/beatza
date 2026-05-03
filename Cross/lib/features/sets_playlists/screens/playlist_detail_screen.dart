





import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:cross_team5/core/services/theme_service.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/sets_playlists/models/playlist_model.dart';
import 'package:cross_team5/features/sets_playlists/screens/add_music_screen.dart';
import 'package:cross_team5/features/sets_playlists/screens/edit_playlist_screen.dart';
import 'package:cross_team5/features/sets_playlists/services/playlist_api_service.dart';
import 'package:cross_team5/features/sets_playlists/widgets/playlist_options_sheet.dart';
import 'package:cross_team5/features/sets_playlists/widgets/playlist_track_tile.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/features/sets_playlists/playlist_playback.dart';

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
  List<PlaylistTrack> _tracks = [];
  Map<String, dynamic>? _creatorInfo;

  
  List<Map<String, dynamic>> _suggestions = [];
  bool _suggestionsLoading = false;

  bool _isLoading = true;
  String? _error;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // The API is page-based (returns page/totalPages), not offset-based.
  // Sending offset=0 causes 400. Match the frontend: no pagination params on load.
  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _tracks = [];
    });

    final (code, playlist) = await _service.getPlaylistWithTracks(
      playlistId: widget.playlistId,
    );

    if (!mounted) return;

    if (code == 200 && playlist != null) {
      setState(() {
        _playlist = playlist;
        _tracks = List.from(playlist.tracks);
        _isLoading = false;
      });
      _loadCreatorInfo(playlist.artistId);
      _loadSuggestions();
      _service.addPlaylistToHistory(playlistId: widget.playlistId);
    } else {
      setState(() {
        _error = code == 401
            ? 'Sign in to view this playlist.'
            : 'Failed to load playlist.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCreatorInfo(String artistId) async {
    if (artistId.isEmpty) return;
    final (code, info) = await _service.getArtistInfo(creatorId: artistId);
    if (!mounted) return;
    if (code == 200 && info != null) {
      setState(() => _creatorInfo = info);
    }
  }

  Future<void> _loadSuggestions() async {
    setState(() => _suggestionsLoading = true);
    final (code, data) =
        await _service.getPublicTracksPaginated(page: 1, limit: 10);
    if (!mounted) return;

    if (code == 200) {
      final tracks = (data['tracks'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      setState(() {
        _suggestions = tracks;
        _suggestionsLoading = false;
      });
    } else {
      setState(() => _suggestionsLoading = false);
    }
  }

  

  Future<void> _openOptions() async {
    if (_playlist == null) return;

    final result = await showModalBottomSheet<PlaylistOptionResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PlaylistOptionsSheet(
        playlist: _playlist!,
        isOwner: widget.isOwner,
      ),
    );

    if (!mounted) return;

    switch (result) {
      case PlaylistOptionResult.edited:
        _navigateToEdit();
        break;
      case PlaylistOptionResult.deleted:
        Navigator.pop(context, true);
        break;
      case PlaylistOptionResult.privacyChanged:
      case PlaylistOptionResult.secretTokenUpdated:
        _load();
        break;
      case PlaylistOptionResult.musicAdded:
        _navigateToAddMusic();
        break;
      case PlaylistOptionResult.copied:
        break;
      case null:
        break;
    }
  }

  void _navigateToEdit() {
    if (_playlist == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPlaylistScreen(
          playlist: _playlist!,
          tracks: _tracks,
        ),
      ),
    ).then((updated) {
      if (updated == true) _load();
    });
  }

  Future<void> _navigateToAddMusic() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddMusicScreen(playlistId: widget.playlistId),
      ),
    );
    if (added == true && mounted) _load();
  }

  Future<void> _addSuggestionToPlaylist(Map<String, dynamic> track) async {
    final trackId =
        (track['trackId'] ?? track['_id'] ?? '').toString();
    if (trackId.isEmpty) return;

    final (code, _) = await _service.addTrackToPlaylist(
      playlistId: widget.playlistId,
      trackId: trackId,
    );

    if (!mounted) return;
    if (code == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Track added to playlist')),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to add track'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _playTrackAtIndex(int index) async {
    if (_tracks.isEmpty) return;
    await playPlaylistTracksAt(
      context,
      _tracks,
      index,
      playlistArtistId: _playlist?.artistId,
    );
  }

  Future<void> _playAllFromStart() async {
    if (_tracks.isEmpty) return;
    await playPlaylistTracksAt(
      context,
      _tracks,
      0,
      playlistArtistId: _playlist?.artistId,
    );
  }

  Future<void> _playAllShuffled() async {
    if (_tracks.isEmpty) return;
    final queue = playbackQueueFromPlaylistTracks(
      _tracks,
      playlistArtistId: _playlist?.artistId,
    )..shuffle();
    await playPlaybackQueueAt(context, queue: queue, index: 0);
  }

  List<PlaybackTrackModel> get _suggestionPlaybackQueue =>
      _suggestions.map(PlaybackTrackModel.fromApiJson).toList();

  Future<void> _playSuggestionAt(int index) async {
    final queue = _suggestionPlaybackQueue;
    await playPlaybackQueueAt(context, queue: queue, index: index);
  }

  Future<void> _removeTrack(PlaylistTrack track) async {
    final index = _tracks.indexOf(track);
    setState(() => _tracks.remove(track));

    final (code, _) = await _service.removeTrackFromPlaylist(
      playlistId: widget.playlistId,
      trackId: track.id,
    );

    if (!mounted) return;
    if (code != 200) {
      setState(() => _tracks.insert(index, track));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to remove track'),
            backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Track removed')),
      );
    }
  }

  

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeService>();
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SafeArea(
        child: Center(
            child: CircularProgressIndicator(color: AppColors.crusta)),
      );
    }

    if (_error != null) {
      return SafeArea(child: _buildErrorState());
    }

    if (_playlist == null) return const SizedBox();

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.crusta,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildActionRow()),
          if (_tracks.isEmpty) ...[
            SliverToBoxAdapter(child: _buildSuggestionsSection(isNew: true)),
          ] else ...[
            _buildTrackList(),
            SliverToBoxAdapter(
                child: _buildSuggestionsSection(isNew: false)),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.pureBlack,
      elevation: 0,
      pinned: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        _playlist?.title ?? 'Playlist',
        style: const TextStyle(
            color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _creatorDisplayName() {
    final info = _creatorInfo;
    if (info == null) return 'Unknown';
    String? pick(Map<String, dynamic>? m) =>
        m?['displayName']?.toString().trim();
    var n = pick(info);
    if (n != null && n.isNotEmpty) return n;
    final raw = info['artist'];
    if (raw is Map<String, dynamic>) {
      n = pick(raw);
      if (n != null && n.isNotEmpty) return n;
    } else if (raw is List && raw.isNotEmpty && raw.first is Map) {
      n = pick(Map<String, dynamic>.from(raw.first as Map));
      if (n != null && n.isNotEmpty) return n;
    }
    return 'Unknown';
  }

  String? _creatorImageUrl() {
    final info = _creatorInfo;
    if (info == null) return null;
    dynamic img(dynamic node) {
      if (node is Map) return node['imgLink']?.toString();
      return null;
    }

    final top = info['profileImage'];
    if (top is Map) {
      final u = img(top);
      if (u != null && u.isNotEmpty) return u;
    } else if (top is String && top.isNotEmpty) {
      return top;
    }

    final raw = info['artist'];
    if (raw is Map) {
      final u = img(raw['profileImage']);
      if (u != null && u.isNotEmpty) return u;
    } else if (raw is List && raw.isNotEmpty && raw.first is Map) {
      final u = img((raw.first as Map)['profileImage']);
      if (u != null && u.isNotEmpty) return u;
    }
    return null;
  }

  Widget _buildHeader() {
    final p = _playlist!;
    final totalSecs = p.playlistLengthInSeconds;
    final mins = totalSecs ~/ 60;
    final trackCount = p.trackCount;

    final creatorName = _creatorDisplayName();
    final creatorImg = _creatorImageUrl();

    final timeAgo = _timeAgo(p.createdAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: p.image != null && p.image!.imgLink.isNotEmpty
                  ? Image.network(
                      p.image!.imgLink,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => _placeholderArt(),
                    )
                  : _placeholderArt(),
            ),
          ),
          const SizedBox(height: 16),

          
          Text(
            p.title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),

          
          Text(
            '${p.isPrivate ? 'Secret' : 'Public'} · Playlist · $trackCount Track${trackCount == 1 ? '' : 's'}${mins > 0 ? ' · ${mins}m' : ''} · $timeAgo',
            style:
                const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 10),

          
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.cardDark,
                backgroundImage: (creatorImg != null && creatorImg.isNotEmpty)
                    ? NetworkImage(creatorImg)
                    : null,
                child: creatorImg == null || creatorImg.isEmpty
                    ? const Icon(Icons.person,
                        color: Colors.white54, size: 16)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'By $creatorName',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          
          _iconCircleButton(
            icon: Icons.more_horiz,
            onTap: _openOptions,
          ),
          const Spacer(),

          
          _iconCircleButton(
            icon: Icons.shuffle,
            onTap: _tracks.isEmpty ? () {} : _playAllShuffled,
          ),
          const SizedBox(width: 12),

          
          GestureDetector(
            onTap: _tracks.isEmpty ? () {} : _playAllFromStart,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.crusta,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow,
                  color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconCircleButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildTrackList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final track = _tracks[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            child: PlaylistTrackTile(
              track: track,
              showOptions: true,
              playlistOwnerArtistId: _playlist?.artistId,
              onTap: () => _playTrackAtIndex(index),
              onRemove: widget.isOwner ? () => _removeTrack(track) : null,
            ),
          );
        },
        childCount: _tracks.length,
      ),
    );
  }

  Widget _buildSuggestionsSection({required bool isNew}) {
    if (_suggestionsLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
            child: CircularProgressIndicator(
                color: AppColors.crusta, strokeWidth: 2)),
      );
    }
    if (_suggestions.isEmpty) {
      if (isNew) {
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.music_note, color: Colors.white24, size: 56),
              SizedBox(height: 12),
              Text('No tracks yet',
                  style: TextStyle(color: Colors.white54, fontSize: 15)),
              SizedBox(height: 6),
              Text('Add music to get started',
                  style: TextStyle(color: Colors.white38, fontSize: 13)),
            ],
          ),
        );
      }
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            isNew
                ? 'Suggestions for your new playlist'
                : 'Suggested for you',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700),
          ),
        ),
        if (isNew)
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _loadSuggestions,
                child: const Text('Refresh suggestions',
                    style: TextStyle(color: AppColors.crusta, fontSize: 13)),
              ),
            ),
          ),
        ..._suggestions.asMap().entries.map(
              (e) => _buildSuggestionTile(e.key, e.value),
            ),
      ],
    );
  }

  Widget _buildSuggestionTile(int index, Map<String, dynamic> track) {
    final basicInfo = track['basicInfo'] as Map<String, dynamic>? ?? {};
    final image = track['image'] as Map<String, dynamic>? ?? {};
    final title = basicInfo['title']?.toString() ?? 'Unknown';
    final artists =
        (basicInfo['mainArtists'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
    final artistName =
        artists.isNotEmpty ? artists.first : 'Unknown Artist';
    final imgLink = image['imgLink']?.toString() ?? '';
    final duration =
        (track['durationInSeconds'] as num?)?.toInt() ?? 0;
    final plays = (track['numPlays'] ?? track['numOfPlays'] ?? 0) as num;

    return ListTile(
      onTap: () => _playSuggestionAt(index),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: imgLink.isNotEmpty
            ? Image.network(
                imgLink,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, st) => _suggestionPlaceholder(),
              )
            : _suggestionPlaceholder(),
      ),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '$artistName  ▶ ${_formatPlays(plays)} · ${_formatDuration(duration)}',
        style: const TextStyle(color: Colors.white54, fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: widget.isOwner
          ? GestureDetector(
              onTap: () => _addSuggestionToPlaylist(track),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: const Icon(Icons.add,
                    color: Colors.white70, size: 18),
              ),
            )
          : null,
    );
  }

  Widget _buildErrorState() {
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
              onPressed: _load,
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

  Widget _placeholderArt() {
    return Container(
      width: 200,
      height: 200,
      color: AppColors.cardDark,
      child: const Icon(Icons.queue_music, color: Colors.white24, size: 72),
    );
  }

  Widget _suggestionPlaceholder() {
    return Container(
      width: 52,
      height: 52,
      color: AppColors.tileDark,
      child:
          const Icon(Icons.music_note, color: Colors.white24, size: 22),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatPlays(num plays) {
    if (plays >= 1000000) return '${(plays / 1000000).toStringAsFixed(1)}M';
    if (plays >= 1000) return '${(plays / 1000).toStringAsFixed(1)}K';
    return plays.toString();
  }

  String _timeAgo(String isoDate) {
    if (isoDate.isEmpty) return 'Recently';
    try {
      final dt = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 365) return '${diff.inDays ~/ 365}y ago';
      if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return 'Just now';
    } catch (_) {
      return 'Recently';
    }
  }
}
