// Screen: AddMusicScreen
// Paginated track list. User selects tracks with checkboxes, taps Save to add
// them all to the given playlist via PATCH /api/playlists/v1/{id}/tracks/{trackId}.

import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/sets_playlists/services/playlist_api_service.dart';

class AddMusicScreen extends StatefulWidget {
  final String playlistId;

  const AddMusicScreen({super.key, required this.playlistId});

  @override
  State<AddMusicScreen> createState() => _AddMusicScreenState();
}

class _AddMusicScreenState extends State<AddMusicScreen> {
  final PlaylistApiService _service = PlaylistApiService();

  List<Map<String, dynamic>> _tracks = [];
  final Set<String> _selected = {};
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  bool _isSaving = false;
  String? _error;
  int _page = 1;
  static const int _limit = 30;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTracks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isFetchingMore &&
        _hasMore) {
      _fetchMore();
    }
  }

  Future<void> _loadTracks() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _page = 1;
      _tracks = [];
    });

    final (code, data) =
        await _service.getPublicTracksPaginated(page: 1, limit: _limit);

    if (!mounted) return;

    if (code == 200) {
      final tracks =
          (data['tracks'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();
      final info =
          data['paginationInfo'] as Map<String, dynamic>? ?? {};
      setState(() {
        _tracks = tracks;
        _hasMore = info['hasNext'] as bool? ?? false;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = 'Failed to load tracks. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMore() async {
    if (_isFetchingMore || !_hasMore) return;
    setState(() => _isFetchingMore = true);

    final nextPage = _page + 1;
    final (code, data) =
        await _service.getPublicTracksPaginated(page: nextPage, limit: _limit);

    if (!mounted) return;

    if (code == 200) {
      final tracks =
          (data['tracks'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();
      final info =
          data['paginationInfo'] as Map<String, dynamic>? ?? {};
      setState(() {
        _tracks.addAll(tracks);
        _page = nextPage;
        _hasMore = info['hasNext'] as bool? ?? false;
        _isFetchingMore = false;
      });
    } else {
      setState(() => _isFetchingMore = false);
    }
  }

  Future<void> _save() async {
    if (_selected.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    int added = 0;
    for (final trackId in _selected) {
      final (code, _) = await _service.addTrackToPlaylist(
        playlistId: widget.playlistId,
        trackId: trackId,
      );
      if (code == 200) added++;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    Navigator.pop(context, added > 0);
    if (added > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$added track${added == 1 ? '' : 's'} added'),
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      appBar: AppBar(
        backgroundColor: AppColors.pureBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add music',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _isSaving ? null : _save,
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
                    : const Text('Save',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.crusta));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTracks,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.crusta,
                  foregroundColor: Colors.white),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _tracks.length + 2, // header + footer
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Recommended',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          );
        }

        if (index == _tracks.length + 1) {
          return _isFetchingMore
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.crusta, strokeWidth: 2)),
                )
              : const SizedBox(height: 80);
        }

        final track = _tracks[index - 1];
        final trackId = (track['trackId'] ?? track['_id'] ?? '').toString();
        final basicInfo =
            track['basicInfo'] as Map<String, dynamic>? ?? {};
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
        final isSelected = _selected.contains(trackId);

        return ListTile(
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
                    errorBuilder: (ctx, err, st) => _placeholder(),
                  )
                : _placeholder(),
          ),
          title: Text(
            title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '$artistName  ▶ ${_formatPlays(plays)} · ${_formatDuration(duration)}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selected.remove(trackId);
                } else {
                  _selected.add(trackId);
                }
              });
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.crusta : Colors.white38,
                  width: 2,
                ),
                color: isSelected ? AppColors.crusta : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
          onTap: () {
            setState(() {
              if (isSelected) {
                _selected.remove(trackId);
              } else {
                _selected.add(trackId);
              }
            });
          },
        );
      },
    );
  }

  Widget _placeholder() {
    return Container(
      width: 52,
      height: 52,
      color: AppColors.tileDark,
      child: const Icon(Icons.music_note, color: Colors.white24, size: 22),
    );
  }
}
