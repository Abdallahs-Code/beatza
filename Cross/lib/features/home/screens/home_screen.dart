import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/core/theme/app_text.dart';
import 'package:cross_team5/core/widgets/common_widgets.dart';
import 'package:cross_team5/features/home/widgets/home_widgets.dart';
import 'package:cross_team5/features/audio_upload_track_management/audio_upload_track_management.dart';
import 'package:cross_team5/features/library/library_routes.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/playback_streaming_engine_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/public_tracks_paging_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/public_tracks_api_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/mock_playback_access_service.dart';
import 'package:cross_team5/features/activity/controllers/activity_notifications_controller.dart';
import 'package:cross_team5/features/activity/screens/activity_screen.dart';
import 'package:cross_team5/features/messaging_track_sharing/services/messaging_notification_service.dart';

import '../../premium_subscription/screens/premium_subscription.dart';
import '../../premium_subscription/services/offline_download_service.dart';
import '../../premium_subscription/services/payment_service.dart';
import '../../authentication_user_management/services/auth_api_service.dart';
import '../../user_profile_social_identity/services/user_profile_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final PublicTracksPagingService _publicTracksPagingService =
      PublicTracksPagingService.shared;
  final PublicTracksApiService _quickPicksApiService = PublicTracksApiService();
  List<PlaybackTrackModel> _quickPickTracks = [];
  bool _quickPickLoading = true;
  String? _displayName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ActivityNotificationsController.shared.initialize();
    ActivityNotificationsController.shared.reconnectIfNeeded();
    MessagingNotificationService.shared.initialize();
    _publicTracksPagingService.loadInitial(limit: 20);
    _loadQuickPickTracks();
    _loadDisplayName();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ActivityNotificationsController.shared.reconnectIfNeeded();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _quickPicksApiService.dispose();
    super.dispose();
  }

  Future<void> _loadDisplayName() async {
    try {
      final authService = AuthApiService();
      final userId = await authService.getStoredUserId();
      final token = await authService.getStoredAccessToken();
      if (userId == null || token == null) return;
      final profile = await UserProfileService().getUserProfile(userId, token);
      if (mounted && profile.displayName.trim().isNotEmpty) {
        setState(() => _displayName = profile.displayName.trim());
      }
    } catch (_) {}
  }

  Future<void> _loadQuickPickTracks() async {
    try {
      final result = await _quickPicksApiService.fetchPublicTracksPage(
        page: 2,
        limit: 3,
      );
      if (mounted) {
        setState(() {
          _quickPickTracks = result.tracks;
          _quickPickLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _quickPickLoading = false);
    }
  }

  Future<void> _handleQuickPickTap(PlaybackTrackModel track, int index) async {
    if (!track.hasAnyPlayableSource || track.playbackUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This track does not have a playable audio source yet.'),
        ),
      );
      return;
    }
    await PlaybackStreamingEngineService.shared.playTrack(
      track,
      queue: _quickPickTracks,
      startIndex: index,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ActivityNotificationsController.shared.onAppResumed();
    }
  }

  void _handleUpload(BuildContext context) async {
    final isPro = PaymentService.subscriptionSuccessNotifier.isPro;
    final int currentUploads = AudioUploadService.globalMockTracksNotifier.value.length;

    if (!isPro && currentUploads >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Free tier limited to 3 uploads. Please upgrade to Pro.'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumSubscriptionScreen()),
      );
      return;
    }

    final AudioUploadService audioService = AudioUploadService();
    final file = await audioService.pickAudioFile();
    if (file != null) {
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const UploadTrackScreen(),
          settings: RouteSettings(arguments: file),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('test_home_screen'),
      backgroundColor: AppColors.homeBackground,
      appBar: AppBar(
        backgroundColor: AppColors.homeBackground,
        elevation: 0,
        leadingWidth: 140,
        title: const Text(
          'Home',
          style: TextStyle(
            color: AppColors.whiteSmoke,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 10, bottom: 10),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ArtistStudioScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Artist Studio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
            onPressed: () => _handleUpload(context),
          ),
          AnimatedBuilder(
            animation: ActivityNotificationsController.shared,
            builder: (context, _) {
              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.white,
                    ),
                    if (ActivityNotificationsController.shared.unreadCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            ActivityNotificationsController.shared.unreadCount > 9
                                ? '9+'
                                : ActivityNotificationsController.shared.unreadCount
                                .toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ActivityScreen(),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: const CommonBottomNavBar(
        currentItem: AppNavItem.home,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(
                          context,
                          LibraryRoutes.yourLikes,
                        ),
                        child: const YourLikesCard(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _QuickPickTracksSection(
                      tracks: _quickPickTracks,
                      isLoading: _quickPickLoading,
                      onTap: _handleQuickPickTap,
                    ),
                    const SizedBox(height: 28),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Playback accessibility demo',
                        style: TextStyle(
                          color: AppColors.whiteSmoke,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: _PlaybackAccessibilityDemoSection(),
                    ),
                    const SizedBox(height: 18),
                    const SizedBox(height: 28),
                    const SectionHeader(
                      title: AppText.moreOfWhatYouLike,
                      showSeeAll: true,
                    ),
                    const SizedBox(height: 14),
                    AnimatedBuilder(
                      animation: _publicTracksPagingService,
                      builder: (context, _) {
                        return _HomePublicTracksSection(
                          tracks: _publicTracksPagingService.tracks,
                          isLoading:
                          _publicTracksPagingService.isInitialLoading,
                          errorMessage: _publicTracksPagingService.errorMessage,
                          ensureNextTrackAvailable: _publicTracksPagingService
                              .ensureNextTrackAvailableForPlayer,
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    const HorizontalPosterSection(
                      items: [
                        PosterItemData(
                          title: AppText.playlistPlaceholder,
                          subtitle: "Artist one, Artist two",
                        ),
                        PosterItemData(
                          title: AppText.userMixPlaceholder,
                          subtitle: AppText.generatedBackend,
                        ),
                        PosterItemData(
                          title: AppText.playlistPlaceholder,
                          subtitle: AppText.anotherRecommendation,
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    SectionHeader(
                      title: 'Mixed for ${_displayName ?? 'You'}',
                    ),
                    const SizedBox(height: 14),
                    const HorizontalMixSection(),
                    const SizedBox(height: 26),
                    const SectionHeader(title: AppText.trendingByGenre),
                    const SizedBox(height: 14),
                    const GenreChipsSection(),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: TrendingTracksCard(),
                    ),
                    const SizedBox(height: 26),
                    const SectionHeader(title: AppText.albumsForYou),
                    const SizedBox(height: 14),
                    const HorizontalPosterSection(
                      items: [
                        PosterItemData(
                          title: AppText.albumPlaceholder,
                          subtitle: AppText.singerName,
                        ),
                        PosterItemData(
                          title: AppText.slowArabic,
                          subtitle: AppText.artistName,
                        ),
                        PosterItemData(
                          title: AppText.arabicLoveSongs,
                          subtitle: AppText.anotherArtist,
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    const SectionHeader(title: AppText.madeForYou),
                    const SizedBox(height: 14),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: EditorialCard(
                              label: AppText.dailyDrops,
                              description: AppText.dailyDropsDesc,
                              accentColor: AppColors.dailyDropsBlue,
                            ),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: EditorialCard(
                              label: AppText.weeklyWave,
                              description: AppText.weeklyWaveDesc,
                              accentColor: AppColors.papaya,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    const SectionHeader(title: AppText.discoverStations),
                    const SizedBox(height: 14),
                    const HorizontalStationSection(),
                    const SizedBox(height: 26),
                    const SectionHeader(title: AppText.artistsToWatch),
                    const SizedBox(height: 14),
                    const HorizontalBuzzingSection(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomePublicTracksSection extends StatelessWidget {
  final List<PlaybackTrackModel> tracks;
  final bool isLoading;
  final String? errorMessage;
  final Future<bool> Function()? ensureNextTrackAvailable;

  const _HomePublicTracksSection({
    required this.tracks,
    required this.isLoading,
    required this.errorMessage,
    this.ensureNextTrackAvailable,
  });

  Future<void> _handleTrackTap(
      BuildContext context,
      PlaybackTrackModel track,
      int index,
      ) async {
    if (!track.hasAnyPlayableSource || track.playbackUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This track does not have a playable audio source yet.',
          ),
        ),
      );
      return;
    }

    if (track.accessState == PlaybackAccessState.blocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            track.blockedReason ?? 'Playback is disabled for this track.',
          ),
        ),
      );
      return;
    }

    await PlaybackStreamingEngineService.shared.playTrack(
      track,
      queue: tracks,
      startIndex: index,
      ensureNextTrackAvailable: ensureNextTrackAvailable,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 255,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(width: 16),
          itemBuilder: (_, _) => const _HomePublicTrackPosterPlaceholder(),
        ),
      );
    }

    if (errorMessage != null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _HomeTracksMessageCard(
          title: 'Could not load tracks right now',
          subtitle: 'Please try again later.',
        ),
      );
    }

    if (tracks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _HomeTracksMessageCard(
          title: 'No tracks available yet',
          subtitle: 'Public tracks will appear here when available.',
        ),
      );
    }

    final List<PlaybackTrackModel> visibleTracks = tracks;

    return SizedBox(
      height: 255,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: visibleTracks.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return _HomePublicTrackPosterCard(
            track: visibleTracks[index],
            onTap: () => _handleTrackTap(context, visibleTracks[index], index),
          );
        },
      ),
    );
  }
}

class _HomePublicTrackPosterCard extends StatelessWidget {
  final PlaybackTrackModel track;
  final VoidCallback? onTap;

  const _HomePublicTrackPosterCard({required this.track, this.onTap});

  bool get _isBlocked => track.accessState == PlaybackAccessState.blocked;
  bool get _isPreview => track.accessState == PlaybackAccessState.preview;

  @override
  Widget build(BuildContext context) {
    final String? accessLabel = _isBlocked
        ? 'Not available'
        : _isPreview
        ? 'Preview · ${track.effectivePreviewDuration.inSeconds}s'
        : null;

    return SizedBox(
      width: 170,
      child: Opacity(
        opacity: _isBlocked ? 0.55 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isBlocked ? null : onTap,
            borderRadius: BorderRadius.circular(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        color: AppColors.blueCard,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (track.artworkUrl ?? '').trim().isEmpty
                          ? const Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: AppColors.white54,
                          size: 42,
                        ),
                      )
                          : Image.network(
                        track.artworkUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) {
                          return const Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: AppColors.white54,
                              size: 42,
                            ),
                          );
                        },
                      ),
                    ),
                    if (accessLabel != null)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _isBlocked
                                ? Colors.black.withValues(alpha: 0.78)
                                : AppColors.brilliantOrange.withValues(
                              alpha: 0.92,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            accessLabel,
                            style: TextStyle(
                              color: _isBlocked ? Colors.white70 : Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _isBlocked
                        ? AppColors.white54
                        : AppColors.whiteSmoke,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isBlocked
                      ? (track.blockedReason ?? 'Not available in your region')
                      : track.artistName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white54,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomePublicTrackPosterPlaceholder extends StatelessWidget {
  const _HomePublicTrackPosterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              color: AppColors.blueCard,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 14,
            width: 140,
            decoration: BoxDecoration(
              color: AppColors.whiteSmoke.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 110,
            decoration: BoxDecoration(
              color: AppColors.whiteSmoke.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTracksMessageCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HomeTracksMessageCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.white60,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaybackAccessibilityDemoSection extends StatelessWidget {
  const _PlaybackAccessibilityDemoSection();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: MockPlaybackAccessService.shared,
      builder: (context, _) {
        final mockService = MockPlaybackAccessService.shared;
        final List<PlaybackTrackModel> tracks =
            mockService.accessibilityDemoTracks;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Country: ${mockService.currentCountry}',
                style: const TextStyle(
                  color: AppColors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tier: ${mockService.currentTier == MockPlaybackUserTier.goPlus ? 'Go+' : 'Free'}',
                style: const TextStyle(
                  color: AppColors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              ...List.generate(tracks.length, (index) {
                final track = tracks[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == tracks.length - 1 ? 0 : 12,
                  ),
                  child: _AccessibilityDemoTrackTile(
                    track: track,
                    queue: tracks,
                    index: index,
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _AccessibilityDemoTrackTile extends StatelessWidget {
  final PlaybackTrackModel track;
  final List<PlaybackTrackModel> queue;
  final int index;

  const _AccessibilityDemoTrackTile({
    required this.track,
    required this.queue,
    required this.index,
  });

  bool get _isBlocked => track.accessState == PlaybackAccessState.blocked;
  bool get _isPreview => track.accessState == PlaybackAccessState.preview;

  @override
  Widget build(BuildContext context) {
    final String subtitle = _isBlocked
        ? (track.blockedReason ?? 'Not available in your country')
        : _isPreview
        ? 'Preview only · ${track.effectivePreviewDuration.inSeconds}s'
        : 'Fully playable';

    final Color chipBg = _isBlocked
        ? Colors.black.withValues(alpha: 0.78)
        : _isPreview
        ? AppColors.brilliantOrange.withValues(alpha: 0.92)
        : const Color(0xFF1C7C43);

    final String chipText = _isBlocked ? 'Blocked' : _isPreview ? 'Preview' : 'Playable';

    return Opacity(
      opacity: _isBlocked ? 0.58 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isBlocked
              ? null
              : () async {
            await PlaybackStreamingEngineService.shared.playTrack(
              track,
              queue: queue,
              startIndex: index,
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1D1D),
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: (track.artworkUrl ?? '').trim().isEmpty
                    ? const Icon(
                  Icons.music_note_rounded,
                  color: AppColors.white54,
                )
                    : Image.network(
                  track.artworkUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.music_note_rounded,
                    color: AppColors.white54,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _isBlocked ? AppColors.white60 : AppColors.whiteSmoke,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white60,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              ValueListenableBuilder<Map<String, double>>(
                valueListenable: OfflineDownloadService.shared.downloadProgressNotifier,
                builder: (context, progressMap, _) {
                  final double? progress = progressMap[track.id];

                  return ValueListenableBuilder<List<PlaybackTrackModel>>(
                    valueListenable: OfflineDownloadService.shared.downloadedTracksNotifier,
                    builder: (context, downloadedTracks, _) {
                      final isDownloaded = downloadedTracks.any((t) => t.id == track.id);
                      if (isDownloaded) {
                        return const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.download_done_rounded, color: Colors.green, size: 24),
                        );
                      }
                      if (progress != null) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 3,
                                  color: AppColors.brilliantOrange,
                                  backgroundColor: AppColors.white10,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        );
                      }

                      return IconButton(
                        icon: const Icon(Icons.download_rounded, color: AppColors.white60, size: 24),
                        onPressed: _isBlocked ? null : () {
                          final isPro = PaymentService.subscriptionSuccessNotifier.isPro;
                          if (!isPro) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PremiumSubscriptionScreen()),
                            );
                          } else {
                            OfflineDownloadService.shared.downloadTrack(track);
                          }
                        },
                      );
                    },
                  );
                },
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  chipText,
                  style: TextStyle(
                    color: _isBlocked ? Colors.white70 : Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickPickTracksSection extends StatelessWidget {
  final List<PlaybackTrackModel> tracks;
  final bool isLoading;
  final Future<void> Function(PlaybackTrackModel, int)? onTap;

  const _QuickPickTracksSection({
    required this.tracks,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String title0 = tracks.isNotEmpty ? tracks[0].title : AppText.trackTitle;
    final String sub0 = tracks.isNotEmpty ? tracks[0].artistName : AppText.artistName;
    final String title1 = tracks.length > 1 ? tracks[1].title : AppText.anotherTrack;
    final String sub1 = tracks.length > 1 ? tracks[1].artistName : AppText.anotherArtist;
    final String title2 = tracks.length > 2 ? tracks[2].title : AppText.longTrackTitle;
    final String sub2 = tracks.length > 2 ? tracks[2].artistName : AppText.trackSubtitle;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: tracks.isNotEmpty ? () => onTap?.call(tracks[0], 0) : null,
                  child: MiniTrackCard(
                    title: title0,
                    subtitle: sub0,
                    artworkUrl: tracks.isNotEmpty ? tracks[0].artworkUrl : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: tracks.length > 1 ? () => onTap?.call(tracks[1], 1) : null,
                  child: MiniTrackCard(
                    title: title1,
                    subtitle: sub1,
                    artworkUrl: tracks.length > 1 ? tracks[1].artworkUrl : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: tracks.length > 2 ? () => onTap?.call(tracks[2], 2) : null,
            child: WideTrackCard(
              title: title2,
              subtitle: sub2,
              artworkUrl: tracks.length > 2 ? tracks[2].artworkUrl : null,
            ),
          ),
        ),
      ],
    );
  }
}