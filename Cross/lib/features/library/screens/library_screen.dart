import 'package:flutter/material.dart';

import '../widgets/library_widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/theme/app_text.dart';
import 'package:cross_team5/features/user_profile_social_identity/user_profile_social_identity.dart';
import '../../authentication_user_management/services/auth_api_service.dart';



class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

   Future<void> _openProfile(BuildContext context) async {
  final authApiService = AuthApiService();

  try {
    final token = await authApiService.getStoredAccessToken();
    final userId = await authApiService.getStoredUserId();

    final safeToken = (token == null || token.trim().isEmpty) ? 'mock_token' : token;
    final safeUserId = (userId == null || userId.trim().isEmpty)
        ? 'mock_user_id'
        : userId;

    if (!context.mounted) return;

    Navigator.pushNamed(
      context,
      UserProfileSocialIdentityRoutes.userProfileRoute,
      arguments: {
        'userId': safeUserId,
        'token': safeToken,
        'currentUserId': safeUserId,
      },
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open profile: $e')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
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
                  const LibraryMenuItem(title: AppText.yourInsights),
                  const LibraryMenuItem(title: AppText.yourUploads),

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
                      children: List.generate(
                        4,
                        (index) => const AlbumPlaceholder(),
                      ),
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

            /// BOTTOM
            Positioned(
              top: 8,
              right: 12,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openProfile(context),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.10),
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
