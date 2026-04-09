import 'package:flutter/material.dart';
import '../models/track_model.dart';
import '../audio_upload_track_management_routes.dart';

class TrackManagementScreen extends StatefulWidget {
  const TrackManagementScreen({super.key});

  @override
  State<TrackManagementScreen> createState() => _TrackManagementScreenState();
}

class _TrackManagementScreenState extends State<TrackManagementScreen> {
  List<TrackModel> mockTracks = [
    TrackModel(
      id: '1', title: 'Summer Vibes 2026', genre: 'House',
      descriptiveTags: ['summer', 'party'], releaseDate: DateTime.now(),
      fileFormat: 'WAV', processingState: TrackProcessingState.finished,
      visibility: TrackVisibility.public, audioUrl: '', waveformPeaks: [],
    ),
    TrackModel(
      id: '2', title: 'Podcast Episode 4 - Raw', genre: 'Speech',
      descriptiveTags: ['podcast'], releaseDate: DateTime.now(),
      fileFormat: 'MP3', processingState: TrackProcessingState.processing,
      visibility: TrackVisibility.private, audioUrl: '', waveformPeaks: [],
    ),
  ];

  void _toggleVisibility(int index) {
    setState(() {
      final track = mockTracks[index];
      mockTracks[index] = TrackModel(
        id: track.id, title: track.title, genre: track.genre,
        descriptiveTags: track.descriptiveTags, releaseDate: track.releaseDate,
        fileFormat: track.fileFormat, processingState: track.processingState,
        audioUrl: track.audioUrl, waveformPeaks: track.waveformPeaks,
        visibility: track.visibility == TrackVisibility.public ? TrackVisibility.private : TrackVisibility.public,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: const Text('Your Tracks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined, color: Color(0xFFFF5500)),
            onPressed: () => Navigator.pushNamed(context, AudioUploadRoutes.uploadTrack),
          )
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: mockTracks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final track = mockTracks[index];
          final isProcessing = track.processingState == TrackProcessingState.processing;

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isProcessing ? Icons.sync : Icons.music_note,
                    color: isProcessing ? Colors.orange : Colors.white54,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('${track.fileFormat} • ${isProcessing ? 'Processing...' : 'Finished'}',
                          style: TextStyle(color: isProcessing ? Colors.orange : const Color(0xFF9A9A9A), fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Icon(
                      track.visibility == TrackVisibility.public ? Icons.public : Icons.lock_outline,
                      color: const Color(0xFF9A9A9A), size: 16,
                    ),
                    Switch(
                      value: track.visibility == TrackVisibility.private,
                      activeColor: const Color(0xFFFF5500),
                      onChanged: isProcessing ? null : (_) => _toggleVisibility(index),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}