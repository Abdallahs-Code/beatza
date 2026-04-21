import 'package:cross_team5/features/activity/models/activity_notification_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  PushNotificationService._shared();
  static final PushNotificationService shared = PushNotificationService._shared();

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

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    // Request permission on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> show(ActivityNotificationModel notification) async {
    final title = notification.actor.displayName;
    final body = _buildBody(notification);
    // Use hashCode of notificationId as int ID (keeps notifications distinct)
    final id = notification.notificationId.hashCode.abs() % 100000;

    await _plugin.show(id, title, body, _notificationDetails);
  }

  String _buildBody(ActivityNotificationModel n) {
    final trackTitle = n.target.title ?? 'your track';
    switch (n.activityType) {
      case 'track_liked':
        return 'liked $trackTitle';
      case 'track_reposted':
        return 'reposted $trackTitle';
      case 'track_commented':
        final comment = n.target.commentText;
        return comment != null && comment.isNotEmpty
            ? 'commented: $comment'
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
}
