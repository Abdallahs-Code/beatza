// Dart imports
import 'package:flutter/material.dart';
import 'package:cross_team5/features/user_profile_social_identity/user_profile_social_identity.dart' hide YourUploadsScreen;
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/library/widgets/library_widgets.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/core/theme/app_text.dart';
import 'package:cross_team5/core/widgets/common_widgets.dart';
import 'package:cross_team5/features/user_profile_social_identity/services/user_profile_service.dart';
import 'package:cross_team5/features/user_profile_social_identity/models/user_profile_model.dart';
import '../../audio_upload_track_management/screens/your_insights_screen.dart';
import '../../audio_upload_track_management/screens/your_uploads_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final AuthApiService _authApiService = AuthApiService();
  final UserProfileService _userProfileService = UserProfileService();
  late Future<UserProfileModel?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadUserProfile();
  }

  Future<UserProfileModel?> _loadUserProfile() async {
    try {
      final token = await _authApiService.getStoredAccessToken();
      final userId = await _authApiService.getStoredUserId();
      if (token != null && userId != null) {
        return await _userProfileService.getUserProfile(userId, token);
      }
    } catch (e) {
      debugPrint('Error loading profile image: $e');
    }
    return null;
  }

  Future<void> _openProfile(BuildContext context) async {
    try {
      final token = await _authApiService.getStoredAccessToken();
      final userId = await _authApiService.getStoredUserId();

      final safeToken = (token == null || token.trim().isEmpty) ? 'mock_token' : token;
      final safeUserId = (userId == null || userId.trim().isEmpty) ? 'mock_user_id' : userId;

      if (!context.mounted) return;

      Navigator.pushNamed(
        context,
        UserProfileSocialIdentityRoutes.userProfileRoute,
        arguments: {
          'userId': safeUserId,
          'token': safeToken,
          'currentUserId': safeUserId,
        },
      ).then((_) {
        setState(() {
          _profileFuture = _loadUserProfile();
        });
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to open profile: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      bottomNavigationBar: const CommonBottomNavBar(
        currentItem: AppNavItem.library,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 170),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LibraryHeader(),
                  const SizedBox(height: 20),

                  /// MENU
                  const LibraryMenuItem(title: AppText.yourLikes),
                  const LibraryMenuItem(title: AppText.playlists),
                  const LibraryMenuItem(title: AppText.albums),
                  const LibraryMenuItem(title: AppText.following),
                  const LibraryMenuItem(title: AppText.stations),

                  InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const YourInsightsScreen()));
                    },
                    child: const LibraryMenuItem(title: AppText.yourInsights),
                  ),

                  InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const YourUploadsScreen()));
                    },
                    child: const LibraryMenuItem(title: AppText.yourUploads),
                  ),

                  const SizedBox(height: 20),

                  /// RECENTLY PLAYED
                  const SectionHeader(
                    title: AppText.recentlyPlayed,
                    actionText: AppText.seeAll,
                  ),
                  const SizedBox(height: 14),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: List.generate(4, (index) => const AlbumPlaceholder()),
                    ),
                  ),

                  const SizedBox(height: 28),

                  /// LISTENING HISTORY
                  const SectionHeader(
                    title: AppText.listeningHistory,
                    actionText: AppText.seeAll,
                  ),
                  const SizedBox(height: 14),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        TrackPlaceholder(),
                        SizedBox(height: 16),
                        TrackPlaceholder(),
                        SizedBox(height: 16),
                        TrackPlaceholder(),
                        SizedBox(height: 16),
                        TrackPlaceholder(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  /// IMPORT CARD
                  const ImportCard(),
                ],
              ),
            ),

            Positioned(
              top: 8,
              right: 12,
              child: FutureBuilder<UserProfileModel?>(
                future: _profileFuture,
                builder: (context, snapshot) {
                  final imageUrl = snapshot.data?.profileImgLink ?? "";

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('test_library_to_profile_btn'),
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
                              ? const Icon(Icons.person, color: Colors.white, size: 22)
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