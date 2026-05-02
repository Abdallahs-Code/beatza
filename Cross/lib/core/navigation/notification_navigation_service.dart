import 'dart:async';

import 'package:cross_team5/core/navigation/app_navigator.dart';
import 'package:cross_team5/core/navigation/profile_navigator.dart';
import 'package:cross_team5/features/activity/models/activity_notification_model.dart';
import 'package:cross_team5/features/activity/screens/behind_the_track_screen.dart';
import 'package:cross_team5/features/activity/screens/quick_reply_sheet.dart';
import 'package:cross_team5/features/messaging_track_sharing/messaging_track_sharing_routes.dart';
import 'package:flutter/material.dart';

class NotificationNavigationService {
  NotificationNavigationService._();
  static final NotificationNavigationService shared =
      NotificationNavigationService._();

  ActivityNotificationModel? _pendingNotification;
  ({String chatId, String receiverName, String receiverPhotoUrl})? _pendingChat;

  /// Call when a push notification is tapped. If the navigator is not yet
  /// ready (cold start), the action is queued and executed once
  /// [executePendingIfAny] is called (from HomeScreen).
  Future<void> handleActivityNotification(
    ActivityNotificationModel notification,
  ) async {
    final nav = appNavigatorKey.currentState;
    if (nav == null) {
      _pendingNotification = notification;
      return;
    }
    await _navigateActivity(nav, notification);
  }

  Future<void> handleChatNotification({
    required String chatId,
    required String receiverName,
    required String receiverPhotoUrl,
  }) async {
    final nav = appNavigatorKey.currentState;
    if (nav == null) {
      _pendingChat = (
        chatId: chatId,
        receiverName: receiverName,
        receiverPhotoUrl: receiverPhotoUrl,
      );
      return;
    }
    _navigateChat(nav, chatId, receiverName, receiverPhotoUrl);
  }

  /// Called from HomeScreen after the app finishes loading — executes any
  /// navigation that was queued during a cold start.
  Future<void> executePendingIfAny() async {
    final pending = _pendingNotification;
    final chat = _pendingChat;
    _pendingNotification = null;
    _pendingChat = null;

    final nav = appNavigatorKey.currentState;
    if (nav == null) return;

    if (pending != null) await _navigateActivity(nav, pending);
    if (chat != null) {
      _navigateChat(nav, chat.chatId, chat.receiverName, chat.receiverPhotoUrl);
    }
  }

  Future<void> _navigateActivity(
    NavigatorState nav,
    ActivityNotificationModel n,
  ) async {
    final resolvedTrackId = (n.target.trackId?.isNotEmpty == true)
        ? n.target.trackId!
        : n.target.targetId;

    switch (n.activityType) {
      case 'user_followed':
        await ProfileNavigator.pushViaState(nav, n.actor.userId);

      case 'track_liked':
      case 'track_reposted':
      case 'new_track':
        final trackOwnerId = n.activityType == 'new_track'
            ? n.actor.userId
            : n.to;
        unawaited(
          nav.push(
            MaterialPageRoute(
              builder: (_) => BehindTheTrackScreen(
                trackId: resolvedTrackId,
                actorName: n.actor.displayName,
                actorAvatarUrl: n.actor.avatarUrl,
                actorUserId: n.actor.userId,
                activityType: n.activityType,
                trackOwnerId: trackOwnerId,
              ),
            ),
          ),
        );

      case 'track_commented':
      case 'user_mentioned':
        showModalBottomSheet(
          context: nav.context,
          isScrollControlled: true,
          useRootNavigator: true,
          backgroundColor: Colors.transparent,
          builder: (_) => QuickReplySheet(
            trackId: resolvedTrackId,
            trackTitle: n.target.title ?? '',
            trackArtist: n.actor.displayName,
            trackThumbnailUrl: null,
            numComments: 0,
            numReposts: 0,
          ),
        );
    }
  }

  void _navigateChat(
    NavigatorState nav,
    String chatId,
    String receiverName,
    String receiverPhotoUrl,
  ) {
    nav.pushNamed(
      MessagingTrackSharingRoutes.chatRoute,
      arguments: {
        'chatId': chatId,
        'receiverName': receiverName,
        'receiverPhotoUrl': receiverPhotoUrl,
      },
    );
  }
}
