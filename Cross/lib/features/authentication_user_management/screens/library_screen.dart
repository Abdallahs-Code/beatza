import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/library_widgets.dart';

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
                  const LibraryMenuItem(title: "Your likes"),
                  const LibraryMenuItem(title: "Playlists"),
                  const LibraryMenuItem(title: "Albums"),
                  const LibraryMenuItem(title: "Following"),
                  const LibraryMenuItem(title: "Stations"),
                  const LibraryMenuItem(title: "Your insights"),
                  const LibraryMenuItem(title: "Your uploads"),

                  const SizedBox(height: 20),

                  /// RECENTLY PLAYED
                  const SectionHeader(
                    title: "Recently played",
                    actionText: "See all",
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
                    title: "Listening history",
                    actionText: "See all",
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
                  BottomNavBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}