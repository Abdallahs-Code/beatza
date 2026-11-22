import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cross_team5/core/services/theme_service.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/features/library/widgets/library_widgets.dart';
import '../services/offline_download_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/playback_streaming_engine_service.dart';

class OfflineDownloadsScreen extends StatelessWidget {
  const OfflineDownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeService>();
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      appBar: AppBar(
        backgroundColor: AppColors.pureBlack,
        elevation: 0,
        title: const Text(
          'Downloads',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<List<PlaybackTrackModel>>(
        valueListenable: OfflineDownloadService.shared.downloadedTracksNotifier,
        builder: (context, tracks, _) {
          if (tracks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_for_offline,
                    color: AppColors.white54,
                    size: 80,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No downloaded tracks yet.',
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Download tracks to listen without internet.',
                    style: TextStyle(color: AppColors.white60, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tracks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final track = tracks[index];
              return HistoryTrackTile(
                track: track,
                onTap: () async {
                  await PlaybackStreamingEngineService.shared.playTrack(
                    track,
                    queue: tracks,
                    startIndex: index,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
