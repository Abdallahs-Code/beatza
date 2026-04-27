// Widget: VibesGrid
// Static genre/mood grid shown on the Search screen when the user
// is not actively typing (idle state). Matches the SoundCloud UI in
// module_8_screens.pdf page 1 (left screenshot).
//
// Genres are hardcoded — no API for this yet (as confirmed by user).
// Each tile has a unique gradient color pair to match the SoundCloud style.

import 'package:flutter/material.dart';

class VibesGrid extends StatelessWidget {
  const VibesGrid({super.key});

  static const List<_VibeItem> _vibes = [
    _VibeItem('Hip Hop & Rap', Color(0xFF6B2FBA), Color(0xFF9B59B6)),
    _VibeItem('Electronic', Color(0xFFFF4081), Color(0xFFE91E63)),
    _VibeItem('Pop', Color(0xFFFFD600), Color(0xFFFFC107)),
    _VibeItem('R&B', Color(0xFF00BCD4), Color(0xFF0097A7)),
    _VibeItem('Party', Color(0xFFFF5722), Color(0xFFE64A19)),
    _VibeItem('Chill', Color(0xFF4CAF50), Color(0xFF388E3C)),
    _VibeItem('Workout', Color(0xFF03A9F4), Color(0xFF0288D1)),
    _VibeItem('Techno', Color(0xFF9C27B0), Color(0xFF7B1FA2)),
    _VibeItem('Jazz', Color(0xFF795548), Color(0xFF5D4037)),
    _VibeItem('Classical', Color(0xFF607D8B), Color(0xFF455A64)),
    _VibeItem('Arabic', Color(0xFFFF9800), Color(0xFFF57C00)),
    _VibeItem('Afrobeats', Color(0xFF009688), Color(0xFF00796B)),
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
            return _VibeCard(vibe: vibe);
          },
        ),
      ],
    );
  }
}

class _VibeCard extends StatelessWidget {
  final _VibeItem vibe;

  const _VibeCard({required this.vibe});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Decorative tilted image-like block in bottom right
          Positioned(
            right: -10,
            bottom: -10,
            child: Transform.rotate(
              angle: 0.4,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // Label
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
    );
  }
}

class _VibeItem {
  final String label;
  final Color colorStart;
  final Color colorEnd;

  const _VibeItem(this.label, this.colorStart, this.colorEnd);
}
