// Widget: VibesGrid
// Static genre grid shown on the Search screen when the user
// is not actively typing (idle state). Genres match the app's
// upload genre list exactly. Tapping a tile navigates to
// GenreTracksScreen with tracks filtered by that genre.

import 'package:flutter/material.dart';
import '../screens/genre_tracks_screen.dart';

class VibesGrid extends StatelessWidget {
  const VibesGrid({super.key});

  static const List<_VibeItem> _vibes = [
    _VibeItem('Alternative Rock', Color(0xFFC0392B), Color(0xFF922B21)),
    _VibeItem('Ambient',          Color(0xFF0097A7), Color(0xFF006064)),
    _VibeItem('Classical',        Color(0xFF546E7A), Color(0xFF37474F)),
    _VibeItem('Country',          Color(0xFFF57F17), Color(0xFFE65100)),
    _VibeItem('Electronic',       Color(0xFFE91E63), Color(0xFFAD1457)),
    _VibeItem('Hip-Hop',          Color(0xFF6B2FBA), Color(0xFF4A148C)),
    _VibeItem('House',            Color(0xFFFF5722), Color(0xFFBF360C)),
    _VibeItem('Indie',            Color(0xFF388E3C), Color(0xFF1B5E20)),
    _VibeItem('Jazz',             Color(0xFF795548), Color(0xFF3E2723)),
    _VibeItem('Latin',            Color(0xFFF44336), Color(0xFFB71C1C)),
    _VibeItem('Metal',            Color(0xFF455A64), Color(0xFF263238)),
    _VibeItem('Pop',              Color(0xFFFFD600), Color(0xFFFFC107)),
    _VibeItem('R&B',              Color(0xFF00BCD4), Color(0xFF006064)),
    _VibeItem('Reggae',           Color(0xFF2E7D32), Color(0xFF1B5E20)),
    _VibeItem('Rock',             Color(0xFFD32F2F), Color(0xFFB71C1C)),
    _VibeItem('Soul',             Color(0xFF7B1FA2), Color(0xFF4A148C)),
    _VibeItem('Trap',             Color(0xFF283593), Color(0xFF1A237E)),
    _VibeItem('World Music',      Color(0xFF00695C), Color(0xFF004D40)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Vibes',
            style: TextStyle(
              color: Colors.white,
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
            // Decorative tilted block in bottom right (SoundCloud style)
            Positioned(
              right: -10,
              bottom: -10,
              child: Transform.rotate(
                angle: 0.4,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            // Genre label
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                vibe.label,
                style: const TextStyle(
                  color: Colors.white,
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
