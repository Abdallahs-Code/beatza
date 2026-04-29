// Screen: GenreTracksScreen
// Shows a list of public tracks filtered by a specific genre.
// Fetches up to 15 tracks from GET /api/public/tracks/v1/ and filters
// client-side by basicInfo.genre matching the selected genre.

import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

import '../services/feed_search_api_service.dart';
import '../widgets/search_result_tile.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/playback_streaming_engine_service.dart';

class GenreTracksScreen extends StatefulWidget {
  final String genre;
  final Color genreColor;

  const GenreTracksScreen({
    super.key,
    required this.genre,
    required this.genreColor,
  });

  @override
  State<GenreTracksScreen> createState() => _GenreTracksScreenState();
}

class _GenreTracksScreenState extends State<GenreTracksScreen> {
  final FeedSearchApiService _service = FeedSearchApiService();

  List<Map<String, dynamic>> _tracks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final (code, data) = await _service.getPublicTracks(page: 1, limit: 30);
    if (!mounted) return;

    if (code == 200 && data is Map<String, dynamic>) {
      final rawList = data['tracks'] as List<dynamic>? ?? [];
      final filtered = rawList
          .whereType<Map<String, dynamic>>()
          .where((t) {
            final info = t['basicInfo'];
            final genre =
                (info is Map ? (info['genre'] ?? '') : '').toString();
            return genre.toLowerCase() == widget.genre.toLowerCase();
          })
          .toList();

      setState(() {
        _tracks = filtered;
        _loading = false;
      });
    } else {
      setState(() {
        _error = data?.toString() ?? 'Failed to load tracks';
        _loading = false;
      });
    }
  }

  Future<void> _onTrackTap(Map<String, dynamic> trackJson) async {
    final track = PlaybackTrackModel.fromApiJson(trackJson);
    await PlaybackStreamingEngineService.shared.playTrack(track);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.chineseBlack,
      appBar: AppBar(
        backgroundColor: widget.genreColor,
        title: Text(
          widget.genre,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.white54)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadTracks,
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    if (_tracks.isEmpty) {
      return Center(
        child: Text(
          'No ${widget.genre} tracks found',
          style: const TextStyle(color: AppColors.white54, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final track = _tracks[index];
        final basicInfo =
            track['basicInfo'] as Map<String, dynamic>? ?? {};
        final image =
            track['image'] as Map<String, dynamic>? ?? {};
        final artists =
            (basicInfo['mainArtists'] as List<dynamic>? ?? []);
        final id =
            (track['trackId'] ?? track['_id'] ?? '').toString();

        return SearchResultTile(
          id: id,
          type: 'track',
          title: basicInfo['title']?.toString() ?? id,
          subtitle:
              artists.isNotEmpty ? artists.first.toString() : null,
          imageUrl: image['imgLink']?.toString(),
          onTap: () => _onTrackTap(track),
        );
      },
    );
  }
}
