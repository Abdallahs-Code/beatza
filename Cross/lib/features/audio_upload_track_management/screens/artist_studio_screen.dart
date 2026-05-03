import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import '../../audio_upload_track_management/models/track_model.dart';
import '../../audio_upload_track_management/services/audio_upload_service.dart';
import '../../audio_upload_track_management/screens/your_insights_screen.dart';
import '../../audio_upload_track_management/screens/your_uploads_screen.dart';
import 'package:provider/provider.dart';
import 'package:cross_team5/core/services/theme_service.dart';
import '../../audio_upload_track_management/screens/upload_track_screen.dart';

class ArtistStudioScreen extends StatefulWidget {
  const ArtistStudioScreen({super.key});

  @override
  State<ArtistStudioScreen> createState() => _ArtistStudioScreenState();
}

class _ArtistStudioScreenState extends State<ArtistStudioScreen> {
  void _showProModal(String title, String subtitle, String iconType) {
    IconData modalIcon;
    Color iconColor;
    String topLabel;

    if (iconType == 'amplify') {
      modalIcon = Icons.flash_on;
      iconColor = AppColors.flashPurple;
      topLabel = 'AMPLIFY';
    } else if (iconType == 'upload') {
      modalIcon = Icons.cloud_upload;
      iconColor = AppColors.studioActionBlue;
      topLabel = 'UPLOAD';
    } else {
      modalIcon = Icons.swap_horiz;
      iconColor = AppColors.studioActionBlue;
      topLabel = 'REPLACE FILE';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 16.0,
            bottom: MediaQuery.of(context).padding.bottom + 24.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(modalIcon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    topLabel,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.white70,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: AppColors.white54, fontSize: 14),
                  children: [
                    const TextSpan(text: 'EGP 164.99/month. Cancel anytime. '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Restrictions apply.',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.whiteSmoke, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {},
                  child: Text(
                    'Subscribe now',
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Maybe later',
                    style: TextStyle(
                      color: AppColors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeService>();
    return Scaffold(
      backgroundColor: AppColors.backgroundDark3,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark3,
        elevation: 0,
        title: Text(
          'Artist Studio',
          style: TextStyle(
            color: AppColors.whiteSmoke,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.whiteSmoke,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UploadTrackScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.artistStudioGradientStart, AppColors.surfaceMid],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      color: AppColors.whiteSmoke,
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Upload a track',
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _GridItem(
                    icon: Icons.bar_chart,
                    title: 'Uploads',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const YourUploadsScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GridItem(
                    icon: Icons.alt_route,
                    title: 'Releases',
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _GridItem(
                    icon: Icons.show_chart,
                    title: 'Insights',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const YourInsightsScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GridItem(
                    icon: Icons.attach_money,
                    title: 'Earnings',
                    onTap: () {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            Text(
              'Latest uploads',
              style: TextStyle(
                color: AppColors.whiteSmoke,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<List<TrackModel>>(
              valueListenable: AudioUploadService.globalMockTracksNotifier,
              builder: (context, tracks, child) {
                if (tracks.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMid,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'No tracks uploaded yet.',
                        style: TextStyle(
                          color: AppColors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }
                final latestTrack = tracks.last;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMid,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child:
                                latestTrack.coverImagePath != null &&
                                    latestTrack.coverImagePath!.isNotEmpty
                                ? Image.file(
                                    File(latestTrack.coverImagePath!),
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 56,
                                    height: 56,
                                    color: AppColors.tileDark,
                                    child: Icon(
                                      Icons.music_note,
                                      color: AppColors.white54,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  latestTrack.title,
                                  style: TextStyle(
                                    color: AppColors.whiteSmoke,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '1 day ago',
                                  style: TextStyle(
                                    color: AppColors.white54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.whiteSmoke,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              color: AppColors.pureBlack,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton('Share'),
                          _buildActionButton('Distribute'),
                          _buildActionButton(
                            'Insights',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const YourInsightsScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.play_arrow_outlined,
                            color: AppColors.white54,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '0',
                            style: TextStyle(
                              color: AppColors.white54,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 16),
                          Icon(
                            Icons.favorite_border,
                            color: AppColors.white54,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '0',
                            style: TextStyle(
                              color: AppColors.white54,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 16),
                          Icon(
                            Icons.chat_bubble_outline,
                            color: AppColors.white54,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '0',
                            style: TextStyle(
                              color: AppColors.white54,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 16),
                          Icon(
                            Icons.repeat,
                            color: AppColors.white54,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '0',
                            style: TextStyle(
                              color: AppColors.white54,
                              fontSize: 12,
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.more_horiz,
                            color: AppColors.white54,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 32),
            Text(
              'Your remaining credits',
              style: TextStyle(
                color: AppColors.whiteSmoke,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            
            Row(
              children: [
                Expanded(
                  child: _CreditCard(
                    icon: Icons.flash_on,
                    iconColor: AppColors.flashPurple,
                    title: 'Amplify',
                    subtitle: 'TRY IT',
                    onTap: () => _showProModal(
                      'Reach more listeners.',
                      'With Artist Pro, you can get your tracks analyzed and recommended to the right listeners without limits.',
                      'amplify',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CreditCard(
                    icon: Icons.cloud_upload,
                    iconColor: AppColors.studioActionBlue,
                    title: 'Upload time',
                    subtitle: '0/120 mins used',
                    onTap: () => _showProModal(
                      'You have limited upload time',
                      'As a free user, you can upload up to 2 hours of audio content.\n\nUpgrade to Artist Pro to get unlimited uploads.',
                      'upload',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CreditCard(
                    icon: Icons.swap_horiz,
                    iconColor: AppColors.studioActionBlue,
                    title: 'Replace file',
                    subtitle: 'TRY IT',
                    onTap: () => _showProModal(
                      'Enjoy unlimited file replacements.',
                      'With Artist Pro, you can replace files without limits and keep your plays, likes, and comments.',
                      'replace',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            Text(
              'Artists that follow you back',
              style: TextStyle(
                color: AppColors.whiteSmoke,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 100,
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1511367461989-f85a21fda167?q=80&w=300&auto=format&fit=crop',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Abdelrahman Ka...',
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.white54),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Message',
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.white24),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _GridItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _GridItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceMid,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.whiteSmoke, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: AppColors.whiteSmoke,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CreditCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceMid,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(color: AppColors.white70, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: AppColors.white54, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
