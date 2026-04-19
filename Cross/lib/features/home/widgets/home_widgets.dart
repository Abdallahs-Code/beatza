import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/core/theme/app_text.dart';
import '../../audio_upload_track_management/screens/upload_track_screen.dart';
import '../../audio_upload_track_management/services/audio_upload_service.dart';
import '../../premium_subscription/screens/premium_subscription.dart';
import '../../premium_subscription/services/payment_service.dart';

class TopHeader extends StatelessWidget {
  const TopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        const Text(
          AppText.homeTitle,
          style: TextStyle(
            color: AppColors.whiteSmoke,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        ValueListenableBuilder<bool>(
          valueListenable: PaymentService.subscriptionSuccessNotifier,
          builder: (context, isPro, _) {
            return HeaderIcon(
              Icons.cloud_upload_outlined,
              onTap: () async {
                final AudioUploadService audioService = AudioUploadService();
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
              },
            );
          },
        ),
        const SizedBox(width: 10),
        const HeaderIcon(Icons.more_horiz),
      ],
    );
  }
}

class HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const HeaderIcon(this.icon, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.whiteSmoke.withValues(alpha: 0.04),
        ),
        child: Icon(icon, color: AppColors.whiteSmoke, size: 21),
      ),
    );
  }
}

class YourLikesCard extends StatelessWidget {
  const YourLikesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [AppColors.borderDark, AppColors.likesGradientEnd],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.papaya, width: 2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.favorite_border,
                color: AppColors.papaya,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                AppText.yourLikes,
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: AppColors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shuffle,
                color: AppColors.whiteSmoke,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniTrackCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const MiniTrackCard({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.tileDark3,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
            ),
            child: const Icon(Icons.music_note, color: AppColors.white54),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WideTrackCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const WideTrackCard({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.tileDark3,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
            ),
            child: const Icon(Icons.album_outlined, color: AppColors.white54),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.whiteSmoke,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final bool showSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.showSeeAll = false,
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
                fontSize: 27,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (showSeeAll)
            const Text(
              AppText.seeAll,
              style: TextStyle(
                color: AppColors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class PosterItemData {
  final String title;
  final String subtitle;

  const PosterItemData({required this.title, required this.subtitle});
}

class HorizontalPosterSection extends StatelessWidget {
  final List<PosterItemData> items;

  const HorizontalPosterSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 255,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = items[index];
          return PosterCard(title: item.title, subtitle: item.subtitle);
        },
      ),
    );
  }
}

class PosterCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const PosterCard({super.key, required this.title, required this.subtitle});

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
            child: const Center(
              child: Icon(
                Icons.image_outlined,
                color: AppColors.white54,
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
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
    );
  }
}

class HorizontalMixSection extends StatelessWidget {
  const HorizontalMixSection({super.key});

  @override
  Widget build(BuildContext context) {
    const labels = ['MIX 1', 'MIX 2', 'MIX 3'];

    return SizedBox(
      height: 250,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return MixCard(mixLabel: labels[index]);
        },
      ),
    );
  }
}

class MixCard extends StatelessWidget {
  final String mixLabel;

  const MixCard({super.key, required this.mixLabel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  color: AppColors.mixBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Icon(
                    Icons.queue_music,
                    color: AppColors.white54,
                    size: 42,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 12,
                bottom: 10,
                child: Container(
                  height: 30,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.mixLabelBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    mixLabel,
                    style: const TextStyle(
                      color: AppColors.pureBlack,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            AppText.mixPlaceholder,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            AppText.mixGenerated,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class GenreChipsSection extends StatelessWidget {
  const GenreChipsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final genres = AppText.genres;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: genres.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = index == 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: selected ? AppColors.chipPink : AppColors.white60,
              ),
            ),
            child: Text(
              genres[index],
              style: TextStyle(
                color: selected ? AppColors.chipPink : AppColors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          );
        },
      ),
    );
  }
}

class TrendingTracksCard extends StatelessWidget {
  const TrendingTracksCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: RadialGradient(
          colors: [
            AppColors.anger.withValues(alpha: 0.28),
            AppColors.chineseBlack,
          ],
          radius: 1.1,
        ),
      ),
      child: const Column(
        children: [
          TrendingTrackRow(
            title: AppText.trendingTrack1,
            subtitle: AppText.artistName,
          ),
          TrendingTrackRow(
            title: AppText.trendingTrack2,
            subtitle: AppText.anotherArtist,
          ),
          TrendingTrackRow(
            title: AppText.trendingTrack3,
            subtitle: AppText.featuringArtist,
          ),
        ],
      ),
    );
  }
}

class TrendingTrackRow extends StatelessWidget {
  final String title;
  final String subtitle;

  const TrendingTrackRow({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.tileDark2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.music_note, color: AppColors.white54, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.whiteSmoke,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.white54, fontSize: 13),
      ),
      trailing: const Icon(Icons.more_horiz, color: AppColors.white70),
    );
  }
}

class EditorialCard extends StatelessWidget {
  final String label;
  final String description;
  final Color accentColor;

  const EditorialCard({
    super.key,
    required this.label,
    required this.description,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 245,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [accentColor.withValues(alpha: 0.28), AppColors.surfaceDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.whiteSmoke.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_outlined,
                size: 16,
                color: AppColors.white70,
              ),
            ),
          ),
          Container(
            height: 92,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.play_circle_outline,
                color: AppColors.white54,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            color: accentColor,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.whiteSmoke,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white70,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HorizontalStationSection extends StatelessWidget {
  const HorizontalStationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) => const StationCard(),
      ),
    );
  }
}

class StationCard extends StatelessWidget {
  const StationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 205,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 205,
            height: 170,
            decoration: BoxDecoration(
              color: AppColors.stationBackground,
              border: Border.all(color: AppColors.white12),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(Icons.radio, color: AppColors.white54, size: 42),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: AppColors.tileDark,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 18,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.white24),
                      shape: BoxShape.circle,
                      color: AppColors.tileDark5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            AppText.stationPlaceholder,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            AppText.stationDesc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class HorizontalBuzzingSection extends StatelessWidget {
  const HorizontalBuzzingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) => BuzzingCard(
          title: index == 0
              ? AppText.buzzingPop
              : index == 1
              ? AppText.buzzingMexico
              : AppText.buzzingRnB,
        ),
      ),
    );
  }
}

class BuzzingCard extends StatelessWidget {
  final String title;

  const BuzzingCard({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 205,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 205,
            height: 145,
            decoration: BoxDecoration(
              color: AppColors.cardDark2,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.buzzingYellow.withValues(alpha: 0.30),
                          AppColors.buzzingPink.withValues(alpha: 0.20),
                          AppColors.buzzingCyan.withValues(alpha: 0.18),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 12,
                  top: 12,
                  child: Text(
                    AppText.buzzing,
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: AppColors.tileDark4,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.audiotrack,
                      color: AppColors.white54,
                      size: 34,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.whiteSmoke,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            AppText.newLabel,
            style: TextStyle(color: AppColors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}