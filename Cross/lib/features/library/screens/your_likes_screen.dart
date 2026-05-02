import 'package:flutter/material.dart';

import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/library/services/library_history_api_service.dart';
import 'package:cross_team5/features/library/widgets/library_widgets.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/playback_streaming_engine_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/mini_player_state.dart';

class YourLikesScreen extends StatefulWidget {
  const YourLikesScreen({super.key});

  @override
  State<YourLikesScreen> createState() => _YourLikesScreenState();
}

class _YourLikesScreenState extends State<YourLikesScreen> {
  final AuthApiService _authApiService = AuthApiService();
  final LibraryHistoryApiService _libraryService = LibraryHistoryApiService();

  List<PlaybackTrackModel> _likedTracks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLikedTracks();
  }

  @override
  void dispose() {
    _libraryService.dispose();
    super.dispose();
  }

  Future<void> _loadLikedTracks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _authApiService.getStoredAccessToken();
      final userId = await _authApiService.getStoredUserId();

      if (token == null || userId == null) {
        throw Exception('Please sign in to view your likes.');
      }

      final tracks = await _libraryService.getUserLikedTracks(userId, token);

      if (!mounted) return;
      setState(() {
        _likedTracks = tracks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _playTrack(PlaybackTrackModel track, int index) async {
    await PlaybackStreamingEngineService.shared.playTrack(
      track,
      queue: _likedTracks,
      startIndex: index,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      appBar: AppBar(
        backgroundColor: AppColors.pureBlack,
        title: Text(
          'Your likes',
          style: TextStyle(
            color: AppColors.whiteSmoke,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.whiteSmoke),
        actions: _likedTracks.isNotEmpty
            ? [
                IconButton(
                  icon: Icon(
                    Icons.shuffle_rounded,
                    color: AppColors.whiteSmoke,
                  ),
                  onPressed: () {
                    final shuffled = List<PlaybackTrackModel>.from(_likedTracks)
                      ..shuffle();
                    PlaybackStreamingEngineService.shared.playTrack(
                      shuffled.first,
                      queue: shuffled,
                      startIndex: 0,
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.play_circle_outline_rounded,
                    color: AppColors.whiteSmoke,
                    size: 30,
                  ),
                  onPressed: () {
                    PlaybackStreamingEngineService.shared.playTrack(
                      _likedTracks.first,
                      queue: _likedTracks,
                      startIndex: 0,
                    );
                  },
                ),
                const SizedBox(width: 4),
              ]
            : null,
      ),
      body: _buildBody(),
      bottomNavigationBar: const MiniPlayerSpacer(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: AppColors.white54, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.white54),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadLikedTracks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: AppColors.whiteSmoke,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_likedTracks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_border_rounded,
                color: AppColors.white54,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'No liked tracks yet',
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Like a track and it will show up here.',
                style: TextStyle(color: AppColors.white54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 140),
      itemCount: _likedTracks.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: HistoryTrackTile(
            track: _likedTracks[index],
            onTap: () => _playTrack(_likedTracks[index], index),
          ),
        );
      },
    );
  }
}
