// Single entry for opening [TrackOptionsSheet] with the same variant + callbacks
// as the mini player / home (own vs normal based on signed-in user vs track.artistId).

import 'package:flutter/material.dart';

import 'package:cross_team5/core/navigation/app_navigator.dart';
import 'package:cross_team5/features/activity/screens/behind_the_track_screen.dart';
import 'package:cross_team5/features/activity/screens/track_options_sheet.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';

Future<void> showTrackOptionsSheet(
  BuildContext context,
  PlaybackTrackModel track, {
  VoidCallback? onEditTrack,
}) async {
  final navigatorContext = appNavigatorKey.currentContext;
  if (navigatorContext == null) return;

  final currentUserId = await AuthApiService().getStoredUserId();
  if (!context.mounted) return;
  final isOwnTrack = currentUserId != null &&
      currentUserId.isNotEmpty &&
      track.artistId != null &&
      track.artistId == currentUserId;

  final freshContext = appNavigatorKey.currentContext;
  if (freshContext == null) return;

  await showModalBottomSheet<void>(
    context: freshContext,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TrackOptionsSheet(
      track: track,
      variant: isOwnTrack
          ? TrackOptionsVariant.ownTrack
          : TrackOptionsVariant.normalTrack,
      onEditTrack: onEditTrack,
      onBehindThisTrack: () {
        final navCtx = appNavigatorKey.currentContext;
        if (navCtx == null) return;
        Navigator.of(navCtx, rootNavigator: true).push(
          MaterialPageRoute<void>(
            builder: (_) => BehindTheTrackScreen(
              trackId: track.id,
              actorName: track.artistName,
              actorAvatarUrl: track.artworkUrl ?? '',
              actorUserId: track.artistId ?? '',
              activityType: 'new_track',
              trackOwnerId: track.artistId ?? '',
            ),
          ),
        );
      },
    ),
  );
}
