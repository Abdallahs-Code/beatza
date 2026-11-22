
import 'package:flutter/material.dart';


import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/core/theme/app_text.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/library/services/library_history_api_service.dart';
import 'package:cross_team5/features/library/widgets/library_widgets.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:provider/provider.dart';
import 'package:cross_team5/core/services/theme_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/playback_streaming_engine_service.dart';

class ListeningHistoryScreen extends StatefulWidget {
  final List<PlaybackTrackModel> initialTracks;

  const ListeningHistoryScreen({super.key, required this.initialTracks});

  @override
  State<ListeningHistoryScreen> createState() => _ListeningHistoryScreenState();
}

class _ListeningHistoryScreenState extends State<ListeningHistoryScreen> {
  late List<PlaybackTrackModel> _tracks;
  final AuthApiService _authApiService = AuthApiService();
  final LibraryHistoryApiService _historyApiService =
      LibraryHistoryApiService();

  @override
  void initState() {
    super.initState();
    _tracks = List<PlaybackTrackModel>.from(widget.initialTracks);
  }

  Future<void> _playTrack(PlaybackTrackModel track, int index) async {
    await PlaybackStreamingEngineService.shared.playTrack(
      track,
      queue: _tracks,
      startIndex: index,
    );
  }

  Future<void> _showClearHistoryDialog() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Clear listening history?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'This will permanently clear your listening history.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.white60, height: 1.45),
          ),
          actionsPadding: EdgeInsets.zero,
          actions: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pop(dialogContext, false),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.white12),
                          right: BorderSide(color: AppColors.white12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.blueHyperlink,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pop(dialogContext, true),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.white12),
                        ),
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          color: AppColors.blueHyperlink,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final String? token = await _authApiService.getStoredAccessToken();
        if (token == null || token.trim().isEmpty) return;
        await _historyApiService.deleteUserHistory(token);
        if (!mounted) return;
        setState(() => _tracks = []);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to clear history. Try again.')),
        );
      }
    }
  }

  void _handleBack() {
    Navigator.pop(context, _tracks);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeService>();
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      bottomNavigationBar: const LibraryBottomArea(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  CircularIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: _handleBack,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        AppText.listeningHistory,
                        style: TextStyle(
                          color: AppColors.whiteSmoke,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _showClearHistoryDialog,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.white60,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: _tracks.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: _ListeningHistoryEmptyState(),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 170),
                      itemCount: _tracks.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 18),
                      itemBuilder: (context, index) {
                        return HistoryTrackTile(
                          track: _tracks[index],
                          onTap: () => _playTrack(_tracks[index], index),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListeningHistoryEmptyState extends StatelessWidget {
  const _ListeningHistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeService>();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.tileDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.history_rounded,
              color: AppColors.white60,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No tracks in history',
                  style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Tracks you listen to will appear here.',
                  style: TextStyle(
                    color: AppColors.white60,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
