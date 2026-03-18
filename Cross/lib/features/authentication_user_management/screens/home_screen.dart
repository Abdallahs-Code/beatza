import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/home_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      bottomNavigationBar: const BottomNavBar(),
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
                              title: 'Track title',
                              subtitle: 'Artist name',
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: MiniTrackCard(
                              title: 'Another track',
                              subtitle: 'Another artist',
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 10),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: WideTrackCard(
                        title: 'Long track title placeholder',
                        subtitle: 'Artist / Playlist / Publisher',
                      ),
                    ),

                    SizedBox(height: 28),

                    SectionHeader(
                      title: 'More of what you like',
                      showSeeAll: true,
                    ),
                    SizedBox(height: 14),
                    HorizontalPosterSection(
                      items: [
                        PosterItemData(
                          title: 'Playlist placeholder',
                          subtitle: 'Artist one, Artist two',
                        ),
                        PosterItemData(
                          title: 'User mix placeholder',
                          subtitle: 'Generated from backend',
                        ),
                        PosterItemData(
                          title: 'Playlist placeholder',
                          subtitle: 'Another recommendation',
                        ),
                      ],
                    ),

                    SizedBox(height: 26),

                    SectionHeader(
                      title: 'Mixed for Abdelrahman Poda',
                    ),
                    SizedBox(height: 14),
                    HorizontalMixSection(),

                    SizedBox(height: 26),

                    SectionHeader(
                      title: 'Trending by genre',
                    ),
                    SizedBox(height: 14),
                    GenreChipsSection(),

                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: TrendingTracksCard(),
                    ),

                    SizedBox(height: 26),

                    SectionHeader(
                      title: 'Albums for you',
                    ),
                    SizedBox(height: 14),
                    HorizontalPosterSection(
                      items: [
                        PosterItemData(
                          title: 'Album placeholder',
                          subtitle: 'Singer name',
                        ),
                        PosterItemData(
                          title: 'Slow - Arabic',
                          subtitle: 'Artist placeholder',
                        ),
                        PosterItemData(
                          title: 'Arabic love songs',
                          subtitle: 'Another artist',
                        ),
                      ],
                    ),

                    SizedBox(height: 26),

                    SectionHeader(
                      title: 'Made for you',
                    ),
                    SizedBox(height: 14),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: EditorialCard(
                              label: 'DAILY DROPS',
                              description:
                                  'New releases based on your taste. Updated every day',
                              accentColor: AppColors.dailyDropsBlue,
                            ),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: EditorialCard(
                              label: 'WEEKLY WAVE',
                              description:
                                  'The best of SoundCloud just for you. Updated every Monday',
                              accentColor: AppColors.papaya,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 26),

                    SectionHeader(
                      title: 'Discover with Stations',
                    ),
                    SizedBox(height: 14),
                    HorizontalStationSection(),

                    SizedBox(height: 26),

                    SectionHeader(
                      title: 'Artists to watch out for',
                    ),
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