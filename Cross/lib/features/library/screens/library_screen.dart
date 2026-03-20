import 'package:flutter/material.dart';

import '../widgets/library_widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/theme/app_text.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

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
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MiniPlayer(),
                  CommonBottomNavBar(currentItem: AppNavItem.library),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
