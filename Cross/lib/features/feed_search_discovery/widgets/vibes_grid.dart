





import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import '../screens/genre_tracks_screen.dart';

class VibesGrid extends StatelessWidget {
  const VibesGrid({super.key});

  static const List<_VibeItem> _vibes = [
    _VibeItem(
      'Alternative Rock',
      AppColors.vibeAltRockStart,
      AppColors.vibeAltRockEnd,
    ),
    _VibeItem('Ambient', AppColors.vibeAmbientStart, AppColors.vibeAmbientEnd),
    _VibeItem(
      'Classical',
      AppColors.vibeClassicalStart,
      AppColors.vibeClassicalEnd,
    ),
    _VibeItem('Country', AppColors.vibeCountryStart, AppColors.vibeCountryEnd),
    _VibeItem(
      'Electronic',
      AppColors.vibeElectronicStart,
      AppColors.vibeElectronicEnd,
    ),
    _VibeItem('Hip-Hop', AppColors.vibeHipHopStart, AppColors.vibeHipHopEnd),
    _VibeItem('House', AppColors.vibeHouseStart, AppColors.vibeHouseEnd),
    _VibeItem('Indie', AppColors.vibeIndieStart, AppColors.vibeIndieEnd),
    _VibeItem('Jazz', AppColors.vibeJazzStart, AppColors.vibeJazzEnd),
    _VibeItem('Latin', AppColors.vibeLatinStart, AppColors.vibeLatinEnd),
    _VibeItem('Metal', AppColors.vibeMetalStart, AppColors.vibeMetalEnd),
    _VibeItem('Pop', AppColors.vibePopStart, AppColors.vibePopEnd),
    _VibeItem('R&B', AppColors.vibeRnBStart, AppColors.vibeRnBEnd),
    _VibeItem('Reggae', AppColors.vibeReggaeStart, AppColors.vibeReggaeEnd),
    _VibeItem('Rock', AppColors.vibeRockStart, AppColors.vibeRockEnd),
    _VibeItem('Soul', AppColors.vibeSoulStart, AppColors.vibeSoulEnd),
    _VibeItem('Trap', AppColors.vibeTrapStart, AppColors.vibeTrapEnd),
    _VibeItem(
      'World Music',
      AppColors.vibeWorldMusicStart,
      AppColors.vibeWorldMusicEnd,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Vibes',
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.8,
          ),
          itemCount: _vibes.length,
          itemBuilder: (context, index) {
            final vibe = _vibes[index];
            return _VibeCard(
              vibe: vibe,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GenreTracksScreen(
                    genre: vibe.label,
                    genreColor: vibe.colorStart,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _VibeCard extends StatelessWidget {
  final _VibeItem vibe;
  final VoidCallback onTap;

  const _VibeCard({required this.vibe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [vibe.colorStart, vibe.colorEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            
            Positioned(
              right: -10,
              bottom: -10,
              child: Transform.rotate(
                angle: 0.4,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.whiteSmoke.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                vibe.label,
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VibeItem {
  final String label;
  final Color colorStart;
  final Color colorEnd;

  const _VibeItem(this.label, this.colorStart, this.colorEnd);
}
