// Dart imports
import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/core/theme/app_text.dart';
import 'package:cross_team5/core/navigation/profile_navigator.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/library/library_routes.dart';
import 'package:cross_team5/features/library/screens/listening_history_screen.dart';
import 'package:cross_team5/features/library/screens/recently_played_screen.dart';
import 'package:cross_team5/features/library/services/library_history_api_service.dart';
import 'package:cross_team5/features/library/widgets/library_widgets.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/playback_streaming_engine_service.dart';
import 'package:cross_team5/features/user_profile_social_identity/user_profile_social_identity.dart';
import 'package:cross_team5/features/followers_social_graph/followers_social_graph_routes.dart';
import '../../audio_upload_track_management/screens/your_insights_screen.dart';
import '../../audio_upload_track_management/screens/your_uploads_screen.dart';
import '../../premium_subscription/screens/offline_downloads_screen.dart';
import '../../premium_subscription/services/payment_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final AuthApiService _authApiService = AuthApiService();
  final UserProfileService _userProfileService = UserProfileService();
  final LibraryHistoryApiService _historyApiService =
  LibraryHistoryApiService();

  late Future<UserProfileModel?> _profileFuture;

  bool _isLoadingHistory = true;
  String? _historyError;
  List<PlaybackTrackModel> _historyTracks = [];

  static const List<RecentlyPlayedMockItem> _mockRecentlyPlayedItems = [
    RecentlyPlayedMockItem(
      type: RecentlyPlayedMockItemType.playlist,
      title: 'gdry',
      subtitle: 'Abdessamad Hamidallah',
      metadata: '0 · 1 track',
      imageUrl:
      'https://res.cloudinary.com/dr1sqiouu/image/upload/v1775770962/audio/file_owxgue.jpg',
    ),
    RecentlyPlayedMockItem(
      type: RecentlyPlayedMockItemType.profile,
      title: 'octobersveryown',
      subtitle: 'Toronto, Canada',
      metadata: '4M Followers',
      imageUrl: 'https://picsum.photos/seed/ovo/300/300',
      isVerified: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadUserProfile();
    _loadListeningHistory();
  }

  @override
  void dispose() {
    _historyApiService.dispose();
    super.dispose();
  }

  Future<UserProfileModel?> _loadUserProfile() async {
    final token = await _authApiService.getStoredAccessToken();
    final userId = await _authApiService.getStoredUserId();
    if (token != null && userId != null) {
      return await _userProfileService.getUserProfile(userId, token);
    }

    return null;
  }

  Future<void> _loadListeningHistory() async {
    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });

    try {
      final String? token = await _authApiService.getStoredAccessToken();

      if (token == null || token.trim().isEmpty) {
        throw Exception('No access token found.');
      }

      final List<PlaybackTrackModel> tracks = await _historyApiService
          .getUserHistoryTracks(token);

      if (!mounted) {
        return;
      }

      setState(() {
        _historyTracks = tracks;
        _isLoadingHistory = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _historyError = e.toString();
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _openProfile(BuildContext context) async {
    try {
      final userId = await _authApiService.getStoredUserId();
      if (userId == null || userId.trim().isEmpty) return;
      if (!context.mounted) return;
      await ProfileNavigator.push(context, userId);
      if (mounted) setState(() => _profileFuture = _loadUserProfile());
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to open profile: $e')));
      }
    }
  }

  Future<void> _openListeningHistoryPage() async {
    final List<PlaybackTrackModel>? updatedTracks =
    await Navigator.push<List<PlaybackTrackModel>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ListeningHistoryScreen(initialTracks: _historyTracks),
      ),
    );

    if (updatedTracks != null && mounted) {
      setState(() {
        _historyTracks = updatedTracks;
      });
    }
  }

  Future<void> _playHistoryTrack(PlaybackTrackModel track, int index) async {
    await PlaybackStreamingEngineService.shared.playTrack(
      track,
      queue: _historyTracks,
      startIndex: index,
    );
  }

  Future<void> _openFollowingScreen() async {
    final token = await _authApiService.getStoredAccessToken();
    final userId = await _authApiService.getStoredUserId();
    if (userId == null || !mounted) return;
    Navigator.pushNamed(
      context,
      FollowersSocialGraphRoutes.following,
      arguments: {
        'userId': userId,
        'token': token ?? '',
        'currentUserId': userId,
      },
    );
  }

  void _openRecentlyPlayedPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const RecentlyPlayedScreen(items: _mockRecentlyPlayedItems),
      ),
    );
  }

  Widget _buildRecentlyPlayedSection() {
    if (_mockRecentlyPlayedItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _LibraryEmptyStateCard(
          title: 'No recently played items yet',
          subtitle:
          'Profiles and playlists you interact with will show up here.',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _mockRecentlyPlayedItems
              .map(
                (item) => Padding(
              padding: const EdgeInsets.only(right: 18),
              child: RecentlyPlayedPreviewCard(item: item),
            ),
          )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildHistoryPreviewSection() {
    if (_isLoadingHistory) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: const [
            _HistoryTrackPlaceholder(),
            SizedBox(height: 16),
            _HistoryTrackPlaceholder(),
            SizedBox(height: 16),
            _HistoryTrackPlaceholder(),
            SizedBox(height: 16),
            _HistoryTrackPlaceholder(),
          ],
        ),
      );
    }

    if (_historyError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Failed to load listening history.',
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please try again.',
                style: TextStyle(color: AppColors.white60, height: 1.45),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loadListeningHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brilliantOrange,
                  foregroundColor: AppColors.whiteSmoke,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_historyTracks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _LibraryEmptyStateCard(
          title: 'No tracks in history',
          subtitle: 'Tracks you listen to will appear here.',
        ),
      );
    }

    final List<PlaybackTrackModel> previewTracks = _historyTracks
        .take(4)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(previewTracks.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == previewTracks.length - 1 ? 0 : 16,
            ),
            child: HistoryTrackTile(
              track: previewTracks[index],
              onTap: () => _playHistoryTrack(previewTracks[index], index),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      bottomNavigationBar: const LibraryBottomArea(),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LibraryHeader(),
                  const SizedBox(height: 20),

                  /// MENU
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, LibraryRoutes.yourLikes);
                    },
                    child: const LibraryMenuItem(title: AppText.yourLikes),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, '/playlists');
                    },
                    child: const LibraryMenuItem(title: AppText.playlists),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, '/albums');
                    },
                    child: const LibraryMenuItem(title: AppText.albums),
                  ),
                  InkWell(
                    onTap: _openFollowingScreen,
                    child: const LibraryMenuItem(title: AppText.following),
                  ),
                  const LibraryMenuItem(title: AppText.stations),

                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const YourInsightsScreen(),
                        ),
                      );
                    },
                    child: const LibraryMenuItem(title: AppText.yourInsights),
                  ),

                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const YourUploadsScreen(),
                        ),
                      );
                    },
                    child: const LibraryMenuItem(title: AppText.yourUploads),
                  ),

                  ValueListenableBuilder<SubscriptionState>(
                    valueListenable: PaymentService.subscriptionSuccessNotifier,
                    builder: (context, state, _) {
                      if (!state.isPro) return const SizedBox.shrink();
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OfflineDownloadsScreen(),
                            ),
                          );
                        },
                        child: const LibraryMenuItem(title: 'Downloads'),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  /// RECENTLY PLAYED
                  SectionHeader(
                    title: AppText.recentlyPlayed,
                    actionText: AppText.seeAll,
                    onActionTap: _openRecentlyPlayedPage,
                  ),
                  const SizedBox(height: 14),
                  _buildRecentlyPlayedSection(),

                  const SizedBox(height: 28),

                  /// LISTENING HISTORY
                  SectionHeader(
                    title: AppText.listeningHistory,
                    actionText: AppText.seeAll,
                    onActionTap: _openListeningHistoryPage,
                  ),
                  const SizedBox(height: 14),
                  _buildHistoryPreviewSection(),

                ],
              ),
            ),

            /// Profile Image Overlay
            Positioned(
              top: 8,
              right: 12,
              child: FutureBuilder<UserProfileModel?>(
                future: _profileFuture,
                builder: (context, snapshot) {
                  final String imageUrl = snapshot.data?.profileImgLink ?? '';

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openProfile(context),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          backgroundImage: imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : null,
                          child: imageUrl.isEmpty
                              ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 22,
                          )
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTrackPlaceholder extends StatelessWidget {
  const _HistoryTrackPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 18,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 16,
                  width: 140,
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 14,
                  width: 110,
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.cardDark,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _LibraryEmptyStateCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _LibraryEmptyStateCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.tileDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppColors.white60,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.whiteSmoke,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.white60,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}