// Dart imports
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/features/home/home_routes.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/core/theme/app_text.dart';

class LibraryHeader extends StatelessWidget {
  const LibraryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          const Spacer(),
          const Text(
            AppText.libraryTitle,
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Icon(Icons.settings_outlined, color: AppColors.whiteSmoke),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, HomeRoutes.home);
            },
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.tileDark,
            ),
          ),
        ],
      ),
    );
  }
}

class LibraryMenuItem extends StatelessWidget {
  final String title;

  const LibraryMenuItem({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: AppColors.whiteSmoke, fontSize: 18),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.white60),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;

  const SectionHeader({
    super.key,
    required this.title,
    required this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.whiteSmoke,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            actionText,
            style: const TextStyle(color: AppColors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class AlbumPlaceholder extends StatelessWidget {
  const AlbumPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.tileDark,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 14, width: 90, color: AppColors.tileDark2),
          const SizedBox(height: 6),
          Container(height: 12, width: 60, color: AppColors.tileDark3),
        ],
      ),
    );
  }
}

class TrackPlaceholder extends StatelessWidget {
  const TrackPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.tileDark,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 12),

        /// TEXT BLOCK
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 14,
                width: double.infinity,
                color: AppColors.tileDark2,
              ),
              const SizedBox(height: 6),
              Container(height: 12, width: 120, color: AppColors.tileDark3),
              const SizedBox(height: 6),
              Container(height: 10, width: 80, color: AppColors.tileDark4),
            ],
          ),
        ),

        const SizedBox(width: 8),
        const Icon(Icons.more_horiz, color: AppColors.white60),
      ],
    );
  }
}

class ImportCard extends StatelessWidget {
  const ImportCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          children: [
            const Text("💎", style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),

            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppText.transferFaves,
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    AppText.importDesc,
                    style: TextStyle(color: AppColors.white60),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.whiteSmoke,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                AppText.importButton,
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.whiteSmoke,
            child: Icon(Icons.play_arrow, color: Colors.black),
          ),
          const SizedBox(width: 10),

          const Expanded(
            child: Text(
              AppText.nowPlaying,
              style: TextStyle(color: AppColors.whiteSmoke),
            ),
          ),

          Icon(Icons.favorite_border, color: AppColors.whiteSmoke),
        ],
      ),
    );
  }
}
