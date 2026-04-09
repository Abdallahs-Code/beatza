import 'dart:io';
import 'package:flutter/material.dart';
import '../audio_upload_track_management_routes.dart';
import '../services/audio_upload_service.dart';
import '../models/track_model.dart';
import 'your_uploads_screen.dart';

class YourInsightsScreen extends StatefulWidget {
  const YourInsightsScreen({super.key});

  @override
  State<YourInsightsScreen> createState() => _YourInsightsScreenState();
}

class _YourInsightsScreenState extends State<YourInsightsScreen> {
  String _selectedFilter = 'Last 7 Days';
  final List<String> _filterOptions = ['Last 7 Days', 'Last 30 Days', 'Last 12 Months', 'All Time'];

  void _downloadReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            SizedBox(width: 16),
            Text('Generating report...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: const Color(0xFF1DB954),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Your insights', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<List<TrackModel>>(
        valueListenable: AudioUploadService.globalMockTracksNotifier,
        builder: (context, tracks, child) {
          if (tracks.isEmpty) {
            return _buildEmptyState(context);
          } else {
            return _buildProDashboard(context, tracks);
          }
        },
      ),
    );
  }
  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'SoundCloud',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                  decorationThickness: 2,
                ),
              ),
              const SizedBox(width: 24),
              Text(
                'All Platforms',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Center(
            child: SizedBox(
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200, height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFFF5500)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Icon(Icons.graphic_eq, color: Colors.white, size: 40)),
                  ),
                  const Positioned(bottom: 0, right: 30, child: Icon(Icons.pie_chart, color: Color(0xFFFF5500), size: 30)),
                  const Positioned(bottom: -10, left: 40, child: Icon(Icons.bar_chart, color: Colors.white, size: 30)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'Get unmatched insights into your listeners that you won\'t find anywhere else.',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.2),
          ),
          const SizedBox(height: 24),
          const Text(
            'SoundCloud is the only platform that lets you easily identify and connect with your top fans based on their listening and engagement habits.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'To get started, all it takes is an upload.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, AudioUploadRoutes.uploadTrack),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white, width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: const Text('Upload', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProDashboard(BuildContext context, List<TrackModel> tracks) {
    double multiplier = 1.0;
    if (_selectedFilter == 'Last 30 Days') multiplier = 4.2;
    if (_selectedFilter == 'Last 12 Months') multiplier = 15.5;
    if (_selectedFilter == 'All Time') multiplier = 25.0;

    int totalPlays = ((tracks.length * 14250 + 342) * multiplier).toInt();
    int totalLikes = ((tracks.length * 840 + 12) * multiplier).toInt();
    int totalComments = ((tracks.length * 124 + 5) * multiplier).toInt();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PopupMenuButton<String>(
                color: const Color(0xFF1C1C1C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (String value) {
                  setState(() {
                    _selectedFilter = value;
                  });
                },
                itemBuilder: (BuildContext context) {
                  return _filterOptions.map((String choice) {
                    return PopupMenuItem<String>(
                      value: choice,
                      child: Text(choice, style: TextStyle(color: _selectedFilter == choice ? const Color(0xFFFF5500) : Colors.white)),
                    );
                  }).toList();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFF1C1C1C), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Text(_selectedFilter, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 18),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_rounded, color: Colors.white, size: 28),
                onPressed: _downloadReport,
                splashRadius: 24,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildStatCard('Plays', _formatNumber(totalPlays), '+12%', true)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Likes', _formatNumber(totalLikes), '+4%', true)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Comments', _formatNumber(totalComments), '-2%', false)),
            ],
          ),
          const SizedBox(height: 32),

          const Text('Plays Overview', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildCustomBarChart(),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Top Tracks', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const YourUploadsScreen()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text('See All', style: TextStyle(color: const Color(0xFFFF5500).withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...tracks.take(5).map((track) {
            int trackPlays = (((track.title.length * 3120) % 50000 + 1000) * multiplier).toInt();
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: const Color(0xFF1D1D1D), borderRadius: BorderRadius.circular(4)),
                    child: track.coverImagePath != null && track.coverImagePath!.isNotEmpty
                        ? ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.file(File(track.coverImagePath!), fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.music_note, color: Colors.white24)))
                        : const Icon(Icons.music_note, color: Colors.white24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(track.genre.isEmpty ? 'Unknown Genre' : track.genre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF9A9A9A), fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_formatNumber(trackPlays), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Plays', style: TextStyle(color: Color(0xFF9A9A9A), fontSize: 11)),
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          const Text('Top Listeners Location', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF141414), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
            child: Column(
              children: [
                _buildLocationRow('1', 'Cairo, Egypt', 0.85),
                const SizedBox(height: 16),
                _buildLocationRow('2', 'Riyadh, KSA', 0.60),
                const SizedBox(height: 16),
                _buildLocationRow('3', 'Dubai, UAE', 0.45),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  Widget _buildStatCard(String title, String value, String percentage, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF9A9A9A), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, color: isPositive ? const Color(0xFF49D17D) : Colors.redAccent, size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                    percentage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: isPositive ? const Color(0xFF49D17D) : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBarChart() {
    double mod = _selectedFilter == 'Last 7 Days' ? 1.0 : (_selectedFilter == 'Last 30 Days' ? 0.8 : 1.2);
    final List<double> heights = [40 * mod, 70 * mod, 50 * mod, 100 * mod, 80 * mod, 120 * mod, 90 * mod];

    for (int i = 0; i < heights.length; i++) {
      if (heights[i] > 110) heights[i] = 110;
    }

    final List<String> days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          bool isMax = heights[index] == heights.reduce((curr, next) => curr > next ? curr : next);

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isMax)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                  child: const Text('Peak', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 22,
                    height: heights[index],
                    decoration: BoxDecoration(
                      color: isMax ? const Color(0xFFFF5500) : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(days[index], style: TextStyle(color: isMax ? Colors.white : const Color(0xFF777777), fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLocationRow(String rank, String city, double percentage) {
    return Row(
      children: [
        Text(rank, style: const TextStyle(color: Color(0xFF9A9A9A), fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(city, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(height: 6, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(4))),
                  FractionallySizedBox(
                    widthFactor: percentage,
                    child: Container(height: 6, decoration: BoxDecoration(color: const Color(0xFFFF5500), borderRadius: BorderRadius.circular(4))),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 40,
          child: Text('${(percentage * 100).toInt()}%', textAlign: TextAlign.end, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}