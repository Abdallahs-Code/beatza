// Screen: TrackManagementScreen
// Shows all tracks with visibility toggle and delete.
// Fully independent of Module 5 and Module 6.
//
// Data: TrackApiService.getAllTracksPaginated()
// Visibility toggle: TrackApiService.updateTrack(isPrivate: !current)
// Delete: TrackApiService.deleteTrack() with confirmation dialog
// Pagination: Load more button when hasNext == true
// Pull-to-refresh: RefreshIndicator

import 'package:flutter/material.dart';
import 'package:cross_team5/features/audio_upload_track_management/models/track.dart';
import 'package:cross_team5/features/audio_upload_track_management/services/track_api_service.dart';
import 'package:cross_team5/features/audio_upload_track_management/audio_upload_track_management_routes.dart';

class TrackManagementScreen extends StatefulWidget {
  const TrackManagementScreen({super.key});

  @override
  State<TrackManagementScreen> createState() =>
      _TrackManagementScreenState();
}

class _TrackManagementScreenState
    extends State<TrackManagementScreen> {
  final TrackApiService _apiService = TrackApiService();

  List<Track> _tracks = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasNext = false;

  // IDs currently being toggled (show spinner instead of switch)
  final Set<String> _togglingIds = {};

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  // ─────────────────────────────────────────────
  // Load page 1
  // ─────────────────────────────────────────────
  Future<void> _loadTracks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _apiService.getAllTracksPaginated(
        page: 1, limit: 20);

    setState(() {
      _isLoading = false;
      if (result.$1 == 200) {
        final data = result.$2 as Map<String, dynamic>;
        _tracks = data['tracks'] as List<Track>;
        _hasNext = data['hasNext'] as bool? ?? false;
        _currentPage = 1;
      } else {
        _errorMessage = result.$2.toString();
      }
    });
  }

  // ─────────────────────────────────────────────
  // Load next page
  // ─────────────────────────────────────────────
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasNext) return;
    setState(() => _isLoadingMore = true);

    final result = await _apiService.getAllTracksPaginated(
        page: _currentPage + 1, limit: 20);

    setState(() {
      _isLoadingMore = false;
      if (result.$1 == 200) {
        final data = result.$2 as Map<String, dynamic>;
        _tracks.addAll(data['tracks'] as List<Track>);
        _hasNext = data['hasNext'] as bool? ?? false;
        _currentPage++;
      }
    });
  }

  // ─────────────────────────────────────────────
  // Toggle visibility — optimistic
  // ─────────────────────────────────────────────
  Future<void> _toggleVisibility(Track track) async {
    if (_togglingIds.contains(track.id)) return;

    final wasPrivate = track.isPrivate;
    final nowPrivate = !wasPrivate;

    setState(() {
      _togglingIds.add(track.id);
      final idx = _tracks.indexWhere((t) => t.id == track.id);
      if (idx != -1) {
        _tracks[idx] = _rebuildTrack(track, nowPrivate);
      }
    });

    final result = await _apiService.updateTrack(
      trackId: track.id,
      isPrivate: nowPrivate,
    );

    setState(() => _togglingIds.remove(track.id));

    if (!mounted) return;

    if (result.$1 != 200) {
      // Revert
      setState(() {
        final idx = _tracks.indexWhere((t) => t.id == track.id);
        if (idx != -1) {
          _tracks[idx] = _rebuildTrack(_tracks[idx], wasPrivate);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.$2.toString()),
        backgroundColor: Colors.red[800],
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(nowPrivate
            ? 'Track set to private'
            : 'Track set to public'),
        backgroundColor: const Color(0xFF2A2A2A),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // Rebuild Track with flipped isPrivate (Track fields are final)
  Track _rebuildTrack(Track t, bool isPrivate) => Track(
        t.id, t.title, t.permalink, t.mainArtists,
        t.genre, t.tags, t.description, isPrivate,
        t.audioLink, t.imageUrl, t.numLikes, t.numPlays,
        t.numReposts, t.numComments, t.releaseDate,
      );

  // ─────────────────────────────────────────────
  // Delete — optimistic
  // ─────────────────────────────────────────────
  Future<void> _deleteTrack(Track track) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete track',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${track.title}"? This cannot be undone.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Optimistic removal
    final removed = track;
    final removedIdx =
        _tracks.indexWhere((t) => t.id == track.id);
    setState(
        () => _tracks.removeWhere((t) => t.id == track.id));

    final result =
        await _apiService.deleteTrack(trackId: track.id);

    if (!mounted) return;

    if (result.$1 != 200) {
      // Revert
      setState(() {
        if (removedIdx >= 0 && removedIdx <= _tracks.length) {
          _tracks.insert(removedIdx, removed);
        } else {
          _tracks.add(removed);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.$2.toString()),
        backgroundColor: Colors.red[800],
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Track deleted'),
          backgroundColor: Color(0xFF2A2A2A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: const Text('Your Tracks',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined,
                color: Color(0xFFFF5500)),
            onPressed: () => Navigator.pushNamed(
                context, AudioUploadRoutes.uploadTrack),
          ),
          IconButton(
            icon: const Icon(Icons.refresh,
                color: Colors.white54),
            onPressed: _loadTracks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Colors.orange))
          : _errorMessage != null
              ? _errorState()
              : RefreshIndicator(
                  onRefresh: _loadTracks,
                  color: Colors.orange,
                  backgroundColor: const Color(0xFF1A1A1A),
                  child: _tracks.isEmpty
                      ? _emptyState()
                      : _trackList(),
                ),
    );
  }

  Widget _trackList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _tracks.length + (_hasNext ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        // Load more row
        if (index == _tracks.length) {
          return _isLoadingMore
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                        color: Colors.orange, strokeWidth: 2),
                  ),
                )
              : Center(
                  child: TextButton(
                    onPressed: _loadMore,
                    child: const Text('Load more',
                        style: TextStyle(
                            color: Colors.orange)),
                  ),
                );
        }

        final track = _tracks[index];
        final toggling = _togglingIds.contains(track.id);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(children: [
            // Thumbnail
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1C),
                  borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: track.imageUrl != null
                    ? Image.network(track.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.music_note,
                                color: Colors.white54))
                    : const Icon(Icons.music_note,
                        color: Colors.white54),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(
                        track.isPrivate
                            ? Icons.lock_outline
                            : Icons.public,
                        color: const Color(0xFF9A9A9A),
                        size: 12),
                    const SizedBox(width: 4),
                    Text(
                        track.isPrivate
                            ? 'Private'
                            : 'Public',
                        style: const TextStyle(
                            color: Color(0xFF9A9A9A),
                            fontSize: 12)),
                    if (track.numPlays > 0) ...[
                      const Text(' · ',
                          style: TextStyle(
                              color: Color(0xFF9A9A9A),
                              fontSize: 12)),
                      Text('${_fmt(track.numPlays)} plays',
                          style: const TextStyle(
                              color: Color(0xFF9A9A9A),
                              fontSize: 12)),
                    ],
                  ]),
                ],
              ),
            ),

            // Visibility toggle
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (toggling)
                  const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.orange, strokeWidth: 2),
                  )
                else
                  Switch(
                    value: !track.isPrivate,
                    activeColor: const Color(0xFFFF5500),
                    onChanged: (_) => _toggleVisibility(track),
                  ),
                Text(track.isPrivate ? 'Private' : 'Public',
                    style: const TextStyle(
                        color: Color(0xFF9A9A9A),
                        fontSize: 10)),
              ],
            ),

            // More options
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  color: Color(0xFF9A9A9A), size: 20),
              color: const Color(0xFF1A1A1A),
              onSelected: (v) {
                if (v == 'delete') _deleteTrack(track);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline,
                        color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Delete',
                        style: TextStyle(
                            color: Colors.red)),
                  ]),
                ),
              ],
            ),
          ]),
        );
      },
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off,
                color: Colors.grey[700], size: 60),
            const SizedBox(height: 16),
            Text(_errorMessage!,
                style: TextStyle(color: Colors.grey[400]),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadTracks,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload_outlined,
              color: Colors.grey[700], size: 60),
          const SizedBox(height: 16),
          Text('No tracks yet',
              style: TextStyle(
                  color: Colors.grey[500], fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(
                context, AudioUploadRoutes.uploadTrack),
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Upload first track'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    }
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}
