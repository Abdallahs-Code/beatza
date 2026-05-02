import 'package:flutter/material.dart';

import 'package:cross_team5/core/theme/app_colors.dart';

import '../models/playback_track_model.dart';

class PlaybackDebugTrackTile extends StatelessWidget {
  final PlaybackTrackModel track;
  final VoidCallback onPlayTap;

  const PlaybackDebugTrackTile({
    super.key,
    required this.track,
    required this.onPlayTap,
  });

  String _buildAccessLabel() {
    return switch (track.accessState) {
      PlaybackAccessState.playable => 'Playable',
      PlaybackAccessState.preview => 'Preview',
      PlaybackAccessState.blocked => 'Blocked',
    };
  }

  Color _buildAccessColor() {
    return switch (track.accessState) {
      PlaybackAccessState.playable => AppColors.whiteSmoke,
      PlaybackAccessState.preview => AppColors.brilliantOrange,
      PlaybackAccessState.blocked => AppColors.anger,
    };
  }

  IconData _buildLeadingIcon() {
    return switch (track.accessState) {
      PlaybackAccessState.playable => Icons.music_note,
      PlaybackAccessState.preview => Icons.lock_clock_outlined,
      PlaybackAccessState.blocked => Icons.block,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [AppColors.tileDark, AppColors.tileDark4],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(_buildLeadingIcon(), color: AppColors.whiteSmoke),
        ),
        title: Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.whiteSmoke,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.artistName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.white60, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                _buildAccessLabel(),
                style: TextStyle(
                  color: _buildAccessColor(),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          onPressed: onPlayTap,
          icon: Icon(
            Icons.play_arrow_rounded,
            color: AppColors.whiteSmoke,
            size: 30,
          ),
        ),
      ),
    );
  }
}
