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

// ─── Top-level helpers (must be accessible from background isolate) ───────────

// Parses an FCM data map into an ActivityNotificationModel.
// The backend sends actor/target as JSON-encoded strings under the keys
// "actor" and "target", with all other fields as plain strings.
// Pattern A is kept as a fallback in case the format ever changes.
ActivityNotificationModel? _parseFromData(Map<String, dynamic> data) {
  // (A) — full notification JSON encoded as a string under a single key
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

  // (B) — actor/target as nested Maps (actual backend format).
  //   Also handles the legacy case where they arrive as JSON-encoded strings.
  if (data.containsKey('actor') || data.containsKey('activityType')) {
    try {
      final merged = Map<String, dynamic>.from(data);
      final actorRaw = merged['actor'];
      final targetRaw = merged['target'];
      if (actorRaw is String) merged['actor'] = jsonDecode(actorRaw);
      if (targetRaw is String) merged['target'] = jsonDecode(targetRaw);
      // read may arrive as bool or as the string "true"/"false"
      if (merged['read'] is String) {
        merged['read'] = merged['read'] == 'true';
      }
      return ActivityNotificationModel.fromJson(merged);
    } catch (_) {}
  }

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

String _buildActivityPayload(ActivityNotificationModel n) {
  return jsonEncode({
    't': 'a',
    'at': n.activityType,
    'auid': n.actor.userId,
    'adn': n.actor.displayName,
    'aau': n.actor.avatarUrl,
    'tid': n.target.targetId,
    'trkid': n.target.trackId ?? '',
    'ttl': n.target.title ?? '',
    'to': n.to,
  });
}

// Handles data-only FCM messages while the app is in the background / killed.
// FCM auto-shows messages that carry a `notification` field — this handler
// only runs when there is NO notification field.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (message.notification != null) return;

  final notification = _parseFromData(message.data);
  if (notification == null) return;

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
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
    payload: _buildActivityPayload(notification),
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

  static const _notificationDetails = NotificationDetails(
    android: _androidDetails,
  );

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

  static const _msgNotificationDetails = NotificationDetails(
    android: _msgAndroidDetails,
  );

  Future<void> initialize() async {
    // ── Step 1: capture launch-from-local-notification details BEFORE
    //   calling _plugin.initialize().  On Android (flutter_local_notifications
    //   v15+) calling getNotificationAppLaunchDetails() after initialize()
    //   always returns null.
    NotificationAppLaunchDetails? localLaunchDetails;
    if (Platform.isAndroid || Platform.isIOS) {
      localLaunchDetails = await _plugin.getNotificationAppLaunchDetails();
    }

    // ── Step 2: FCM setup ────────────────────────────────────────────────────
    if (Platform.isAndroid || Platform.isIOS) {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      await FirebaseMessaging.instance.requestPermission();

      // Foreground FCM message → show via local notification.
      FirebaseMessaging.onMessage.listen((message) {
        final notification = _parseFromData(message.data);
        if (notification != null) show(notification);
      });

      // App was in BACKGROUND → user tapped the system FCM notification.
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        final notification = _parseFromData(message.data);
        if (notification != null) {
          unawaited(
            NotificationNavigationService.shared.handleActivityNotification(
              notification,
            ),
          );
        }
      });

      // NOTE: getInitialMessage() is intentionally NOT called here.
      // The Firebase Flutter plugin requires it to be called from a widget
      // (after runApp) to reliably receive the initial message on Android.
      // It is called from HomeScreen via handleInitialFcmMessage() below.
    }

    // ── Step 3: initialise local-notifications plugin ────────────────────────
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // ── Step 4: handle app launched from a local notification (data-only FCM
    //   shown by the background handler).  Details were captured in Step 1.
    if (localLaunchDetails != null &&
        localLaunchDetails.didNotificationLaunchApp) {
      final response = localLaunchDetails.notificationResponse;
      if (response != null) _onLocalNotificationTap(response);
    }
  }

  /// Call this from HomeScreen.initState (inside addPostFrameCallback).
  ///
  /// The Firebase Flutter plugin requires getInitialMessage() to be called
  /// from a widget after the app is running, not from main() before runApp().
  /// Calling it too early returns null on Android even when the app was
  /// genuinely opened by tapping an FCM notification.
  Future<void> handleInitialFcmMessage() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial == null) return;
      final notification = _parseFromData(initial.data);
      if (notification != null) {
        await NotificationNavigationService.shared.handleActivityNotification(
          notification,
        );
      }
    } catch (_) {}
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
        unawaited(
          NotificationNavigationService.shared.handleActivityNotification(
            notification,
          ),
        );
      } else if (type == 'm') {
        unawaited(
          NotificationNavigationService.shared.handleChatNotification(
            chatId: data['cid'] as String? ?? '',
            receiverName: data['rn'] as String? ?? '',
            receiverPhotoUrl: data['rp'] as String? ?? '',
          ),
        );
      }
    } catch (_) {}
  }

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
      await http
          .post(
            Uri.parse(
              '${ApiServices().baseUrl}/api/notifications/v1/fcm-token',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
              'User-Agent': 'Android',
            },
            body: jsonEncode({'token': fcmToken, 'platform': 'android'}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<void> showMessage({
    required String senderName,
    required String content,
    required String chatId,
    String receiverPhotoUrl = '',
  }) async {
    final body = content.startsWith('track::') ? 'sent you a track' : content;
    final id = chatId.hashCode.abs() % 100000;
    final payload = jsonEncode({
      't': 'm',
      'cid': chatId,
      'rn': senderName,
      'rp': receiverPhotoUrl,
    });
    await _plugin.show(
      id,
      senderName,
      body,
      _msgNotificationDetails,
      payload: payload,
    );
  }

  Future<void> show(ActivityNotificationModel notification) async {
    final id = notification.notificationId.hashCode.abs() % 100000;
    await _plugin.show(
      id,
      notification.actor.displayName,
      _buildBody(notification),
      _notificationDetails,
      payload: _buildActivityPayload(notification),
    );
  }
}
