import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cross_team5/core/navigation/notification_navigation_service.dart';
import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/activity/models/activity_notification_model.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

// ─── Top-level helpers (accessible from background isolate) ──────────────────

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
      return (c != null && c.isNotEmpty)
          ? 'commented: $c'
          : 'commented on $trackTitle';
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
    // No payload here — the tap will be captured by getInitialMessage/onMessageOpenedApp
    // since this notification was triggered by FCM data, not by local plugin.
  );
}

// ─── Service ──────────────────────────────────────────────────────────────────

class PushNotificationService {
  PushNotificationService._shared();
  static final PushNotificationService shared =
      PushNotificationService._shared();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

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

  static const _notificationDetails =
      NotificationDetails(android: _androidDetails);

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

  static const _msgNotificationDetails =
      NotificationDetails(android: _msgAndroidDetails);

  Future<void> initialize() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Must be registered before runApp.
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      await FirebaseMessaging.instance.requestPermission();

      // Foreground FCM message — show via local notification.
      FirebaseMessaging.onMessage.listen((message) {
        final notification = _parseFromData(message.data);
        if (notification != null) show(notification);
      });

      // App was in BACKGROUND — user tapped the system notification.
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        final notification = _parseFromData(message.data);
        if (notification != null) {
          unawaited(NotificationNavigationService.shared
              .handleActivityNotification(notification));
        }
      });

      // App was KILLED — user tapped the system notification that launched us.
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        final notification = _parseFromData(initial.data);
        if (notification != null) {
          // Navigator is not yet ready — stored as pending and executed from HomeScreen.
          unawaited(NotificationNavigationService.shared
              .handleActivityNotification(notification));
        }
      }
    }

    // flutter_local_notifications — handles taps on foreground (in-app) notifications.
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
      final type = data['t'] as String?;

      if (type == 'a') {
        final notification = ActivityNotificationModel(
          notificationId: '',
          to: data['to'] as String? ?? '',
          read: true,
          activityType: data['at'] as String? ?? '',
          actor: ActivityNotificationActor(
            userId: data['auid'] as String? ?? '',
            displayName: data['adn'] as String? ?? '',
            avatarUrl: data['aau'] as String? ?? '',
          ),
          target: ActivityNotificationTarget(
            targetType: '',
            targetId: data['tid'] as String? ?? '',
            title: data['ttl'] as String?,
            trackId: (data['trkid'] as String?)?.isNotEmpty == true
                ? data['trkid'] as String
                : null,
          ),
          createdAt: DateTime.now(),
        );
        unawaited(NotificationNavigationService.shared
            .handleActivityNotification(notification));
      } else if (type == 'm') {
        unawaited(NotificationNavigationService.shared.handleChatNotification(
          chatId: data['cid'] as String? ?? '',
          receiverName: data['rn'] as String? ?? '',
          receiverPhotoUrl: data['rp'] as String? ?? '',
        ));
      }
    } catch (_) {}
  }

  // Call after login (and on every app launch while logged in).
  Future<void> registerFcmToken(String accessToken) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;
      await _postFcmToken(accessToken, fcmToken);

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        final fresh = await AuthApiService().getStoredAccessToken();
        if (fresh != null) await _postFcmToken(fresh, newToken);
      });
    } catch (_) {}
  }

  Future<void> _postFcmToken(String accessToken, String fcmToken) async {
    try {
      await http.post(
        Uri.parse('${ApiServices().baseUrl}/api/notifications/v1/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'User-Agent': 'Android',
        },
        body: jsonEncode({'token': fcmToken, 'platform': 'android'}),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<void> showMessage({
    required String senderName,
    required String content,
    required String chatId,
    String receiverPhotoUrl = '',
  }) async {
    final body =
        content.startsWith('track::') ? 'sent you a track' : content;
    final id = chatId.hashCode.abs() % 100000;
    final payload = jsonEncode({
      't': 'm',
      'cid': chatId,
      'rn': senderName,
      'rp': receiverPhotoUrl,
    });
    await _plugin.show(id, senderName, body, _msgNotificationDetails,
        payload: payload);
  }

  Future<void> show(ActivityNotificationModel notification) async {
    final id = notification.notificationId.hashCode.abs() % 100000;
    final payload = jsonEncode({
      't': 'a',
      'at': notification.activityType,
      'auid': notification.actor.userId,
      'adn': notification.actor.displayName,
      'aau': notification.actor.avatarUrl,
      'tid': notification.target.targetId,
      'trkid': notification.target.trackId ?? '',
      'ttl': notification.target.title ?? '',
      'to': notification.to,
    });
    await _plugin.show(
      id,
      notification.actor.displayName,
      _buildBody(notification),
      _notificationDetails,
      payload: payload,
    );
  }
}
