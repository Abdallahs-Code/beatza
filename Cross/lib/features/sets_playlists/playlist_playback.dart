// Helpers: playlist / album track rows → [PlaybackTrackModel] and global engine.
// Mirrors home screen / genre flow: [PlaybackTrackModel.fromApiJson] + [playTrack].

import 'package:flutter/material.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/playback_streaming_engine_service.dart';
import 'package:cross_team5/features/sets_playlists/models/playlist_model.dart';

List<PlaybackTrackModel> playbackQueueFromPlaylistTracks(
  List<PlaylistTrack> tracks, {
  String? playlistArtistId,
}) {
  return tracks
      .map(
        (t) => playbackModelFromPlaylistTrack(
          t,
          playlistArtistId: playlistArtistId,
        ),
      )
      .toList();
}

/// Builds a [PlaybackTrackModel] for the global player / track options sheet.
/// When the API omits uploader id on embedded track objects, pass
/// [playlistArtistId] (playlist/album owner) so profile / Send to / own-track
/// detection match home behavior.
PlaybackTrackModel playbackModelFromPlaylistTrack(
  PlaylistTrack t, {
  String? playlistArtistId,
}) {
  final PlaybackTrackModel m = t.rawApiJson != null
      ? PlaybackTrackModel.fromApiJson(t.rawApiJson!)
      : PlaybackTrackModel.fromApiJson(_fallbackTrackJson(t));
  final pid = playlistArtistId?.trim();
  if (pid != null &&
      pid.isNotEmpty &&
      (m.artistId == null || m.artistId!.trim().isEmpty)) {
    return m.copyWith(artistId: pid);
  }
  return m;
}

Map<String, dynamic> _fallbackTrackJson(PlaylistTrack t) {
  return {
    '_id': t.id,
    'basicInfo': {
      'title': t.title,
      'permalink': t.permalink,
      'mainArtists': t.mainArtists,
    },
    if (t.audioLink != null && t.audioLink!.trim().isNotEmpty)
      'audio': {'audioLink': t.audioLink},
    if (t.imageUrl != null && t.imageUrl!.trim().isNotEmpty)
      'image': {'imgLink': t.imageUrl},
    'durationInSeconds': t.durationInSeconds,
    'numOfPlays': t.numOfPlays,
    'numOfLikes': t.numOfLikes,
    'isLiked': t.isLiked,
    'isReposted': t.isReposted,
  };
}

/// Same guards as home `_HomePublicTracksSection._handleTrackTap`.
Future<void> playPlaybackQueueAt(
  BuildContext context, {
  required List<PlaybackTrackModel> queue,
  required int index,
}) async {
  if (queue.isEmpty || index < 0 || index >= queue.length) return;
  final track = queue[index];
  if (!track.hasAnyPlayableSource || track.playbackUrl.trim().isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This track does not have a playable audio source yet.',
        ),
      ),
    );
    return;
  }
  if (track.accessState == PlaybackAccessState.blocked) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          track.blockedReason ?? 'Playback is disabled for this track.',
        ),
      ),
    );
    return;
  }
  await PlaybackStreamingEngineService.shared.playTrack(
    track,
    queue: queue,
    startIndex: index,
  );
}

Future<void> playPlaylistTracksAt(
  BuildContext context,
  List<PlaylistTrack> tracks,
  int index, {
  String? playlistArtistId,
}) {
  final queue = playbackQueueFromPlaylistTracks(
    tracks,
    playlistArtistId: playlistArtistId,
  );
  return playPlaybackQueueAt(context, queue: queue, index: index);
}
