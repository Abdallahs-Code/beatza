// Screen: FeedScreen
// Module 8 — Feed, Search & Discovery
//
// Two tabs:
//   • Discover → getTrendingTracks() → fetch each track by ID → FeedCard
//   • Following → getUserFeed() → fetch each track by ID → FeedCard
//     (feed items carry actor info; full track data supplies title/audio/art)
//
// Audio behaviour (FeedCard handles locally):
//   - Muted by default, no audio plays
//   - Tap "Tap to preview" overlay first, then unmuting starts local audio
//   - Tap ▶ → stops local audio, global mini-player takes over

import 'package:flutter/material.dart';
import 'package:cross_team5/core/navigation/profile_navigator.dart';
import 'package:cross_team5/core/widgets/common_widgets.dart';

import '../models/feed_item_model.dart';
import '../models/trending_item_model.dart';
import '../services/feed_search_api_service.dart';
import '../widgets/feed_card.dart';

import 'package:cross_team5/features/playback_streaming_engine/services/playback_streaming_engine_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FeedSearchApiService _service = FeedSearchApiService();

  // Mute state shared across all FeedCards
  final ValueNotifier<bool> _isMuted = ValueNotifier<bool>(true);

  // ── Discover (trending) tab ────────────────────────────────────────────────
  List<Map<String, dynamic>> _discoverTracks = [];
  bool _discoverLoading = true;
  String? _discoverError;
  final PageController _discoverPageController = PageController();
  int _discoverCurrentPage = 0;

  // ── Following tab — enriched: feed actor info + full track data ────────────
  List<({FeedItemModel item, Map<String, dynamic> track})> _feedItems = [];
  bool _feedLoading = true;
  String? _feedError;
  final PageController _feedPageController = PageController();
  int _feedCurrentPage = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDiscoverTracks();
    _loadFeedItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _discoverPageController.dispose();
    _feedPageController.dispose();
    _isMuted.dispose();
    super.dispose();
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _loadDiscoverTracks() async {
    setState(() {
      _discoverLoading = true;
      _discoverError = null;
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
          tracks.add(trackData);
        }
      }

      if (mounted) {
        setState(() {
          _discoverTracks = tracks;
          _discoverLoading = false;
        });
      }
    } else {
      setState(() {
        _discoverError = data?.toString() ?? 'Failed to load trending tracks';
        _discoverLoading = false;
      });
    }
  }

  Future<void> _loadFeedItems() async {
    setState(() {
      _feedLoading = true;
      _feedError = null;
    });

    final (statusCode, data) = await _service.getUserFeed(limit: 20);
    if (!mounted) return;

    if (statusCode == 200 && data is List) {
      final items = FeedItemModel.listFromJson(data);

      // Fetch full track details concurrently for each feed item
      final results = await Future.wait(
        items.map((item) => _service.getTrackById(item.id)),
      );

      final enriched = <({FeedItemModel item, Map<String, dynamic> track})>[];
      for (int i = 0; i < items.length; i++) {
        final (code, trackData) = results[i];
        if (code == 200 && trackData is Map<String, dynamic>) {
          enriched.add((item: items[i], track: trackData));
        }
      }

      if (mounted) {
        setState(() {
          _feedItems = enriched;
          _feedLoading = false;
        });
      }
    } else {
      setState(() {
        _feedError = data?.toString() ?? 'Failed to load feed';
        _feedLoading = false;
      });
    }
  }

  // ── Playback ───────────────────────────────────────────────────────────────

  Future<void> _playDiscoverTrack(Map<String, dynamic> trackData) async {
    final track = PlaybackTrackModel.fromApiJson(trackData);
    await PlaybackStreamingEngineService.shared.playTrack(track);
  }

  Future<void> _openActorProfile(String actorId) async {
    await ProfileNavigator.push(context, actorId);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildTabBar(),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [_buildDiscoverTab(), _buildFollowingTab()],
      ),
      bottomNavigationBar: const CommonBottomNavBar(
        currentItem: AppNavItem.feed,
      ),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: Container(
        color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.whiteSmoke,
            indicatorWeight: 2,
            labelColor: AppColors.whiteSmoke,
            unselectedLabelColor: AppColors.white54,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Discover'),
              Tab(text: 'Following'),
            ],
          ),
        ),
      ),
    );
  }

  // ── Discover tab ───────────────────────────────────────────────────────────

  Widget _buildDiscoverTab() {
    if (_discoverLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (_discoverError != null) {
      return _buildErrorState(_discoverError!, _loadDiscoverTracks);
    }

    if (_discoverTracks.isEmpty) {
      return Center(
        child: Text(
          'No trending tracks',
          style: TextStyle(color: AppColors.white54),
        ),
      );
    }

    return PageView.builder(
      controller: _discoverPageController,
      scrollDirection: Axis.vertical,
      onPageChanged: (index) => setState(() => _discoverCurrentPage = index),
      itemCount: _discoverTracks.length,
      itemBuilder: (context, index) {
        final trackData = _discoverTracks[index];
        final basicInfo = trackData['basicInfo'] as Map<String, dynamic>? ?? {};
        final image = trackData['image'] as Map<String, dynamic>? ?? {};
        final artists = (basicInfo['mainArtists'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();

        return FeedCard(
          key: ValueKey('discover_$index'),
          itemId: (trackData['trackId'] ?? trackData['_id'] ?? '').toString(),
          isCurrent: index == _discoverCurrentPage,
          isMuted: _isMuted,
          audioUrl: (trackData['audio'] as Map<String, dynamic>?)?['audioLink']
              ?.toString(),
          imgLink: image['imgLink']?.toString(),
          displayName: basicInfo['title']?.toString() ?? 'Unknown',
          actorName: artists.isNotEmpty ? artists.first : 'Unknown Artist',
          actorId: trackData['posterId']?.toString() ?? '',
          isFollowing: false,
          likeCount: trackData['numLikes'] as int? ?? 0,
          commentCount: trackData['numComments'] as int? ?? 0,
          isLiked: trackData['isLikedByUser'] as bool? ?? false,
          isRepost: false,
          onPlayTap: () => _playDiscoverTrack(trackData),
          onActorTap: () =>
              _openActorProfile(trackData['posterId']?.toString() ?? ''),
        );
      },
    );
  }

  // ── Following tab ──────────────────────────────────────────────────────────

  Widget _buildFollowingTab() {
    if (_feedLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (_feedError != null) {
      return _buildErrorState(_feedError!, _loadFeedItems);
    }

    if (_feedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, color: AppColors.white54, size: 64),
            const SizedBox(height: 16),
            Text(
              'Follow artists to see their tracks here',
              style: TextStyle(color: AppColors.white54, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return PageView.builder(
      controller: _feedPageController,
      scrollDirection: Axis.vertical,
      onPageChanged: (index) => setState(() => _feedCurrentPage = index),
      itemCount: _feedItems.length,
      itemBuilder: (context, index) {
        final entry = _feedItems[index];
        final item = entry.item;
        final trackData = entry.track;
        final basicInfo = trackData['basicInfo'] as Map<String, dynamic>? ?? {};
        final image = trackData['image'] as Map<String, dynamic>? ?? {};

        return FeedCard(
          key: ValueKey('feed_${item.id}_$index'),
          itemId: (trackData['trackId'] ?? trackData['_id'] ?? item.id)
              .toString(),
          isCurrent: index == _feedCurrentPage,
          isMuted: _isMuted,
          audioUrl: (trackData['audio'] as Map<String, dynamic>?)?['audioLink']
              ?.toString(),
          imgLink: image['imgLink']?.toString(),
          displayName: basicInfo['title']?.toString() ?? 'Unknown',
          actorName: item.displayName, // who posted / reposted
          actorId: item.actorId,
          isFollowing: true,
          likeCount: trackData['numLikes'] as int? ?? 0,
          commentCount: trackData['numComments'] as int? ?? 0,
          isLiked: trackData['isLikedByUser'] as bool? ?? false,
          isRepost: item.isRepost,
          onPlayTap: () => _playDiscoverTrack(trackData),
          onActorTap: () => _openActorProfile(item.actorId),
        );
      },
    );
  }

  // ── Shared error state ─────────────────────────────────────────────────────

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColors.white54, size: 48),
          const SizedBox(height: 12),
          Text(
            error,
            style: TextStyle(color: AppColors.white54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}
