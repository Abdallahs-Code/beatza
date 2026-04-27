// Screen: FeedScreen
// Module 8 — Feed, Search & Discovery
//
// Layout (matches module_8_screens.pdf pages 7-9, SoundCloud feed UI):
//   - Full-screen black background
//   - Two tabs at top centre: "Discover" | "Following"
//     • Discover → calls getTrendingTracks() → fetches each track by ID
//     • Following → calls getUserFeed()
//   - Vertical PageView (TikTok-style) — one card per track
//   - When a card becomes the current page:
//       1. Show "Tap to preview" overlay
//       2. On tap, fetch full track details (by ID from feed/trending), then
//          auto-play audio via PlaybackStreamingEngineService.shared.playTrack()
//          with mute state applied
//       3. Scrolling away stops the audio (pause, not stop — better UX)
//   - Mute state is a single ValueNotifier<bool> shared across all cards
//   - Global mute toggle shown as speaker icon on the cover art
//   - ▶ play button tap → fetch full track → playTrack → mini player appears
//   - Bottom nav bar active on "Feed" item
//
// Integration points:
//   - PlaybackStreamingEngineService.shared.playTrack(PlaybackTrackModel)
//     triggers the global mini player bar (set up in main scaffold)
//   - User avatar tap → UserProfileSocialIdentityRoutes.userProfileRoute
//   - Like / comment wired via FeedCard widget (see CLAUDE CODE TODOs there)

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cross_team5/core/widgets/common_widgets.dart';

import '../models/feed_item_model.dart';
import '../models/trending_item_model.dart';
import '../services/feed_search_api_service.dart';
import '../widgets/feed_card.dart';

import 'package:cross_team5/features/playback_streaming_engine/services/playback_streaming_engine_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/features/user_profile_social_identity/user_profile_social_identity_routes.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  late TabController _tabController;
  final FeedSearchApiService _service = FeedSearchApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Mute state shared across all FeedCards
  final ValueNotifier<bool> _isMuted = ValueNotifier<bool>(true);

  // ── Discover (trending) tab state ──────────────────────────────────────────
  List<Map<String, dynamic>> _discoverTracks = [];
  bool _discoverLoading = true;
  String? _discoverError;
  final PageController _discoverPageController = PageController();
  int _discoverCurrentPage = 0;

  // ── Following (feed) tab state ─────────────────────────────────────────────
  List<FeedItemModel> _feedItems = [];
  bool _feedLoading = true;
  String? _feedError;
  final PageController _feedPageController = PageController();
  int _feedCurrentPage = 0;

  // Track which item is being fetched for playback (loading state)
  String? _loadingTrackId;

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
      // Fetch full track details for each trending ID concurrently
      final futures = ids.map((item) => _service.getTrackById(item.id));
      final results = await Future.wait(futures);

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
      setState(() {
        _feedItems = FeedItemModel.listFromJson(data);
        _feedLoading = false;
      });
    } else {
      setState(() {
        _feedError = data?.toString() ?? 'Failed to load feed';
        _feedLoading = false;
      });
    }
  }

  // ── Playback ───────────────────────────────────────────────────────────────

  /// Called when the user taps ▶ on a Discover card.
  /// The track data is already fetched (it's in _discoverTracks).
  Future<void> _playDiscoverTrack(Map<String, dynamic> trackData) async {
    final track = PlaybackTrackModel.fromApiJson(trackData);
    await PlaybackStreamingEngineService.shared.playTrack(track);
  }

  /// Called when the user taps ▶ on a Following/Feed card.
  /// The feed item only has ID + basic info — fetch full details first.
  Future<void> _playFeedItem(FeedItemModel item) async {
    if (_loadingTrackId == item.id) return;
    setState(() => _loadingTrackId = item.id);

    final (statusCode, trackData) = await _service.getTrackById(item.id);
    if (!mounted) return;
    setState(() => _loadingTrackId = null);

    if (statusCode == 200 && trackData is Map<String, dynamic>) {
      final track = PlaybackTrackModel.fromApiJson(trackData);
      await PlaybackStreamingEngineService.shared.playTrack(track);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load track: $trackData')),
      );
    }
  }

  /// Navigate to actor's profile.
  Future<void> _openActorProfile(String actorId) async {
    final token = await _storage.read(key: 'access_token') ?? '';
    final currentUserId = await _storage.read(key: 'user_id');
    if (!mounted) return;
    Navigator.pushNamed(
      context,
      UserProfileSocialIdentityRoutes.userProfileRoute,
      arguments: {
        'userId': actorId,
        'token': token,
        'currentUserId': currentUserId,
        'initialIsFollowing': false,
      },
    );
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
        children: [
          _buildDiscoverTab(),
          _buildFollowingTab(),
        ],
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
            indicatorColor: Colors.white,
            indicatorWeight: 2,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
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
      return const Center(
        child: Text('No trending tracks', style: TextStyle(color: Colors.white54)),
      );
    }

    return PageView.builder(
      controller: _discoverPageController,
      scrollDirection: Axis.vertical,
      onPageChanged: (index) {
        setState(() => _discoverCurrentPage = index);
      },
      itemCount: _discoverTracks.length,
      itemBuilder: (context, index) {
        final trackData = _discoverTracks[index];
        final isCurrent = index == _discoverCurrentPage;
        final basicInfo =
            trackData['basicInfo'] as Map<String, dynamic>? ?? {};
        final image = trackData['image'] as Map<String, dynamic>? ?? {};
        final artists =
            (basicInfo['mainArtists'] as List<dynamic>? ?? [])
                .map((e) => e.toString())
                .toList();

        return FeedCard(
          key: ValueKey('discover_$index'),
          itemId: (trackData['trackId'] ?? trackData['_id'] ?? '').toString(),
          isCurrent: isCurrent,
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
          isLiked: false,
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
            const Icon(Icons.people_outline, color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Follow artists to see their tracks here',
              style: TextStyle(color: Colors.white54, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return PageView.builder(
      controller: _feedPageController,
      scrollDirection: Axis.vertical,
      onPageChanged: (index) {
        setState(() => _feedCurrentPage = index);
      },
      itemCount: _feedItems.length,
      itemBuilder: (context, index) {
        final item = _feedItems[index];
        final isCurrent = index == _feedCurrentPage;

        return FeedCard(
          key: ValueKey('feed_${item.id}'),
          itemId: item.id,
          isCurrent: isCurrent,
          isMuted: _isMuted,
          imgLink: item.imgLink,
          displayName: item.displayName,
          actorName: item.displayName,
          actorId: item.actorId,
          isFollowing: true,
          likeCount: 0,
          commentCount: 0,
          isLiked: false,
          isRepost: item.isRepost,
          onPlayTap: () => _playFeedItem(item),
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
          const Icon(Icons.error_outline, color: Colors.white54, size: 48),
          const SizedBox(height: 12),
          Text(
            error,
            style: const TextStyle(color: Colors.white54),
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
