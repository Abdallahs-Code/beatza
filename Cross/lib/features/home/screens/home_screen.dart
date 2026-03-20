import 'package:flutter/material.dart';

import '../widgets/home_widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/theme/app_text.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      bottomNavigationBar: const CommonBottomNavBar(
        currentItem: AppNavItem.home,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const TopHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SizedBox(height: 18),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: YourLikesCard(),
                    ),

                    SizedBox(height: 12),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: MiniTrackCard(
                              title: AppText.trackTitle,
                              subtitle: AppText.artistName,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: MiniTrackCard(
                              title: AppText.anotherTrack,
                              subtitle: AppText.anotherArtist,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 10),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: WideTrackCard(
                        title: AppText.longTrackTitle,
                        subtitle: AppText.trackSubtitle,
                      ),
                    ),

                    SizedBox(height: 28),

                    SectionHeader(
                      title: AppText.moreOfWhatYouLike,
                      showSeeAll: true,
                    ),
                    SizedBox(height: 14),
                    HorizontalPosterSection(
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

                    SizedBox(height: 26),

                    SectionHeader(title: AppText.mixedForUser),
                    SizedBox(height: 14),
                    HorizontalMixSection(),

                    SizedBox(height: 26),

                    SectionHeader(title: AppText.trendingByGenre),
                    SizedBox(height: 14),
                    GenreChipsSection(),

                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: TrendingTracksCard(),
                    ),

                    SizedBox(height: 26),

                    SectionHeader(title: AppText.albumsForYou),
                    SizedBox(height: 14),
                    HorizontalPosterSection(
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

                    SizedBox(height: 26),

                    SectionHeader(title: AppText.madeForYou),
                    SizedBox(height: 14),
                    Padding(
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

                    SizedBox(height: 26),

                    SectionHeader(title: AppText.discoverStations),
                    SizedBox(height: 14),
                    HorizontalStationSection(),

                    SizedBox(height: 26),

                    SectionHeader(title: AppText.artistsToWatch),
                    SizedBox(height: 14),
                    HorizontalBuzzingSection(),

                    SizedBox(height: 10),
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
