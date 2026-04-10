// Dart imports
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_team5/features/home/widgets/home_widgets.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/core/widgets/common_widgets.dart';
import 'package:cross_team5/core/theme/app_text.dart';
import '../../audio_upload_track_management/screens/artist_studio_screen.dart';
import '../../audio_upload_track_management/screens/upload_track_screen.dart';
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  void _handleUpload(BuildContext context) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.isNotEmpty) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const UploadTrackScreen(),
            settings: RouteSettings(arguments: result.files.first),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      appBar: AppBar(
        backgroundColor: AppColors.homeBackground,
        elevation: 0,
        leadingWidth: 140,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 10, bottom: 10),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ArtistStudioScreen()),
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
                  Text('Artist Studio', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () {},
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