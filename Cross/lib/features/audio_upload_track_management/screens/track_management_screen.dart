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
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/audio_upload_track_management/models/track.dart';
import 'package:cross_team5/features/audio_upload_track_management/services/track_api_service.dart';
import 'package:provider/provider.dart';
import 'package:cross_team5/core/services/theme_service.dart';
import 'package:cross_team5/features/audio_upload_track_management/audio_upload_track_management_routes.dart';

class TrackManagementScreen extends StatefulWidget {
  const TrackManagementScreen({super.key});

  @override
  State<TrackManagementScreen> createState() => _TrackManagementScreenState();
}

class _TrackManagementScreenState extends State<TrackManagementScreen> {
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

    final result = await _apiService.getAllTracksPaginated(page: 1, limit: 20);

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
      page: _currentPage + 1,
      limit: 20,
    );

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
      // basicInfo — send all current values so the server accepts the update;
      // only isPrivate changes, the rest are preserved as-is.
      title: track.title,
      permalink: track.permalink.isNotEmpty ? track.permalink : null,
      mainArtists: track.mainArtists.isNotEmpty ? track.mainArtists : null,
      genre: track.genre.isNotEmpty ? track.genre : null,
      tags: track.tags.isNotEmpty ? track.tags : null,
      description: track.description.isNotEmpty ? track.description : null,
      caption: track.caption.isNotEmpty ? track.caption : null,
      isPrivate: nowPrivate,
      // permissions — preserve current values instead of sending defaults
      enableDirectDownload: track.enableDirectDownload,
      offlineListening: track.offlineListening,
      includeInRssFeed: track.includeInRssFeed,
      displayedEmbedCode: track.displayedEmbedCode,
      enableAppPlayback: track.enableAppPlayback,
      // license
      licensing: track.licenseType == 'creativeCommons' ? 'creative_commons' : 'all_rights',
      // advanced
      containsExplicit: track.explicitContent,
      recordLabel: track.recordLabel,
      publisher: track.publisher,
      isrc: track.isrc,
      pLine: track.pLine,
      // geoBlocking
      availability: track.geoBlockingMode,
      geoBlockingRegions: track.geoBlockingRegions,
      geoBlockingCountries: track.geoBlockingCountries,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.$2.toString()),
          backgroundColor: AppColors.deepRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nowPrivate ? 'Track set to private' : 'Track set to public',
          ),
          backgroundColor: AppColors.containerMid,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Rebuild Track with flipped isPrivate (Track fields are final)
  Track _rebuildTrack(Track t, bool isPrivate) => Track(
    t.id,
    t.title,
    t.permalink,
    t.mainArtists,
    t.genre,
    t.tags,
    t.description,
    isPrivate,
    t.audioLink,
    t.imageUrl,
    t.numLikes,
    t.numPlays,
    t.numReposts,
    t.numComments,
    t.releaseDate,
  );

  // ─────────────────────────────────────────────
  // Delete — optimistic
  // ─────────────────────────────────────────────
  Future<void> _deleteTrack(Track track) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.container,
        title: Text(
          'Delete track',
          style: TextStyle(color: AppColors.whiteSmoke),
        ),
        content: Text(
          'Delete "${track.title}"? This cannot be undone.',
          style: TextStyle(color: AppColors.greyMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.greyMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: AppColors.deepRed)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Optimistic removal
    final removed = track;
    final removedIdx = _tracks.indexWhere((t) => t.id == track.id);
    setState(() => _tracks.removeWhere((t) => t.id == track.id));

    final result = await _apiService.deleteTrack(trackId: track.id);

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.$2.toString()),
          backgroundColor: AppColors.deepRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Track deleted'),
          backgroundColor: AppColors.containerMid,
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
    context.watch<ThemeService>();
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      appBar: AppBar(
        backgroundColor: AppColors.homeBackground,
        elevation: 0,
        title: Text(
          'Your Tracks',
          style: TextStyle(
            color: AppColors.whiteSmoke,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.whiteSmoke),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.cloud_upload_outlined,
              color: AppColors.primaryOrange,
            ),
            onPressed: () =>
                Navigator.pushNamed(context, AudioUploadRoutes.uploadTrack),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.white54),
            onPressed: _loadTracks,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : _errorMessage != null
          ? _errorState()
          : RefreshIndicator(
              onRefresh: _loadTracks,
              color: AppColors.primaryOrange,
              backgroundColor: AppColors.container,
              child: _tracks.isEmpty ? _emptyState() : _trackList(),
            ),
    );
  }

  Widget _trackList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _tracks.length + (_hasNext ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        // Load more row
        if (index == _tracks.length) {
          return _isLoadingMore
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryOrange,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : Center(
                  child: TextButton(
                    onPressed: _loadMore,
                    child: Text(
                      'Load more',
                      style: TextStyle(color: AppColors.primaryOrange),
                    ),
                  ),
                );
        }

        final track = _tracks[index];
        final toggling = _togglingIds.contains(track.id);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.white10),
          ),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: track.imageUrl != null
                      ? Image.network(
                          track.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              Icon(Icons.music_note, color: AppColors.white54),
                        )
                      : Icon(Icons.music_note, color: AppColors.white54),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          track.isPrivate ? Icons.lock_outline : Icons.public,
                          color: AppColors.greyMedium,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          track.isPrivate ? 'Private' : 'Public',
                          style: TextStyle(
                            color: AppColors.greyMedium,
                            fontSize: 12,
                          ),
                        ),
                        if (track.numPlays > 0) ...[
                          Text(
                            ' · ',
                            style: TextStyle(
                              color: AppColors.greyMedium,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${_fmt(track.numPlays)} plays',
                            style: TextStyle(
                              color: AppColors.greyMedium,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Visibility toggle
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (toggling)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: AppColors.primaryOrange,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    Switch(
                      value: !track.isPrivate,
                      activeThumbColor: AppColors.primaryOrange,
                      onChanged: (_) => _toggleVisibility(track),
                    ),
                  Text(
                    track.isPrivate ? 'Private' : 'Public',
                    style: TextStyle(color: AppColors.greyMedium, fontSize: 10),
                  ),
                ],
              ),

              // More options
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: AppColors.greyMedium,
                  size: 20,
                ),
                color: AppColors.container,
                onSelected: (v) {
                  if (v == 'delete') _deleteTrack(track);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.deepRed, size: 18),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.deepRed)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
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
            Icon(Icons.cloud_off, color: AppColors.greyMedium, size: 60),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: AppColors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadTracks,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: AppColors.whiteSmoke,
              ),
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
          Icon(Icons.cloud_upload_outlined, color: AppColors.greyMedium, size: 60),
          const SizedBox(height: 16),
          Text(
            'No tracks yet',
            style: TextStyle(color: AppColors.greyMuted, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AudioUploadRoutes.uploadTrack),
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Upload first track'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: AppColors.whiteSmoke,
            ),
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
