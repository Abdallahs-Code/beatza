// Screen: GenreTracksScreen
// Shows a list of public tracks filtered by a specific genre.
// Fetches up to 30 tracks from GET /api/tracks/v2/ and filters
// client-side by basicInfo.genre matching the selected genre.

import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

import '../models/trending_item_model.dart';
import '../services/feed_search_api_service.dart';
import '../widgets/search_result_tile.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/playback_streaming_engine_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/mini_player_state.dart';

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

class _GenreTracksScreenState extends State<GenreTracksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FeedSearchApiService _service = FeedSearchApiService();

  // ── All tab ────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _allTracks = [];
  bool _allLoading = true;
  String? _allError;

  // ── Trending tab ───────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _trendingTracks = [];
  bool _trendingLoading = false;
  bool _trendingLoaded = false;
  String? _trendingError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadAllTracks();
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && !_trendingLoaded && !_trendingLoading) {
      _loadTrendingTracks();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _loadAllTracks() async {
    setState(() {
      _allLoading = true;
      _allError = null;
    });

    final (code, data) = await _service.getPublicTracks(page: 1, limit: 30);
    if (!mounted) return;

    if (code == 200 && data is Map<String, dynamic>) {
      final rawList = data['tracks'] as List<dynamic>? ?? [];
      final filtered = rawList.whereType<Map<String, dynamic>>().where((t) {
        final info = t['basicInfo'];
        final genre = (info is Map ? (info['genre'] ?? '') : '').toString();
        return genre.toLowerCase() == widget.genre.toLowerCase();
      }).toList();

      setState(() {
        _allTracks = filtered;
        _allLoading = false;
      });
    } else {
      setState(() {
        _allError = data?.toString() ?? 'Failed to load tracks';
        _allLoading = false;
      });
    }
  }

  Future<void> _loadTrendingTracks() async {
    setState(() {
      _trendingLoading = true;
      _trendingError = null;
    });

    final (statusCode, data) = await _service.getTrendingTracks(limit: 20);
    if (!mounted) return;

    if (statusCode == 200 && data is List) {
      final ids = TrendingItemModel.listFromJson(data);
      final results = await Future.wait(
        ids.map((item) => _service.getTrackById(item.id)),
      );

      final tracks = <Map<String, dynamic>>[];
      for (final (code, trackData) in results) {
        if (code == 200 && trackData is Map<String, dynamic>) {
          final info = trackData['basicInfo'];
          final genre =
              (info is Map ? (info['genre'] ?? '') : '').toString();
          if (genre.toLowerCase() == widget.genre.toLowerCase()) {
            tracks.add(trackData);
          }
        }
      }

      if (mounted) {
        setState(() {
          _trendingTracks = tracks;
          _trendingLoading = false;
          _trendingLoaded = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _trendingError =
              data?.toString() ?? 'Failed to load trending tracks';
          _trendingLoading = false;
          _trendingLoaded = true;
        });
      }
    }
  }

  Future<void> _onTrackTap(Map<String, dynamic> trackJson) async {
    final track = PlaybackTrackModel.fromApiJson(trackJson);
    await PlaybackStreamingEngineService.shared.playTrack(track);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.chineseBlack,
      appBar: AppBar(
        backgroundColor: widget.genreColor,
        title: Text(
          widget.genre,
          style: TextStyle(
            color: AppColors.whiteSmoke,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.whiteSmoke),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.whiteSmoke,
          labelColor: AppColors.whiteSmoke,
          unselectedLabelColor: AppColors.white54,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Trending'),
            Tab(text: 'Playlists'),
            Tab(text: 'Albums'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllTab(),
          _buildTrendingTab(),
          _buildPlaceholder('Playlists coming soon'),
          _buildPlaceholder('Albums coming soon'),
        ],
      ),
      bottomNavigationBar: const MiniPlayerSpacer(),
    );
  }

  // ── Tab bodies ─────────────────────────────────────────────────────────────

  Widget _buildAllTab() {
    if (_allLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      );
    }

    if (_allError != null) {
      return _buildError(_allError!, _loadAllTracks);
    }

    if (_allTracks.isEmpty) {
      return _buildPlaceholder('No ${widget.genre} tracks found');
    }

    return _buildTrackList(_allTracks);
  }

  Widget _buildTrendingTab() {
    if (_trendingLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      );
    }

    if (_trendingError != null) {
      return _buildError(_trendingError!, _loadTrendingTracks);
    }

    if (_trendingTracks.isEmpty) {
      return _buildPlaceholder('No trending ${widget.genre} tracks');
    }

    return _buildTrackList(_trendingTracks);
  }

  Widget _buildPlaceholder(String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(color: AppColors.white54, fontSize: 16),
      ),
    );
  }

  Widget _buildTrackList(List<Map<String, dynamic>> tracks) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        final basicInfo = track['basicInfo'] as Map<String, dynamic>? ?? {};
        final image = track['image'] as Map<String, dynamic>? ?? {};
        final artists = (basicInfo['mainArtists'] as List<dynamic>? ?? []);
        final id = (track['trackId'] ?? track['_id'] ?? '').toString();

        return SearchResultTile(
          id: id,
          type: 'track',
          title: basicInfo['title']?.toString() ?? id,
          subtitle: artists.isNotEmpty ? artists.first.toString() : null,
          imageUrl: image['imgLink']?.toString(),
          onTap: () => _onTrackTap(track),
        );
      },
    );
  }

  Widget _buildError(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(error, style: TextStyle(color: AppColors.white54)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

}
