import 'dart:convert';
import 'dart:io';

import 'package:cross_team5/features/activity/models/activity_notification_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ─── Top-level helpers (accessible from background isolate) ──────────────────

// The Socket.io service passes the notification object directly as a Map.
// FCM data values are all strings, so the backend either:
//   (A) JSON-encodes the whole notification under one key, or
//   (B) flattens the top-level fields as strings with actor/target JSON-encoded.
// We try (A) first with the most likely key names, then fall back to (B).
ActivityNotificationModel? _parseFromData(Map<String, dynamic> data) {
  // (A) — full JSON string under a single key
  for (final key in ['notification', 'payload', 'data']) {
    try {
      final raw = data[key];
      if (raw is String && raw.isNotEmpty) {
        return ActivityNotificationModel.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      }
    } catch (_) {}
  }

  // (B) — flattened fields, actor/target are JSON-encoded strings
  try {
    final actorRaw = data['actor'];
    final targetRaw = data['target'];
    if (actorRaw is String && targetRaw is String) {
      final merged = Map<String, dynamic>.from(data);
      merged['actor'] = jsonDecode(actorRaw);
      merged['target'] = jsonDecode(targetRaw);
      merged['read'] = data['read'] == 'true';
      return ActivityNotificationModel.fromJson(merged);
    }
  } catch (_) {}

  return null;
}

String _buildBody(ActivityNotificationModel n) {
  final trackTitle = n.target.title ?? 'your track';
  switch (n.activityType) {
    case 'track_liked':
      return 'liked $trackTitle';
    case 'track_reposted':
      return 'reposted $trackTitle';
    case 'track_commented':
      final c = n.target.commentText;
      return (c != null && c.isNotEmpty) ? 'commented: $c' : 'commented on $trackTitle';
    case 'user_followed':
      return 'started following you';
    case 'user_mentioned':
      return 'mentioned you in a comment';
    case 'new_track':
      return 'posted a new track: $trackTitle';
    default:
      return 'sent you a notification';
  }
}

// Called when a data-only FCM message arrives while the app is killed/background.
// FCM auto-shows messages that carry a `notification` field — this handler
// only needs to display when there is NO notification field (data-only).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (message.notification != null) return; // FCM already showed it

  final notification = _parseFromData(message.data);
  if (notification == null) return;

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(const InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  ));
  await plugin.show(
    notification.notificationId.hashCode.abs() % 100000,
    notification.actor.displayName,
    _buildBody(notification),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'beatza_activity',
        'Activity',
        channelDescription: 'Likes, reposts, comments and follows',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    ),
  );
}

// ─── Service ──────────────────────────────────────────────────────────────────

class PushNotificationService {
  PushNotificationService._shared();
  static final PushNotificationService shared = PushNotificationService._shared();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'beatza_activity';
  static const _channelName = 'Activity';
  static const _channelDesc = 'Likes, reposts, comments and follows';

  static const _androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDesc,
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  static const _notificationDetails = NotificationDetails(android: _androidDetails);

  static const _msgChannelId = 'beatza_messages';
  static const _msgChannelName = 'Messages';
  static const _msgChannelDesc = 'New message notifications';

  static const _msgAndroidDetails = AndroidNotificationDetails(
    _msgChannelId,
    _msgChannelName,
    channelDescription: _msgChannelDesc,
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  static const _msgNotificationDetails = NotificationDetails(android: _msgAndroidDetails);

  Future<void> initialize() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Must be registered before runApp — called from main() before runApp.
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // FCM permission request
      await FirebaseMessaging.instance.requestPermission();

      // Foreground FCM messages — show via local notifications
      // (Socket.io handles the in-app activity feed refresh separately)
      FirebaseMessaging.onMessage.listen((message) {
        final notification = _parseFromData(message.data);
        if (notification != null) show(notification);
      });
    }

    // flutter_local_notifications setup (used on all platforms that support it)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: androidSettings));
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showMessage({
    required String senderName,
    required String content,
    required String chatId,
  }) async {
    final body = content.startsWith('track::') ? 'sent you a track' : content;
    final id = chatId.hashCode.abs() % 100000;
    await _plugin.show(id, senderName, body, _msgNotificationDetails);
  }

  Future<void> show(ActivityNotificationModel notification) async {
    final id = notification.notificationId.hashCode.abs() % 100000;
    await _plugin.show(
      id,
      notification.actor.displayName,
      _buildBody(notification),
      _notificationDetails,
    );
  }
}
